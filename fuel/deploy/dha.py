import yaml
import io

from dha_adapters.libvirt_adapter import LibvirtAdapter
from dha_adapters.ipmi_adapter import IpmiAdapter
from dha_adapters.hp_adapter import HpAdapter

class DeploymentHardwareAdapter(object):
    def __new__(cls, yaml_path):
        with io.open(yaml_path) as yaml_file:
            dha_struct = yaml.load(yaml_file)
        type = dha_struct['adapter']

        if cls is DeploymentHardwareAdapter:
            if type == 'libvirt': return LibvirtAdapter(yaml_path)
            if type == 'ipmi': return IpmiAdapter(yaml_path)
            if type == 'hp': return HpAdapter(yaml_path)

        return super(DeploymentHardwareAdapter, cls).__new__(cls)
