##############################################################################
# Copyright (c) 2017 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{% from "opendaylight/map.jinja" import server with context %}
{% from "linux/map.jinja" import system with context %}

{%- if server.enabled %}

opendaylight_repo_key:
  cmd.run:
    - name: "apt-key adv --keyserver keyserver.ubuntu.com --recv 44C05248"
{%- if system.proxy is defined and system.proxy.pkg is defined %}
    - env:
{%- if system.proxy.pkg.http is defined %}
      - http_proxy: {{ system.proxy.pkg.http }}
{%- endif %}
{%- if system.proxy.pkg.https is defined %}
      - https_proxy: {{ system.proxy.pkg.https }}
{%- endif %}
{%- endif %}

opendaylight_repo:
  pkgrepo.managed:
  # NOTE(armband): PPA handling behind proxy broken, define it explicitly
  # https://github.com/saltstack/salt/pull/45224
  # - ppa: {{ server.repo }}
  - human_name: opendaylight-ppa
  - name: deb http://ppa.launchpad.net/odl-team/{{ server.version }}/ubuntu xenial main
  - file: /etc/apt/sources.list.d/odl-team-ubuntu-{{ server.version }}-xenial.list

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

opendaylight:
  pkg.installed:
  - require:
    - pkgrepo: opendaylight_repo
  service.running:
  - enable: true
{%- if grains['saltversioninfo'] >= [2017, 7] %}
  - unmask: true
{%- endif %}
  - watch:
    - file: /opt/opendaylight/etc/jetty.xml
    - file: /opt/opendaylight/bin/setenv
    - ini: /opt/opendaylight/etc/org.apache.karaf.features.cfg
    - ini: /opt/opendaylight/etc/org.ops4j.pax.web.cfg
    - ini: /opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg

/opt/opendaylight/etc/jetty.xml:
  file.managed:
  - source: salt://opendaylight/files/jetty.xml
  - template: jinja
  - user: odl
  - group: odl

/opt/opendaylight/bin/setenv:
  file.managed:
  - source: salt://opendaylight/files/setenv.shell
  - mode: 0755
  - use:
    - file: /opt/opendaylight/etc/jetty.xml

{% set features %}
{%- for f in server.karaf_features.itervalues() -%}
{{ f | join(',') }}{%- if not loop.last %},{%- endif %}
{%- endfor %}
{% endset %}

/opt/opendaylight/etc/org.apache.karaf.features.cfg:
  ini.options_present:
    - sections:
        featuresBoot: {{ features }}

/opt/opendaylight/etc/org.ops4j.pax.web.cfg:
  ini.options_present:
    - sections:
        org.ops4j.pax.web.listening.addresses: {{ server.odl_bind_ip }}
        org.osgi.service.http.port: {{ server.odl_rest_port }}

/opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg_present:
  file.managed:
    - name: /opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg
    - require_in:
      - ini: /opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg

/opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg:
  ini.options_present:
    - sections:
        is-statistics-polling-on: {{ server.stats_polling_enabled }}

{%- if server.get('router_enabled', false) %}
/opt/opendaylight/etc/custom.properties:
  ini.options_present:
    - sections:
        ovsdb.l3.fwd.enabled: 'yes'
        ovsdb.of.version: 1.3
    - require:
      - pkg: opendaylight
    - watch_in:
      - service: opendaylight
{%- endif %}

{%- if server.dhcp.enabled %}
/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml:
  file.managed:
  - source: salt://opendaylight/files/netvirt-dhcpservice-config.xml
  - makedirs: true
  - watch_in:
    - service: opendaylight
  - use:
    - file: /opt/opendaylight/etc/jetty.xml
{%- endif %}

{%- if grains['cpuarch'] == 'aarch64' %}
opendaylight-leveldbjni:
  pkg.installed
{%- endif %}

{%- endif %}
