##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

iptables_pxe_nat:
  iptables.append:
    - table: nat
    - chain: POSTROUTING
    - jump: MASQUERADE
    - destination: 0/0
    - source: {{ salt['pillar.get']('_param:single_address') }}/24
    - save: True

iptables_pxe_source:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - destination: 0/0
    - source: {{ salt['pillar.get']('_param:single_address') }}/24
    - save: True

iptables_pxe_destination:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - destination: {{ salt['pillar.get']('_param:single_address') }}/24
    - source: 0/0
    - save: True
