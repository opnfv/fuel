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


class HardwareAdapter(object):

    def __init__(self, yaml_path):
        self.dha_struct = None
        self.parse_yaml(yaml_path)

    def parse_yaml(self, yaml_path):
        with io.open(yaml_path) as yaml_file:
            self.dha_struct = yaml.load(yaml_file)

    def get_adapter_type(self):
        return self.dha_struct['adapter']

    def get_all_node_ids(self):
        node_ids = []
        for node in self.dha_struct['nodes']:
            node_ids.append(node['id'])
        node_ids.sort()
        return node_ids

    def get_fuel_node_id(self):
        for node in self.dha_struct['nodes']:
            if 'isFuel' in node and node['isFuel']:
                return node['id']

    def get_node_ids(self):
        node_ids = []
        fuel_node_id = self.get_fuel_node_id()
        for node in self.dha_struct['nodes']:
            if node['id'] != fuel_node_id:
                node_ids.append(node['id'])
        node_ids.sort()
        return node_ids

    def get_node_property(self, node_id, property_name):
        for node in self.dha_struct['nodes']:
            if node['id'] == node_id and property_name in node:
                return node[property_name]

    def get_fuel_access(self):
        for node in self.dha_struct['nodes']:
            if 'isFuel' in node and node['isFuel']:
                return node['username'], node['password']

    def get_disks(self):
        return self.dha_struct['disks']

    def get_vm_definition(self, role):
        vm_definition = self.dha_struct.get('define_vms')
        if vm_definition:
            return vm_definition.get(role)
