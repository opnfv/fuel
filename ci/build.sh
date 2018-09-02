#!/bin/bash -e
# shellcheck disable=SC1004,SC1090
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# BEGIN of Exit handlers
#
do_exit () {
    local RC=$?
    [ -z "${FORMULA_TMP_DIR}" ] || rm -rf "${FORMULA_TMP_DIR}"
    if [ -n "${HTTP_SERVER_PID}" ]; then
        disown "${HTTP_SERVER_PID}"
        kill -9 "${HTTP_SERVER_PID}" > /dev/null 2>&1
    fi
    if [ ${RC} -eq 0 ]; then
        notify_n "[OK] MCP: Docker build finished succesfully!" 2
    else
        notify_n "[ERROR] MCP: Docker build threw a fatal error!"
    fi
}
#
# End of Exit handlers
##############################################################################

##############################################################################
# BEGIN of variables to customize
#
CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
FORMULA_REV=nightly  # should be in sync with patching mechanism's config.mk
GH_SF="https://gerrit.mcp.mirantis.com/salt-formulas"
MCP_REPO_ROOT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
DEPLOY_DIR=$(cd "${MCP_REPO_ROOT_PATH}/mcp/scripts"; pwd)
DOCKER_DIR=$(cd "${MCP_REPO_ROOT_PATH}/docker"; pwd)
DOCKER_TAG=${1:-latest}
DOCKER_PUSH=${2---push}  # pass an empty second arg to disable push
CACHE_INVALIDATE=${CACHE_INVALIDATE:-0}
HTTP_SERVER_PORT=${HTTP_SERVER_PORT:-8080}

source "${DEPLOY_DIR}/globals.sh"
source "${DEPLOY_DIR}/lib.sh"
source "${DEPLOY_DIR}/lib_jump_common.sh"

[ ! "${TERM:-unknown}" = 'unknown' ] || export TERM=vt220
[ "${CACHE_INVALIDATE}" = 0 ] || CACHE_INVALIDATE=$(date +%s)

#
# END of variables to customize
##############################################################################

##############################################################################
# BEGIN of main
#

# Enable the automatic exit trap
trap do_exit SIGINT SIGTERM EXIT

# Set no restrictive umask so that Jenkins can remove any residuals
umask 0000

# Clone git submodules and apply our patches
make -C "${MCP_REPO_ROOT_PATH}/mcp/patches" deepclean patches-import

pushd "${DEPLOY_DIR}" > /dev/null

# Install distro packages and pip-managed prerequisites
PYTHON_BIN_PATH="$(python -m site --user-base)/bin"
PATH="$PATH:$PYTHON_BIN_PATH"
notify "[NOTE] Installing required build-time distro and pip pkgs" 2
jumpserver_pkg_install 'build'
python -m pip install --upgrade pipenv --user
docker_install

# Prepare OPNFV formulas, reclass.system for fetching during container build
TMP_DIR="${DOCKER_DIR}/files/extra"
FORMULA_TMP_DIR="${TMP_DIR}/opnfv/salt-formulas"
SYSTEM_TMP_DIR="${TMP_DIR}/opnfv/system"
rm -rf "${TMP_DIR}"
mkdir -p "${FORMULA_TMP_DIR}" "${SYSTEM_TMP_DIR}"
for formula_dir in "${MCP_REPO_ROOT_PATH}/mcp/salt-formulas"/*; do
  formula_tmp="${FORMULA_TMP_DIR}/$(basename "${formula_dir}")"
  if [ -e "${formula_dir}/.git" ]; then
    # upstream formulas that we patched locally (e.g. salt-formula-linux) have
    # their own git submodule and can be simply cloned (use patched branch)
    git clone "${formula_dir}" "${formula_tmp}" -b "${FORMULA_REV}"
  else
    # OPNFV only formulas should each have their own git repo for formula fetch
    # scripts to work; clone full repo and filter only relevant files
    git clone "${MCP_REPO_ROOT_PATH}" "${formula_tmp}"
    pushd "${formula_tmp}" > /dev/null
    # new local branch to match expected revision after filter-branch
    git checkout -b "${FORMULA_REV}"
    git filter-branch --subdirectory-filter "${formula_dir#${MCP_REPO_ROOT_PATH}/}"
    popd > /dev/null
  fi
done
git clone "${MCP_REPO_ROOT_PATH}/mcp/reclass/classes/system" \
          "${SYSTEM_TMP_DIR}" -b "${FORMULA_REV}"

popd > /dev/null

# Run a simple HTTP server during build to bypass the need for useless COPY/ADD
pushd "${TMP_DIR}" > /dev/null
tar cf opnfv.tar opnfv
python -m SimpleHTTPServer "${HTTP_SERVER_PORT}" > /dev/null 2>&1 &
HTTP_SERVER_PID=$!
HTTP_SERVER_ADDR="http://$(ip route get 1 | awk '{print $NF;exit}'):${HTTP_SERVER_PORT}"
popd > /dev/null

pushd "${DOCKER_DIR}" > /dev/null
env PIPENV_HIDE_EMOJIS=1 VIRTUALENV_ALWAYS_COPY=1 python -m pipenv --two install
# shellcheck disable=SC2086
env PIPENV_HIDE_EMOJIS=1 python -m pipenv run \
  invoke build saltmaster-reclass \
    --require 'salt salt-formulas opnfv reclass tini-saltmaster' \
    --dist=ubuntu \
    --dist-rel=xenial \
    --build-arg-extra " \
        OPNFV_EXTRA=\"${HTTP_SERVER_ADDR}/opnfv.tar\" \
        SALT_FORMULA_SOURCES=\"file:///tmp/${FORMULA_TMP_DIR#${TMP_DIR}/} ${GH_SF}\" \
        SALT_FORMULA_SKIP_DEPENDENCIES=\"true\" \
        RECLASS_BASE_SOURCE=\"file:///tmp/${SYSTEM_TMP_DIR#${TMP_DIR}/}\"" \
    --formula-rev="${FORMULA_REV}" \
    --opnfv-tag="${DOCKER_TAG}" \
    --salt='stable 2017.7' \
    --build-arg-extra " \
        CACHE_INVALIDATE=\"${CACHE_INVALIDATE}\"" \
    ${DOCKER_PUSH}
popd > /dev/null

#
# END of main
##############################################################################
