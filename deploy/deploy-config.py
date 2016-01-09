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
import calendar
import time
import collections
import hashlib

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
                        default=False, help='dha configuration file FQDN URI', required=True)
    parser.add_argument('-deab', dest='dea_base_uri', action='store',
                        default=False, help='dea base configuration FQDN URI', required=True)
    parser.add_argument('-deao', dest='dea_pod_override_uri', action='store',
                        default=False, help='dea POD override configuration FQDN URI',
                        required=True)
    parser.add_argument('-scenario-base-uri', dest='scenario_base_uri', action='store',
                        default=False, help='Deploymen scenario base directory URI',
                        required=True)
    parser.add_argument('-scenario', dest='scenario', action='store',
                        default=False, help='Deploymen scenario short-name (priority), or base file name (in the absense of a shortname defenition)',
                        required=True)

    parser.add_argument('-plugins', dest='plugins_uri', action='store',
                        default=False, help='Plugin configurations directory URI',
                        required=True)
    parser.add_argument('-output', dest='output_path', action='store',
                        default=False,
                        help='Local path for resulting output configuration files',
                        required=True)
    args = parser.parse_args()
    log(args)
    kwargs = {'dha_uri': args.dha_uri,
              'dea_base_uri': args.dea_base_uri,
              'dea_pod_override_uri': args.dea_pod_override_uri,
              'scenario_base_uri': args.scenario_base_uri,
              'scenario': args.scenario,
              'plugins_uri': args.plugins_uri,
              'output_path': args.output_path}
    return kwargs

def setup_yaml():
  represent_dict_order = lambda self, data:  self.represent_mapping('tag:yaml.org,2002:map', data.items())
  yaml.add_representer(collections.OrderedDict, represent_dict_order)

def sha_uri(uri):
    import hashlib
    response = urllib2.urlopen(uri)
    data = response.read()
    sha1 = hashlib.sha1()
    sha1.update(data)
    return sha1.hexdigest()

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
        elif k in dict1:
            yield (k, dict1[k])
        else:
            yield (k, dict2[k])

setup_yaml()
kwargs = parse_arguments()

# Generate final dea.yaml by merging following config files/fragments in revers priority order:
# "dea-base", "dea-pod-override", "deplyment-scenario/module-config-override"
# and "deployment-scenario/dea-override"
print 'Generating final dea.yaml configuration....'

# Fetch dea-base, extract and purge meta-data
print 'Parsing dea-base from: ' + kwargs["dea_base_uri"] + "...."
response = urllib2.urlopen(kwargs["dea_base_uri"])
dea_base_conf = yaml.load(response.read())
dea_base_title = dea_base_conf['dea-base-config-metadata']['title']
dea_base_version = dea_base_conf['dea-base-config-metadata']['version']
dea_base_creation = dea_base_conf['dea-base-config-metadata']['created']
dea_base_sha = sha_uri(kwargs["dea_base_uri"])
dea_base_comment = dea_base_conf['dea-base-config-metadata']['comment']
dea_base_conf.pop('dea-base-config-metadata')
final_dea_conf = dea_base_conf

# Fetch dea-pod-override, extract and purge meta-data, merge with previous dea data structure
print 'Parsing the dea-pod-override from: ' + kwargs["dea_pod_override_uri"] + "...."
response = urllib2.urlopen(kwargs["dea_pod_override_uri"])
dea_pod_override_conf = yaml.load(response.read())
if dea_pod_override_conf:
    dea_pod_title = dea_pod_override_conf['dea-pod-override-config-metadata']['title']
    dea_pod_version = dea_pod_override_conf['dea-pod-override-config-metadata']['version']
    dea_pod_creation = dea_pod_override_conf['dea-pod-override-config-metadata']['created']
    dea_pod_sha = sha_uri(kwargs["dea_pod_override_uri"])
    dea_pod_comment = dea_pod_override_conf['dea-pod-override-config-metadata']['comment']
    print 'Merging dea-base and dea-pod-override configuration ....'
    dea_pod_override_conf.pop('dea-pod-override-config-metadata')
    if dea_pod_override_conf:
        final_dea_conf = dict(mergedicts(final_dea_conf, dea_pod_override_conf))

# Fetch deployment-scenario, extract and purge meta-data, merge deployment-scenario/
# dea-override-configith previous dea data structure
print 'Parsing deployment-scenario from: ' + kwargs["scenario"] + "...."

response = urllib2.urlopen(kwargs["scenario_base_uri"] + "/scenario.yaml")
scenario_short_translation_conf = yaml.load(response.read())
if kwargs["scenario"] in scenario_short_translation_conf:
    scenario_uri = kwargs["scenario_base_uri"] + "/" + scenario_short_translation_conf[kwargs["scenario"]]['configfile']
else:
    scenario_uri = kwargs["scenario_base_uri"] + "/" + kwargs["scenario"]
response = urllib2.urlopen(scenario_uri)
deploy_scenario_conf = yaml.load(response.read())

if deploy_scenario_conf:
    deploy_scenario_title = deploy_scenario_conf['deployment-scenario-metadata']['title']
    deploy_scenario_version = deploy_scenario_conf['deployment-scenario-metadata']['version']
    deploy_scenario_creation = deploy_scenario_conf['deployment-scenario-metadata']['created']
    deploy_scenario_sha = sha_uri(scenario_uri)
    deploy_scenario_comment = deploy_scenario_conf['deployment-scenario-metadata']['comment']
    deploy_scenario_conf.pop('deployment-scenario-metadata')
else:
    print "Deployment scenario file not found or is empty"
    print "Cannot continue, exiting ...."
    sys.exit(1)

dea_scenario_override_conf = deploy_scenario_conf["dea-override-config"]
if dea_scenario_override_conf:
    print 'Merging dea-base-, dea-pod-override- and deployment-scenario configuration into final dea.yaml configuration....'
    final_dea_conf = dict(mergedicts(final_dea_conf, dea_scenario_override_conf))

# Fetch plugin-configuration configuration files, extract and purge meta-data,
# merge/append with previous dea data structure, override plugin-configuration with
# deploy-scenario/module-config-override
modules = []
module_uris = []
module_titles = []
module_versions = []
module_creations = []
module_shas = []
module_comments = []
if deploy_scenario_conf["stack-extensions"]:
    for module in deploy_scenario_conf["stack-extensions"]:
        print 'Loading configuration for module: ' + module["module"] + ' and merging it to final dea.yaml configuration....'
        response = urllib2.urlopen(kwargs["plugins_uri"] + '/' + module["module-config-name"] + '_' + module["module-config-version"] + '.yaml')
        module_conf = yaml.load(response.read())
        modules.append(module["module"])
        module_uris.append(kwargs["plugins_uri"] + '/' + module["module-config-name"] + '_' + module["module-config-version"] + '.yaml')
        module_titles.append(str(module_conf['plugin-config-metadata']['title']))
        module_versions.append(str(module_conf['plugin-config-metadata']['version']))
        module_creations.append(str(module_conf['plugin-config-metadata']['created']))
        module_shas.append(sha_uri(kwargs["plugins_uri"] + '/' + module["module-config-name"] + '_' + module["module-config-version"] + '.yaml'))
        module_comments.append(str(module_conf['plugin-config-metadata']['comment']))
        module_conf.pop('plugin-config-metadata')
        final_dea_conf['settings']['editable'].update(module_conf)
        scenario_module_override_conf = module['module-config-override']
        if scenario_module_override_conf:
            dea_scenario_module_override_conf = {}
            dea_scenario_module_override_conf['settings'] = {}
            dea_scenario_module_override_conf['settings']['editable'] = {}
            dea_scenario_module_override_conf['settings']['editable'][module["module"]] = scenario_module_override_conf
            final_dea_conf = dict(mergedicts(final_dea_conf, dea_scenario_module_override_conf))

# Dump final dea.yaml including configuration management meta-data to argument provided
# directory
if not os.path.exists(kwargs["output_path"]):
    os.makedirs(kwargs["output_path"])
print 'Dumping final dea.yaml to ' + kwargs["output_path"] + '/dea.yaml....'
with open(kwargs["output_path"] + '/dea.yaml', "w") as f:
    f.write("title: DEA.yaml file automatically generated from the configuration files stated in the \"configuration-files\" fragment below\n")
    f.write("version: " + str(calendar.timegm(time.gmtime()))  + "\n")
    f.write("created: " + str(time.strftime("%d/%m/%Y")) + " " + str(time.strftime("%H:%M:%S"))  + "\n")
    f.write("comment: none\n")

    f.write("configuration-files:\n")
    f.write("  dea-base:\n")
    f.write("    uri: " +  kwargs["dea_base_uri"] + "\n")
    f.write("    title: " +  str(dea_base_title) + "\n")
    f.write("    version: " +  str(dea_base_version) + "\n")
    f.write("    created: " +  str(dea_base_creation) + "\n")
    f.write("    sha1: " +  str(dea_base_sha) + "\n")
    f.write("    comment: " +  str(dea_base_comment) + "\n")

    f.write("  pod-override:\n")
    f.write("    uri: " +  kwargs["dea_pod_override_uri"] + "\n")
    f.write("    title: " +  str(dea_pod_title) + "\n")
    f.write("    version: " +  str(dea_pod_version) + "\n")
    f.write("    created: " +  str(dea_pod_creation) + "\n")
    f.write("    sha1: " +  str(dea_pod_sha) + "\n")
    f.write("    comment: " +  str(dea_pod_comment) + "\n")

    f.write("  deployment-scenario:\n")
    f.write("    uri: " +  str(scenario_uri) + "\n")
    f.write("    title: " +  str(deploy_scenario_title) + "\n")
    f.write("    version: " +  str(deploy_scenario_version) + "\n")
    f.write("    created: " +  str(deploy_scenario_creation) + "\n")
    f.write("    sha1: " +  str(deploy_scenario_sha) + "\n")
    f.write("    comment: " +  str(deploy_scenario_comment) + "\n")

    f.write("  plugin-modules:\n")
    for k in range(0,len(modules)):
        f.write("  - module: " + modules[k] + "\n")
        f.write("    uri: " + module_uris[k] + "\n")
        f.write("    title: " + module_titles[k] + "\n")
        f.write("    version: " + module_versions[k] + "\n")
        f.write("    created: " + module_creations[k] + "\n")
        f.write("    sha-1: " + module_shas[k] + "\n")
        f.write("    comment: " + module_comments[k] + "\n")

    yaml.dump(final_dea_conf, f, default_flow_style=False)

# Load POD dha and override it with "deployment-scenario/dha-override-config" section
print 'Generating final dha.yaml configuration....'
print 'Parsing dha-pod yaml configuration....'
response = urllib2.urlopen(kwargs["dha_uri"])
dha_pod_conf = yaml.load(response.read())
dha_pod_title = dha_pod_conf['dha-pod-config-metadata']['title']
dha_pod_version = dha_pod_conf['dha-pod-config-metadata']['version']
dha_pod_creation = dha_pod_conf['dha-pod-config-metadata']['created']
dha_pod_sha = sha_uri(kwargs["dha_uri"])
dha_pod_comment = dha_pod_conf['dha-pod-config-metadata']['comment']
dha_pod_conf.pop('dha-pod-config-metadata')
final_dha_conf = dha_pod_conf

dha_scenario_override_conf = deploy_scenario_conf["dha-override-config"]
# Only virtual deploy scenarios can override dha.yaml since there
# is no way to programatically override a physical environment:
# wireing, IPMI set-up, etc.
# For Physical environments, dha.yaml overrides will be silently ignored
if dha_scenario_override_conf and (final_dha_conf['adapter'] == 'libvirt' or final_dha_conf['adapter'] == 'esxi' or final_dha_conf['adapter'] == 'vbox'):
    print 'Merging dha-pod and deployment-scenario override information to final dha.yaml configuration....'
    final_dha_conf = dict(mergedicts(final_dha_conf, dha_scenario_override_conf))

# Dump final dha.yaml to argument provided directory
print 'Dumping final dha.yaml to ' + kwargs["output_path"] + '/dha.yaml....'
with open(kwargs["output_path"] + '/dha.yaml', "w") as f:
    f.write("title: DHA.yaml file automatically generated from the configuration files stated in the \"configuration-files\" fragment below\n")
    f.write("version: " + str(calendar.timegm(time.gmtime()))  + "\n")
    f.write("created: " + str(time.strftime("%d/%m/%Y")) + " " + str(time.strftime("%H:%M:%S"))  + "\n")
    f.write("comment: none\n")

    f.write("configuration-files:\n")

    f.write("  dha-pod-configuration:\n")
    f.write("    uri: " +  kwargs["dha_uri"] + "\n")
    f.write("    title: " +  str(dha_pod_title) + "\n")
    f.write("    version: " +  str(dha_pod_version) + "\n")
    f.write("    created: " +  str(dha_pod_creation) + "\n")
    f.write("    sha-1: " +  str(dha_pod_sha) + "\n")
    f.write("    comment: " +  str(dha_pod_comment) + "\n")

    f.write("  deployment-scenario:\n")
    f.write("    uri: " +  str(scenario_uri) + "\n")
    f.write("    title: " +  str(deploy_scenario_title) + "\n")
    f.write("    version: " +  str(deploy_scenario_version) + "\n")
    f.write("    created: " +  str(deploy_scenario_creation) + "\n")
    f.write("    sha-1: " +  str(deploy_scenario_sha) + "\n")
    f.write("    comment: " +  str(deploy_scenario_comment) + "\n")
    yaml.dump(final_dha_conf, f, default_flow_style=False)
