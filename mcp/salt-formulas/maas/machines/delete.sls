{%- from "maas/map.jinja" import region with context %}

maas_login_admin:
  cmd.run:
  - name: "maas-region apikey --username {{ region.admin.username }} > /var/lib/maas/.maas_credentials"

# TODO: implement delete_machine via _modules/maas.py
delete_machine:
  cmd.run:
  - name: "maas login {{ region.admin.username }} http://{{ region.bind.host }}:5240/MAAS/api/2.0 - < /var/lib/maas/.maas_credentials && maas opnfv machine delete {{ pillar['system_id'] }}"
  - require:
    - cmd: maas_login_admin
