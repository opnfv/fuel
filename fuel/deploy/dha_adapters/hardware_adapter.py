import yaml
import io

class HardwareAdapter(object):
    def __init__(self, yaml_path):
        self.dha_struct = None
        self.parse_yaml(yaml_path)

    def parse_yaml(self, yaml_path):
        with io.open(yaml_path) as yaml_file:
            self.dha_struct = yaml.load(yaml_file)

    def get_adapter_type(self):
        return self.dha_struct['adapter']

    def get_all_node_ids(self):
        node_ids = []
        for node in self.dha_struct['nodes']:
            node_ids.append(node['id'])
        node_ids.sort()
        return node_ids

    def get_fuel_node_id(self):
        for node in self.dha_struct['nodes']:
            if 'isFuel' in node and node['isFuel']:
                return node['id']

    def get_node_ids(self):
        node_ids = []
        fuel_node_id = self.get_fuel_node_id()
        for node in self.dha_struct['nodes']:
            if node['id'] != fuel_node_id:
                node_ids.append(node['id'])
        node_ids.sort()
        return node_ids

    def use_fuel_custom_install(self):
        return self.dha_struct['fuelCustomInstall']

    def get_node_property(self, node_id, property_name):
        for node in self.dha_struct['nodes']:
            if node['id'] == node_id and property_name in node:
                return node[property_name]

    def node_can_zero_mbr(self, node_id):
        return self.get_node_property(node_id, 'nodeCanZeroMBR')

    def get_fuel_access(self):
        for node in self.dha_struct['nodes']:
            if 'isFuel' in node and node['isFuel']:
                return node['username'], node['password']
