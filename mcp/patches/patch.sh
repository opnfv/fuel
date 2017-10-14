#!/bin/bash -ex
##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

if [ -r "$1" ]; then
  while IFS=': ' read -r p_dest p_file; do
    if [[ "${p_dest}" =~ $2 ]]; then
      patch -fd "${p_dest}" -p1 < "/root/fuel/mcp/patches/${p_file}"
    fi
  done < "$1"
fi
