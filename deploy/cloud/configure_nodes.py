###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import yaml
import io
import glob

from common import (
    exec_cmd,
    check_file_exists,
    log,
    backup,
)


class ConfigureNodes(object):

    def __init__(self, yaml_config_dir, env_id, node_id_roles_dict, dea):
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.node_id_roles_dict = node_id_roles_dict
        self.dea = dea

    def config_nodes(self):
        log('Configure nodes')

        # Super dirty fix since Fuel 7 requires user defined roles to be
        # assigned before anything else (BUG fixed in Fuel 8)!
        for node_id, roles_blade in self.node_id_roles_dict.iteritems():
            if "opendaylight" in roles_blade[0] or "onos" in roles_blade[0] or "contrail" in roles_blade[0]:
                exec_cmd('fuel node set --node-id %s --role %s --env %s'
                         % (node_id, roles_blade[0], self.env_id))

        for node_id, roles_blade in self.node_id_roles_dict.iteritems():
            if "opendaylight" not in roles_blade[0] and "onos" not in roles_blade[0] and "contrail" not in roles_blade[0]:
                exec_cmd('fuel node set --node-id %s --role %s --env %s'
                         % (node_id, roles_blade[0], self.env_id))

        # Download the unmodified default deployment configuration, because we
        # need it for the network config.
        self.download_deployment_config()
        for node_id, roles_blade in self.node_id_roles_dict.iteritems():
            self.download_interface_config(node_id)
            self.modify_node_interface(node_id, roles_blade)
            self.modify_node_network_schemes(node_id, roles_blade)
            self.upload_interface_config(node_id)

        # Download our modified deployment configuration, which includes our
        # changes to network topology etc.
        self.download_deployment_config()
        self.upload_deployment_config()

    def modify_node_network_schemes(self, node_id, roles_blade):
        log('Modify network transformations for node %s' % node_id)
        type = self.dea.get_node_property(roles_blade[1], 'transformations')
        transformations = self.dea.get_property(type)
        deployment_dir = '%s/deployment_%s' % (
            self.yaml_config_dir, self.env_id)
        backup(deployment_dir)
        for node_file in glob.glob(deployment_dir + '/*_%s.yaml' % node_id):
            with io.open(node_file) as stream:
                node = yaml.load(stream)

            node['network_scheme'].update(transformations)

            with io.open(node_file, 'w') as stream:
                yaml.dump(node, stream, default_flow_style=False)

    def download_deployment_config(self):
        log('Download deployment config for environment %s' % self.env_id)
        exec_cmd('fuel deployment --env %s --default --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def upload_deployment_config(self):
        log('Upload deployment config for environment %s' % self.env_id)
        exec_cmd('fuel deployment --env %s --upload --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def download_interface_config(self, node_id):
        log('Download interface config for node %s' % node_id)
        exec_cmd('fuel node --env %s --node %s --network --download '
                 '--dir %s' % (self.env_id, node_id, self.yaml_config_dir))

    def upload_interface_config(self, node_id):
        log('Upload interface config for node %s' % node_id)
        exec_cmd('fuel node --env %s --node %s --network --upload '
                 '--dir %s' % (self.env_id, node_id, self.yaml_config_dir))

    def modify_node_interface(self, node_id, roles_blade):
        log('Modify interface config for node %s' % node_id)
        interface_yaml = ('%s/node_%s/interfaces.yaml'
                          % (self.yaml_config_dir, node_id))
        check_file_exists(interface_yaml)
        backup('%s/node_%s' % (self.yaml_config_dir, node_id))

        with io.open(interface_yaml) as stream:
            interfaces = yaml.load(stream)

        net_name_id = {}
        for interface in interfaces:
            for network in interface['assigned_networks']:
                net_name_id[network['name']] = network['id']

        type = self.dea.get_node_property(roles_blade[1], 'interfaces')
        interface_config = self.dea.get_property(type)

        for interface in interfaces:
            interface['assigned_networks'] = []
            if interface['name'] in interface_config:
                for net_name in interface_config[interface['name']]:
                    net = {}
                    net['id'] = net_name_id[net_name]
                    net['name'] = net_name
                    interface['assigned_networks'].append(net)

        with io.open(interface_yaml, 'w') as stream:
            yaml.dump(interfaces, stream, default_flow_style=False)
