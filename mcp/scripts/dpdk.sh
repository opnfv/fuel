#!/bin/bash
#
# Enable DPDK on compute nodes
#

ssh ${SSH_OPTS} ubuntu@${SALT_MASTER} bash -s << DPDK_INSTALL_END
  sudo -i

  salt -C 'I@nova:compute' system.reboot
  salt -C 'I@nova:compute' test.ping

  salt -C 'I@nova:compute' state.sls linux
  salt -C 'I@nova:compute' state.sls nova,neutron

  salt -C 'I@keystone:server and *01*' cmd.run ". /root/keystonercv3; nova service-list; openstack network agent list"
DPDK_INSTALL_END
