#!/bin/bash
##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Deploy Salt Master
#

F_GIT_ROOT=$(git rev-parse --show-toplevel)
OPNFV_TMP_DIR="/home/${SALT_MASTER_USER}/fuel"
OPNFV_FUEL_DIR="/root/fuel"
OPNFV_RDIR="reclass/classes/cluster/all-mcp-ocata-common"
LOCAL_PDF_RECLASS=$1

# patch reclass-system-salt-model locally before copying it over
make -C "${F_GIT_ROOT}/mcp/patches" deepclean patches-import

# push to cfg01 current git repo first (including submodules), at ~ubuntu/fuel
# later we move it to ~root/fuel and delete the temporary clone
rsync -Erl --delete -e "ssh ${SSH_OPTS}" \
  --exclude-from="${F_GIT_ROOT}/.gitignore" \
  "${F_GIT_ROOT}/" "${SSH_SALT}:$(basename "${OPNFV_TMP_DIR}")/"
if [ -n "${LOCAL_PDF_RECLASS}" ] && [ -f "${LOCAL_PDF_RECLASS}" ]; then
  rsync -e "ssh ${SSH_OPTS}" "${LOCAL_PDF_RECLASS}" \
    "${SSH_SALT}:$(basename "${OPNFV_TMP_DIR}")/mcp/${OPNFV_RDIR}/opnfv/"
fi

# ssh to cfg01
# shellcheck disable=SC2086,2087
ssh ${SSH_OPTS} "${SSH_SALT}" bash -s << SALT_INSTALL_END
  sudo -i

  echo -n 'Checking out cloud-init has finished running ...'
  while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo -n '.'; sleep 1; done
  echo ' done'

  mkdir -p /srv/salt /usr/share/salt-formulas/reclass
  mv ${OPNFV_TMP_DIR} ${OPNFV_FUEL_DIR} && chown -R root.root ${OPNFV_FUEL_DIR}
  ln -s ${OPNFV_FUEL_DIR}/mcp/reclass /srv/salt/reclass
  ln -s ${OPNFV_FUEL_DIR}/mcp/deploy/scripts /srv/salt/scripts
  cd /srv/salt/${OPNFV_RDIR} && ln -s "\$(uname -i)" arch

  cp -r ${OPNFV_FUEL_DIR}/mcp/metadata/service /usr/share/salt-formulas/reclass
  cd /srv/salt/reclass/classes/service && \
    ln -s /usr/share/salt-formulas/reclass/service/opendaylight
  cd ${OPNFV_FUEL_DIR}/mcp/patches && ./patch.sh patches.list reclass

  cd /srv/salt/scripts
  BOOTSTRAP_SALTSTACK_OPTS=" -r -dX stable 2016.11 " \
    MASTER_HOSTNAME=cfg01.${CLUSTER_DOMAIN} DISTRIB_REVISION=nightly \
      EXTRA_FORMULAS="nfs" \
        ./salt-master-init.sh
  salt-key -Ay

  cp -r ${OPNFV_FUEL_DIR}/mcp/salt-formulas/* /usr/share/salt-formulas/env
  cd ${OPNFV_FUEL_DIR}/mcp/patches && ./patch.sh patches.list formulas

  salt-call state.apply salt
  salt '*' saltutil.sync_all
  salt '*' state.apply salt | fgrep -q 'No response' && salt '*' state.apply salt

  salt -C 'I@salt:master' state.sls linux
  salt -C '* and not cfg01*' state.sls linux

  salt '*' state.sls ntp
SALT_INSTALL_END
