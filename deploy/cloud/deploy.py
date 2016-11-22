###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from dea import DeploymentEnvironmentAdapter
from configure_environment import ConfigureEnvironment
from deployment import Deployment

from common import (
    R,
    exec_cmd,
    parse,
    check_file_exists,
    commafy,
    ArgParser,
    log,
)

YAML_CONF_DIR = '/var/lib/opnfv'


class Deploy(object):

    def __init__(self, dea_file, no_health_check, deploy_timeout,
                 no_deploy_environment):
        self.dea = DeploymentEnvironmentAdapter(dea_file)
        self.no_health_check = no_health_check
        self.deploy_timeout = deploy_timeout
        self.no_deploy_environment = no_deploy_environment
        self.macs_per_blade = {}
        self.blades = self.dea.get_node_ids()
        self.blade_node_dict = self.dea.get_blade_node_map()
        self.node_roles_dict = {}
        self.env_id = None
        self.wanted_release = self.dea.get_property('wanted_release')

    def assign_roles_to_cluster_node_ids(self):
        self.node_roles_dict = {}
        for blade, node in self.blade_node_dict.iteritems():
            if self.dea.get_node_roles(blade):
                roles = commafy(self.dea.get_node_roles(blade))
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
                         self.node_roles_dict, self.no_health_check,
                         self.deploy_timeout)
        if not self.no_deploy_environment:
            dep.deploy()
        else:
            log('Configuration is done. Deployment is not launched.')

    def deploy(self):

        self.assign_roles_to_cluster_node_ids()

        self.configure_environment()

        self.deploy_cloud()


def parse_arguments():
    parser = ArgParser(prog='python %s' % __file__)
    parser.add_argument('-nh', dest='no_health_check', action='store_true',
                        default=False,
                        help='Don\'t run health check after deployment')
    parser.add_argument('-dt', dest='deploy_timeout', action='store',
                        default=240, help='Deployment timeout (in minutes) '
                        '[default: 240]')
    parser.add_argument('-nde', dest='no_deploy_environment',
                        action='store_true', default=False,
                        help=('Do not launch environment deployment'))
    parser.add_argument('dea_file', action='store',
                        help='Deployment Environment Adapter: dea.yaml')

    args = parser.parse_args()
    check_file_exists(args.dea_file)

    kwargs = {'dea_file': args.dea_file,
              'no_health_check': args.no_health_check,
              'deploy_timeout': args.deploy_timeout,
              'no_deploy_environment': args.no_deploy_environment}
    return kwargs


def main():
    kwargs = parse_arguments()
    deploy = Deploy(**kwargs)
    deploy.deploy()

if __name__ == '__main__':
    main()
