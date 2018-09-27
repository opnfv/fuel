##############################################################################
# Copyright (c) 2018 Intracom Telecom and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{%- from "quagga/map.jinja" import server with context %}
{%- if server.enabled %}
{% set source_hash = salt['cmd.shell']('echo "md5=`curl -s "{{ quagga_package_checksum }}" | md5sum | cut -c -32`"') %}

quagga_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

download_quagga:
  file.managed:
    - name: /var/cache/{{ quagga_package_url | basename }}
    - source: {{ quagga_package_url }}
    - source_hash: {{ source_hash }}
    - user: root
    - group: root

unarchive_quagga:
  archive.extracted:
    - source: /var/cache/{{ quagga_package_url | basename }}
    - name: {{ temp_quagga_dir | dirname }}
    - user: root
    - group: root

start_zebra_rpc_daemon:
  cmd.run:
    name: /opt/quagga/etc/init.d/zrpcd start
    runas: root

connect_opendaylight_with_quagga:
  cmd.run:
    name: {{ karaf_client }} -h {{ karaf_host }} 'bgp-connect --host {{ karaf_host }} --port {{ bgp_config_server_port }} add'
    runas: root

configure_opendaylight_as_bgp_speaker:
  cmd.run:
    name: {{ karaf_client }} -h {{ karaf_host }} 'odl:configure-bgp -op start-bgp-server --as-num 100 --router-id {{ bgp_speaker_host }}'
    runas: root

{%- endif %}
