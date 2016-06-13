###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from ipmi_adapter import IpmiAdapter
from ssh_client import SSHClient

from common import (
    log,
)

DEV = {'pxe': 'bootsource4',
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
        with ssh as s:
            for order, dev in enumerate(boot_order_list):
                s.exec_cmd('set %s/%s bootorder=%s'
                           % (ROOT, DEV[dev], order + 1))
