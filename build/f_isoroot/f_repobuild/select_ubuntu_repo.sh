#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
RSYNC="rsync -4 --contimeout 5 --no-motd --list-only"

# try to choose close ubuntu mirror which support rsync protocol
# https://bugs.launchpad.net/fuel/+bug/1459252

# A minor modificiation of Michal Skalski's original Makefile version
# to only consider repos where no repo updates are in progress (as
# that may have us hanging quite a while otherwise). If no suitable
# local mirror can be found after four attempts, the default archive
# is returned instead.

# Some Ubuntu mirrors seem less reliable for this type of mirroring -
# as they are discoved they can be added to the blacklist below in order
# for them not to be considered.
BLACKLIST="mirrors.se.eu.kernel.org"

return_url=0

while [ "$1" != "" ]; do
    case $1 in
        -u | --url )   shift
                       return_url=1
                       ;;
    # Shift all the parameters down by one
    esac
    shift
done

cnt=0
while [ $cnt -lt 4 ]
do
    for url in $(curl -s http://mirrors.ubuntu.com/mirrors.txt)
    do
        host=$(echo $url | cut -d'/' -f3)
	echo ${BLACKLIST} | grep -q ${host} && continue
        if $RSYNC "${host}::ubuntu/." &> /dev/null
        then
            if ! $RSYNC "${host}::ubuntu/Archive-Update-in-Progress*" &> /dev/null
            then
                if [ "$return_url" = "1" ]; then
                    echo "$url"
                    exit 0
                else
                    echo "$host"
                    exit 0
                fi
            fi
        fi
    done
    cnt=$[cnt + 1]
    sleep 15
done

if [ "$return_url" = "1" ]; then
    echo "http://archive.ubuntu.com/ubuntu/"
else
    echo "archive.ubuntu.com"
fi
