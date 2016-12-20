###############################################################################
# Copyright (c) 2016 Ericsson AB, ZTE and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from ipmi_adapter import IpmiAdapter

from common import (
    log,
    exec_cmd,
)


class ZteAdapter(IpmiAdapter):

    def __init__(self, yaml_path, attempts=100):
        super(ZteAdapter, self).__init__(yaml_path, attempts)

    def node_reset(self, node_id):
        log('RESET Node %s' % node_id)
        cmd = '%s chassis power cycle' % self.ipmi_cmd(node_id)
        exec_cmd(cmd, attempts=self.attempts, delay=self.delay,
                 verbose=True,
                 mask_args=[8,10])

