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


class opnfv::network {
  ###use 8081 as a default work around swift service
  if $odl_rest_port == '' {$odl_rest_port = '8081'}

  if ($odl_flag != '') and str2bool($odl_flag) {
     $ml2_mech_drivers = ['opendaylight']
     $this_agent = 'opendaylight'
     class {"opendaylight":
       odl_rest_port => $odl_rest_port,
       extra_features => ['odl-base-all', 'odl-aaa-authn', 'odl-restconf', 'odl-nsf-all', 'odl-adsal-northbound', 'odl-mdsal-apidocs', 'odl-ovsdb-openstack', 'odl-ovsdb-northbound', 'odl-dlux-core'],
     }
  }
  else {
    $ml2_mech_drivers = ['openvswitch','l2population']
    $this_agent = 'ovs'
  }



  if $ovs_tunnel_if == '' { fail('ovs_tunnel_if is empty') }
  if $private_ip == '' { fail('private_ip is empty') }

  if $odl_control_ip == '' { fail('odl_controL_ip is empty, should be the IP of your network node private interface') }

  if $mysql_ip == '' { fail('mysql_ip is empty') }
  if $amqp_ip == '' { fail('amqp_ip is empty') }

  if $nova_user_password == '' { fail('nova_user_password is empty') }
  if $nova_db_password == '' { fail('nova_db_password is empty') }

  if $neutron_user_password == '' { fail('neutron_user_password is empty') }
  if $neutron_db_password == '' { fail('neutron_db_password is empty') }
  if $neutron_metadata_shared_secret == '' { fail('neutron_metadata_shared_secret is empty') }

  class { "quickstack::neutron::networker":
    agent_type                    => $this_agent,
    neutron_metadata_proxy_secret => $neutron_metadata_shared_secret,
    neutron_db_password           => $neutron_db_password,
    neutron_user_password         => $neutron_user_password,
    nova_db_password              => $nova_db_password,
    nova_user_password            => $nova_user_password,

    controller_priv_host          => $private_ip,

    enable_tunneling              => true,
    ovs_tunnel_iface              => $ovs_tunnel_if,
    ovs_tunnel_network            => '',
    ovs_l2_population             => 'True',
    ovs_tunnel_types              => ['vxlan'],
    external_network_bridge       => 'br-ex',
    tenant_network_type           => 'vxlan',
    tunnel_id_ranges              => '1:1000',

    mysql_host                    => $mysql_ip,
    amqp_host                     => $amqp_ip,
    amqp_username                 => 'guest',
    amqp_password                 => 'guest',

    ml2_mechanism_drivers        => $ml2_mech_drivers,
    odl_controller_ip            => $odl_control_ip,
  }
}
