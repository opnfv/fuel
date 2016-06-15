###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
#           (c) 2016 Enea Software AB
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

    def __init__(self, yaml_path, attempts=20, delay=3):
        super(IpmiAdapter, self).__init__(yaml_path)
        self.attempts = attempts
        self.delay = delay

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

    def node_get_state(self, node_id):
        state = exec_cmd('%s chassis power status' % self.ipmi_cmd(node_id),
                         attempts=self.attempts, delay=self.delay,
                         verbose=True)
        return state

    def _node_power_cmd(self, node_id, cmd):
        expected = 'Chassis Power is %s' % cmd
        if self.node_get_state(node_id) == expected:
            return

        pow_cmd = '%s chassis power %s' % (self.ipmi_cmd(node_id), cmd)
        exec_cmd(pow_cmd, attempts=self.attempts, delay=self.delay,
                 verbose=True)

        attempts = self.attempts
        while attempts:
            state = self.node_get_state(node_id)
            attempts -= 1
            if state == expected:
                return
            elif attempts != 0:
                # reinforce our will, but allow the command to fail,
                # we know our message got across once already...
                exec_cmd(pow_cmd, check=False)

        err('Could not set chassis %s for node %s' % (cmd, node_id))

    def node_power_on(self, node_id):
        log('Power ON Node %s' % node_id)
        self._node_power_cmd(node_id, 'on')

    def node_power_off(self, node_id):
        log('Power OFF Node %s' % node_id)
        self._node_power_cmd(node_id, 'off')

    def node_reset(self, node_id):
        log('RESET Node %s' % node_id)
        cmd = '%s chassis power reset' % self.ipmi_cmd(node_id)
        exec_cmd(cmd, attempts=self.attempts, delay=self.delay, verbose=True)

    def node_set_boot_order(self, node_id, boot_order_list):
        log('Set boot order %s on Node %s' % (boot_order_list, node_id))
        boot_order_list.reverse()
        cmd_prefix = self.ipmi_cmd(node_id)
        for dev in boot_order_list:
            if dev == 'pxe':
                exec_cmd('%s chassis bootdev pxe options=persistent'
                         % cmd_prefix, attempts=self.attempts, delay=self.delay,
                         verbose=True)
            elif dev == 'iso':
                exec_cmd('%s chassis bootdev cdrom' % cmd_prefix,
                         attempts=self.attempts, delay=self.delay, verbose=True)
            elif dev == 'disk':
                exec_cmd('%s chassis bootdev disk options=persistent'
                         % cmd_prefix, attempts=self.attempts, delay=self.delay,
                         verbose=True)
