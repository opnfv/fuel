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
import netaddr


class DeploymentEnvironmentAdapter(object):

    def __init__(self, yaml_path):
        self.dea_struct = None
        self.parse_yaml(yaml_path)
        self.network_names = []
        self.collect_network_names()

    def modify_ip(self, ip_addr, index, val):
        ip_str = str(netaddr.IPAddress(ip_addr))
        decimal_list = map(int, ip_str.split('.'))
        decimal_list[index] = val
        return '.'.join(map(str, decimal_list))

    def parse_yaml(self, yaml_path):
        with io.open(yaml_path) as yaml_file:
            self.dea_struct = yaml.load(yaml_file)

    def get_env_name(self):
        return self.get_property('environment')['name']

    def get_env_net_segment_type(self):
        return self.get_property('environment')['net_segment_type']

    def get_fuel_config(self):
        return self.dea_struct['fuel']

    def get_fuel_ip(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['ADMIN_NETWORK']['ipaddress']

    def get_fuel_netmask(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['ADMIN_NETWORK']['netmask']

    def get_fuel_gateway(self):
        ip = self.get_fuel_ip()
        return self.modify_ip(ip, 3, 1)

    def get_fuel_hostname(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['HOSTNAME']

    def get_fuel_dns(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['DNS_UPSTREAM']

    def get_node_property(self, node_id, property_name):
        for node in self.dea_struct['nodes']:
            if node['id'] == node_id and property_name in node:
                return node[property_name]

    def get_node_roles(self, node_id):
        return self.get_node_property(node_id, 'role')

    def get_node_main_role(self, node_id, fuel_node_id):
        if node_id == fuel_node_id:
            return 'fuel'
        roles = self.get_node_roles(node_id)
        return 'controller' if 'controller' in roles else 'compute'

    def get_node_ids(self):
        node_ids = []
        for node in self.dea_struct['nodes']:
            node_ids.append(node['id'])
        return node_ids

    def get_property(self, property_name):
        return self.dea_struct[property_name]

    def collect_network_names(self):
        self.network_names = []
        for network in self.dea_struct['network']['networks']:
            self.network_names.append(network['name'])

    def get_network_names(self):
        return self.network_names

    def get_dns_list(self):
        settings = self.get_property('settings')
        dns_list = settings['editable']['external_dns']['dns_list']['value']
        return [d.strip() for d in dns_list.split(',')]

    def get_ntp_list(self):
        settings = self.get_property('settings')
        ntp_list = settings['editable']['external_ntp']['ntp_list']['value']
        return [n.strip() for n in ntp_list.split(',')]

    def get_blade_node_map(self):
        return self.dea_struct['blade_node_map']
