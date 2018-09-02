#!/bin/bash -e
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

mkdir -p /etc/salt/{master.d,minion.d,proxy.d}

if [ ! -z "$SALT_EXT_PILLAR" ]; then
    cp -avr "/tmp/${SALT_EXT_PILLAR}.conf" /etc/salt/master.d/
fi

if [ ! -f /home/ubuntu/.ssh/authorized_keys ]; then
    install -D -o ubuntu /root/fuel/mcp/scripts/mcp.rsa.pub \
                         /home/ubuntu/.ssh/authorized_keys
fi

if ! grep -q localhost /etc/hosts; then
    # overwrite hosts only on first container up, to preserve cluster nodes
    cp -a /root/fuel/mcp/scripts/docker-compose/files/hosts /etc/hosts
fi

# salt state does not properly configure file_roots in master.conf, hard set it
cp -a /root/fuel/mcp/scripts/docker-compose/files/opnfv_master.conf \
      /etc/salt/master.d/opnfv_master.conf
echo 'master: localhost' > /etc/salt/minion.d/opnfv_slave.conf

source /root/fuel/mcp/scripts/xdf_data.sh
cp -a "/root/fuel/mcp/reclass/nodes/cfg01.${CLUSTER_DOMAIN}.yml" /srv/salt/reclass/nodes/

# Tini init system resembles upstart very much, but needs a little adjustment
sed -i -e "s|return 'start/running' in |return 'is running' in |" \
       -e "s|ret = _default_runlevel|return _default_runlevel|" \
    /usr/lib/python2.7/dist-packages/salt/modules/upstart.py

# Workaround for: https://github.com/salt-formulas/reclass/issues/77
sed -i -e 's|\(ignore_overwritten_missing_references\)defaults.|\1|' \
    /usr/local/lib/python2.7/dist-packages/reclass/settings.py
service ssh start
service salt-minion start

if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
    exec /usr/bin/salt-master --log-file-level=quiet --log-level=info "$@"
else
    exec "$@"
fi
