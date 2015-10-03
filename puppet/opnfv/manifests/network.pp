class opnfv::network {

  if $private_ip == '' { fail('private_ip is empty') }
  if $mysql_ip == '' { fail('mysql_ip is empty') }
  if $amqp_ip == '' { fail('amqp_ip is empty') }
  if $opendaylight_ip == '' { fail('opendaylight_ip is empty') }
   

  if $nova_user_password == '' { fail('nova_user_password is empty') }
  if $nova_db_password == '' { fail('nova_db_password is empty') }

  if $neutron_user_password == '' { fail('neutron_user_password is empty') }
  if $neutron_db_password == '' { fail('neutron_db_password is empty') }
  if $neutron_metadata_shared_secret == '' { fail('neutron_metadata_shared_secret is empty') }

  class { "opendaylight":
        features => ['odl-base-all','odl-aaa-authn','odl-restconf',
                     'odl-nsf-all','odl-adsal-northbound','odl-mdsal-apidocs',
                     'odl-ovsdb-openstack','odl-ovsdb-northbound','odl-dlux-core'],
  }


  class { "quickstack::neutron::networker":
    require                       => Class['opendaylight'],
    neutron_metadata_proxy_secret => $neutron_metadata_shared_secret,
    neutron_db_password           => $neutron_db_password,
    neutron_user_password         => $neutron_user_password,
    nova_db_password              => $nova_db_password,
    nova_user_password            => $nova_user_password,

    controller_priv_host          => $private_ip,

    agent_type                    => 'ovs',
    enable_tunneling              => true,
    ovs_tunnel_iface              => 'em1',
    ovs_tunnel_network            => '',
    ovs_l2_population             => 'True',
    ovs_tunnel_types              => ['vxlan'],
    external_network_bridge       => 'br-ex',
    tenant_network_type           => 'vxlan',
    tunnel_id_ranges              => '1:1000',
    ml2_mechanism_drivers         => ['opendaylight'],
    odl_controller_ip             => $opendaylight_ip,

    mysql_host                    => $mysql_ip,
    amqp_host                     => $amqp_ip,
    amqp_username                 => 'guest',
    amqp_password                 => 'guest',
  }
}
