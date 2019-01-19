#!/bin/bash -e
# shellcheck disable=SC2155,SC2015
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Library of common shell functions used by build/deploy scripts, states etc.
#

function wait_for {
  # Execute in a subshell to prevent local variable override during recursion
  (
    local total_attempts=$1; shift
    local cmdstr=$*
    local sleep_time=10
    echo -e "\n[wait_for] Waiting for cmd to return success: ${cmdstr}"
    # shellcheck disable=SC2034
    for attempt in $(seq "${total_attempts}"); do
      echo "[wait_for] Attempt ${attempt}/${total_attempts%.*} for: ${cmdstr}"
      if [ "${total_attempts%.*}" = "${total_attempts}" ]; then
        eval "${cmdstr}" && echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      else
        ! (eval "${cmdstr}" || echo 'No response') |& tee /dev/stderr | \
           grep -Eq '(Not connected|No response)' && \
           echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      fi
      sleep "${sleep_time}"
    done
    echo "[wait_for] ERROR: Failed after max attempts: ${cmdstr}"
    return 1
  )
}

function cleanup_uefi {
  # Clean up Ubuntu boot entry if cfg01, baremetal nodes online from previous deploy
  local cmd_str="ssh ${SSH_OPTS} ${SSH_SALT}"
  ping -c 1 -w 1 "${SALT_MASTER}" || return 0
  [ ! "$(hostname)" = 'cfg01' ] || cmd_str='eval'
  ${cmd_str} "sudo salt -C 'G@virtual:physical and not cfg01*' cmd.run \
    \"which efibootmgr > /dev/null 2>&1 && \
    efibootmgr | grep -oP '(?<=Boot)[0-9]+(?=.*ubuntu)' | \
    xargs -I{} efibootmgr --delete-bootnum --bootnum {}; \
    rm -rf /boot/efi/*\"" || true

  ${cmd_str} "sudo salt -C 'G@virtual:physical and not cfg01*' cmd.run 'shutdown now'" || true
}

function get_nova_compute_pillar_data {
  local value=$(salt -C 'I@nova:compute and *01*' pillar.get _param:"${1}" --out yaml | cut -d ' ' -f2)
  if [ "${value}" != "''" ]; then
    echo "${value}"
  fi
}
