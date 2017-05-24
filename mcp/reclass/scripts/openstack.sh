#!/bin/bash
#
# Deploy Openstack
#

ssh -i mcp.rsa ubuntu@192.168.10.100 bash -s << OPENSTACK_INSTALL_END
  sudo -i

  salt '*' state.sls linux,ntp,rsyslog

  salt -C 'I@keepalived:cluster' state.sls keepalived -b 1

  salt -C 'I@rabbitmq:server' state.sls rabbitmq
  salt -C 'I@rabbitmq:server' cmd.run "rabbitmqctl cluster_status"

  salt -C 'I@glusterfs:server' state.sls glusterfs.server.service
  salt -C 'I@glusterfs:server' state.sls glusterfs.server.setup -b 1
  salt -C 'I@glusterfs:server' cmd.run "gluster peer status; gluster volume status" -b 1

  salt -C 'I@galera:master' state.sls galera
  salt -C 'I@galera:slave' state.sls galera
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

  salt -C 'I@keystone:server' cmd.run ". /root/keystonercv3; nova service-list"
  salt -C 'I@keystone:server' cmd.run ". /root/keystonercv3; neutron agent-list"
  salt -C 'I@keystone:server' cmd.run ". /root/keystonercv3; heat stack-list"
  salt -C 'I@keystone:server' cmd.run ". /root/keystonercv3; cinder list"
OPENSTACK_INSTALL_END
