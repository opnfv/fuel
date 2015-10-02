#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

cleanup () {
    if [ -n "$tmpDir" ]; then
        rm -Rf $tmpDir
    fi
}

trap cleanup exit

error_exit () {
    echo "Error: $@" >&2
    exit 1
}

tmpDir=`mktemp -d /tmp/deaXXXX`

export PATH=`dirname $0`:$PATH

if [ $# -lt 1 ]; then
    error_exit "Argument error"
fi
deafile=$1
shift

if [ ! -f "$deafile" ]; then
    error_exit "Can't find $deafile"
fi

transplant_fuel_settings.py /etc/fuel/astute.yaml $deafile || \
    error_exit "Could not transplant astute settings"
