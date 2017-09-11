#!/bin/bash
##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Collect /var/log from all cluster nodes via Salt Master
#

DEPLOY_LOG=$1
OPNFV_TMP_LOG="opnfv_fuel_logs"

[ -n "${DEPLOY_LOG}" ] || exit 0

# ssh to cfg01
# shellcheck disable=SC2086,2087
ssh ${SSH_OPTS} "${SSH_SALT}" bash -s << LOG_COLLECT_END
  sudo -i

  echo salt -C '*' cp.push_dir /var/log upload_path='${OPNFV_TMP_LOG}'
  salt -C '*' cp.push_dir /var/log upload_path='${OPNFV_TMP_LOG}'

  cd /var/cache/salt/master/minions && \
    find */files/${OPNFV_TMP_LOG}/ | \
      xargs tar czf \$(eval echo \~\${SUDO_USER}/${OPNFV_TMP_LOG}.tar.gz) \
        --transform 's|/files/${OPNFV_TMP_LOG}||'
LOG_COLLECT_END

# shellcheck disable=SC2086
scp ${SSH_OPTS} "${SSH_SALT}:${OPNFV_TMP_LOG}.tar.gz" "${DEPLOY_LOG}"
# shellcheck disable=SC2086,2029
ssh ${SSH_OPTS} "${SSH_SALT}" rm -f "${OPNFV_TMP_LOG}.tar.gz"
