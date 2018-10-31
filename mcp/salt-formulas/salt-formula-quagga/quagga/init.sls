##############################################################################
# Copyright (c) 2018 Intracom Telecom and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
include:
{%- if pillar.quagga.server is defined %}
- quagga.server
{%- endif %}
