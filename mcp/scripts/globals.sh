#!/bin/bash -e
##############################################################################
# Copyright (c) 2017 Ericsson AB, Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Global variables
export CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
export SSH_KEY=${SSH_KEY:-"/var/lib/opnfv/mcp.rsa"}
export SALT_MASTER=${INSTALLER_IP:-10.20.0.2}
export SALT_MASTER_USER=${SALT_MASTER_USER:-ubuntu}
export MAAS_IP=${MAAS_IP:-${SALT_MASTER%.*}.3}

# Derivated from above global vars
export SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_KEY}"
export SSH_SALT="${SALT_MASTER_USER}@${SALT_MASTER}"

##############################################################################
# BEGIN of colored notification wrappers
#
function notify() {
    local msg=${1}; shift
    notify_i "${msg}\n" "$@"
}

function notify_i() {
    tput setaf "${2:-1}" || true
    echo -en "${1:-"[WARN] Unsupported opt arg: $3\\n"}"
    tput sgr0
}

function notify_n() {
    local msg=${1}; shift
    notify_i "\n${msg}\n\n" "$@"
}

function notify_e() {
    local msg=${1}; shift
    notify_i "\n${msg}\n\n" "$@" 1>&2
    exit 1
}
#
# END of colored notification wrapper
##############################################################################
