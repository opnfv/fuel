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
import os
import yaml
import sys
from contextlib import contextmanager
from cStringIO import StringIO
from packetary.cli.app import main

@contextmanager
def captureStdOut(output):
    stdout = sys.stdout
    sys.stdout = output
    yield
    sys.stdout = stdout

mos_version = os.environ['MOS_VERSION']
mos_ubuntu = os.environ['MIRROR_MOS_UBUNTU']
mos_ubuntu_root = os.environ['MIRROR_MOS_UBUNTU_ROOT']
mirror_ubuntu = os.environ['MIRROR_UBUNTU_URL']
mirror_ubuntu_path = os.environ['MIRROR_UBUNTU_OPNFV_PATH']
if os.environ.get('BUILD_FUEL_PLUGINS'):
  plugins = os.environ['BUILD_FUEL_PLUGINS']
else:
  plugins = os.environ['PLUGINS']

pattern_file = open('fuel-mirror/contrib/fuel_mirror/data/ubuntu.yaml').read()
pattern = yaml.load(pattern_file)
# Convert old fuel-mirror format as packetary input on the fly
for group in pattern['groups']['mos']:
  group['uri'] = "http://{}{}".format(mos_ubuntu, mos_ubuntu_root)
  group['suite'] = group['suite'].replace('$mos_version', mos_version)
  group['section'] = group['section'].split()
for group in pattern['groups']['ubuntu']:
  group['uri'] = mirror_ubuntu
  group['path'] = mirror_ubuntu_path
  group['section'] = group['section'].split()

# MOS mirror config for packetary, just for MOS dependency resolution
with open('mos_mirror.yaml', 'w') as outfile:
  outfile.write( yaml.safe_dump(pattern['groups']['mos'], default_flow_style=False) )
# Ubuntu mirror config for packetary, for fetching Ubuntu pkgs + MOS deps
with open('ubuntu_mirror.yaml', 'w') as outfile:
  outfile.write( yaml.safe_dump(pattern['groups']['ubuntu'], default_flow_style=False) )

# OPNFV plugins dependency resolution
for plugin in plugins.split():
  path = "../{}/packages.yaml".format(plugin)
  if os.path.isfile(path):
    f = open(path).read()
    plugin_yaml = yaml.load(f)
    plugin_set = set(plugin_yaml['packages'])
    main_set = set(pattern['packages'])
    new_packages = plugin_set - main_set
    print "Plugin {} require new packages: {}".format(plugin, ', '.join(new_packages))
    pattern['packages'] = pattern['packages'] + list(new_packages)

# Convert predefined package list from fuel-mirror to packetary pkg list
unresolved_pkgs = dict()
unresolved_pkgs['packages'] = list()
unresolved_pkgs['mandatory'] = 'exact'
for pkg in pattern['packages']:
  unresolved_pkgs['packages'] += [ {'name': pkg} ]

# Use packetary to determine unresolved MOS dependencies from Ubuntu
packetary_output = StringIO()
with captureStdOut(packetary_output):
  main('unresolved -r mos_mirror.yaml -c name version --sep ;'.split(' '))

for mos_dep_pkg in packetary_output.getvalue().splitlines():
  if mos_dep_pkg.startswith('#'):
    continue
  dep = mos_dep_pkg.split(';')
  unresolved_pkgs['packages'] += [ {'name': dep[0], 'version': dep[1]} ]

# Ubuntu pkgs to fetch: predefined list + plugin deps + MOS deps
with open('ubuntu_pkgs.yaml', 'w') as outfile:
  outfile.write( yaml.safe_dump(unresolved_pkgs, default_flow_style=False) )

# Packetary does not use a config file, pass old settings here (-d is ignored)
main('clone -r ubuntu_mirror.yaml -R ubuntu_pkgs.yaml -d . '
     '--ignore-errors-num 2 --retries-num 3 --threads-num 10'.split(' '))
