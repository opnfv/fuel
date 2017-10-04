#!/bin/bash -ex
##############################################################################
# Copyright (c) 2017 Ericsson AB, Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Global variables
export SSH_KEY=${SSH_KEY:-"/var/lib/opnfv/mcp.rsa"}
export SALT_MASTER=${INSTALLER_IP:-10.20.0.2}
export SALT_MASTER_USER=${SALT_MASTER_USER:-ubuntu}
export MAAS_IP=${MAAS_IP:-${SALT_MASTER%.*}.3}

# These should be determined from PDF later
export MAAS_PXE_NETWORK=${MAAS_PXE_NETWORK:-192.168.11.0}

# Derivated from above global vars
export SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_KEY}"
export SSH_SALT="${SALT_MASTER_USER}@${SALT_MASTER}"
