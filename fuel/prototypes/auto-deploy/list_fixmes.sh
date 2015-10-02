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

for file in `find . -type f -exec egrep -il "FIXME|TODO" {} \; \
    | grep -v list_fixmes.sh \
    | grep -v TODO.txt`
do
  echo "***** Things to fix in $file *****"
  egrep -i "FIXME|TODO" $file
  echo ""
done
