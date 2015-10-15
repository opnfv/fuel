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

usage() {
  cat <<EOF
Usage: `basename $0` [-r] <path>

 -r
    Recursively list all repos found starting at <path>
 -h
    Display help text
EOF
}

repoinfo() {
    repotop=$(git -C $1 rev-parse --show-toplevel)
    origin=$(git -C $repotop config --get remote.origin.url)
    sha1=$(git -C $repotop rev-parse HEAD)
    echo "$origin: $sha1"
}


if [ $# -eq 2 ]; then
    case $1 in
        -r)
            RECURSE=1
            shift
            ;;
        -h)
            usage
            exit 0
            ;;
        *)
            echo "Error, argument $1 not known" >&2
            usage
            exit 1
    esac
fi

if [ $# -gt 1 ]; then
    echo "Error, too many arguments" >&2
    usage
    exit 1
fi

abspath=$(readlink -f $1)

if [ -n "$RECURSE" ]; then
    for dir in $(find $abspath -type d -name .git)
    do
        repoinfo $(readlink -f $dir/..)
    done
else
    repoinfo $abspath
fi
