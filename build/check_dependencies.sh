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

# Given a file as input, this script verifies that all URIs in the file can
# be fetched.

if [ $# -ne 1 ]; then
  echo "Usage: $(basename $0) <filename>"
  exit 1
fi

if [ ! -e $1 ]; then
  echo "Could not open $1"
  exit 1
fi

echo "Checking dependencies in $1"
rc=0
for uri in `cat $1`
do
  if ! curl -sfr 0-100 $uri > /dev/null; then
    echo "Failed fetching $uri" >&2
    rc=1
  fi
done

if [ $rc -ne 0 ]; then
  echo "ERROR checking dependencies in $1"
else
  echo "Dependencies OK"
fi

exit $rc
