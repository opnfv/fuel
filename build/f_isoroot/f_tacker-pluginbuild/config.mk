##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# geopar@intracom-telecom.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TACKER_BRANCH?=master
TACKER_REPO?="https://github.com/openstack/fuel-plugin-tacker"
TACKER_CHANGE?=7068a300df0c695fb4589bf504b29cbed970ba58

# Tacker Horizon Dashboard override; default branch (stable/mitaka) was removed
export TACKER_HORIZON_BRANCH := mitaka-eol
