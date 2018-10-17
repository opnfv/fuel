##############################################################################
# Copyright (c) 2018 Intracom Telecom and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{%- from "quagga/map.jinja" import server with context %}
{%- if server.enabled %}

quagga_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

download_quagga:
  file.managed:
  - name: /var/cache/quagga.tar.gz
  - source: {{ server.quagga_package_url }}
  - source_hash: {{ server.quagga_package_checksum }}
  - user: root
  - group: root

unarchive_quagga:
  archive.extracted:
  - source: /var/cache/quagga.tar.gz
  - name: /tmp
  - user: root
  - group: root

install_quagga_packages:
  cmd.run:
  - name: {{ server.install_cmd }} $(ls |grep -vE 'debuginfo|devel|contrib')
  - cwd: /tmp/quagga
  - runas: root

start_zebra_rpc_daemon:
  cmd.run:
  - name: /opt/quagga/etc/init.d/zrpcd start
  - runas: root

{%- endif %}
