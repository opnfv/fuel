#!/bin/bash -e
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

CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
F_GIT_ROOT=$(git rev-parse --show-toplevel)
F_GIT_DIR=$(cd "${F_GIT_ROOT}/mcp" && git rev-parse --git-dir)
F_GIT_SUBD=${F_GIT_ROOT#${F_GIT_DIR%%/.git*}}
OPNFV_TMP_DIR="/home/${SALT_MASTER_USER}/opnfv"
OPNFV_GIT_DIR="/root/opnfv"
OPNFV_FUEL_DIR="/root/fuel" # Should be in sync with patch.sh, scripts patches
OPNFV_RDIR="reclass/classes/cluster/all-mcp-arch-common"
OPNFV_VCP_IMG="mcp/scripts/base_image_opnfv_fuel_vcp.img"
OPNFV_VCP_DIR="/srv/salt/env/prd/salt/files/control/images"
LOCAL_GIT_DIR="${F_GIT_ROOT%${F_GIT_SUBD}}"
LOCAL_PDF_RECLASS=$1; shift
# shellcheck disable=SC2116,SC2086
LOCAL_VIRT_NODES=$(echo ${*//cfg01/}) # unquoted to filter space
NODE_MASK="${LOCAL_VIRT_NODES// /|}"

# push to cfg01 current git repo first (including submodules), at ~ubuntu/opnfv
# later we move it to ~root/opnfv (and ln as ~root/fuel); delete the temp clone
remote_tmp="${SSH_SALT}:$(basename "${OPNFV_TMP_DIR}")"
rsync -Erl --delete -e "ssh ${SSH_OPTS}" \
  --exclude-from="${F_GIT_ROOT}/.gitignore" \
  "${LOCAL_GIT_DIR}/" "${remote_tmp}/"
if [ -n "${LOCAL_PDF_RECLASS}" ] && [ -f "${LOCAL_PDF_RECLASS}" ]; then
  rsync -e "ssh ${SSH_OPTS}" "${LOCAL_PDF_RECLASS}" \
    "${remote_tmp}${F_GIT_SUBD}/mcp/${OPNFV_RDIR}/opnfv/"
fi
local_vcp_img=$(dirname "${LOCAL_PDF_RECLASS}")/$(basename "${OPNFV_VCP_IMG}")
if [ -e "${local_vcp_img}" ]; then
  rsync -L -e "ssh ${SSH_OPTS}" "${local_vcp_img}" \
    "${remote_tmp}${F_GIT_SUBD}/${OPNFV_VCP_IMG}"
fi

# ssh to cfg01
# shellcheck disable=SC2086,2087
ssh ${SSH_OPTS} "${SSH_SALT}" bash -s -e << SALT_INSTALL_END
  sudo -i
  set -e
  export TERM=${TERM}
  export CI_DEBUG=${CI_DEBUG}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x

  echo -n 'Checking out cloud-init has finished running ...'
  while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo -n '.'; sleep 1; done
  echo ' done'

  mkdir -p /srv/salt /usr/share/salt-formulas/reclass
  rm -rf ${OPNFV_GIT_DIR} ${OPNFV_FUEL_DIR}
  mv ${OPNFV_TMP_DIR} ${OPNFV_GIT_DIR} && chown -R root.root ${OPNFV_GIT_DIR}
  find ${OPNFV_GIT_DIR} -name '.git' -type f | while read f_git; do
    sed -i 's@${LOCAL_GIT_DIR}@${OPNFV_GIT_DIR}@g' \$f_git
  done
  ln -sf ${OPNFV_GIT_DIR}${F_GIT_SUBD} ${OPNFV_FUEL_DIR}
  ln -sf ${OPNFV_FUEL_DIR}/mcp/reclass /srv/salt
  ln -sf ${OPNFV_FUEL_DIR}/mcp/deploy/scripts /srv/salt
  ln -sf ${OPNFV_FUEL_DIR}/mcp/scripts/mcp.rsa $(dirname "${OPNFV_FUEL_DIR}")
  cd /srv/salt/${OPNFV_RDIR} && rm -f arch && ln -sf "\$(uname -i)" arch

  cp -r ${OPNFV_FUEL_DIR}/mcp/metadata/service /usr/share/salt-formulas/reclass
  cd /srv/salt/reclass/classes/service && \
    ln -sf /usr/share/salt-formulas/reclass/service/opendaylight

  # Armband APT-MK nightly/extra repo for forked & extended reclass
  apt-key adv --keyserver keys.gnupg.net --recv 798AB1D1
  echo 'deb http://linux.enea.com/apt-mk/xenial nightly extra' > \
    '/etc/apt/sources.list.d/armband_mcp_extra.list'
  apt-get update

  cd /srv/salt/scripts
  export DEBIAN_FRONTEND=noninteractive
  echo 'Dpkg::Use-Pty "0";' > /etc/apt/apt.conf.d/90silence-dpkg
  OLD_DOMAIN=\$(grep -sPzo "id: cfg01\.\K(\S*)" /etc/salt/minion.d/minion.conf) || true
  BOOTSTRAP_SALTSTACK_OPTS=" -r -dX stable 2016.11 " \
    MASTER_HOSTNAME=cfg01.${CLUSTER_DOMAIN} DISTRIB_REVISION=nightly \
      EXTRA_FORMULAS="nfs" \
        ./salt-master-init.sh
  salt-key -Ay

  cp -r ${OPNFV_FUEL_DIR}/mcp/salt-formulas/* /usr/share/salt-formulas/env
  cd ${OPNFV_FUEL_DIR}/mcp/patches && ./patch.sh patches.list formulas
  cd ${OPNFV_FUEL_DIR}/mcp/patches && ./patch.sh patches.list reclass

  source ${OPNFV_FUEL_DIR}/mcp/scripts/lib.sh
  wait_for 3.0 "salt-call state.apply salt"

  # In case scenario changed (and implicitly domain name), re-register minions
  if [ -n "\${OLD_DOMAIN}" ] && [ "\${OLD_DOMAIN}" != "${CLUSTER_DOMAIN}" ]; then
    salt "*.\${OLD_DOMAIN}" cmd.run "grep \${OLD_DOMAIN} -sRl /etc/salt | \
      xargs --no-run-if-empty sed -i 's/\${OLD_DOMAIN}/${CLUSTER_DOMAIN}/g'; \
        service salt-minion restart" || true
    salt-key -yd "*.\${OLD_DOMAIN}"
    salt-key -Ay
  fi

  # Init specific to VMs on FN (all for virtual, cfg|mas for baremetal)
  wait_for 3.0 'salt -C "cfg01*" state.apply linux'
  if [[ "${LOCAL_VIRT_NODES}" =~ mas ]]; then
    wait_for 3.0 'salt -C "mas*" test.ping'
  else
    wait_for 3.0 '(for n in ${LOCAL_VIRT_NODES}; do salt -C \${n}.* test.ping || exit; done)'
  fi
  wait_for 3.0 'salt -C "E@^(${NODE_MASK}|cfg01).*" saltutil.sync_all'
  wait_for 3.0 'salt -C "E@^(${NODE_MASK}|cfg01).*" state.apply salt'

  wait_for 3.0 'salt -C "E@^(${NODE_MASK}).*" state.sls linux.system,linux.storage'
  wait_for 2.0 'salt -C "E@^(${NODE_MASK}).*" state.sls linux.network' || true
  salt -C "E@^(${NODE_MASK}).*" state.sls opnfv.route_wrapper
  salt -C "E@^(${NODE_MASK}).*" system.reboot
  wait_for 90.0 'salt -C "E@^(${NODE_MASK}).*" test.ping'
  wait_for 3.0 'salt -C "E@^(${NODE_MASK}).*" pkg.upgrade refresh=False dist_upgrade=True'

  wait_for 3.0 'salt -C "E@^(${NODE_MASK}|cfg01).*" state.sls ntp'

  if [ -f "${OPNFV_FUEL_DIR}/${OPNFV_VCP_IMG}" ]; then
    mkdir -p "${OPNFV_VCP_DIR}"
    mv "${OPNFV_FUEL_DIR}/${OPNFV_VCP_IMG}" "${OPNFV_VCP_DIR}/"
  fi
SALT_INSTALL_END
