##############################################################################
# Copyright (c) 2019 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{% from "opendaylight/map.jinja" import server with context %}

/opt/opendaylight/etc/jetty.xml:
  file.managed:
  - source: salt://opendaylight/files/jetty.xml
  - template: jinja
  - user: odl
  - group: odl

/opt/opendaylight/bin/setenv:
  file.managed:
  - source: salt://opendaylight/files/setenv.shell
  - template: jinja
  - mode: 0755
  - user: odl
  - group: odl

{%- set features = [] %}
{%- for f in server.karaf_features.itervalues() %}
  {%- do features.extend(f) %}
{%- endfor %}

/opt/opendaylight/etc/org.apache.karaf.features.cfg:
  ini.options_present:
  - sections:
      featuresBoot: {{ features|join(',') }}

/opt/opendaylight/etc/org.ops4j.pax.web.cfg:
  ini.options_present:
  - sections:
      org.ops4j.pax.web.listening.addresses: {{ server.odl_bind_ip }}
      org.osgi.service.http.port: {{ server.odl_rest_port }}

{%- if not server.pax_logging_enabled|d(false) %}
  {%-
    set pax_logging_opts = [
      'log4j2.rootLogger.appenderRef.PaxOsgi.ref',
      'log4j2.appender.osgi.type',
      'log4j2.appender.osgi.name',
      'log4j2.appender.osgi.filter'
    ]
  %}

  {%- for opt in pax_logging_opts %}
pax.logging.cfg.{{ opt }}:
  file.comment:
  - name: /opt/opendaylight/etc/org.ops4j.pax.logging.cfg
  - regex: ^{{ opt }}\s*=
  - backup: false
  {%- endfor %}
{%- endif %}

/opt/opendaylight/etc/org.opendaylight.openflowplugin.cfg:
  file.managed:
  - user: odl
  - group: odl
  ini.options_present:
  - sections:
      is-statistics-polling-on: {{ server.stats_polling_enabled }}

{%- if server.get('router_enabled', false) %}
/opt/opendaylight/etc/custom.properties:
  ini.options_present:
  - sections:
      ovsdb.l3.fwd.enabled: 'yes'
      ovsdb.of.version: 1.3
{%- endif %}

{%- if server.netvirt_natservice is defined %}
/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml:
  file.managed:
  - source: salt://opendaylight/files/netvirt-natservice-config.xml
  - template: jinja
  - makedirs: true
  - user: odl
  - group: odl
{%- endif %}

{%- if server.dhcp.enabled %}
/opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml:
  file.managed:
  - source: salt://opendaylight/files/netvirt-dhcpservice-config.xml
  - template: jinja
  - makedirs: true
  - user: odl
  - group: odl
{%- endif %}
