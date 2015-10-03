#Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#Provides a manifest to configure OpenStack compute node in HA or non-HA
#environment, with Ceph configured as Cinder backend storage.
#ha_flag set to true will use virtual IP addresses (VIPs provided by
#global params) as the provider to the compute node for HA

class opnfv::compute {
  if ($odl_flag != '') and str2bool($odl_flag) {
     $ml2_mech_drivers = ['opendaylight']
     $this_agent = 'opendaylight'
  }
  else {
    $ml2_mech_drivers = ['openvswitch','l2population']
    $this_agent = 'ovs'
  }

  ##Common Parameters
  if !$rbd_secret_uuid { $rbd_secret_uuid = '3b519746-4021-4f72-957e-5b9d991723be' }
  if !$private_subnet { fail('private_subnet is empty')}
  if !$ceph_public_network { $ceph_public_network = $private_subnet }
  if !$ceph_fsid { $ceph_fsid = '904c8491-5c16-4dae-9cc3-6ce633a7f4cc' }
  if !$ceph_images_key { $ceph_images_key = 'AQAfHBdUKLnUFxAAtO7WPKQZ8QfEoGqH0CLd7A==' }
  if !$ceph_osd_journal_size { $ceph_osd_journal_size = '1000' }
  if !$ceph_osd_pool_size { $ceph_osd_pool_size = '1' }
  if !$ceph_volumes_key { $ceph_volumes_key = 'AQAfHBdUsFPTHhAAfqVqPq31FFCvyyO7oaOQXw==' }


  ##Most users will only care about a single user/password for all services
  ##so lets create one variable that can be used instead of separate usernames/passwords
  if !$single_username { $single_username = 'octopus' }
  if !$single_password { $single_password = 'octopus' }

  if !$admin_password { $admin_password = $single_password }
  if !$neutron_db_password  { $neutron_db_password = $single_password }
  if !$neutron_user_password  { $neutron_user_password = $single_password }

  if !$ceilometer_user_password { $ceilometer_user_password = $single_password }
  if !$ceilometer_metering_secret { $ceilometer_metering_secret = $single_password }

  ##HA Global params
  if $ha_flag {
     if $private_network == '' { fail('private_network is empty') }
     if !$keystone_private_vip { fail('keystone_private_vip is empty') }
     if !$glance_private_vip { fail('glance_private_vip is empty') }
     if !$nova_private_vip { fail('nova_private_vip is empty') }
     if !$nova_db_password { $nova_db_password = $single_password }
     if !$nova_user_password { $nova_user_password = $single_password }
     if !$controllers_ip_array { fail('controllers_ip_array is empty') }
     if !$controllers_hostnames_array { fail('controllers_hostnames_array is empty') }
     $controllers_ip_array = split($controllers_ip_array, ',')
     $controllers_hostnames_array = split($controllers_hostnames_array, ',')
     if !$odl_control_ip  { $odl_control_ip =  $controllers_ip_array[0] }
     if !$db_vip { fail('db_vip is empty') }
     $mysql_ip = $db_vip
     if !$amqp_vip { fail('amqp_vip is empty') }
     $amqp_ip = $amqp_vip
     if !$amqp_username { $amqp_username = $single_username }
     if !$amqp_password { $amqp_password = $single_password }
     if !$ceph_mon_initial_members { $ceph_mon_initial_members = $controllers_hostnames_array }
     if !$ceph_mon_host { $ceph_mon_host = $controllers_ip_array }
     if !$neutron_private_vip { fail('neutron_private_vip is empty') }

    ##Find private interface
    $ovs_tunnel_if = get_nic_from_network("$private_network")

  } else {
  ##non HA params
     if $ovs_tunnel_if == '' { fail('ovs_tunnel_if is empty') }
     if !$private_ip { fail('private_ip is empty') }
     $keystone_private_vip = $private_ip
     $glance_private_vip   = $private_ip
     $nova_private_vip     = $private_ip
     $neutron_private_vip  = $private_ip
     if !$nova_db_password { fail('nova_db_password is empty') }
     if !$nova_user_password { fail('nova_user_password is empty') }
     if !$odl_control_ip { $odl_control_ip = $private_ip }
     if !$mysql_ip { $mysql_ip = $private_ip }
     if !$amqp_ip { $amqp_ip = $private_ip }
     if !$amqp_username { $amqp_username = 'guest' }
     if !$amqp_password { $amqp_password = 'guest' }
     if !$ceph_mon_host { $ceph_mon_host= ["$private_ip"] }
     if !$ceph_mon_initial_members { $ceph_mon_initial_members = ["$::hostname"] }
  }

  class { "quickstack::neutron::compute":
    auth_host                    => $keystone_private_vip,
    glance_host                  => $glance_private_vip,
    libvirt_images_rbd_pool      => 'volumes',
    libvirt_images_rbd_ceph_conf => '/etc/ceph/ceph.conf',
    libvirt_inject_password      => 'false',
    libvirt_inject_key           => 'false',
    libvirt_images_type          => 'rbd',
    nova_host                    => $nova_private_vip,
    nova_db_password             => $nova_db_password,
    nova_user_password           => $nova_user_password,
    private_network              => '',
    private_iface                => $ovs_tunnel_if,
    private_ip                   => '',
    rbd_user                     => 'volumes',
    rbd_secret_uuid              => $rbd_secret_uuid,
    network_device_mtu           => $quickstack::params::network_device_mtu,

    admin_password               => $admin_password,
    ssl                          => false,

    mysql_host                   => $mysql_ip,
    mysql_ca                     =>  '/etc/ipa/ca.crt',
    amqp_host                    => $amqp_ip,
    amqp_username                => $amqp_username,
    amqp_password                => $amqp_password,

    ceilometer                   => 'false',
    ceilometer_metering_secret   => $ceilometer_metering_secret,
    ceilometer_user_password     => $ceilometer_user_password,

    cinder_backend_gluster       => $quickstack::params::cinder_backend_gluster,
    cinder_backend_rbd           => 'true',
    glance_backend_rbd           => 'true',
    ceph_cluster_network         => $ceph_public_network,
    ceph_fsid                    => $ceph_fsid,
    ceph_images_key              => $ceph_images_key,
    ceph_mon_host                => $ceph_mon_host,
    ceph_mon_initial_members     => $ceph_mon_initial_members,
    ceph_osd_pool_default_size   => $ceph_osd_pool_size,
    ceph_osd_journal_size        => $ceph_osd_journal_size,
    ceph_volumes_key             => $ceph_volumes_key,

    agent_type                   => $this_agent,
    enable_tunneling             => true,

    ml2_mechanism_drivers        => $ml2_mech_drivers,
    odl_controller_ip            => $odl_control_ip,

    neutron_db_password          => $neutron_db_password,
    neutron_user_password        => $neutron_user_password,
    neutron_host                 => $neutron_private_vip,

    ovs_tunnel_iface             => $ovs_tunnel_if,
    ovs_tunnel_network           => '',
    ovs_l2_population            => 'false',

    tenant_network_type          => 'vxlan',
    tunnel_id_ranges             => '1:1000',
    ovs_tunnel_types             => ['vxlan'],

    verbose                      => 'true',
    security_group_api           => 'neutron',

  }
}
