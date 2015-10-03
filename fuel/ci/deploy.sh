#!/bin/bash -x
set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

WORKSPACE=$(readlink -e ..)
ISO_LOCATION="$(readlink -f $(find $WORKSPACE -iname 'fuel*iso' -type f))"
INTERFACE="fuel"

cd "${WORKSPACE}/deploy"
./deploy_fuel.sh "$ISO_LOCATION" $INTERFACE 2>&1 | tee deploy_fuel.log
