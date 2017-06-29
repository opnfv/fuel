#!/bin/bash
#
# Deploy Salt Master
#

# ssh to cfg01
ssh ${SSH_OPTS} ubuntu@${SALT_MASTER} bash -s << SALT_INSTALL_END
  sudo -i

  echo -n 'Checking out cloud-init has finished running ...'
  while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo -n '.'; sleep 1; done
  echo ' done'

  apt-get install -y git curl subversion

  svn export --force https://github.com/salt-formulas/salt-formulas/trunk/deploy/scripts /srv/salt/scripts
  git clone --depth=1 --recurse-submodules https://git.opnfv.org/fuel
  ln -s /root/fuel/mcp/reclass /srv/salt/reclass

  cd /srv/salt/scripts
  MASTER_HOSTNAME=cfg01.${CLUSTER_DOMAIN} DISTRIB_REVISION=nightly ./salt-master-init.sh
  salt-key -Ay
SALT_INSTALL_END
