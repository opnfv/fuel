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
                        default=False,
                        help='dha configuration file FQDN URI',
                        required=True)
    parser.add_argument('-deab', dest='dea_base_uri', action='store',
                        default=False,
                        help='dea base configuration FQDN URI',
                        required=True)
    parser.add_argument('-deao', dest='dea_pod_override_uri',
                        action='store',
                        default=False,
                        help='dea POD override configuration FQDN URI',
                        required=True)
    parser.add_argument('-scenario-base-uri',
                        dest='scenario_base_uri',
                        action='store',
                        default=False,
                        help='Deployment scenario base directory URI',
                        required=True)
    parser.add_argument('-scenario', dest='scenario', action='store',
                        default=False,
                        help=('Deployment scenario short-name (priority), '
                              'or base file name (in the absense of a '
                              'shortname defenition)'),
                        required=True)

    parser.add_argument('-plugins', dest='plugins_uri', action='store',
                        default=False,
                        help='Plugin configurations directory URI',
                        required=True)
    parser.add_argument('-output', dest='output_path', action='store',
                        default=False,
                        help='Local path for resulting output configuration files',
                        required=True)
    args = parser.parse_args()
    # log(args)
    kwargs = {'dha_uri': args.dha_uri,
              'dea_base_uri': args.dea_base_uri,
              'dea_pod_override_uri': args.dea_pod_override_uri,
              'scenario_base_uri': args.scenario_base_uri,
              'scenario': args.scenario,
              'plugins_uri': args.plugins_uri,
              'output_path': args.output_path}
    return kwargs


def warning(msg):
    red = '\033[0;31m'
    NC = '\033[0m'
    print('%(red)s WARNING: %(msg)s %(NC)s' % {'red': red,
                                               'msg': msg,
                                               'NC': NC})


def setup_yaml():
    represent_dict_order = lambda self, data: self.represent_mapping('tag:yaml.org,2002:map', data.items())
    yaml.add_representer(collections.OrderedDict, represent_dict_order)


def sha_uri(uri):
    response = urllib2.urlopen(uri)
    data = response.read()
    sha1 = hashlib.sha1()
    sha1.update(data)
    return sha1.hexdigest()


def merge_fuel_plugin_version_list(list1, list2):
    final_list = []
    # When the plugin version in not there in list1 it will
    # not be copied
    for e_l1 in list1:
        plugin_version = e_l1.get('metadata', {}).get('plugin_version')
        plugin_version_found = False
        for e_l2 in list2:
            if plugin_version == e_l2.get('metadata', {}).get('plugin_version'):
                final_list.append(dict(merge_dicts(e_l1, e_l2)))
                plugin_version_found = True
        if not plugin_version_found:
            final_list.append(e_l1)
    return final_list


def merge_networks(list_1, list_2):
    new_nets = {x.get('name'): x for x in list_2}

    return [new_nets.get(net.get('name'), net) for net in list_1]


def merge_dicts(dict1, dict2):
    for k in set(dict1).union(dict2):
        if k in dict1 and k in dict2:
            if isinstance(dict1[k], dict) and isinstance(dict2[k], dict):
                yield (k, dict(merge_dicts(dict1[k], dict2[k])))
                continue
            if isinstance(dict1[k], list) and isinstance(dict2[k], list):
                if k == 'versions':
                    yield (k,
                           merge_fuel_plugin_version_list(dict1[k], dict2[k]))
                    continue
                if k == 'networks':
                    yield (k,
                           merge_networks(dict1[k], dict2[k]))
                    continue

            # If one of the values is not a dict nor a list,
            # you can't continue merging it.
            # Value from second dict overrides one in first if exists.
        if k in dict2:
            yield (k, dict2[k])
        else:
            yield (k, dict1[k])


def get_node_ifaces_and_trans(nodes, nid):
    for node in nodes:
        if node['id'] == nid:
            if 'transformations' in node and 'interfaces' in node:
                return (node['interfaces'], node['transformations'])
            else:
                return None

    return None


def process_dea_base(kwargs):
    # Fetch dea-base, extract and purge meta-data
    print('Parsing dea-base from: ' + kwargs["dea_base_uri"] + "....")
    response = urllib2.urlopen(kwargs["dea_base_uri"])
    dea_base_conf = yaml.load(response.read())

    metadata = dict()
    metadata['title'] = dea_base_conf['dea-base-config-metadata']['title']
    metadata['version'] = dea_base_conf['dea-base-config-metadata']['version']
    metadata['created'] = dea_base_conf['dea-base-config-metadata']['created']
    metadata['sha'] = sha_uri(kwargs["dea_base_uri"])
    metadata['comment'] = dea_base_conf['dea-base-config-metadata']['comment']
    dea_base_conf.pop('dea-base-config-metadata')

    return(dea_base_conf, metadata)


def process_dea_pod_override(kwargs, dea_conf):
    # Fetch dea-pod-override, extract and purge meta-data, merge with previous dea data structure
    print('Parsing the dea-pod-override from: ' + kwargs["dea_pod_override_uri"] + "....")
    response = urllib2.urlopen(kwargs["dea_pod_override_uri"])
    dea_pod_override_conf = yaml.load(response.read())

    metadata = dict()
    if dea_pod_override_conf:
        metadata['title'] = dea_pod_override_conf['dea-pod-override-config-metadata']['title']
        metadata['version'] = dea_pod_override_conf['dea-pod-override-config-metadata']['version']
        metadata['created'] = dea_pod_override_conf['dea-pod-override-config-metadata']['created']
        metadata['sha'] = sha_uri(kwargs["dea_pod_override_uri"])
        metadata['comment'] = dea_pod_override_conf['dea-pod-override-config-metadata']['comment']
        print('Merging dea-base and dea-pod-override configuration ....')
        dea_pod_override_conf.pop('dea-pod-override-config-metadata')
        # Copy the list of original nodes, which holds info on their transformations
        dea_pod_override_nodes = None
        if 'nodes' in dea_pod_override_conf:
            dea_pod_override_nodes = list(dea_pod_override_conf['nodes'])
        if dea_pod_override_conf:
            dea_conf = dict(merge_dicts(dea_conf, dea_pod_override_conf))

    return(dea_conf, metadata, dea_pod_override_nodes)


def get_scenario_uri():
    kwargs = parse_arguments()
    response = urllib2.urlopen(kwargs["scenario_base_uri"] + "/scenario.yaml")
    scenario_short_translation_conf = yaml.load(response.read())
    if kwargs["scenario"] in scenario_short_translation_conf:
        scenario_uri = (kwargs["scenario_base_uri"]
                        + "/"
                        + scenario_short_translation_conf[kwargs["scenario"]]['configfile'])
    else:
        scenario_uri = kwargs["scenario_base_uri"] + "/" + kwargs["scenario"]

    return scenario_uri


def get_scenario_config(scenario):
    scenario_metadata = dict()
    scenario_uri = get_scenario_uri()
    scenario_metadata['uri'] = scenario_uri
    response = urllib2.urlopen(scenario_uri)
    return yaml.load(response.read()), scenario_metadata


def process_scenario_config(kwargs, dea_conf, dea_pod_override_nodes):
    # Fetch deployment-scenario, extract and purge meta-data, merge deployment-scenario/
    # dea-override-configith previous dea data structure
    print('Parsing deployment-scenario from: ' + kwargs["scenario"] + "....")

    scenario_conf, scenario_metadata = get_scenario_config(kwargs["scenario"])

    # scenario_metadata = dict()

    if scenario_conf:
        scenario_metadata['title'] = scenario_conf['deployment-scenario-metadata']['title']
        scenario_metadata['version'] = scenario_conf['deployment-scenario-metadata']['version']
        scenario_metadata['created'] = scenario_conf['deployment-scenario-metadata']['created']
        scenario_metadata['sha'] = sha_uri(scenario_metadata['uri'])
        scenario_metadata['comment'] = scenario_conf['deployment-scenario-metadata']['comment']
        scenario_conf.pop('deployment-scenario-metadata')
    else:
        print("Deployment scenario file not found or is empty")
        print("Cannot continue, exiting ....")
        sys.exit(1)

    dea_scenario_override_conf = scenario_conf["dea-override-config"]
    if dea_scenario_override_conf:
        print('Merging dea-base-, dea-pod-override- and deployment-scenario '
              'configuration into final dea.yaml configuration....')
        dea_conf = dict(merge_dicts(dea_conf, dea_scenario_override_conf))

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
    if scenario_conf["stack-extensions"]:
        for module in scenario_conf["stack-extensions"]:
            print('Loading configuration for module: '
                  + module["module"]
                  + ' and merging it to final dea.yaml configuration....')
            response = urllib2.urlopen(kwargs["plugins_uri"]
                                       + '/'
                                       + module["module-config-name"]
                                       + '_'
                                       + module["module-config-version"]
                                       + '.yaml')
            module_conf = yaml.load(response.read())
            modules.append(module["module"])
            module_uris.append(kwargs["plugins_uri"]
                               + '/'
                               + module["module-config-name"]
                               + '_'
                               + module["module-config-version"]
                               + '.yaml')
            module_titles.append(str(module_conf['plugin-config-metadata']['title']))
            module_versions.append(str(module_conf['plugin-config-metadata']['version']))
            module_creations.append(str(module_conf['plugin-config-metadata']['created']))
            module_shas.append(sha_uri(kwargs["plugins_uri"]
                                       + '/'
                                       + module["module-config-name"]
                                       + '_'
                                       + module["module-config-version"]
                                       + '.yaml'))
            module_comments.append(str(module_conf['plugin-config-metadata']['comment']))
            module_conf.pop('plugin-config-metadata')
            dea_conf['settings']['editable'].update(module_conf)
            scenario_module_override_conf = module.get('module-config-override')
            if scenario_module_override_conf:
                dea_scenario_module_override_conf = {}
                dea_scenario_module_override_conf['settings'] = {}
                dea_scenario_module_override_conf['settings']['editable'] = {}
                dea_scenario_module_override_conf['settings']['editable'][module["module"]] = scenario_module_override_conf
                dea_conf = dict(merge_dicts(dea_conf, dea_scenario_module_override_conf))

    if dea_pod_override_nodes:
        for node in dea_conf['nodes']:
            data = get_node_ifaces_and_trans(dea_pod_override_nodes, node['id'])
            if data:
                print ("Honoring original interfaces and transformations for "
                        "node %d to %s, %s" % (node['id'], data[0], data[1]))
                node['interfaces'] = data[0]
                node['transformations'] = data[1]

    return(dea_conf, scenario_metadata, modules)


def dump_dea_config(kwargs, dea_conf, dea_base_metadata, dea_pod_override_metadata, scenario_metadata, modules):
    # Dump final dea.yaml including configuration management meta-data to argument provided
    # directory
    if not os.path.exists(kwargs["output_path"]):
        os.makedirs(kwargs["output_path"])
    print('Dumping final dea.yaml to ' + kwargs["output_path"] + '/dea.yaml....')
    with open(kwargs["output_path"] + '/dea.yaml', "w") as f:
        f.write("\n".join([("title: DEA.yaml file automatically generated from the "
                            'configuration files stated in the "configuration-files" '
                            "fragment below"),
                           "version: " + str(calendar.timegm(time.gmtime())),
                           "created: " + time.strftime("%d/%m/%Y %H:%M:%S"),
                           "comment: none\n"]))

        f.write("\n".join(["configuration-files:",
                           "  dea-base:",
                           "    uri: " + kwargs["dea_base_uri"],
                           "    title: " + dea_base_metadata['title'],
                           "    version: " + dea_base_metadata['version'],
                           "    created: " + dea_base_metadata['created'],
                           "    sha1: " + sha_uri(kwargs["dea_base_uri"]),
                           "    comment: " + dea_base_metadata['comment'] + "\n"]))

        f.write("\n".join(["  pod-override:",
                           "    uri: " + kwargs["dea_pod_override_uri"],
                           "    title: " + dea_pod_override_metadata['title'],
                           "    version: " + dea_pod_override_metadata['version'],
                           "    created: " + dea_pod_override_metadata['created'],
                           "    sha1: " + dea_pod_override_metadata['sha'],
                           "    comment: " + dea_pod_override_metadata['comment'] + "\n"]))

        f.write("\n".join(["  deployment-scenario:",
                           "    uri: " + scenario_metadata['uri'],
                           "    title: " + scenario_metadata['title'],
                           "    version: " + scenario_metadata['version'],
                           "    created: " + scenario_metadata['created'],
                           "    sha1: " + scenario_metadata['sha'],
                           "    comment: " + scenario_metadata['comment'] + "\n"]))

        f.write("  plugin-modules:\n")
        for k, _ in enumerate(modules):
            f.write("\n".join(["  - module: " + modules[k],
                               "    uri: " + module_uris[k],
                               "    title: " + module_titles[k],
                               "    version: " + module_versions[k],
                               "    created: " + module_creations[k],
                               "    sha-1: " + module_shas[k],
                               "    comment: " + module_comments[k] + "\n"]))

        yaml.dump(dea_conf, f, default_flow_style=False)


def process_dha_pod_config(kwargs):
    # Load POD dha and override it with "deployment-scenario/dha-override-config" section
    print('Generating final dha.yaml configuration....')
    print('Parsing dha-pod yaml configuration....')
    response = urllib2.urlopen(kwargs["dha_uri"])
    dha_pod_conf = yaml.load(response.read())

    dha_metadata = dict()
    dha_metadata['title'] = dha_pod_conf['dha-pod-config-metadata']['title']
    dha_metadata['version'] = dha_pod_conf['dha-pod-config-metadata']['version']
    dha_metadata['created'] = dha_pod_conf['dha-pod-config-metadata']['created']
    dha_metadata['sha'] = sha_uri(kwargs["dha_uri"])
    dha_metadata['comment'] = dha_pod_conf['dha-pod-config-metadata']['comment']
    dha_pod_conf.pop('dha-pod-config-metadata')

    scenario_conf, _ = get_scenario_config(kwargs['scenario'])
    dha_scenario_override_conf = scenario_conf["dha-override-config"]
    # Only virtual deploy scenarios can override dha.yaml since there
    # is no way to programatically override a physical environment:
    # wireing, IPMI set-up, etc.
    # For Physical environments, dha.yaml overrides will be silently ignored
    if dha_scenario_override_conf and (dha_pod_conf['adapter'] == 'libvirt'
                                       or dha_pod_conf['adapter'] == 'esxi'
                                       or dha_pod_conf['adapter'] == 'vbox'):
        print('Merging dha-pod and deployment-scenario override information to final dha.yaml configuration....')
        dha_pod_conf = dict(merge_dicts(dha_pod_conf, dha_scenario_override_conf))

    return(dha_pod_conf, dha_metadata)


def dump_dha_config(kwargs, dha_conf, dha_metadata, scenario_metadata):
    # Dump final dha.yaml to argument provided directory
    print('Dumping final dha.yaml to ' + kwargs["output_path"] + '/dha.yaml....')
    with open(kwargs["output_path"] + '/dha.yaml', "w") as f:
        f.write("\n".join([("title: DHA.yaml file automatically generated from "
                            "the configuration files stated in the "
                            '"configuration-files" fragment below'),
                           "version: " + str(calendar.timegm(time.gmtime())),
                           "created: " + time.strftime("%d/%m/%Y %H:%M:%S"),
                           "comment: none\n"]))

        f.write("configuration-files:\n")

        f.write("\n".join(["  dha-pod-configuration:",
                           "    uri: " + kwargs["dha_uri"],
                           "    title: " + dha_metadata['title'],
                           "    version: " + dha_metadata['version'],
                           "    created: " + dha_metadata['created'],
                           "    sha-1: " + dha_metadata['sha'],
                           "    comment: " + dha_metadata['comment'] + "\n"]))

        f.write("\n".join(["  deployment-scenario:",
                           "    uri: " + scenario_metadata['uri'],
                           "    title: " + scenario_metadata['title'],
                           "    version: " + scenario_metadata['version'],
                           "    created: " + scenario_metadata['created'],
                           "    sha-1: " + scenario_metadata['sha'],
                           "    comment: " + scenario_metadata['comment'] + "\n"]))

        yaml.dump(dha_conf, f, default_flow_style=False)


def main():
    setup_yaml()
    kwargs = parse_arguments()

    # Generate final dea.yaml by merging following config files/fragments in reverse priority order:
    # "dea-base", "dea-pod-override", "deplyment-scenario/module-config-override"
    # and "deployment-scenario/dea-override"
    print('Generating final dea.yaml configuration....')

    dea_conf, dea_base_metadata = process_dea_base(kwargs)
    dea_conf, dea_pod_override_metadata, dea_pod_override_nodes = process_dea_pod_override(kwargs, dea_conf)
    dea_conf, scenario_metadata, modules = process_scenario_config(kwargs, dea_conf, dea_pod_override_nodes)
    dump_dea_config(kwargs, dea_conf, dea_base_metadata, dea_pod_override_metadata, scenario_metadata, modules)

    dha_conf, dha_metadata = process_dha_pod_config(kwargs)
    dump_dha_config(kwargs, dha_conf, dha_metadata, scenario_metadata)


if __name__ == '__main__':
    main()
