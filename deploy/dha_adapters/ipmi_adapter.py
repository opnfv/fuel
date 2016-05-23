###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import time
from hardware_adapter import HardwareAdapter

from common import (
    log,
    exec_cmd,
    err,
)


class IpmiAdapter(HardwareAdapter):

    def __init__(self, yaml_path):
        super(IpmiAdapter, self).__init__(yaml_path)

    def get_access_info(self, node_id):
        ip = self.get_node_property(node_id, 'ipmiIp')
        username = self.get_node_property(node_id, 'ipmiUser')
        password = self.get_node_property(node_id, 'ipmiPass')
        ipmiport = self.get_node_property(node_id, 'ipmiPort')
        return ip, username, password, ipmiport

    def ipmi_cmd(self, node_id):
        ip, username, password, ipmiport = self.get_access_info(node_id)
        cmd = 'ipmitool -I lanplus -A password'
        cmd += ' -H %s -U %s -P %s' % (ip, username, password)
        if ipmiport:
            cmd += ' -p %d' % int(ipmiport)
        return cmd

    def get_node_pxe_mac(self, node_id):
        mac_list = []
        mac_list.append(self.get_node_property(node_id, 'pxeMac').lower())
        return mac_list

    def node_power_on(self, node_id):
        WAIT_LOOP = 200
        SLEEP_TIME = 3
        log('Power ON Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is off':
            exec_cmd('%s chassis power on' % cmd_prefix)
            done = False
            for i in range(WAIT_LOOP):
                state, _ = exec_cmd('%s chassis power status' % cmd_prefix,
                                    False)
                if state == 'Chassis Power is on':
                    done = True
                    break
                else:
                    time.sleep(SLEEP_TIME)
            if not done:
                err('Could Not Power ON Node %s' % node_id)

    def node_power_off(self, node_id):
        WAIT_LOOP = 200
        SLEEP_TIME = 3
        log('Power OFF Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is on':
            done = False
            exec_cmd('%s chassis power off' % cmd_prefix)
            for i in range(WAIT_LOOP):
                state, _ = exec_cmd('%s chassis power status' % cmd_prefix,
                                    False)
                if state == 'Chassis Power is off':
                    done = True
                    break
                else:
                    time.sleep(SLEEP_TIME)
            if not done:
                err('Could Not Power OFF Node %s' % node_id)

    def node_reset(self, node_id):
        WAIT_LOOP = 600
        log('RESET Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is on':
            was_shut_off = False
            done = False
            exec_cmd('%s chassis power reset' % cmd_prefix)
            for i in range(WAIT_LOOP):
                state, _ = exec_cmd('%s chassis power status' % cmd_prefix,
                                    False)
                if state == 'Chassis Power is off':
                    was_shut_off = True
                elif state == 'Chassis Power is on' and was_shut_off:
                    done = True
                    break
                time.sleep(1)
            if not done:
                err('Could Not RESET Node %s' % node_id)
        else:
            err('Cannot RESET Node %s because it\'s not Active, state: %s'
                % (node_id, state))

    def node_set_boot_order(self, node_id, boot_order_list):
        log('Set boot order %s on Node %s' % (boot_order_list, node_id))
        boot_order_list.reverse()
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
