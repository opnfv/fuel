#!/usr/bin/python
###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################

###############################################################################
# Description
# This script constructs the final deployment dea.yaml and dha.yaml files
# The dea.yaml get's constructed from (in reverse priority):
# 1) dea-base
# 2) dea-pod-override
# 3) deployment-scenario dea-override-config section
#
# The dha.yaml get's constructed from (in reverse priority):
# 1) pod dha
# 2) deployment-scenario dha-override-config section
###############################################################################

import os
import yaml
import sys
import urllib2
from functools import reduce
from operator import or_
from common import (
    log,
    exec_cmd,
    err,
    warn,
    check_file_exists,
    create_dir_if_not_exists,
    delete,
    check_if_root,
    ArgParser,
)


def parse_arguments():
    parser = ArgParser(prog='python %s' % __file__)
    parser.add_argument('-dha', dest='dha_uri', action='store',
                        default=False, help='dha URI', required=True)
    parser.add_argument('-deab', dest='dea_base_uri', action='store',
                        default=False, help='dea base URI', required=True)
    parser.add_argument('-deao', dest='dea_pod_override_uri', action='store',
                        default=False, help='dea POD override URI',
                        required=True)
    parser.add_argument('-scenario', dest='scenario_uri', action='store',
                        default=False, help='Deploymen scenario URI',
                        required=True)
    parser.add_argument('-plugins', dest='plugins_uri', action='store',
                        default=False, help='Plugin configurations URI',
                        required=True)
    parser.add_argument('-output', dest='output_path', action='store',
                        default=False,
                        help='Path to resulting configuration files',
                        required=True)
    args = parser.parse_args()
    log(args)
    kwargs = {'dha_uri': args.dha_uri,
              'dea_base_uri': args.dea_base_uri,
              'dea_pod_override_uri': args.dea_pod_override_uri,
              'scenario_uri': args.scenario_uri,
              'plugins_uri': args.plugins_uri,
              'output_path': args.output_path}
    return kwargs


def mergedicts(dict1, dict2):
    for k in set(dict1.keys()).union(dict2.keys()):
        if k in dict1 and k in dict2:
            if isinstance(dict1[k], dict) and isinstance(dict2[k], dict):
                yield (k, dict(mergedicts(dict1[k], dict2[k])))
            else:
                # If one of the values is not a dict, you can't continue
                # merging it.
                # Value from second dict overrides one in first and we move on.
                yield (k, dict2[k])
                # Alternatively, replace this with exception raiser to alert
                # you of value conflicts
        elif k in dict1:
            yield (k, dict1[k])
        else:
            yield (k, dict2[k])


kwargs = parse_arguments()

# Load Deployment scenario .yaml
response = urllib2.urlopen(kwargs["scenario_uri"])
deploy_scenario_conf = yaml.load(response.read())

# Merge (in priority order) "dea base", "dea POD override" and
# "deployment scenario dea override"
print 'Generating final dea.yaml configuration'
response = urllib2.urlopen(kwargs["dea_base_uri"])
dea_base_conf = yaml.load(response.read())
final_dea_conf = dea_base_conf
response = urllib2.urlopen(kwargs["dea_pod_override_uri"])
dea_pod_override_conf = yaml.load(response.read())
if dea_pod_override_conf:
    print 'Merging dea pod override information to final dea.yaml config'
    final_dea_conf = dict(mergedicts(dea_base_conf, dea_pod_override_conf))
dea_scenario_override_conf = deploy_scenario_conf["dea-override-config"]
if dea_scenario_override_conf:
    print 'Merging dea deploy-scenario override information to final dea.yaml config'
    final_dea_conf = dict(mergedicts(final_dea_conf, dea_scenario_override_conf))

# Append/Merge plugins conf to dea
for module in deploy_scenario_conf["stack-extensions"]:
    print 'Loading configuration for module: ' + module["module"] + ' and merging it to final dea.yaml configuration'
    response = urllib2.urlopen(kwargs["plugins_uri"] + '/' + module["module-config-name"] + '_' + module["module-config-version"] + '.yaml')
    final_dea_conf['settings']['editable'].update(yaml.load(response.read()))

# TBD Remove original dea-base and dea-override meta data and auto generate
# new metadata providing strict traceability

# Dump dea.yaml to argument provided directory
if not os.path.exists(kwargs["output_path"]):
    os.makedirs(kwargs["output_path"])
print 'Dumping final dea.yaml to ' + kwargs["output_path"] + '/dea.yaml'
with open(kwargs["output_path"] + '/dea.yaml', "w") as f:
    yaml.dump(final_dea_conf, f, default_flow_style=False)

# Load POD dha and override it with "deployment scenario DHA override section"
print 'Generating final dha.yaml configuration'
response = urllib2.urlopen(kwargs["dha_uri"])
dha_base_conf = yaml.load(response.read())
final_dha_conf = dha_base_conf
dha_scenario_override_conf = deploy_scenario_conf["dha-override-config"]
if dha_scenario_override_conf:
    print 'Merging dha deploy-scenario override information to final dha.yaml config'
    final_dha_conf = dict(mergedicts(dha_base_conf, dha_scenario_override_conf))

# TBD Remove original dha-base metadata and auto generate
# new metadata providing strict traceability

# Dump dha.yaml to argument provided directory
print 'Dumping final dha.yaml to ' + kwargs["output_path"] + '/dha.yaml'
with open(kwargs["output_path"] + '/dha.yaml', "w") as f:
    yaml.dump(final_dha_conf, f, default_flow_style=False)
