#!/bin/bash -e
##############################################################################
# Copyright (c) 2019 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
if [ ! -e /var/lib/postgresql/*/main ]; then
    cp -ar /var/lib/opnfv/{postgresql,maas} /var/lib/
    cp -ar /var/lib/opnfv/etc/{ssh,maas} /etc/
fi
# FIXME: slae conf?
#echo 'master: localhost' > /etc/salt/minion.d/opnfv_slave.conf

# Configure mass-region-controller if not already done previously
[ ! -e /var/lib/maas/secret ] || exit 0
MAAS_FIXUP_SERVICE="/etc/systemd/system/maas-fixup.service"
cat <<-EOF | tee "${MAAS_FIXUP_SERVICE}"
[Unit]
After=postgresql.service
[Service]
ExecStart=/bin/sh -ec '\
  echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections && \
  /var/lib/dpkg/info/maas-region-controller.config configure && \
  /var/lib/dpkg/info/maas-region-controller.postinst configure'
EOF
ln -sf "${MAAS_FIXUP_SERVICE}" "/etc/systemd/system/multi-user.target.wants/"
rm "/usr/sbin/policy-rc.d"
