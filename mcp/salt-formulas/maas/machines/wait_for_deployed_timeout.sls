{%- from "maas/map.jinja" import region with context %}

maas_login_admin:
  cmd.run:
  - name: "maas-region apikey --username {{ region.admin.username }} > /var/lib/maas/.maas_credentials"

wait_for_machines_deployed:
  module.run:
  - name: maas.wait_for_machine_status
  - kwargs:
        req_status: "Deployed"
        #TBD to featch value from IDF maas.timeout_deploying
        timeout: 900
  - require:
    - cmd: maas_login_admin
