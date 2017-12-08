##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
routes:
  network.routes:
    - name: {{ salt['pillar.get']('_param:opnfv_fn_vm_primary_interface') }}
    - routes:
      - name: maas_mcp_to_pxe_network
        ipaddr: {{ salt['pillar.get']('_param:opnfv_infra_maas_pxe_network_address') }}
        netmask: 255.255.255.0
        gateway: {{ salt['pillar.get']('_param:opnfv_maas_mcp_address') }}
