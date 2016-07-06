#!/usr/bin/env python
##############################################################################
# Copyright (c) 2015,2016 Ericsson AB, Mirantis Inc., Enea AB and others.
# mskalski@mirantis.com
# Alexandru.Avadanii@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# Build multiarch partial local Ubuntu mirror
##############################################################################
# Design quirks / workarounds:
# 1. Fuel-agent uses `debootstrap` to build bootstrap and target chroots from
#    the local mirror; which only uses the "main" component from the first
#    repository, i.e. does not include "updates"/"security".
#    In order to fullfill all debootstrap dependencies in "main" repo, we will
#    do an extra packetary run using a reduced scope:
#    - only "main" component of the first mirror;
#    - reduced package dependency list (without MOS/OPNFV plugin deps).
# 2. If repo structure is not mandatory to be in sync with official mirrors,
#    we can mitigate the issue by "merging" all repo-components into a single
#    "main".
##############################################################################
# Mirror build steps (for EACH architecture in UBUNTU_ARCH):
# 1. Collect bootstrap package deps from <fuel_bootstrap_cli.yaml>;
# 2. Collect all fixture release packages from fuel-web's <openstack.yaml>;
# 3. Parse new "opnfv_config.yaml" list of packages (from old fuel-mirror);
# 4. Inherit enviroment variable(s) for mirror URLs, paths etc.
#    - Allow arch-specific overrides for each env var;
# 5. Mirror config is defined based on common config + OPNFV overrides;
#    - Convert old configuration format to packetary style where needed;
# 6. Package lists are defined based on common config + OPNFV deps;
#    - Keep track of "main" packages separately, required by debootstrap;
# 7. Clone/update all mirror components;
# 8. IF mirror merging is disabled OR workaround for ifupdown (see below):
#    - Clone/update "main" mirror component (fix missing debootstrap deps);
# 9. IF mirror merging is enabled:
#    - Use `dpkg-scanpackages` to filter out old versions of duplicate pkgs;
#    - Run `packetary create` on the set of downloaded packages, merging
#      them on the fly into a single-component mirror;
##############################################################################

import copy
import os
import shutil
import sys
import yaml
from contextlib import contextmanager
from cStringIO import StringIO
from packetary.cli.app import main

@contextmanager
def captureStdOut(output):
    stdout = sys.stdout
    sys.stdout = output
    yield
    sys.stdout = stdout

# FIXME: Find a better approach for eliminating duplicate logs than this
def force_logger_reload():
  for mod in sys.modules.keys():
    if mod.startswith('logging'):
      try:
        reload(sys.modules[mod])
      except:
        pass

# Determine missing package dependecies for a mirror defition
def get_unres_pkgs(arch, cfg_mirror):
  unresolved_pkgs = list()
  packetary_output = StringIO()
  with captureStdOut(packetary_output):
    main('unresolved -a {0} -r {1} -c name version --sep ;'
      .format(_ARCHITECTURES[arch], cfg_mirror).split(' '))
  for dep_pkg in packetary_output.getvalue().splitlines():
    if dep_pkg.startswith('#'):
      continue
    dep = dep_pkg.split(';')
    unresolved_pkgs += [ {'name': dep[0], 'version': dep[1]} ]
  force_logger_reload()
  return unresolved_pkgs

# Package list conversion from `old fuel-mirror` to `packetary` style
def from_legacy_pkglist(legacy_pkglist):
  pkglist = list()
  for pkg in legacy_pkglist:
    pkglist += [ {'name': pkg} ]
  return pkglist

def to_legacy_pkglist(pkglist):
  legacy_pkglist = list()
  for pkg in pkglist:
    legacy_pkglist.append(pkg['name'])
  return legacy_pkglist

def legacy_diff(base_pkglist, new_pkglist, requester, arch):
  diff_set = set(new_pkglist)
  if base_pkglist:
    diff_set -= set(base_pkglist)
  if diff_set:
    print(' * {0} requires new packages for arch [{1}]: {2}'
          .format(requester, arch, ', '.join(diff_set)))
  return list(diff_set)

# Create single-component local repo (one arch per call)
def do_local_repo(arch, cfg_repo, cfg_packages_paths):
  # Packetary does not use a global config file, so pass old settings here.
  main('create -t deb -a {0} --repository {1} --package-files {2}'
    ' --ignore-errors-num 2 --retries-num 3 --threads-num 10'
    .format(_ARCHITECTURES[arch], cfg_repo, cfg_packages_paths).split(' '))
  force_logger_reload()

# Clone partial local mirror (one arch per call)
def do_partial_mirror(arch, cfg_mirror, cfg_packages):
  # Note: '-d .' is ignored, as each mirror defines its own path.
  main('clone -t deb -a {0} -r {1} -R {2} -d .'
    ' --ignore-errors-num 2 --retries-num 3 --threads-num 10'
    .format(_ARCHITECTURES[arch], cfg_mirror, cfg_packages).split(' '))
  force_logger_reload()

# Write configuration (yaml) file (package list / mirror defition)
def write_cfg_file(cfg_mirror, data):
  with open(cfg_mirror, 'w') as outfile:
    outfile.write( yaml.safe_dump(data, default_flow_style=False) )

# Allow arch-specific overrides of env vars
def get_env(env_var, arch=None):
  if arch:
    env_var_arch = '{0}_{1}'.format(env_var, arch)
    if os.environ.get(env_var_arch):
      return os.environ[env_var_arch]
  if os.environ.get(env_var):
    return os.environ[env_var]
  return None

# Architecture name mapping (dpkg:packetary) for packetary CLI invocation
_ARCHITECTURES = {
    "i386": "i386",
    "amd64": "x86_64",
    "arm64": "aarch64",
}

# Arch-indepedent configuration (old fuel-mirror + OPNFV extra packages)
cfg_dir = 'opnfv_config'
cfg_p_opnfv = 'opnfv_config.yaml'
mos_version = get_env('MOS_VERSION')
ubuntu_arch = get_env('UBUNTU_ARCH')
mirror_ubuntu_path = get_env('MIRROR_UBUNTU_OPNFV_PATH')
mirror_ubuntu_tmp_path = '{0}.tmp'.format(mirror_ubuntu_path)
mirror_ubuntu_merge = get_env('MIRROR_UBUNTU_MERGE')
cfg_mm_ubuntu = '{0}/ubuntu_mirror_local.yaml'.format(cfg_dir)
fuel_bootstrap_cli_file = open('fuel_bootstrap_cli.yaml').read()
fuel_bootstrap_cli = yaml.load(fuel_bootstrap_cli_file)
fixture_file = open('fuel-web/nailgun/nailgun/fixtures/openstack.yaml').read()
fixture = yaml.load(fixture_file)
opnfv_cfg_yaml = open(cfg_p_opnfv).read()
opnfv_cfg = yaml.load(opnfv_cfg_yaml)

# FIXME: Packetary solves missing dependecies by also accepting
# different packages that provide the same name (e.g. "ifupdown" dependency
# is satisfied by "netscript" package from "universe" repo-component).
# Work around this by resolving all deps in "main" repo-component,
# then scan and keep only latest debs for the whole <merged> repo.
mirror_ubuntu_resolve_main_deps = True

# Create local partial mirror using packetary, one arch at a time
for arch in ubuntu_arch.split(' '):
  # Mirror / Package env vars, arch-overrideable
  mos_ubuntu = get_env('MIRROR_MOS_UBUNTU', arch)
  mos_ubuntu_root = get_env('MIRROR_MOS_UBUNTU_ROOT', arch)
  mirror_ubuntu = get_env('MIRROR_UBUNTU_URL', arch)
  plugins = get_env('BUILD_FUEL_PLUGINS', arch)
  if plugins is None:
    plugins = get_env('PLUGINS', arch)

  # Mirror / Package list configuration files (arch-specific)
  cfg_m_mos = '{0}/mos_{1}_mirror.yaml'.format(cfg_dir, arch)
  cfg_m_ubuntu = '{0}/ubuntu_{1}_mirror.yaml'.format(cfg_dir, arch)
  cfg_p_ubuntu = '{0}/ubuntu_{1}_packages.yaml'.format(cfg_dir, arch)
  cfg_m_ubuntu_main = '{0}/ubuntu_{1}_mirror_main.yaml'.format(cfg_dir, arch)
  cfg_p_ubuntu_main = '{0}/ubuntu_{1}_packages_main.yaml'.format(cfg_dir, arch)

  # Mirror config fork before customizing (arch-specific)
  arch_group_mos = 'mos_{0}'.format(arch)
  arch_group_ubuntu = 'ubuntu_{0}'.format(arch)
  arch_packages = 'packages_{0}'.format(arch)
  opnfv_cfg['groups'][arch_group_mos] = copy.deepcopy(opnfv_cfg['groups']['mos'])
  opnfv_cfg['groups'][arch_group_ubuntu] = copy.deepcopy(opnfv_cfg['groups']['ubuntu'])
  opnfv_cfg[arch_packages] = opnfv_cfg['packages']

  # Mirror config update & conversion to packetary input
  group_main_ubuntu = dict()
  for group in opnfv_cfg['groups'][arch_group_mos]:
    group['uri'] = "http://{}{}".format(mos_ubuntu, mos_ubuntu_root)
    group['suite'] = group['suite'].replace('$mos_version', mos_version)
  for group in opnfv_cfg['groups'][arch_group_ubuntu]:
    group['uri'] = mirror_ubuntu
    # FIXME: At `create`, packetary insists on copying all pkgs to dest dir,
    # so configure it for another dir, which will replace the orig at the end.
    group['path'] = mirror_ubuntu_tmp_path
    if not group_main_ubuntu and 'main' in group:
      group_main_ubuntu = [ copy.deepcopy(group) ]
      group_main_ubuntu[0]['section'] = [ 'main' ]

  # Mirror config dump: MOS (for dep resolution), Ubuntu, Ubuntu[main]
  write_cfg_file(cfg_m_mos, opnfv_cfg['groups'][arch_group_mos])
  write_cfg_file(cfg_m_ubuntu, opnfv_cfg['groups'][arch_group_ubuntu])
  if mirror_ubuntu_resolve_main_deps or mirror_ubuntu_merge is None:
    write_cfg_file(cfg_m_ubuntu_main, group_main_ubuntu)
  if mirror_ubuntu_merge is not None:
    # FIXME: For multiarch, only one dump would be enough
    group_main_ubuntu[0]['origin'] = 'Ubuntu'
    group_main_ubuntu[0]['path'] = mirror_ubuntu_path
    group_main_ubuntu[0]['uri'] = mirror_ubuntu_path
    write_cfg_file(cfg_mm_ubuntu, group_main_ubuntu[0])

  # Collect package dependencies from:
  ## 1. fuel_bootstrap_cli.yaml (bootstrap image additional packages)
  legacy_unresolved = legacy_diff(None, fuel_bootstrap_cli['packages'] + [
      fuel_bootstrap_cli['kernel_flavor'],
      fuel_bootstrap_cli['kernel_flavor'].replace('image', 'headers')],
    'Bootstrap', arch)
  ## 2. openstack.yaml fixture definition (default target image packages)
  for release in fixture:
    editable = release['fields']['attributes_metadata']['editable']
    if 'provision' in editable and 'packages' in editable['provision']:
      release_pkgs = editable['provision']['packages']['value'].split()
      legacy_unresolved += legacy_diff(legacy_unresolved,
        release_pkgs, 'Release {0}'.format(release['fields']['name']), arch)
  ## 3. OPNFV additional packages (includes old fuel-mirror ubuntu.yaml pkgs)
  unresolved = dict()
  unresolved['mandatory'] = 'exact'
  unresolved['packages'] = from_legacy_pkglist(legacy_unresolved)
  if 'packages' in opnfv_cfg:
    legacy_diff(legacy_unresolved, to_legacy_pkglist(opnfv_cfg['packages']),
      'OPNFV config', arch)
    unresolved['packages'] += opnfv_cfg['packages']

  # OPNFV plugins dependency resolution
  for plugin in plugins.split():
    path = "../{}/packages.yaml".format(plugin)
    if os.path.isfile(path):
      f = open(path).read()
      plugin_yaml = yaml.load(f)
      new_packages = legacy_diff(to_legacy_pkglist(unresolved['packages']),
        plugin_yaml['packages'], 'Plugin {0}'.format(plugin), arch)
      unresolved['packages'] += from_legacy_pkglist(new_packages)

  # Package list (reduced, i.e. no MOS deps, but with OPNFV plugin deps)
  # FIXME: This helps work around packetary solving main deps from universe
  if mirror_ubuntu_resolve_main_deps or mirror_ubuntu_merge is None:
    write_cfg_file(cfg_p_ubuntu_main, unresolved)

  # Mirror package list (full, including MOS/OPNFV plugin deps)
  unresolved['packages'] += get_unres_pkgs(arch, cfg_m_mos)
  write_cfg_file(cfg_p_ubuntu, unresolved)
  do_partial_mirror(arch, cfg_m_ubuntu, cfg_p_ubuntu)
  if mirror_ubuntu_resolve_main_deps or mirror_ubuntu_merge is None:
    # Ubuntu[main] must be evaluated after Ubuntu
    do_partial_mirror(arch, cfg_m_ubuntu_main, cfg_p_ubuntu_main)

if mirror_ubuntu_merge is None:
  shutil.move(mirror_ubuntu_tmp_path, mirror_ubuntu_path)
else:
  # Construct single-component mirror from all components
  for arch in ubuntu_arch.split(' '):
    cfg_pp_ubuntu = '{0}/ubuntu_{1}_packages_paths.yaml'.format(cfg_dir, arch)
    # FIXME: We need scanpackages to omit older DEBs
    # Inspired from http://askubuntu.com/questions/198474/
    os.system('dpkg-scanpackages -a {0} {1} 2>/dev/null | '
      'grep -e "^Filename:" | sed "s|Filename: |- file://|g" > {2}'
        .format(arch, mirror_ubuntu_tmp_path, cfg_pp_ubuntu))
    do_local_repo(arch, cfg_mm_ubuntu, cfg_pp_ubuntu)
  shutil.rmtree(mirror_ubuntu_tmp_path)
