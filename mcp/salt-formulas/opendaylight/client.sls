{%- from "opendaylight/map.jinja" import client with context %}
{%- if client.get('enabled', True) %}

opendaylight_client_packages:
  pkg.installed:
  - pkgs: {{ client.pkgs }}

ovs_set_manager:
  cmd.run:
  - name: "ovs-vsctl set-manager {{ client.ovsdb_server_iface }} {{ client.ovsdb_odl_iface }}"
  - unless: "ovs-vsctl get-manager | fgrep -x {{ client.ovsdb_odl_iface }}"

ovs_set_tunnel_endpoint:
  cmd.run:
  - name: "ovs-vsctl set Open_vSwitch . other_config:local_ip={{ client.tunnel_ip }}"
  - unless: "ovs-vsctl get Open_vSwitch . other_config | fgrep local_ip"
  - require:
    - cmd: ovs_set_manager

ovs_set_provider_mapping:
  cmd.run:
  - name: "ovs-vsctl set Open_vSwitch . other_config:provider_mappings={{ client.provider_mappings }}"
  - unless: "ovs-vsctl get Open_vSwitch . other_config | fgrep provider_mappings"
  - require:
    - cmd: ovs_set_manager

{%- endif %}
