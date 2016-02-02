#!/usr/bin/env python
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
import os
import yaml

current_snapshot =  os.environ["LATEST_TARGET_UBUNTU"]
mos_version = os.environ['MOS_VERSION']
openstack_version = os.environ['OPENSTACK_VERSION']
mos_ubuntu = os.environ['MIRROR_MOS_UBUNTU']
mos_ubuntu_root = os.environ['MIRROR_MOS_UBUNTU_ROOT']
mirror_ubuntu = os.environ['MIRROR_UBUNTU_URL']
if os.environ.get('BUILD_FUEL_PLUGINS'):
  plugins = os.environ['BUILD_FUEL_PLUGINS']
else:
  plugins = os.environ['PLUGINS']


configuration_file = open('fuel-mirror/contrib/fuel_mirror/etc/config.yaml').read()
conf = yaml.load(configuration_file)
conf['pattern_dir'] = '.'
conf['openstack_version'] = openstack_version
conf['mos_version'] = mos_version

with open('opnfv-config.yaml', 'w') as outfile:
  outfile.write( yaml.dump(conf, default_flow_style=False) )

pattern_file = open('fuel-mirror/contrib/fuel_mirror/data/ubuntu.yaml').read()
pattern = yaml.load(pattern_file)
pattern['mos_baseurl'] = "http://{}{}".format(mos_ubuntu, mos_ubuntu_root)
pattern['ubuntu_baseurl'] = mirror_ubuntu
for group in pattern['groups']['mos']:
  group['uri'] = pattern['mos_baseurl']
for group in pattern['groups']['ubuntu']:
  group['uri'] = pattern['ubuntu_baseurl']

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

pattern['requirements']['ubuntu'] = pattern['packages']

with open('ubuntu.yaml', 'w') as outfile:
  outfile.write( yaml.safe_dump(pattern, default_flow_style=False) )
