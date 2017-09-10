routes:
  network.routes:
    - name: ${_param:opnfv_fn_vm_primary_interface}
    - routes:
      - name: maas_mcp_to_pxe_network
        ipaddr: ${_param:opnfv_fuel_maas_pxe_network}
        netmask: 255.255.255.0
        gateway: ${_param:opnfv_fuel_maas_mcp_address}
