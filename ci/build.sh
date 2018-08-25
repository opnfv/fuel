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

source "${DEPLOY_DIR}/globals.sh"
source "${DEPLOY_DIR}/lib.sh"

[ ! "${TERM:-unknown}" = 'unknown' ] || export TERM=vt220

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
pip install pipenv --user
docker_install

popd > /dev/null
pushd "${DOCKER_DIR}" > /dev/null

pipenv --two
pipenv install
pipenv install invoke
pipenv run \
  invoke build saltmaster-reclass \
    --require 'salt salt-formulas opnfv reclass tini-saltmaster' \
    --dist=ubuntu \
    --dist-rel=xenial \
    --formula-rev=nightly \
    --opnfv-tag="${DOCKER_TAG}" \
    --salt='stable 2017.7' \
    "${DOCKER_PUSH}"

popd > /dev/null

#
# END of main
##############################################################################
