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
    mkdir -p /root/.ssh/
    echo 'User ubuntu' > /root/.ssh/config
    echo 'IdentityFile /root/fuel/mcp/scripts/mcp.rsa' >> /root/.ssh/config
fi

# salt state does not properly configure file_roots in master.conf, hard set it
cp -a /root/fuel/mcp/scripts/docker-compose/files/opnfv_master.conf \
      /etc/salt/master.d/opnfv_master.conf
echo -e 'master: localhost\nmine_interval: 15' > /etc/salt/minion.d/opnfv_slave.conf

# NOTE: Most Salt and/or reclass tools have issues traversing Docker mounts
# or detecting them as directories inside the container.
# For now, let's do a lot of copy operations to bypass this.
# Later, we will inject the OPNFV patched reclass model during image build.
rm -rf /srv/salt/reclass/classes/*
cp -ar /root/fuel/mcp/reclass/classes/* /srv/salt/reclass/classes
cp -ar /root/fuel/mcp/reclass/nodes/* /srv/salt/reclass/nodes
# Sensitive data should stay out of /root/fuel, which is exposed via Jenkins WS
cp -a /root/pod_config.yml \
      /srv/salt/reclass/classes/cluster/all-mcp-arch-common/opnfv/pod_config.yml

# OPNFV formulas
prefix=/srv/salt/formula/salt-formulas
rm -f /root/fuel/mcp/salt-formulas/*/.git
cp -ar /root/fuel/mcp/salt-formulas/* ${prefix}/
for formula in 'armband' 'opendaylight' 'tacker' 'quagga'; do
    ln -sf /root/fuel/mcp/salt-formulas/salt-formula-${formula}/* \
           /srv/salt/env/prd/
done

# Re-create classes.service links that we destroyed above
for formula in ${prefix}/*; do
    if [ -e "${formula}/metadata/service" ] && [[ ! $formula =~ \. ]]; then
        ln -sf "${formula}/metadata/service" \
               "/srv/salt/reclass/classes/service/${formula#${prefix}/salt-formula-}"
    fi
done

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

# Temporary link rocky configs to stein
for f in /srv/salt/env/prd/*/files/rocky; do
    if [ ! -d "$f/../stein" ]; then
        ln -sf "$f" "$f/../stein"
    fi
done

# Tini init system resembles upstart very much, but needs a little adjustment
sed -i -e "s|return 'start/running' in |return 'is running' in |" \
       -e "s|ret = _default_runlevel|return _default_runlevel|" \
    /usr/lib/python2.7/dist-packages/salt/modules/upstart.py

# Workaround for: https://github.com/salt-formulas/reclass/issues/77
sed -i -e 's|\(ignore_overwritten_missing_references\)defaults.|\1|' \
    /usr/local/lib/python2.7/dist-packages/reclass/settings.py

# Remove broken symlinks in /srv/salt, silences recurring warnings
find -L /srv/salt /srv/salt/env/prd/_* -maxdepth 1 -type l -delete

# Fix up any permissions after above file shuffling
chown root:root -R /srv/salt

# Docker-ce 19.x+ workaround for broken domainname setup
# shellcheck source=/dev/null
source /root/fuel/mcp/scripts/xdf_data.sh
hostname -b "cfg01.${CLUSTER_DOMAIN}"

service ssh start
service salt-minion start

if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
    exec /usr/bin/salt-master --log-file-level=quiet --log-level=info "$@"
else
    exec "$@"
fi
