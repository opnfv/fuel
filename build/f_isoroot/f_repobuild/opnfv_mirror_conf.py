#!/usr/bin/env python

import os
import yaml
import pprint

current_snapshot =  os.environ["LATEST_TARGET_UBUNTU"]
mos_version = os.environ['MOS_VERSION']
openstack_version = os.environ['OPENSTACK_VERSION']
mos_ubuntu = os.environ['MIRROR_MOS_UBUNTU']
mos_ubuntu_root = os.environ['MIRROR_MOS_UBUNTU_ROOT']
mirror_ubuntu = os.environ['MIRROR_UBUNTU_URL']


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


pprint.pprint(pattern)

with open('ubuntu.yaml', 'w') as outfile:
  outfile.write( yaml.safe_dump(pattern, default_flow_style=False) )
