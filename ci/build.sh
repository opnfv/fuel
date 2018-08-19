#!/bin/bash -e
# shellcheck disable=SC1004,SC1090
##############################################################################
# Copyright (c) 2018 Ericsson AB, Mirantis Inc., Enea AB and others.
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

source "${DEPLOY_DIR}/globals.sh"
source "${DEPLOY_DIR}/lib.sh"

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

pushd "${DOCKER_DIR}" > /dev/null

# Install distro pacakge and pip-managed prerequisites
notify "[NOTE] Installing required build-time distro and pip pkgs" 2
jumpserver_pkg_install 'build'
pip install pipenv --user
docker_install

# NOTE: We do not include the system reclass classes in the image (yet).
pipenv --two
pipenv install
pipenv shell \
  "invoke build saltmaster-reclass \
    --require 'salt salt-formulas reclass tini-saltmaster' \
    --dist=ubuntu \
    --dist-rel=xenial \
    --formula-rev=nightly \
    --opnfv-tag='${DOCKER_TAG}' \
    --salt='stable 2017.7'; \
  exit"

popd > /dev/null

#
# END of main
##############################################################################
