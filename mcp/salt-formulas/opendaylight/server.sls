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
{%- if system.proxy is defined and system.proxy.keyserver is defined %}
    - env:
{%- if system.proxy.keyserver.http is defined %}
      - http_proxy: {{ system.proxy.keyserver.http }}
{%- endif %}
{%- if system.proxy.keyserver.https is defined %}
      - https_proxy: {{ system.proxy.keyserver.https }}
{%- endif %}
{%- endif %}

opendaylight_repo:
  pkgrepo.managed:
  # NOTE(armband): PPA handling behind proxy broken, define it explicitly
  # https://github.com/saltstack/salt/pull/45224
  # - ppa: {{ server.repo }}
  - human_name: opendaylight-ppa
  - name: deb http://ppa.launchpad.net/odl-team/nitrogen/ubuntu xenial main
  - file: /etc/apt/sources.list.d/odl-team-ubuntu-nitrogen-xenial.list

opendaylight:
  pkg.installed:
  - require:
    - pkgrepo: opendaylight_repo
  - require_in:
    - file: /opt/opendaylight/etc/jetty.xml
    - file: /opt/opendaylight/bin/setenv
    - ini: /opt/opendaylight/etc/org.apache.karaf.features.cfg
    - ini: /opt/opendaylight/etc/org.ops4j.pax.web.cfg
  service.running:
  - enable: true
  - watch:
    - file: /opt/opendaylight/etc/jetty.xml
    - file: /opt/opendaylight/bin/setenv
    - ini: /opt/opendaylight/etc/org.apache.karaf.features.cfg
    - ini: /opt/opendaylight/etc/org.ops4j.pax.web.cfg

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

{%- endif %}
