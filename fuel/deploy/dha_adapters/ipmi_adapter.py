import common
from hardware_adapter import HardwareAdapter

log = common.log
exec_cmd = common.exec_cmd

class IpmiAdapter(HardwareAdapter):

    def __init__(self, yaml_path):
        super(IpmiAdapter, self).__init__(yaml_path)

    def get_access_info(self, node_id):
        ip = self.get_node_property(node_id, 'ipmiIp')
        username = self.get_node_property(node_id, 'ipmiUser')
        password = self.get_node_property(node_id, 'ipmiPass')
        return ip, username, password

    def ipmi_cmd(self, node_id):
        ip, username, password = self.get_access_info(node_id)
        cmd = 'ipmitool -I lanplus -A password'
        cmd += ' -H %s -U %s -P %s' % (ip, username, password)
        return cmd

    def get_node_pxe_mac(self, node_id):
        mac_list = []
        mac_list.append(self.get_node_property(node_id, 'pxeMac').lower())
        return mac_list

    def node_power_on(self, node_id):
        log('Power ON Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is off':
            exec_cmd('%s chassis power on' % cmd_prefix)

    def node_power_off(self, node_id):
        log('Power OFF Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is on':
            exec_cmd('%s chassis power off' % cmd_prefix)

    def node_reset(self, node_id):
        log('Reset Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is on':
            exec_cmd('%s chassis power reset' % cmd_prefix)

    def node_set_boot_order(self, node_id, boot_order_list):
        log('Set boot order %s on Node %s' % (boot_order_list, node_id))
        cmd_prefix = self.ipmi_cmd(node_id)
        for dev in boot_order_list:
            if dev == 'pxe':
                exec_cmd('%s chassis bootdev pxe options=persistent'
                         % cmd_prefix)
            elif dev == 'iso':
                exec_cmd('%s chassis bootdev cdrom' % cmd_prefix)
            elif dev == 'disk':
                exec_cmd('%s chassis bootdev disk options=persistent'
                         % cmd_prefix)
