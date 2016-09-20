#!/bin/bash
##############################################################################
# Copyright (c) 2015,2016 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Try to choose close ubuntu mirror from mirrors.txt, but "whitewash" this
# against the full repo list to removed mirrors not up-to-date.

# Some Ubuntu mirrors seem less reliable for this type of mirroring -
# as they are discoved they can be added to the blacklist below in order
# for them not to be considered.
BLACKLIST="mirror.clibre.uqam.ca"

#NOTE: For now the mirror selection is disabled due to issues not yet
#      understood/resolved.
#for url in $((curl -s  https://launchpad.net/ubuntu/+archivemirrors | \
#              grep -P -B8 "statusUP|statusSIX" | \
#              grep -o -P "(f|ht)tp.*\""  | \
#              sed 's/"$//' | sort | uniq; \
#              curl -s http://mirrors.ubuntu.com/mirrors.txt | sort | uniq) | \
#              sort | uniq -d)
#do
#    host=$(echo $url | cut -d'/' -f3)
#    echo ${BLACKLIST} | grep -q ${host} && continue
#    if curl -s -o /dev/null --head --fail "$url"; then
#      echo $url
#      exit 0
#    else
#      continue
#    fi
#done

# If no suitable local mirror can be found,
# the default archive is returned instead.
echo "http://archive.ubuntu.com/ubuntu/"
