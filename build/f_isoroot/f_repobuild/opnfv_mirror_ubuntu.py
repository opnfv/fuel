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
# Mirror build steps:
# 1. Parse old <fuel-mirror> package list ("ubuntu.yaml");
# 2. Parse new "opnfv_packages.yaml" list of additional packages;
# 3. Inherit enviroment variable(s) for mirror URLs, paths etc.
#    - Allow arch-specific overrides for each env var;
# 4. For each architecture in UBUNTU_ARCH:
# 4.1. Mirror config is defined based on common config + OPNFV overrides;
#      - Convert old configuration format to packetary style where needed;
# 4.2. Package lists are defined based on common config + OPNFV deps;
#      - Keep track of "main" packages separately, required by debootstrap;
# 4.3. Clone/update all mirror components;
# 4.4. IF mirror merging is disabled OR workaround for ifupdown (see below):
#      - Clone/update "main" mirror component (fix missing debootstrap deps);
# 5. IF mirror merging is enabled:
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
  unresolved = dict()
  unresolved['packages'] = list()
  packetary_output = StringIO()
  with captureStdOut(packetary_output):
    main('unresolved -a {0} -r {1} -c name version --sep ;'
      .format(_ARCHITECTURES[arch], cfg_mirror).split(' '))
  for dep_pkg in packetary_output.getvalue().splitlines():
    if dep_pkg.startswith('#'):
      continue
    dep = dep_pkg.split(';')
    unresolved['packages'] += [ {'name': dep[0], 'version': dep[1]} ]
  force_logger_reload()
  return unresolved

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
cfg_p_opnfv = 'opnfv_packages.yaml'
mos_version = get_env('MOS_VERSION')
ubuntu_arch = get_env('UBUNTU_ARCH')
mirror_ubuntu_path = get_env('MIRROR_UBUNTU_OPNFV_PATH')
mirror_ubuntu_tmp_path = '{0}.tmp'.format(mirror_ubuntu_path)
mirror_ubuntu_merge = get_env('MIRROR_UBUNTU_MERGE')
cfg_mm_ubuntu = '{0}/ubuntu_mirror_local.yaml'.format(cfg_dir)
pattern_file = open('fuel-mirror/contrib/fuel_mirror/data/ubuntu.yaml').read()
pattern = yaml.load(pattern_file)
opnfv_pkgs_yaml = open(cfg_p_opnfv).read()
opnfv_pkgs = yaml.load(opnfv_pkgs_yaml)

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
  pattern['groups'][arch_group_mos] = copy.deepcopy(pattern['groups']['mos'])
  pattern['groups'][arch_group_ubuntu] = copy.deepcopy(pattern['groups']['ubuntu'])
  pattern[arch_packages] = pattern['packages']

  # Mirror config update & conversion to packetary input
  group_main_ubuntu = dict()
  for group in pattern['groups'][arch_group_mos]:
    group['uri'] = "http://{}{}".format(mos_ubuntu, mos_ubuntu_root)
    group['suite'] = group['suite'].replace('$mos_version', mos_version)
    group['section'] = group['section'].split()
  for group in pattern['groups'][arch_group_ubuntu]:
    group['uri'] = mirror_ubuntu
    # FIXME: At `create`, packetary insists on copying all pkgs to dest dir,
    # so configure it for another dir, which will replace the orig at the end.
    group['path'] = mirror_ubuntu_tmp_path
    group['section'] = group['section'].split()
    if not group_main_ubuntu and 'main' in group:
      group_main_ubuntu = [ copy.deepcopy(group) ]
      group_main_ubuntu[0]['section'] = [ 'main' ]

  # Mirror config dump: MOS (for dep resolution), Ubuntu, Ubuntu[main]
  write_cfg_file(cfg_m_mos, pattern['groups'][arch_group_mos])
  write_cfg_file(cfg_m_ubuntu, pattern['groups'][arch_group_ubuntu])
  if mirror_ubuntu_resolve_main_deps or mirror_ubuntu_merge is None:
    write_cfg_file(cfg_m_ubuntu_main, group_main_ubuntu)
  if mirror_ubuntu_merge is not None:
    # FIXME: For multiarch, only one dump would be enough
    group_main_ubuntu[0]['origin'] = 'Ubuntu'
    group_main_ubuntu[0]['path'] = mirror_ubuntu_path
    group_main_ubuntu[0]['uri'] = mirror_ubuntu_path
    write_cfg_file(cfg_mm_ubuntu, group_main_ubuntu[0])

  # Package list conversion from `old fuel-mirror` to `packetary` style + OPNFV
  unresolved_pkgs = dict()
  unresolved_pkgs['packages'] = list()
  unresolved_pkgs['mandatory'] = 'exact'
  if opnfv_pkgs['packages'] is not None:
    unresolved_pkgs['packages'] = opnfv_pkgs['packages']
  for pkg in pattern['packages']:
    unresolved_pkgs['packages'] += [ {'name': pkg} ]

  # Package list (reduced, i.e. no MOS/OPNFV plugin deps)
  if mirror_ubuntu_resolve_main_deps or mirror_ubuntu_merge is None:
    write_cfg_file(cfg_p_ubuntu_main, unresolved_pkgs)

  # OPNFV plugins dependency resolution
  for plugin in plugins.split():
    path = "../{}/packages.yaml".format(plugin)
    if os.path.isfile(path):
      f = open(path).read()
      plugin_yaml = yaml.load(f)
      plugin_set = set(plugin_yaml['packages'])
      main_set = set(pattern['packages'])
      new_packages = plugin_set - main_set
      print('Plugin {0} requires new packages for arch [{1}]: {2}'
            .format(plugin, arch, ', '.join(new_packages)))
      for pkg in new_packages:
        unresolved_pkgs['packages'] += [ {'name': pkg} ]

  # Mirror package list (full, including MOS/OPNFV plugin deps)
  unresolved_pkgs['packages'] += get_unres_pkgs(arch, cfg_m_mos)['packages']
  write_cfg_file(cfg_p_ubuntu, unresolved_pkgs)
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
