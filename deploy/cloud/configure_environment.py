###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from configure_settings import ConfigureSettings
from configure_network import ConfigureNetwork
from configure_nodes import ConfigureNodes

from common import (
    E,
    exec_cmd,
    parse,
    err,
    log,
    delete,
    create_dir_if_not_exists,
)


class ConfigureEnvironment(object):

    def __init__(self, dea, yaml_config_dir, release_id, node_id_roles_dict):
        self.env_id = None
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.release_id = release_id
        self.node_id_roles_dict = node_id_roles_dict
        self.required_networks = []

    def env_exists(self, env_name):
        env_list = parse(exec_cmd('fuel env --list'))
        for env in env_list:
            if env[E['name']] == env_name and env[E['status']] == 'new':
                self.env_id = env[E['id']]
                return True
        return False

    def configure_environment(self):
        log('Configure environment')
        delete(self.yaml_config_dir)
        create_dir_if_not_exists(self.yaml_config_dir)
        env_name = self.dea.get_env_name()
        env_net_segment_type = self.dea.get_env_net_segment_type()
        log('Creating environment %s release %s net-segment-type %s'
            % (env_name, self.release_id, env_net_segment_type))
        exec_cmd('fuel env create --name "%s" --release %s --net-segment-type %s'
                 % (env_name, self.release_id, env_net_segment_type))

        if not self.env_exists(env_name):
            err('Failed to create environment %s' % env_name)
        self.config_settings()
        self.config_network()
        self.config_nodes()

    def config_settings(self):
        settings = ConfigureSettings(self.yaml_config_dir, self.env_id,
                                     self.dea)
        settings.config_settings()

    def config_network(self):
        network = ConfigureNetwork(self.yaml_config_dir, self.env_id, self.dea)
        network.config_network()

    def config_nodes(self):
        nodes = ConfigureNodes(self.yaml_config_dir, self.env_id,
                               self.node_id_roles_dict, self.dea)
        nodes.config_nodes()
