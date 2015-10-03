import yaml
import io
import netaddr

class DeploymentEnvironmentAdapter(object):
    def __init__(self, yaml_path):
        self.dea_struct = None
        self.parse_yaml(yaml_path)
        self.network_names = []
        self.collect_network_names()

    def modify_ip(self, ip_addr, index, val):
        ip_str = str(netaddr.IPAddress(ip_addr))
        decimal_list = map(int, ip_str.split('.'))
        decimal_list[index] = val
        return '.'.join(map(str, decimal_list))

    def parse_yaml(self, yaml_path):
        with io.open(yaml_path) as yaml_file:
            self.dea_struct = yaml.load(yaml_file)

    def get_fuel_config(self):
        return self.dea_struct['fuel']

    def get_fuel_ip(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['ADMIN_NETWORK']['ipaddress']

    def get_fuel_netmask(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['ADMIN_NETWORK']['netmask']

    def get_fuel_gateway(self):
        ip = self.get_fuel_ip()
        return self.modify_ip(ip, 3, 1)

    def get_fuel_hostname(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['HOSTNAME']

    def get_fuel_dns(self):
        fuel_conf = self.get_fuel_config()
        return fuel_conf['DNS_UPSTREAM']

    def get_node_property(self, node_id, property_name):
        for node in self.dea_struct['nodes']:
            if node['id'] == node_id and property_name in node:
                return node[property_name]

    def get_node_role(self, node_id):
        return self.get_node_property(node_id, 'role')

    def get_node_ids(self):
        node_ids = []
        for node in self.dea_struct['nodes']:
            node_ids.append(node['id'])
        return node_ids

    def get_property(self, property_name):
        return self.dea_struct[property_name]

    def collect_network_names(self):
        self.network_names = []
        for network in self.dea_struct['network']['networks']:
            self.network_names.append(network['name'])

    def get_network_names(self):
        return self.network_names

    def get_interfaces(self, type):
        return self.dea_struct['interfaces'][type]

    def get_transformations(self, type):
        return self.dea_struct['transformations'][type]

    def get_opnfv(self, role):
        return {'opnfv': self.dea_struct['opnfv'][role]}

    def get_wanted_release(self):
        return self.dea_struct['wanted_release']