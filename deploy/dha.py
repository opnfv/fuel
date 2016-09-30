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

from dha_adapters.libvirt_adapter import LibvirtAdapter
from dha_adapters.ipmi_adapter import IpmiAdapter
from dha_adapters.hp_adapter import HpAdapter
from dha_adapters.amt_adapter import AmtAdapter
from dha_adapters.zte_adapter import ZteAdapter

class DeploymentHardwareAdapter(object):

    def __new__(cls, yaml_path):
        with io.open(yaml_path) as yaml_file:
            dha_struct = yaml.load(yaml_file)
        type = dha_struct['adapter']

        if cls is DeploymentHardwareAdapter:
            if type == 'libvirt':
                return LibvirtAdapter(yaml_path)
            if type == 'ipmi':
                return IpmiAdapter(yaml_path)
            if type == 'hp':
                return HpAdapter(yaml_path)
            if type == 'amt':
                return AmtAdapter(yaml_path)
            if type == 'zte':
                return ZteAdapter(yaml_path)
        return super(DeploymentHardwareAdapter, cls).__new__(cls)
