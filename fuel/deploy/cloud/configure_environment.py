import common
import os
import shutil

from configure_settings import ConfigureSettings
from configure_network import ConfigureNetwork
from configure_nodes import ConfigureNodes

N = common.N
E = common.E
R = common.R
RO = common.RO
exec_cmd = common.exec_cmd
parse = common.parse
err = common.err
log = common.log

class ConfigureEnvironment(object):

    def __init__(self, dea, yaml_config_dir, release_id, node_id_roles_dict):
        self.env_id = None
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.env_name = self.dea.get_property('environment_name')
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
        if os.path.exists(self.yaml_config_dir):
            log('Deleting existing config directory %s' % self.yaml_config_dir)
            shutil.rmtree(self.yaml_config_dir)
        log('Creating new config directory %s' % self.yaml_config_dir)
        os.makedirs(self.yaml_config_dir)

        mode = self.dea.get_property('environment_mode')
        log('Creating environment %s release %s, mode %s, network-mode neutron'
            ', net-segment-type vlan' % (self.env_name, self.release_id, mode))
        exec_cmd('fuel env create --name %s --release %s --mode %s '
                 '--network-mode neutron --net-segment-type vlan'
                 % (self.env_name, self.release_id, mode))

        if not self.env_exists(self.env_name):
            err('Failed to create environment %s' % self.env_name)
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



