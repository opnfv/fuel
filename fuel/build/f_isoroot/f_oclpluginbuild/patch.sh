#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Jonas Bjurel and others.
# jonasbjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

#############################################################################
# Patch operation - patches git root directory based on content in ./patch
#############################################################################

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`

usage() {
    me=$(basename $0)
    my_path=$(basename $SCRIPT_PATH)
    cat << EOF
usage:
$me [generate_cache_id]
Patches ${my_path} according to ${my_path}/patch.
If "generate_cache_id" is provided as argument, a set of cache-id
sums based on the patch directory content are calculated.
EOF
}

if [ -z  $1 ]; then
    echo "================== PATCHING ${SCRIPT_PATH} =================="
    cd ${SCRIPT_PATH}/patch && patches=`find -name "*.patch"`
    for patch in $patches
    do
        orig_file="${patch%.*}"
        patch_file="patch/${patch#./}"
        cd ${SCRIPT_PATH} && [ ! -d ${orig_file%/*} ] && mkdir -p ${orig_file%/*}
        cd ${SCRIPT_PATH} && [ -d ${orig_file#./} ] || [ -e ${orig_file#./} ] && chmod +w ${orig_file#./}
        echo "patch ${SCRIPT_PATH}/${orig_file#./} ${SCRIPT_PATH}/${patch_file}"
        set +e
        cd ${SCRIPT_PATH} && patch ${orig_file} ${patch_file}
        rc=$?
        set -e
        if [ $rc -ne 0 ]; then
            echo "Fuel@OPNFV/OpenContrail: ${patch} needs to be manually rebased"
            echo "Following differences must be rebased:"
            diff patch/${orig_file#./}.orig ${orig_file}
            echo "Exiting ....."
            exit $rc
        fi
    done
else
    if [ "$1" == "generate_cache_id" ]; then
        echo $(sha1sum $0 | awk {'print $1'})
        cd ${SCRIPT_PATH}/patch && PATCHES=`find -name "*"`
        for file in $PATCHES
        do
            [ ! -d $file ] && echo $(sha1sum $file | awk {'print $1'})
        done
    else
        usage
        exit 1
    fi
fi
exit
