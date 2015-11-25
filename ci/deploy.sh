#!/bin/bash
set -o errexit
topdir=$(dirname $(readlink -f $BASH_SOURCE))
deploydir=$(cd ${topdir}/../deploy; pwd)
pushd ${deploydir} > /dev/null
echo -e "python deploy.py $@\n"
python deploy.py $@
popd > /dev/null