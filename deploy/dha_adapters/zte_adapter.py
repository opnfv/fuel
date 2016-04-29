###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import time
from ipmi_adapter import IpmiAdapter

from common import (
    log,
    exec_cmd,
    err,
)


class ZteAdapter(IpmiAdapter):

    def __init__(self, yaml_path):
        super(ZteAdapter, self).__init__(yaml_path)

    def node_reset(self, node_id):
        WAIT_LOOP = 600
        log('RESET Node %s' % node_id)
        cmd_prefix = self.ipmi_cmd(node_id)
        state = exec_cmd('%s chassis power status' % cmd_prefix)
        if state == 'Chassis Power is on':
            was_shut_off = False
            done = False
            exec_cmd('%s chassis power cycle' % cmd_prefix)
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

