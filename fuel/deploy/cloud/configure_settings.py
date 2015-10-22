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

from common import (
    exec_cmd,
    check_file_exists,
    log,
    backup,
)


class ConfigureSettings(object):

    def __init__(self, yaml_config_dir, env_id, dea):
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.dea = dea

    def download_settings(self):
        log('Download settings for environment %s' % self.env_id)
        exec_cmd('fuel settings --env %s --download --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def upload_settings(self):
        log('Upload settings for environment %s' % self.env_id)
        exec_cmd('fuel settings --env %s --upload --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def config_settings(self):
        log('Configure settings')
        self.download_settings()
        self.modify_settings()
        self.upload_settings()

    def modify_settings(self):
        log('Modify settings for environment %s' % self.env_id)
        settings_yaml = ('%s/settings_%s.yaml'
                         % (self.yaml_config_dir, self.env_id))
        check_file_exists(settings_yaml)
        backup(settings_yaml)

        settings = self.dea.get_property('settings')

        with io.open(settings_yaml, 'w') as stream:
            yaml.dump(settings, stream, default_flow_style=False)
