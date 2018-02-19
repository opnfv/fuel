##############################################################################
# Copyright (c) 2018 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{% from "linux/map.jinja" import system with context %}

armband_repo_key:
  cmd.run:
    - name: "apt-key adv --keyserver keys.gnupg.net --recv 798AB1D1"
{%- if system.proxy is defined and system.proxy.keyserver is defined %}
    - env:
{%- if system.proxy.keyserver.http is defined and grains['dns']['nameservers'][0] in system.proxy.keyserver.http %}
      - http_proxy: {{ system.proxy.keyserver.http }}
{%- endif %}
{%- if system.proxy.keyserver.https is defined and grains['dns']['nameservers'][0] in system.proxy.keyserver.https %}
      - https_proxy: {{ system.proxy.keyserver.https }}
{%- endif %}
{%- endif %}

armband_mcp_extra_repo:
  pkgrepo.managed:
  - human_name: armband_mcp_extra
  - name: deb http://linux.enea.com/apt-mk/xenial nightly extra
  - file: /etc/apt/sources.list.d/armband_mcp_extra.list

reclass:
  pkg.installed:
    - only_upgrade: True
