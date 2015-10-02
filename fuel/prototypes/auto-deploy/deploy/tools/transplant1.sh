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

cleanup () {
  if [ -n "$tmpDir" ]; then
    rm -Rf $tmpDir
  fi
}

trap cleanup exit

error_exit () {
  echo "Error: $@" >&2
  exit 1
}

tmpDir=`mktemp -d /tmp/deaXXXX`

export PATH=`dirname $0`:$PATH

if [ $# -lt 1 ]; then
  error_exit "Argument error"
fi
deafile=$1
shift

if [ ! -f "$deafile" ]; then
  error_exit "Can't find $deafile"
fi

if [ `fuel env | tail -n +3 | grep -v '^$' | wc -l` -ne 1 ]; then
  error_exit "Not exactly one environment"
fi
envId=`fuel env | tail -n +3 | grep -v '^$' | awk '{ print $1 }'`

fuel settings --env $envId --download --dir $tmpDir > /dev/null || \
  error_exit "Could not get settings"

fuel network --env $envId --download --dir $tmpDir > /dev/null || \
  error_exit "Could not get network settings"

cp $tmpDir/network_${envId}.yaml network_before.yaml

# Transplant network settings
transplant_network_settings.py $tmpDir/network_${envId}.yaml $deafile || \
  error_exit "Could not transplant network settings"
fuel network --env $envId --upload --dir $tmpDir || \
  error_exit "Could not update network settings"
cp $tmpDir/network_${envId}.yaml network_after.yaml

# Transplant settings
cp $tmpDir/settings_${envId}.yaml settings_before.yaml
transplant_settings.py $tmpDir/settings_${envId}.yaml $deafile || \
  error_exit "Could not transplant settings"
fuel settings --env $envId --upload --dir $tmpDir || \
  error_exit "Could not update settings"
cp $tmpDir/settings_${envId}.yaml settings_after.yaml


