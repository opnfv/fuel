{% from "opendaylight/map.jinja" import server with context %}

{%- if server.enabled %}

opendaylight_repo:
  pkgrepo.managed:
  - ppa: {{ server.repo }}

opendaylight:
  pkg.installed:
  - require:
    - pkgrepo: opendaylight_repo
  - require_in:
    - file: /opt/opendaylight/etc/jetty.xml
    - file: /opt/opendaylight/bin/setenv
    - ini: /opt/opendaylight/etc/org.apache.karaf.features.cfg
  service.running:
  - enable: true
  - watch:
    - file: /opt/opendaylight/etc/jetty.xml
    - file: /opt/opendaylight/bin/setenv
    - ini: /opt/opendaylight/etc/org.apache.karaf.features.cfg

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
