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

class opnfv::external_net_setup {

  if $public_gateway == '' { fail('public_gateway is empty') }
  if $public_dns == '' { fail('public_dns is empty') }
  if $public_network == '' { fail('public_network is empty') }
  if $public_subnet == '' { fail('public_subnet is empty') }
  if $public_allocation_start == '' { fail('public_allocation_start is empty') }
  if $public_allocation_end == '' { fail('public_allocation_end is empty') }
  if !$controllers_hostnames_array { fail('controllers_hostnames_array is empty') }
  $controllers_hostnames_array_str = $controllers_hostnames_array
  $controllers_hostnames_array = split($controllers_hostnames_array, ',')

  #find public NIC
  $public_nic = get_nic_from_network("$public_network")
  $public_nic_ip = get_ip_from_nic("$public_nic")
  $public_nic_netmask = get_netmask_from_nic("$public_nic")

  Anchor[ 'neutron configuration anchor end' ]
  ->
  #update bridge-mappings to physnet1
  file_line { 'ovs':
    ensure  => present,
    path    => '/etc/neutron/plugin.ini',
    line    => '[ovs]',
  }
  ->
  #update bridge-mappings to physnet1
  file_line { 'bridge_mapping':
    ensure  => present,
    path    => '/etc/neutron/plugin.ini',
    line    => 'bridge_mappings = physnet1:br-ex',
  }
  ->
  Exec["pcs-neutron-server-set-up"]

##this way we only let controller1 create the neutron resources
##controller1 should be the active neutron-server at provisioining time

 if $hostname == $controllers_hostnames_array[0] {
  Exec["all-neutron-nodes-are-up"]
  ->
  neutron_network { 'provider_network':
    ensure                    => present,
    name                      => 'provider_network',
    admin_state_up            => true,
    provider_network_type     => flat,
    provider_physical_network => 'physnet1',
    router_external           => true,
    tenant_name               => 'services',
  }
  ->
  neutron_subnet { 'provider_subnet':
    ensure            => present,
    name              => provider_subnet,
    cidr              => $public_subnet,
    gateway_ip        => $public_gateway,
    allocation_pools  => [ "start=${public_allocation_start},end=${public_allocation_end}" ],
    dns_nameservers   => $public_dns,
    enable_dhcp       => false,
    network_name      => 'provider_network',
    tenant_name       => 'services',
  }
  ->
  neutron_router { 'provider_router':
    ensure               => present,
    name                 => 'provider_router',
    admin_state_up       => true,
    gateway_network_name => 'provider_network',
    tenant_name          => 'admin',
  }
 }
}
