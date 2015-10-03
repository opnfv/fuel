###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import common
import yaml
import io

N = common.N
E = common.E
R = common.R
RO = common.RO
exec_cmd = common.exec_cmd
parse = common.parse
err = common.err
check_file_exists = common.check_file_exists
log = common.log
backup = common.backup


class ConfigureNetwork(object):

    def __init__(self, yaml_config_dir, env_id, dea):
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.dea = dea
        self.required_networks = []

    def download_network_config(self):
        log('Download network config for environment %s' % self.env_id)
        exec_cmd('fuel network --env %s --download --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def upload_network_config(self):
        log('Upload network config for environment %s' % self.env_id)
        exec_cmd('fuel network --env %s --upload --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def config_network(self):
        log('Configure network')
        self.download_network_config()
        self.modify_network_config()
        self.upload_network_config()

    def modify_network_config(self):
        log('Modify network config for environment %s' % self.env_id)
        network_yaml = ('%s/network_%s.yaml'
                        % (self.yaml_config_dir, self.env_id))
        check_file_exists(network_yaml)
        backup(network_yaml)

        network_config = self.dea.get_property('network')

        with io.open(network_yaml) as stream:
            network = yaml.load(stream)

        net_names = self.dea.get_network_names()
        net_id = {}
        for net in network['networks']:
            if net['name'] in net_names:
                net_id[net['name']] = {'id': net['id'],
                                       'group_id': net['group_id']}

        for network in network_config['networks']:
            network.update(net_id[network['name']])

        with io.open(network_yaml, 'w') as stream:
            yaml.dump(network_config, stream, default_flow_style=False)
