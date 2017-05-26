#!/bin/bash
#
# Deploy Salt Master
#

# ssh to cfg01
ssh -i mcp.rsa ubuntu@192.168.10.100 bash -s << SALT_INSTALL_END
  sudo -i

  apt-get update
  apt-get install -y git curl subversion

  svn export --force https://github.com/salt-formulas/salt-formulas/trunk/deploy/scripts /srv/salt/scripts
  git clone --depth=1 --recurse-submodules https://git.opnfv.org/fuel
  ln -s $(pwd)/fuel/mcp/reclass /srv/salt/reclass

  cd /srv/salt/scripts
  MASTER_HOSTNAME=cfg01.virtual-mcp-ocata-ovs.local ./salt-master-init.sh
  salt-key -Ay
SALT_INSTALL_END
