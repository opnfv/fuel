###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import os
import yaml
import io
import glob

import common
from dea import DeploymentEnvironmentAdapter
from configure_environment import ConfigureEnvironment
from deployment import Deployment

YAML_CONF_DIR = '/var/lib/opnfv'

N = common.N
E = common.E
R = common.R
RO = common.RO
exec_cmd = common.exec_cmd
parse = common.parse
err = common.err
check_file_exists = common.check_file_exists
log = common.log
commafy = common.commafy
ArgParser = common.ArgParser


class Deploy(object):

    def __init__(self, dea_file, blade_node_file, no_health_check):
        self.dea = DeploymentEnvironmentAdapter(dea_file)
        self.blade_node_file = blade_node_file
        self.no_health_check = no_health_check
        self.macs_per_blade = {}
        self.blades = self.dea.get_node_ids()
        self.blade_node_dict = {}
        self.node_roles_dict = {}
        self.env_id = None
        self.wanted_release = self.dea.get_property('wanted_release')

    def get_blade_node_mapping(self):
        with io.open(self.blade_node_file, 'r') as stream:
            self.blade_node_dict = yaml.load(stream)

    def assign_roles_to_cluster_node_ids(self):
        self.node_roles_dict = {}
        for blade, node in self.blade_node_dict.iteritems():
            roles = commafy(self.dea.get_node_role(blade))
            self.node_roles_dict[node] = (roles, blade)

    def configure_environment(self):
        release_list = parse(exec_cmd('fuel release -l'))
        for release in release_list:
            if release[R['name']] == self.wanted_release:
                break
        config_env = ConfigureEnvironment(self.dea, YAML_CONF_DIR,
                                          release[R['id']],
                                          self.node_roles_dict)
        config_env.configure_environment()
        self.env_id = config_env.env_id

    def deploy_cloud(self):
        dep = Deployment(self.dea, YAML_CONF_DIR, self.env_id,
                         self.node_roles_dict, self.no_health_check)
        dep.deploy()

    def deploy(self):

        self.get_blade_node_mapping()

        self.assign_roles_to_cluster_node_ids()

        self.configure_environment()

        self.deploy_cloud()


def parse_arguments():
    parser = ArgParser(prog='python %s' % __file__)
    parser.add_argument('-nh', dest='no_health_check', action='store_true',
                        default=False,
                        help='Don\'t run health check after deployment')
    parser.add_argument('dea_file', action='store',
                        help='Deployment Environment Adapter: dea.yaml')
    parser.add_argument('blade_node_file', action='store',
                        help='Blade Node mapping: blade_node.yaml')
    args = parser.parse_args()
    check_file_exists(args.dea_file)
    check_file_exists(args.blade_node_file)
    return (args.dea_file, args.blade_node_file, args.no_health_check)


def main():
    dea_file, blade_node_file, no_health_check = parse_arguments()
    deploy = Deploy(dea_file, blade_node_file, no_health_check)
    deploy.deploy()

if __name__ == '__main__':
    main()
