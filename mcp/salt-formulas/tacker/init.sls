##############################################################################
# Copyright (c) 2018 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
include:
{%- if pillar.tacker.server is defined %}
- tacker.server
{%- endif %}
