###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# liyi.meng@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from hardware_adapter import HardwareAdapter

from common import (
    log,
    exec_cmd,
    err,
)


'''
This is hardware adapter for Intel AMT based system. It use amttool to interact
 with the targeting node. It dose not support vPro v9. if the targeting system
 is v9 or later, we need to consider a new adpater with using lib
 like https://github.com/sdague/amt
'''
class AmtAdapter(HardwareAdapter):

    def __init__(self, yaml_path):
        super(AmtAdapter, self).__init__(yaml_path)
        #amttool dose not allow you change bios setting permanently.
        # so we have to make a workaround to make it IPMI like.
        self.boot_order = {}

    def node_get_boot_dev(self, node_id):
        if node_id in self.boot_order:
            dev = self.boot_order[node_id][0]
            if dev == 'pxe':
                return 'PXE-boot'
            elif dev == 'iso':
                return 'cd-boot'
            elif dev == 'disk':
                return 'HD-boot'
        else:
            return 'HD-boot'

    def get_access_info(self, node_id):
        ip = self.get_node_property(node_id, 'amtIp')
        username = self.get_node_property(node_id, 'amtUser')
        password = self.get_node_property(node_id, 'amtPass')
        return ip, username, password

    def amt_cmd(self, node_id):
        ip, username, password = self.get_access_info(node_id)
        # We first Setup password for amttool, then use ping to wake up the node over LAN
        cmd = 'export AMT_PASSWORD={0};' \
              'ping {1} -W 5 -c 1 -q;' \
              'yes | amttool {1}'.format(password, ip)
        return cmd

    def get_node_pxe_mac(self, node_id):
        mac_list = []
        mac_list.append(self.get_node_property(node_id, 'pxeMac').lower())
        return mac_list

    def node_power_on(self, node_id):
        log('Power ON Node %s' % node_id)
        cmd_prefix = self.amt_cmd(node_id)
        resp, ret = exec_cmd('{0} info'.format(cmd_prefix), check=False)
        if 'Powerstate:   S0' not in resp:
            dev = self.node_get_boot_dev(node_id)
            resp, ret = exec_cmd('{0} powerup {1}'.format(cmd_prefix, dev), check=False)
            if 'pt_status: success' not in resp:
                err('Could Not Power ON Node %s' % node_id)

    def node_power_off(self, node_id):
        log('Power OFF Node %s' % node_id)
        cmd_prefix = self.amt_cmd(node_id)
        resp, ret = exec_cmd('{0} info'.format(cmd_prefix), check=False)
        if "Powerstate:   S0" in resp:
            resp, ret = exec_cmd('{0} powerdown'.format(cmd_prefix), check=False)
            if 'pt_status: success' not in resp:
                err('Could Not Power OFF Node %s' % node_id)

    def node_reset(self, node_id):
        log('RESET Node %s' % node_id)
        cmd_prefix = self.amt_cmd(node_id)
        dev = self.node_get_boot_dev(node_id)
        resp, ret = exec_cmd('{0} info'.format(cmd_prefix), check=False)
        if 'Powerstate:   S0' in resp:
            resp, ret = exec_cmd('{0} reset {1}'.format(cmd_prefix, dev), check=False)
            if 'pt_status: success' not in resp:
                err('Could Not RESET Node %s' % node_id)
        else:
            err('Cannot RESET Node %s because it\'s not Active, state: %s'
                % (node_id, resp))

    def node_set_boot_order(self, node_id, boot_order_list):
        log('Set boot order %s on Node %s' % (boot_order_list, node_id))
        self.boot_order[node_id] = boot_order_list

