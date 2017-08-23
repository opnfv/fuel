{%- from "maas/map.jinja" import region with context %}

maas_login_admin:
  cmd.run:
  - name: "maas-region apikey --username {{ region.admin.username }} > /var/lib/maas/.maas_credentials"

# TODO: implement mark_broken_fixed_machine via _modules/maas.py
mark_broken_fixed_machine:
  cmd.run:
  - name: "maas login {{ region.admin.username }} http://{{ region.bind.host }}:5240/MAAS/api/2.0 - < /var/lib/maas/.maas_credentials && maas opnfv machine mark-broken {{ pillar['system_id'] }} && maas opnfv machine mark-fixed {{ pillar['system_id'] }}"
  - require:
    - cmd: maas_login_admin
