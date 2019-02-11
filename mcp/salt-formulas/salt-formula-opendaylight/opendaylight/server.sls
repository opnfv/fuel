##############################################################################
# Copyright (c) 2019 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{% from "opendaylight/map.jinja" import server with context %}

{%- if server.enabled %}

include:
  - opendaylight.config
  - opendaylight.repo

{%- if grains['saltversioninfo'] < [2017, 7] %}
service.mask:
  module.run:
  - m_name: opendaylight
{%- else %}
opendaylight_service_mask:
  service.masked:
  - name: opendaylight
{%- endif %}
  - prereq:
    - pkg: opendaylight

{%- if server.cluster_enabled %}
configure_cluster:
  cmd.run:
  - name: /opt/opendaylight/bin/configure-cluster-ipdetect.sh {{ server.seed_nodes_list }}
  - require:
    - pkg: opendaylight
{%- endif %}

opendaylight:
  pkg.installed:
  - names: {{ server.pkgs }}
  - require:
    - sls: opendaylight.repo
  - require_in:
    - sls: opendaylight.config
  service.running:
  - enable: true
{%- if grains['saltversioninfo'] >= [2017, 7] %}
  - unmask: true
{%- endif %}
  - watch:
    - sls: opendaylight.config

{%- endif %}
