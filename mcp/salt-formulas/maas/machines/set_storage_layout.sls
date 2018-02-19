##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{%- from "maas/map.jinja" import region with context %}

maas_login_admin:
  cmd.run:
  - name: "maas-region apikey --username {{ region.admin.username }} > /var/lib/maas/.maas_credentials"
  - unless: 'test -e /var/lib/maas/.maas_credentials'

# TODO: implement set_storage_layout via _modules/maas.py
set_storage_layout:
  cmd.run:
  - name: "maas login {{ region.admin.username }} http://{{ region.bind.host }}:5240/MAAS/api/2.0 - < /var/lib/maas/.maas_credentials && maas opnfv machine set-storage-layout {{ pillar['system_id'] }} storage_layout={{ pillar['storage_layout'] | default('lvm') }} lv_size={{ pillar['lv_size'] | default('100%') }}"
  - require:
    - cmd: maas_login_admin
