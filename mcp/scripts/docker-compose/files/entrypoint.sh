#!/bin/bash -e
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Preseed salt master & minion configuration
mkdir -p /etc/salt/{master.d,minion.d,proxy.d}
if [ -n "$SALT_EXT_PILLAR" ]; then
    cp -a "/tmp/${SALT_EXT_PILLAR}.conf" /etc/salt/master.d/
    # salt state does not properly configure file_roots in master.conf
    cp -a /root/fuel/mcp/scripts/docker-compose/files/opnfv_master.conf \
          /etc/salt/master.d/opnfv_master.conf
    echo 'master: localhost' > /etc/salt/minion.d/opnfv_slave.conf
fi

# set up keypair based SSH access for ubuntu user
if [ ! -f /home/ubuntu/.ssh/authorized_keys ]; then
    install -D -o ubuntu /root/fuel/mcp/scripts/mcp.rsa.pub \
                         /home/ubuntu/.ssh/authorized_keys
fi

# overwrite hosts only on first container up, to preserve cluster nodes
if ! grep -q localhost /etc/hosts; then
    cp -a /root/fuel/mcp/scripts/docker-compose/files/hosts /etc/hosts
fi

# Only copy the reclass node for the current scenario
cp -a "/root/fuel/mcp/reclass/nodes/cfg01.${CLUSTER_DOMAIN}.yml" \
      /srv/salt/reclass/nodes
# Sensitive data should stay out of /root/fuel, which is exposed via Jenkins WS
cp -a /root/pod_config.yml \
      /srv/salt/reclass/classes/cluster/all-mcp-arch-common/opnfv/pod_config.yml

service ssh start
service salt-minion start

if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
    exec /usr/bin/salt-master --log-file-level=quiet --log-level=info "$@"
else
    exec "$@"
fi
