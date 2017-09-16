routes:
  network.routes:
    - name: {{ salt['pillar.get']('_param:opnfv_fn_vm_primary_interface') }}
    - routes:
      - name: maas_mcp_to_pxe_network
        ipaddr: {{ salt['pillar.get']('_param:opnfv_maas_pxe_network_address') }}
        netmask: 255.255.255.0
        gateway: {{ salt['pillar.get']('_param:opnfv_maas_mcp_address') }}
