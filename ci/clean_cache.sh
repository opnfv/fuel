#!/bin/bash
##############################################################################
# Copyright (c) 2016 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Clean the build cache according to its expiry date. Invoke with the cache
# directory as the first argument.

if [ -z "$1" ]; then
  echo "No cache directory specified, exiting..."
  exit 1
else
  CACHEDIR=$1
  echo "Operating on cache $CACHEDIR"
fi

NOW=$(date '+%s')

cd $CACHEDIR
echo "Step 1, cleaning orphaned meta and blob files"
ls *.meta *.blob | sed 's/\..*//' | sort | uniq -u | xargs -n 1 -I {} sh -c "rm -vf {}.*"
echo "Step 2, cleaning expired files"
for cache in $(ls -1 *.meta | sed 's/\..*//')
do
  blob=${cache}.blob
  meta=${cache}.meta
  expiry=$(grep Expires: $meta | sed 's/Expires: *//')
  if [ $expiry -le $NOW ]; then
     echo "$cache expired $(date -d "@$expiry"), removing..."
     rm -f $blob $meta
  fi
done

