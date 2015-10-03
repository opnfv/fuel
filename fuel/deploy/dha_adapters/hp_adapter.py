import common
from ipmi_adapter import IpmiAdapter
from ssh_client import SSHClient

log = common.log

DEV = {'pxe': 'bootsource5',
       'disk': 'bootsource3',
       'iso': 'bootsource1'}

ROOT = '/system1/bootconfig1'

class HpAdapter(IpmiAdapter):

    def __init__(self, yaml_path):
        super(HpAdapter, self).__init__(yaml_path)

    def node_set_boot_order(self, node_id, boot_order_list):
        log('Set boot order %s on Node %s' % (boot_order_list, node_id))
        ip, username, password = self.get_access_info(node_id)
        ssh = SSHClient(ip, username, password)
        for order, dev in enumerate(boot_order_list):
            with ssh as s:
                s.exec_cmd('set %s/%s bootorder=%s'
                           % (ROOT, DEV[dev], order+1))
