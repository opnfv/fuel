##############################################################################
# Copyright (c) 2018 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{%- from "tacker/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- git

{{ server.git.source }}:
  git.latest:
  - target: {{ server.git.target }}
  - rev: {{ server.git.branch }}
  - depth: 1

tacker_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

tacker_install:
  cmd.run:
  - name: python setup.py install
  - cwd: {{ server.git.target }}
  - creates: /usr/local/bin/tacker-server
  - require:
    - git: {{ server.git.source }}

/usr/local/etc/tacker/tacker.conf:
  file.managed:
  - source: salt://tacker/files/tacker.conf
  - template: jinja
  - makedirs: true
  - require:
    - cmd: tacker_install

tacker_db_manage:
  cmd.run:
  - name: /usr/local/bin/tacker-db-manage --config-file /usr/local/etc/tacker/tacker.conf upgrade head
  - require:
    - file: /usr/local/etc/tacker/tacker.conf

/lib/systemd/system/tacker.service:
  file.managed:
  - source: salt://tacker/files/tacker.systemd

tacker:
  service.running:
  - enable: true
  - watch:
    - file: /usr/local/etc/tacker/tacker.conf

{%- endif %}
