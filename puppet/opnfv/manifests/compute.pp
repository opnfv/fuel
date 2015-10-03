class opnfv::compute {

  if $private_ip == '' { fail('private_ip is empty') }
  if $mysql_ip == '' { fail('mysql_ip is empty') }
  if $amqp_ip == '' { fail('mysql_ip is empty') }

  if $admin_password == '' { fail('admin_password is empty') }

  if $nova_user_password == '' { fail('nova_user_password is empty') }
  if $nova_db_password == '' { fail('nova_db_password is empty') }

  if $neutron_user_password == '' { fail('nova_user_password is empty') }
  if $neutron_db_password == '' { fail('nova_db_password is empty') }

  if $ceilometer_user_password == '' { fail('ceilometer_user_password is empty') }
  if $ceilometer_metering_secret == '' { fail('ceilometer_user_password is empty') }

  class { "quickstack::neutron::compute":
    auth_host                    => $private_ip,
    glance_host                  => $private_ip,
    libvirt_images_rbd_pool      => 'volumes',
    libvirt_images_rbd_ceph_conf => '/etc/ceph/ceph.conf',
    libvirt_inject_password      => 'false',
    libvirt_inject_key           => 'false',
    libvirt_images_type          => 'rbd',
    nova_host                    => $private_ip,
    nova_db_password              => $nova_db_password,
    nova_user_password            => $nova_user_password,
    private_network              => '',
    private_iface                => '',
    private_ip                   => '',
    rbd_user                     => 'volumes',
    rbd_secret_uuid              => '',
    network_device_mtu           => $quickstack::params::network_device_mtu,

    admin_password                => $admin_password,
    ssl                           => false,

    mysql_host                    => $mysql_ip,
    mysql_ca                     => $quickstack::params::mysql_ca,
    amqp_host                     => $amqp_ip,
    amqp_username                 => 'guest',
    amqp_password                 => 'guest',
    #amqp_nssdb_password           => $quickstack::params::amqp_nssdb_password,

    ceilometer                    => 'true',
    ceilometer_metering_secret    => $ceilometer_metering_secret,
    ceilometer_user_password      => $ceilometer_user_password,

    cinder_backend_gluster        => $quickstack::params::cinder_backend_gluster,

    agent_type                   => 'ovs',
    enable_tunneling             => true,

    neutron_db_password          => $neutron_db_password,
    neutron_user_password        => $neutron_user_password,
    neutron_host                 => $private_ip,

    #ovs_bridge_mappings          = $quickstack::params::ovs_bridge_mappings,
    #ovs_bridge_uplinks           = $quickstack::params::ovs_bridge_uplinks,
    #ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
    ovs_tunnel_iface             => 'em1',
    ovs_tunnel_network           => '',
    ovs_l2_population            => 'True',
    ml2_mechanism_drivers         => ['opendaylight'],
    odl_controller_ip             => '10.1.254.4',

    tenant_network_type          => 'vxlan',
    tunnel_id_ranges             => '1:1000',
    #ovs_vxlan_udp_port           = $quickstack::params::ovs_vxlan_udp_port,
    ovs_tunnel_types             => ['vxlan'],

    verbose                      => $quickstack::params::verbose,
    security_group_api           => 'neutron',

  }

}
