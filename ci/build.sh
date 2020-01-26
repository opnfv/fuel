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
MCP_REPO_ROOT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
DEPLOY_DIR=$(cd "${MCP_REPO_ROOT_PATH}/mcp/scripts"; pwd)
DOCKER_DIR=$(cd "${MCP_REPO_ROOT_PATH}/docker"; pwd)
DOCKER_TAG=${1:-latest}
DOCKER_PUSH=${2---push}  # pass an empty second arg to disable push
CACHE_INVALIDATE=${CACHE_INVALIDATE:-0}
SALT_VERSION='stable 2017.7'

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

pushd "${DEPLOY_DIR}" > /dev/null

# Install distro packages and pip-managed prerequisites
notify "[NOTE] Installing required build-time distro and pip pkgs" 2
jumpserver_pkg_install 'build'
PYTHON_BIN_PATH="$(python3 -m site --user-base)/bin"
PATH="$PATH:$PYTHON_BIN_PATH"
# Clone git submodules and apply our patches
make -C "${MCP_REPO_ROOT_PATH}/mcp/patches" deepclean patches-import
python3 -m pip install --upgrade pipenv --user
docker_install

popd > /dev/null
pushd "${DOCKER_DIR}" > /dev/null

env PIPENV_HIDE_EMOJIS=1 VIRTUALENV_ALWAYS_COPY=1 python3 -m pipenv --three install
env PIPENV_HIDE_EMOJIS=1 VIRTUALENV_ALWAYS_COPY=1 python3 -m pipenv install invoke
# shellcheck disable=SC2086
env PIPENV_HIDE_EMOJIS=1 python3 -m pipenv run \
  invoke build saltmaster-reclass \
    --require 'salt salt-formulas opnfv reclass tini-saltmaster' \
    --dist=ubuntu \
    --dist-rel=bionic \
    --formula-rev=nightly \
    --opnfv-tag="${DOCKER_TAG}" \
    --salt="${SALT_VERSION}" \
    --build-arg-extra " \
        CACHE_INVALIDATE=\"${CACHE_INVALIDATE}\"" \
    ${DOCKER_PUSH}

env PIPENV_HIDE_EMOJIS=1 python3 -m pipenv run \
  invoke build saltminion-maas \
    --require 'maas' \
    --dist=ubuntu \
    --dist-rel=bionic \
    --opnfv-tag="${DOCKER_TAG}" \
    --salt="${SALT_VERSION}" \
    ${DOCKER_PUSH}

popd > /dev/null

#
# END of main
##############################################################################
