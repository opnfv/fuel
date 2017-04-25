#!/usr/bin/python
###############################################################################
# Copyright (c) 2015, 2016 Ericsson AB and others.
# szilard.cserey@ericsson.com
# peter.barabas@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import time
import os
import yaml
import glob
import shutil
import tempfile
import re
import netaddr
import templater

from common import (
    N,
    E,
    R,
    ArgParser,
    exec_cmd,
    parse,
    err,
    log,
    delete,
    commafy,
)

DEA_1 = '''
title: Deployment Environment Adapter (DEA)
# DEA API version supported
version: 1.1
created: {date}
comment: {comment}
'''

DHA_1 = '''
title: Deployment Hardware Adapter (DHA)
# DHA API version supported
version: 1.1
created: {date}
comment: {comment}

# Adapter to use for this definition
# adapter: [ipmi|libvirt]
adapter:

# Node list.
# Mandatory properties are id and role.
# All other properties are adapter specific.
# For Non-Fuel nodes controlled by:
#   - ipmi adapter you need to provide:
#       pxeMac
#       ipmiIp
#       ipmiUser
#       ipmiPass
#     and you *MAY* provide (optional, not added by reap.py):
#       ipmiPort
#   - libvirt adapter you need to provide:
#       libvirtName: <whatever>
#       libvirtTemplate: [libvirt/vms/controller.xml | libvirt/vms/compute.xml]
#
# For the Fuel Node you need to provide:
#       libvirtName: <whatever>
#       libvirtTemplate: libvirt/vms/fuel.xml
#       isFuel: yes
#       username: root
#       password: r00tme
'''

DHA_2 = '''
# Adding the Fuel node as node id {node_id}
# which may not be correct - please adjust as needed.
'''

DISKS = {'fuel': '100G',
         'controller': '100G',
         'compute': '100G'}


class Reap(object):

    def __init__(self, dea_file, dha_file, comment, base_dea, template):
        self.dea_file = dea_file
        self.dha_file = dha_file
        self.comment = comment
        self.base_dea = base_dea
        self.template = template
        self.temp_dir = None
        self.env = None
        self.env_id = None
        self.last_node = None

    def get_env(self):
        env_list = parse(exec_cmd('fuel env'))
        if len(env_list) == 0:
            err('No environment deployed')
        elif len(env_list) > 1:
            err('More than 1 environment deployed')
        self.env = env_list[0]
        self.env_id = self.env[E['id']]

    def download_config(self, config_type):
        log('Download %s config for environment %s'
            % (config_type, self.env_id))
        exec_cmd('fuel %s --env %s --download --dir %s'
                 % (config_type, self.env_id, self.temp_dir))

    def download_node_config(self, nodeid):
        log('Download node %s config for environment %s to %s'
            % (nodeid, self.env_id,self.temp_dir))
        exec_cmd('fuel deployment --node-id %s --env %s  --default --dir %s'
                 % (nodeid, self.env_id, self.temp_dir))

    def write(self, file, text, newline=True):
        mode = 'a' if os.path.isfile(file) else 'w'
        with open(file, mode) as f:
            f.write('%s%s' % (text, ('\n' if newline else '')))

    def write_yaml(self, file, data, newline=True):
        self.write(file, yaml.dump(data, default_flow_style=False).strip(),
                   newline)

    def get_node_by_id(self, node_list, node_id):
        for node in node_list:
            if node[N['id']] == node_id:
                return node

    def reap_interface(self, node_id, interfaces):
        interface, mac = self.get_interface(node_id)
        if_name = None
        if interfaces:
            if_name = self.check_dict_exists(interfaces, interface)
        if not if_name:
            if_name = 'interfaces_%s' % str(len(interfaces) + 1)
            interfaces[if_name] = interface
        return if_name, mac

    def reap_transformation(self, node_id, roles, transformations):
        main_role = 'controller' if 'controller' in roles else 'compute'
        node_file = glob.glob('%s/deployment_%s/%s.yaml'
                              % (self.temp_dir, self.env_id, node_id))
        tr_name = None
        with open(node_file[0]) as f:
            node_config = yaml.load(f)
        transformation = {'transformations':
                              node_config['network_scheme']['transformations']}
        if transformations:
            tr_name = self.check_dict_exists(transformations, transformation)
        if not tr_name:
            tr_name = 'transformations_%s' % str(len(transformations) + 1)
            transformations[tr_name] = transformation
        return tr_name

    def check_dict_exists(self, main_dict, dict):
        for key, val in main_dict.iteritems():
            if cmp(dict, val) == 0:
                return key

    def reap_nodes_interfaces_transformations(self):
        node_list = parse(exec_cmd('fuel node'))
        real_node_ids = [node[N['id']] for node in node_list]
        real_node_ids = map(int, real_node_ids)
        real_node_ids.sort()
        min_node = min(real_node_ids)
        interfaces = {}
        transformations = {}
        dea_nodes = []
        dha_nodes = []

        for real_node_id in real_node_ids:
            node_id = real_node_id - min_node + 1
            self.last_node = node_id
            node = self.get_node_by_id(node_list, str(real_node_id))
            roles = commafy(node[N['roles']])
            if not roles:
                err('Fuel Node %s has no role' % real_node_id)
            dea_node = {'id': node_id,
                        'role': roles}
            dha_node = {'id': node_id}
            if_name, mac = self.reap_interface(real_node_id, interfaces)
            log('reap transformation for node %s' % real_node_id)
            tr_name = self.reap_transformation(real_node_id, roles,
                                               transformations)
            dea_node.update(
                {'interfaces': if_name,
                 'transformations': tr_name})

            dha_node.update(
                {'pxeMac': mac if mac else None,
                 'ipmiIp': None,
                 'ipmiUser': None,
                 'ipmiPass': None,
                 'libvirtName': None,
                 'libvirtTemplate': None})

            dea_nodes.append(dea_node)
            dha_nodes.append(dha_node)

        self.write_yaml(self.dha_file, {'nodes': dha_nodes}, False)
        self.write_yaml(self.dea_file, {'nodes': dea_nodes})
        self.write_yaml(self.dea_file, interfaces)
        self.write_yaml(self.dea_file, transformations)
        self.reap_fuel_node_info()
        self.write_yaml(self.dha_file, {'disks': DISKS})

    def reap_fuel_node_info(self):
        dha_nodes = []
        dha_node = {
            'id': self.last_node + 1,
            'libvirtName': None,
            'libvirtTemplate': None,
            'isFuel': True,
            'username': 'root',
            'password': 'r00tme'}

        dha_nodes.append(dha_node)

        self.write(self.dha_file, DHA_2.format(node_id=dha_node['id']), False)
        self.write_yaml(self.dha_file, dha_nodes)

    def reap_environment_info(self):
        network_file = ('%s/network_%s.yaml'
                        % (self.temp_dir, self.env_id))
        network = self.read_yaml(network_file)

        env = {'environment':
                   {'name': self.env[E['name']],
                    'net_segment_type':
                        network['networking_parameters']['segmentation_type']}}
        self.write_yaml(self.dea_file, env)
        wanted_release = None
        rel_list = parse(exec_cmd('fuel release'))
        for rel in rel_list:
            if rel[R['id']] == self.env[E['release_id']]:
                wanted_release = rel[R['name']]
        self.write_yaml(self.dea_file, {'wanted_release': wanted_release})

    def reap_fuel_settings(self):
        data = self.read_yaml('/etc/fuel/astute.yaml')
        fuel = {}
        del data['ADMIN_NETWORK']['mac']
        del data['ADMIN_NETWORK']['interface']
        for key in ['ADMIN_NETWORK', 'HOSTNAME', 'DNS_DOMAIN', 'DNS_SEARCH',
                    'DNS_UPSTREAM', 'NTP1', 'NTP2', 'NTP3', 'FUEL_ACCESS']:
            fuel[key] = data[key]
        for key in fuel['ADMIN_NETWORK'].keys():
            if key not in ['ipaddress', 'netmask',
                           'dhcp_pool_start', 'dhcp_pool_end', 'ssh_network']:
                del fuel['ADMIN_NETWORK'][key]

        ## FIXME(armband): Factor in support for adding public/other interfaces.
        ## TODO: Following block expects interface name(s) to be lowercase only
        interfaces_list = exec_cmd('ip -o -4 a | grep -e "e[nt][hopsx].*"')
        for interface in re.split('\n', interfaces_list):
            # Sample output line from above cmd:
            # 3: eth1 inet 10.0.2.10/24 scope global eth1 valid_lft forever ...
            ifcfg = re.split(r'\s+', interface)
            ifcfg_name = ifcfg[1]
            ifcfg_ipaddr = ifcfg[3]

            # Filter out admin interface (device name is not known, match IP)
            current_network = netaddr.IPNetwork(ifcfg_ipaddr)
            if str(current_network.ip) == fuel['ADMIN_NETWORK']['ipaddress']:
                continue

            # Read ifcfg-* network interface config file, write IFCFG_<IFNAME>
            ifcfg_sec = 'IFCFG_%s' % ifcfg_name.upper()
            fuel[ifcfg_sec] = {}
            ifcfg_data = {}
            ifcfg_f = ('/etc/sysconfig/network-scripts/ifcfg-%s' % ifcfg_name)
            with open(ifcfg_f) as f:
                for line in f:
                    if line.startswith('#'):
                        continue
                    (key, val) = line.split('=')
                    ifcfg_data[key.lower()] = val.rstrip()

            # Keep only needed info (e.g. filter-out type=Ethernet).
            fuel[ifcfg_sec]['ipaddress'] = ifcfg_data['ipaddr']
            fuel[ifcfg_sec]['device'] = ifcfg_data['device']
            fuel[ifcfg_sec]['netmask'] = str(current_network.netmask)
            fuel[ifcfg_sec]['gateway'] = ifcfg_data['gateway']

        self.write_yaml(self.dea_file, {'fuel': fuel})

    def reap_network_settings(self):
        network_file = ('%s/network_%s.yaml'
                        % (self.temp_dir, self.env_id))
        data = self.read_yaml(network_file)
        network = {}
        network['networking_parameters'] = data['networking_parameters']
        network['networks'] = data['networks']
        for net in network['networks']:
            del net['id']
            del net['group_id']
        self.write_yaml(self.dea_file, {'network': network})

    def reap_settings(self):
        settings_file = '%s/settings_%s.yaml' % (self.temp_dir, self.env_id)
        settings = self.read_yaml(settings_file)
        self.write_yaml(self.dea_file, {'settings': settings})

    def get_interface(self, real_node_id):
        exec_cmd('fuel node --node-id %s --network --download --dir %s'
                 % (real_node_id, self.temp_dir))
        interface_file = ('%s/node_%s/interfaces.yaml'
                          % (self.temp_dir, real_node_id))
        interfaces = self.read_yaml(interface_file)
        interface_config = {}
        pxe_mac = None
        for interface in interfaces:
            networks = []
            for network in interface['assigned_networks']:
                networks.append(network['name'])
                if network['name'] == 'fuelweb_admin':
                    pxe_mac = interface['mac']
            if networks:
                interface_config[interface['name']] = networks
        return interface_config, pxe_mac

    def read_yaml(self, yaml_file):
        with open(yaml_file) as f:
            data = yaml.load(f)
            return data

    def intro(self):
        delete(self.dea_file)
        delete(self.dha_file)

        self.temp_dir = tempfile.mkdtemp()
        date = time.strftime('%c')
        self.write(self.dea_file,
                   DEA_1.format(date=date, comment=self.comment), False)
        self.write(self.dha_file,
                   DHA_1.format(date=date, comment=self.comment))
        self.get_env()

        # Need to download deployment with explicit node ids
        node_list = parse(exec_cmd('fuel node'))
        real_node_ids = [node[N['id']] for node in node_list]
        real_node_ids.sort()
        self.download_node_config(','.join(real_node_ids))

        self.download_config('settings')
        self.download_config('network')

    def create_base_dea(self):
        templater = templater.Templater(self.dea_file,
                                        self.template,
                                        self.base_dea)
        templater.run()

    def finale(self):
        log('DEA file is available at %s' % self.dea_file)
        log('DHA file is available at %s (this is just a template)'
            % self.dha_file)
        if self.base_dea:
            log('DEA base file is available at %s' % self.base_dea)
        shutil.rmtree(self.temp_dir)

    def reap(self):
        self.intro()
        self.reap_environment_info()
        self.reap_nodes_interfaces_transformations()
        self.reap_fuel_settings()
        self.reap_network_settings()
        self.reap_settings()
        if self.base_dea:
            self.create_base_dea()
        self.finale()


def parse_arguments():
    parser = ArgParser(prog='python %s' % __file__)
    parser.add_argument('dea_file', nargs='?', action='store',
                        default='dea.yaml',
                        help='Deployment Environment Adapter: dea.yaml')
    parser.add_argument('dha_file', nargs='?', action='store',
                        default='dha.yaml',
                        help='Deployment Hardware Adapter: dha.yaml')
    parser.add_argument('comment', nargs='?', action='store', help='Comment')
    parser.add_argument('-base_dea',
                        dest='base_dea',
                        help='Create specified base DEA file from "dea_file"')
    parser.add_argument('-template',
                        dest='template',
                        nargs='?',
                        default='base_dea_template.yaml',
                        help='Base DEA is generated from this template')
    args = parser.parse_args()
    return (args.dea_file,
            args.dha_file,
            args.comment,
            args.base_dea,
            args.template)


def main():
    dea_file, dha_file, comment, base_dea, template = parse_arguments()

    r = Reap(dea_file, dha_file, comment, base_dea, template)
    r.reap()


if __name__ == '__main__':
    main()
