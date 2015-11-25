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

CACHETRANSPORT=${CACHETRANSPORT:-"curl --silent"}
CACHEBASE=${CACHEBASE:-"file://${HOME}/cache"}
CACHEMAXAGE=${CACHEMAXAGE:-$[14*24*3600]}
CACHEDEBUG=${CACHEDEBUG:-1}

debugmsg () {
    if [ "$CACHEDEBUG" -eq 1 ]; then
        echo "$@" >&2
    fi
}

errormsg () {
    echo "$@" >&2
}

# Get a SHA1 based on what's piped into the cache command
getid() {
    debugmsg "Generating sha1sum"
    sha1sum | sed 's/ .*//'
}


# Put in cache
put() {
    if check $1; then
       debugmsg "SHA1 $1 already in cache, skipping storage"
    else
        debugmsg "Storing SHA1 $1 in cache"
        ${CACHETRANSPORT} -T - ${CACHEBASE}/$1.blob
        echo "Expires: $[`date +"%s"` + $CACHEMAXAGE]" | ${CACHETRANSPORT} -T - ${CACHEBASE}/$1.meta
    fi
    exit 0
}

# Get from cache
get() {
    local rc

    ${CACHETRANSPORT} -o - ${CACHEBASE}/$1.blob 2>/dev/null
    rc=$?

    if [ $rc -eq 0 ]; then
        echo "Got SHA1 $1 from cache" 2>/dev/null
    else
        echo "Tried to get SHA1 $1 from cache but failed" 2>/dev/null
    fi

    return $?
}

# Check if in cache
check() {
    local rc

    ${CACHETRANSPORT} ${CACHEBASE}/$1.meta &>/dev/null
    rc=$?

    if [ $rc -eq 0 ]; then
        debugmsg "Checking for SHA1 $1 in cache and found it, rc = $rc"
    else
        debugmsg "Checking for SHA1 $1 in cache and failed, rc = $rc"
    fi

    return $rc
}

# Verify that SHA1 seems to be a SHA1...
validSHA1() {
    if [ $(echo $1 | wc -c) -ne 41 ]; then
        return 1
    else
        return 0
    fi
}

case $1 in
    getid)
        if [ $# -ne 1 ]; then
            errormsg "No arguments can be given to getid!"
            exit 1
        fi
        getid
        ;;
    get|check|put)
        if [ $# -ne 2 ]; then
            errormsg "Only one argument, the SHA1 sum, can be given to getid!"
            exit 1
        else
            if ! validSHA1 $2; then
                errormsg "Invalid SHA1 format!"
                exit 1
            fi
        fi

        $1 $2
        exit $rc
        ;;
    *)
        errormsg "I only know about getid, check, get and put!"
        exit 1
esac
