class opnfv::controller {

  if $admin_email == '' { fail('admin_email is empty') }
  if $admin_password == '' { fail('admin_password is empty') }

  if $public_ip == '' { fail('public_ip is empty') }
  if $private_ip == '' { fail('private_ip is empty') }

  if $mysql_ip == '' { fail('mysql_ip is empty') }
  if $mysql_root_password == '' { fail('mysql_root_password is empty') }
  if $amqp_ip == '' { fail('mysql_ip is empty') }

  if $memcache_ip == '' { fail('memcache_ip is empty') }
  if $neutron_ip == '' { fail('neutron_ip is empty') }

  if $keystone_admin_token == '' { fail('keystone_admin_token is empty') }
  if $keystone_db_password == '' { fail('keystone_db_password is empty') }

  if $horizon_secret_key == '' { fail('horizon_secret_key is empty') }

  if $nova_user_password == '' { fail('nova_user_password is empty') }
  if $nova_db_password == '' { fail('nova_db_password is empty') }

  if $cinder_user_password == '' { fail('cinder_user_password is empty') }
  if $cinder_db_password == '' { fail('cinder_db_password is empty') }

  if $glance_user_password == '' { fail('glance_user_password is empty') }
  if $glance_db_password == '' { fail('glance_db_password is empty') }

  if $neutron_user_password == '' { fail('neutron_user_password is empty') }
  if $neutron_db_password == '' { fail('neutron_db_password is empty') }
  if $neutron_metadata_shared_secret == '' { fail('neutron_metadata_shared_secret is empty') }

  if $ceilometer_user_password == '' { fail('ceilometer_user_password is empty') }
  if $ceilometer_metering_secret == '' { fail('ceilometer_user_password is empty') }

  if $heat_user_password == '' { fail('heat_user_password is empty') }
  if $heat_db_password == '' { fail('heat_db_password is empty') }
  if $heat_auth_encrypt_key == '' { fail('heat_auth_encrypt_key is empty') }

  if $swift_user_password == '' { fail('swift_user_password is empty') }
  if $swift_shared_secret == '' { fail('swift_shared_secret is empty') }
  if $swift_admin_password == '' { fail('swift_admin_password is empty') }

  class { "quickstack::neutron::controller":
    admin_email                   => $admin_email,
    admin_password                => $admin_password,
    controller_admin_host         => $private_ip,
    controller_priv_host          => $private_ip,
    controller_pub_host           => $public_ip,
    ssl                           => false,
    #support_profile               => $quickstack::params::support_profile,
    #freeipa                       => $quickstack::params::freeipa,

    mysql_host                    => $mysql_ip,
    mysql_root_password           => $mysql_root_password,
    #amqp_provider                 => $amqp_provider,
    amqp_host                     => $amqp_ip,
    amqp_username                 => 'guest',
    amqp_password                 => 'guest',
    #amqp_nssdb_password           => $quickstack::params::amqp_nssdb_password,

    keystone_admin_token          => $keystone_admin_token,
    keystone_db_password          => $keystone_db_password,

    ceilometer_metering_secret    => $ceilometer_metering_secret,
    ceilometer_user_password      => $ceilometer_user_password,

    cinder_backend_gluster        => $quickstack::params::cinder_backend_gluster,
    cinder_backend_gluster_name   => $quickstack::params::cinder_backend_gluster_name,
    cinder_gluster_shares         => $quickstack::params::cinder_gluster_shares,
    cinder_user_password          => $cinder_user_password,
    cinder_db_password            => $cinder_db_password,

    glance_db_password            => $glance_db_password,
    glance_user_password          => $glance_user_password,

    heat_cfn                      => true,
    heat_cloudwatch               => true,
    heat_db_password              => $heat_db_password,
    heat_user_password            => $heat_user_password,
    heat_auth_encrypt_key         => $heat_auth_encrypt_key,

    horizon_secret_key            => $horizon_secret_key,
    horizon_ca                    => $quickstack::params::horizon_ca,
    horizon_cert                  => $quickstack::params::horizon_cert,
    horizon_key                   => $quickstack::params::horizon_key,

    #neutron                       => true,
    neutron_metadata_proxy_secret => $neutron_metadata_shared_secret,
    neutron_db_password           => $neutron_db_password,
    neutron_user_password         => $neutron_user_password,
    ml2_mechanism_drivers         => ['opendaylight'],
    odl_controller_ip             => '10.1.254.4',

    nova_db_password              => $nova_db_password,
    nova_user_password            => $nova_user_password,

    swift_shared_secret           => $swift_shared_secret,
    swift_admin_password          => $swift_admin_password,
    swift_ringserver_ip           => '192.168.203.1',
    swift_storage_ips             => ["192.168.203.2","192.168.203.3","192.168.203.4"],
    swift_storage_device          => 'device1',
  }

}
