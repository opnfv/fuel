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


exit_trap() {
    if [ -d "$TMPDIR" ]; then
        rm -rf $TMPDIR
    fi
}

trap exit_trap EXIT

CACHETRANSPORT=${CACHETRANSPORT:-"curl --silent"}
CACHEMAXAGE=${CACHEMAXAGE:-$[14*24*3600]}
CACHEDEBUG=${CACHEDEBUG:-1}

debugmsg () {
    if [ "$CACHEDEBUG" -eq 1 ]; then
        echo "$@" >&2
    fi
}

errorexit () {
    echo "$@" >&2
    exit 1
}

# Generate a unique number every two weeks - a service routine that
# can be used when generating the SHA1 to make sure that the cache is
# rebuilt bi-weekly even if no pruning of the cache is taking place.
getbiweek () {
  echo "$(date +'%G')$[10#$(date +'%V')/2]"
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

# Figure out commit ID from URI and tag/branch/commit ID
getcommitid() {
    if echo $2 | grep -q '^refs/changes/'; then
        REF=`echo $2 | sed "s,refs\/changes\/\(.*\),\1,"`
    else
        REF=$2
    fi

    echo "Repo is $1, ref is ${REF}" >&2

    HEADMATCH=`git ls-remote $1 | grep "refs/heads/${REF}$" | awk '{ print $1 }'`
    TAGMATCH=`git ls-remote $1 | grep "refs/tags/${REF}$" | awk '{ print $1 }'`
    CHANGEMATCH=`git ls-remote $1 | grep "refs/changes/${REF}$" | awk '{ print $1 }'`

    if [ -n "$HEADMATCH" ]; then
        echo "$HEADMATCH"
    elif [ -n "$TAGMATCH" ]; then
        echo "$TAGMATCH"
    elif [ -n "$CHANGEMATCH" ]; then
        echo "Warning: ${REF} is a change!" >&2
        TMPDIR=`mktemp -d /tmp/cacheXXXXX`
        cd $TMPDIR
        git clone $1 &>/dev/null || errorexit "Could not clone $1"
        cd * || errorexit "Could not enter clone of $1"
	git fetch $1 refs/changes/$REF &>/dev/null || errorexit "Could not fetch change"
	git checkout FETCH_HEAD &>/dev/null || errorexit "Could not checkout FETCH_HEAD"
        git show HEAD &>/dev/null || errorexit "Could not find commit $2"
        git show HEAD | head -1 | awk '{ print $2 }'
    else
        TMPDIR=`mktemp -d /tmp/cacheXXXXX`
        cd $TMPDIR
        git clone $1 &>/dev/null || errorexit "Could not clone $1"
        cd * || errorexit "Could not enter clone of $1"
        git show $2 &>/dev/null || errorexit "Could not find commit $2"
        git show $2 | head -1 | awk '{ print $2 }'
    fi
}



if [ -z "$CACHEBASE" ]; then
  errorexit "CACHEBASE not set - exiting..."
fi

case $1 in
    getbiweek)
        if [ $# -ne 1 ]; then
            errorexit "No arguments can be given to getbiweek!"
        fi
        getbiweek
        ;;
    getcommitid)
        if [ $# -ne 3 ]; then
            errorexit "Arg 1 needs to be URI and arg 2 tag/branch/commit"
        fi
        shift
        getcommitid $@
        ;;
    getid)
        if [ $# -ne 1 ]; then
            errorexit "No arguments can be given to getid!"
        fi
        getid
        ;;
    get|check|put)
        if [ $# -ne 2 ]; then
            errorexit "Only one argument, the SHA1 sum, can be given to getid!"
        else
            if ! validSHA1 $2; then
                errorexit "Invalid SHA1 format!"
            fi
        fi

        $1 $2
        exit $rc
        ;;
    *)
        errorexit "I only know about getcommitid, getid, check, get and put!"
esac
