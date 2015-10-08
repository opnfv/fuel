#!/bin/bash

RSYNC="rsync -4 --contimeout 5 --no-motd --list-only"

# try to choose close ubuntu mirror which support rsync protocol
# https://bugs.launchpad.net/fuel/+bug/1459252

# A slight adaptation of Michal Skalski's original Makefile version
# to remove repos very update is in progress - which is also why the
# script waits for an hour.

cnt=0
while [ $cnt -lt 60 ]
do
    for url in $(curl -s http://mirrors.ubuntu.com/mirrors.txt)
    do
        host=$(echo $url | cut -d'/' -f3)
        if $RSYNC "${host}::ubuntu/." &> /dev/null
        then
            if ! $RSYNC "${host}::ubuntu/Archive-Update-in-Progress*" &> /dev/null
            then
                echo "$host"
                exit 0
            fi
        fi
    done
    cnt=$[cnt + 1]
    sleep 1
done
exit 1
