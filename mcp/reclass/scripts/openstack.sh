#!/bin/bash
#
# Deploy Openstack
#

ssh $SSH_OPTS ubuntu@$SALT_MASTER bash -s << OPENSTACK_INSTALL_END
  sudo -i

  salt-call state.apply salt
  salt '*' state.apply salt || salt '*' state.apply salt

  salt -C 'I@salt:master' state.sls linux
  salt -C '* and not cfg01*' state.sls linux

  salt '*' state.sls ntp

  salt -C 'I@keepalived:cluster' state.sls keepalived -b 1

  salt -C 'I@rabbitmq:server' state.sls rabbitmq
  salt -C 'I@rabbitmq:server' cmd.run "rabbitmqctl cluster_status"

  salt -C 'I@galera:master' state.sls galera
  salt -C 'I@galera:master' mysql.status | grep -A1 wsrep_cluster_size

  salt -C 'I@haproxy:proxy' state.sls haproxy
  salt -C 'I@memcached:server' state.sls memcached

  salt -C 'I@keystone:server' state.sls keystone.server -b 1
  salt -C 'I@keystone:server' cmd.run "service apache2 restart"
  salt -C 'I@keystone:client' state.sls keystone.client
  salt -C 'I@keystone:server' cmd.run ". /root/keystonercv3; openstack user list"

  salt -C 'I@glance:server' state.sls glance -b 1
  salt -C 'I@nova:controller' state.sls nova -b 1
  salt -C 'I@heat:server' state.sls heat -b 1
  salt -C 'I@cinder:controller' state.sls cinder -b 1

  salt -C 'I@neutron:server' state.sls neutron -b 1
  salt -C 'I@neutron:gateway' state.sls neutron

  salt -C 'I@nova:compute' state.sls nova
  salt -C 'I@neutron:compute' state.sls neutron

  salt 'ctl01*' cmd.run ". /root/keystonercv3; openstack compute service list; openstack network agent list; openstack stack list; openstack volume list"

  salt 'ctl01*' cmd.run ". /root/keystonercv3; openstack network create --share --external --provider-network-type flat --provider-physical-network physnet1 floating_net"
  salt 'ctl01*' cmd.run ". /root/keystonercv3; openstack subnet create --gateway 10.16.0.1 --no-dhcp --allocation-pool start=10.16.0.130,end=10.16.0.254 --network floating_net --subnet-range 10.16.0.0/24 floating_subnet"
OPENSTACK_INSTALL_END
