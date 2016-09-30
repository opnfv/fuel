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
import os

from environments.libvirt_environment import LibvirtEnvironment
from environments.virtual_fuel import VirtualFuel


class ExecutionEnvironment(object):

    def __new__(cls, storage_dir, pxe_bridge, dha_path, dea):

        with io.open(dha_path) as yaml_file:
            dha_struct = yaml.load(yaml_file)

        type = dha_struct['adapter']

        root_dir = os.path.dirname(os.path.realpath(__file__))

        if cls is ExecutionEnvironment:
            if type == 'libvirt':
                return LibvirtEnvironment(storage_dir, dha_path, dea, root_dir)

            if type in ['ipmi', 'hp', 'amt', 'zte']:
                return VirtualFuel(storage_dir, pxe_bridge, dha_path, root_dir)

        return super(ExecutionEnvironment, cls).__new__(cls)
