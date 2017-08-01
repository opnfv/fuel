iptables_pxe_nat:
  iptables.append:
    - table: nat
    - chain: POSTROUTING
    - jump: MASQUERADE
    - destination: 0/0
    - source: {{ salt['pillar.get']('_param:pxe_address') }}/24
    - save: True

iptables_pxe_source:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - destination: 0/0
    - source: {{ salt['pillar.get']('_param:pxe_address') }}/24
    - save: True

iptables_pxe_destination:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - destination: {{ salt['pillar.get']('_param:pxe_address') }}/24
    - source: 0/0
    - save: True
