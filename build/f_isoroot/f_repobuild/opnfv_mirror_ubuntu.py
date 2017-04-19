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

"""Build multiarch partial local Ubuntu mirror using packetary"""

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
# 1. Collect bootstrap package deps from fuel-agent's <settings.yaml.sample>;
# 2. Collect all fixture release packages from fuel-web's <openstack.yaml>;
# 3. Parse new "opnfv_config.yaml" list of packages (from old fuel-mirror);
# 4. Inherit enviroment variable(s) for mirror URLs, paths etc.
#    - Allow arch-specific overrides for each env var;
# 5. Mirror config is defined based on common config + OPNFV overrides;
#    - Convert old configuration format to packetary style where needed;
# 6. Package lists are defined based on common config + OPNFV deps;
#    - Keep track of "main" packages separately, required by debootstrap;
# 7. Clone/update all mirror components;
# 8. IF mirror merging is disabled:
#    - Clone/update "main" mirror component (fix missing debootstrap deps);
# 9. IF mirror merging is enabled:
#    - Use `dpkg-scanpackages` to filter out old versions of duplicate pkgs;
#    - Run `packetary create` on the set of downloaded packages, merging
#      them on the fly into a single-component mirror;
##############################################################################

from copy import deepcopy
import os
import shutil
import sys
import yaml
from contextlib import contextmanager
from cStringIO import StringIO
from packetary.cli.app import main

@contextmanager
def capture_stdout(output):
    """Context manager for capturing stdout"""
    stdout = sys.stdout
    sys.stdout = output
    yield
    sys.stdout = stdout

# FIXME: Find a better approach for eliminating duplicate logs than this
def force_logger_reload():
    """Force logger reload (ugly hack to prevent log duplication)"""
    for mod in sys.modules.keys():
        if mod.startswith('logging'):
            try:
                reload(sys.modules[mod])
            except:
                pass

def get_unres_pkgs(architecture, cfg_mirror):
    """Determine missing package dependecies for a mirror defition"""
    unresolved_pkgs = list()
    packetary_output = StringIO()
    with capture_stdout(packetary_output):
        main('unresolved -a {0} -r {1} -c name version --sep ;'
            .format(_ARCH[architecture], cfg_mirror).split(' '))
    for dep_pkg in packetary_output.getvalue().splitlines():
        if dep_pkg.startswith('#'):
            continue
        dep = dep_pkg.split(';')
        unresolved_pkgs += [{'name': dep[0], 'version': dep[1]}]
    force_logger_reload()
    return unresolved_pkgs

def from_legacy_pkglist(legacy_pkglist):
    """Package list conversion from `old fuel-mirror` to `packetary` style"""
    pkglist = list()
    for pkg in legacy_pkglist:
        pkglist += [{'name': pkg}]
    return pkglist

def to_legacy_pkglist(pkglist):
    """Package list conversion from `packetary` style to `old fuel-mirror`"""
    legacy_pkglist = list()
    for pkg in pkglist:
        legacy_pkglist.append(pkg['name'])
    return legacy_pkglist

def legacy_diff(base_pkglist, new_pkglist, requester, architecture):
    """Package list diff (old format)"""
    diff_set = set(new_pkglist)
    if base_pkglist:
        diff_set -= set(base_pkglist)
    if diff_set:
        print(' * {0} requires new packages for architecture [{1}]: {2}'
              .format(requester, architecture, ', '.join(diff_set)))
    return list(diff_set)

def do_local_repo(architecture, cfg_repo, cfg_packages_paths):
    """Create single-component local repo (one architecture per call)"""
    # Packetary does not use a global config file, so pass old settings here.
    main('create -t deb -a {0} --repository {1} --package-files {2}'
         ' --ignore-errors-num 2 --retries-num 3 --threads-num 10'
         .format(_ARCH[architecture], cfg_repo, cfg_packages_paths).split(' '))
    force_logger_reload()

def do_partial_mirror(architecture, cfg_mirror, cfg_packages):
    """Clone partial local mirror (one architecture per call)"""
    # Note: '-d .' is ignored, as each mirror defines its own path.
    main('clone -t deb -a {0} -r {1} -R {2} -d .'
         ' --ignore-errors-num 2 --retries-num 3 --threads-num 10'
         .format(_ARCH[architecture], cfg_mirror, cfg_packages).split(' '))
    force_logger_reload()

def write_cfg_file(cfg_mirror, data):
    """Write configuration (yaml) file (package list / mirror defition)"""
    with open(cfg_mirror, 'w') as outfile:
        outfile.write(yaml.safe_dump(data, default_flow_style=False))

def get_env(env_var, architecture=None):
    """Evaluate architecture-specific overrides of env vars"""
    if architecture:
        env_var_arch = '{0}_{1}'.format(env_var, architecture)
        if os.environ.get(env_var_arch):
            return os.environ[env_var_arch]
    if os.environ.get(env_var):
        return os.environ[env_var]
    return None

# Architecture name mapping (dpkg:packetary) for packetary CLI invocation
_ARCH = {
    "i386": "i386",
    "amd64": "x86_64",
    "arm64": "aarch64",
}

# Arch-indepedent configuration (old fuel-mirror + OPNFV extra packages)
CFG_D = 'opnfv_config'
CFG_OPNFV = 'opnfv_config.yaml'
MOS_VERSION = get_env('MOS_VERSION')
UBUNTU_ARCH = get_env('UBUNTU_ARCH')
MIRROR_UBUNTU_PATH = get_env('MIRROR_UBUNTU_OPNFV_PATH')
MIRROR_UBUNTU_TMP_PATH = '{0}.tmp'.format(MIRROR_UBUNTU_PATH)
MIRROR_UBUNTU_MERGE = get_env('MIRROR_UBUNTU_MERGE')
CFG_MM_UBUNTU = '{0}/ubuntu_mirror_local.yaml'.format(CFG_D)
FUEL_BOOTSTRAP_CLI_FILE = open('fuel-agent/contrib/fuel_bootstrap/'
    'fuel_bootstrap_cli/fuel_bootstrap/settings.yaml.sample').read()
FUEL_BOOTSTRAP_CLI = yaml.load(FUEL_BOOTSTRAP_CLI_FILE)
FIXTURE_FILE = open('fuel-web/nailgun/nailgun/fixtures/openstack.yaml').read()
FIXTURE = yaml.load(FIXTURE_FILE)
OPNFV_CFG_YAML = open(CFG_OPNFV).read()
OPNFV_CFG = yaml.load(OPNFV_CFG_YAML)

# Create local partial mirror using packetary, one arch at a time
for arch in UBUNTU_ARCH.split(' '):
    # Mirror / Package env vars, arch-overrideable
    mos_ubuntu = get_env('MIRROR_MOS_UBUNTU', arch)
    mos_ubuntu_root = get_env('MIRROR_MOS_UBUNTU_ROOT', arch)
    mirror_ubuntu = get_env('MIRROR_UBUNTU_URL', arch)
    plugins = get_env('BUILD_FUEL_PLUGINS', arch)
    if plugins is None:
        plugins = get_env('PLUGINS', arch)

    # Mirror / Package list configuration files (arch-specific)
    cfg_m_mos = '{0}/mos_{1}_mirror.yaml'.format(CFG_D, arch)
    cfg_m_ubuntu = '{0}/ubuntu_{1}_mirror.yaml'.format(CFG_D, arch)
    cfg_p_ubuntu = '{0}/ubuntu_{1}_packages.yaml'.format(CFG_D, arch)
    cfg_m_ubuntu_main = '{0}/ubuntu_{1}_mirror_main.yaml'.format(CFG_D, arch)
    cfg_p_ubuntu_main = '{0}/ubuntu_{1}_packages_main.yaml'.format(CFG_D, arch)

    # Mirror config fork before customizing (arch-specific)
    arch_mos = 'mos_{0}'.format(arch)
    arch_ubuntu = 'ubuntu_{0}'.format(arch)
    arch_packages = 'packages_{0}'.format(arch)
    OPNFV_CFG['groups'][arch_mos] = deepcopy(OPNFV_CFG['groups']['mos'])
    OPNFV_CFG['groups'][arch_ubuntu] = deepcopy(OPNFV_CFG['groups']['ubuntu'])
    OPNFV_CFG[arch_packages] = OPNFV_CFG['packages']

    # Mirror config update & conversion to packetary input
    group_main_ubuntu = dict()
    for group in OPNFV_CFG['groups'][arch_mos]:
        group['uri'] = "http://{}{}".format(mos_ubuntu, mos_ubuntu_root)
        group['suite'] = group['suite'].replace('$mos_version', MOS_VERSION)
    for group in OPNFV_CFG['groups'][arch_ubuntu]:
        group['uri'] = mirror_ubuntu
        # FIXME: At `create`, packetary insists on copying all pkgs to dest dir,
        # so configure it for another dir, which will replace the orig.
        group['path'] = MIRROR_UBUNTU_TMP_PATH
        if not group_main_ubuntu and 'main' in group:
            group_main_ubuntu = [deepcopy(group)]
            group_main_ubuntu[0]['section'] = ['main']

    # Mirror config dump: MOS (for dep resolution), Ubuntu, Ubuntu[main]
    write_cfg_file(cfg_m_mos, OPNFV_CFG['groups'][arch_mos])
    write_cfg_file(cfg_m_ubuntu, OPNFV_CFG['groups'][arch_ubuntu])
    if MIRROR_UBUNTU_MERGE is None:
        write_cfg_file(cfg_m_ubuntu_main, group_main_ubuntu)
    else:
        # FIXME: For multiarch, only one dump would be enough
        group_main_ubuntu[0]['origin'] = 'Ubuntu'
        group_main_ubuntu[0]['path'] = MIRROR_UBUNTU_PATH
        group_main_ubuntu[0]['uri'] = MIRROR_UBUNTU_PATH
        write_cfg_file(CFG_MM_UBUNTU, group_main_ubuntu[0])

    # Collect package dependencies from:
    ## 1. fuel_bootstrap_cli (bootstrap image additional packages)
    legacy_unresolved = legacy_diff(None, FUEL_BOOTSTRAP_CLI['packages'] + [
            FUEL_BOOTSTRAP_CLI['kernel_flavor'],
            FUEL_BOOTSTRAP_CLI['kernel_flavor'].replace('image', 'headers')],
        'Bootstrap', arch)
    ## 2. openstack.yaml FIXTURE definition (default target image packages)
    for release in FIXTURE:
        editable = release['fields']['attributes_metadata']['editable']
        if 'provision' in editable and 'packages' in editable['provision']:
            release_pkgs = editable['provision']['packages']['value'].split()
            legacy_unresolved += legacy_diff(legacy_unresolved, release_pkgs,
                'Release {0}'.format(release['fields']['name']), arch)
    ## 3. OPNFV additional packages (includes old fuel-mirror ubuntu.yaml pkgs)
    unresolved = dict()
    unresolved['mandatory'] = 'exact'
    unresolved['packages'] = from_legacy_pkglist(legacy_unresolved)
    if 'packages' in OPNFV_CFG:
        legacy_diff(legacy_unresolved, to_legacy_pkglist(OPNFV_CFG['packages']),
            'OPNFV config', arch)
        unresolved['packages'] += OPNFV_CFG['packages']

    # OPNFV plugins dependency resolution
    if plugins:
        for plugin in plugins.split():
            path = "../{}/packages.yaml".format(plugin)
            if os.path.isfile(path):
                f = open(path).read()
                plugin_yaml = yaml.load(f)
                new_pkgs = legacy_diff(
                    to_legacy_pkglist(unresolved['packages']),
                    plugin_yaml['packages'], 'Plugin {0}'.format(plugin), arch)
                unresolved['packages'] += from_legacy_pkglist(new_pkgs)

    # Package list (reduced, i.e. no MOS deps, but with OPNFV plugin deps)
    if MIRROR_UBUNTU_MERGE is None:
        write_cfg_file(cfg_p_ubuntu_main, unresolved)

    # Mirror package list (full, including MOS/OPNFV plugin deps)
    unresolved['packages'] += get_unres_pkgs(arch, cfg_m_mos)
    write_cfg_file(cfg_p_ubuntu, unresolved)
    do_partial_mirror(arch, cfg_m_ubuntu, cfg_p_ubuntu)
    if MIRROR_UBUNTU_MERGE is None:
        # Ubuntu[main] must be evaluated after Ubuntu
        do_partial_mirror(arch, cfg_m_ubuntu_main, cfg_p_ubuntu_main)

if MIRROR_UBUNTU_MERGE is None:
    shutil.move(MIRROR_UBUNTU_TMP_PATH, MIRROR_UBUNTU_PATH)
else:
    # Construct single-component mirror from all components
    for arch in UBUNTU_ARCH.split(' '):
        cfg_pp_ubuntu = '{0}/ubuntu_{1}_packages_paths.yaml'.format(CFG_D, arch)
        # OPNFV blacklist
        opnfv_blacklist = to_legacy_pkglist(OPNFV_CFG['opnfv_blacklist'])
        # FIXME: We need scanpackages to omit older DEBs
        # Inspired from http://askubuntu.com/questions/198474/
        os.system('dpkg-scanpackages -a {0} {1} 2>/dev/null | '
                  'grep -e "^Filename:" | sed "s|Filename: |- file://|g" | '
                  'grep -v -E "\/({2})_" > {3}'
                  .format(arch, MIRROR_UBUNTU_TMP_PATH,
                          '|'.join(opnfv_blacklist), cfg_pp_ubuntu))
        do_local_repo(arch, CFG_MM_UBUNTU, cfg_pp_ubuntu)
    shutil.rmtree(MIRROR_UBUNTU_TMP_PATH)
