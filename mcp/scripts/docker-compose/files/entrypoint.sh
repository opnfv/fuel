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

# NOTE: Most Salt and/or reclass tools have issues traversing Docker mounts
# or detecting them as directories inside the container.
rm -rf /srv/salt/reclass/classes/cluster
cp -ar /root/fuel/mcp/reclass/classes/cluster /srv/salt/reclass/classes
cp -ar /root/fuel/mcp/reclass/nodes/* /srv/salt/reclass/nodes
# Sensitive data should stay out of /root/fuel, which is exposed via Jenkins WS
cp -a /root/pod_config.yml \
      /srv/salt/reclass/classes/cluster/all-mcp-arch-common/opnfv/pod_config.yml

# Create links for salt-formula-* packages to mimic git-style salt-formulas
for artifact in /usr/share/salt-formulas/env/_*/*; do
    ln -sf "${artifact}" "/srv/salt/env/prd/${artifact#/usr/share/salt-formulas/env/}"
done
for artifact in /usr/share/salt-formulas/env/*; do
    if [[ ! ${artifact} =~ ^_ ]]; then
        ln -sf "${artifact}" "/srv/salt/env/prd/$(basename ${artifact})"
    fi
done
for formula in /usr/share/salt-formulas/reclass/service/*; do
    ln -sf "${formula}" "/srv/salt/reclass/classes/service/$(basename ${formula})"
done

# Tini init system resembles upstart very much, but needs a little adjustment
sed -i -e "s|return 'start/running' in |return 'is running' in |" \
       -e "s|ret = _default_runlevel|return _default_runlevel|" \
    /usr/lib/python2.7/dist-packages/salt/modules/upstart.py

# Remove broken symlinks in /srv/salt, silences recurring warnings
find -L /srv/salt /srv/salt/env/prd/_* -maxdepth 1 -type l -delete

# Fix up any permissions after above file shuffling
sudo chown root:root -R /srv/salt

service ssh start
service salt-minion start

if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
    exec /usr/bin/salt-master --log-file-level=quiet --log-level=info "$@"
else
    exec "$@"
fi
