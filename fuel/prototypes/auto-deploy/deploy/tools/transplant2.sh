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

# Return offset between DEA node id and cluster node id
getDeaNodeOffset()
{
    local baseId

    baseId=`fuel node | tail -n +3 | awk '{ print $1 }' | sed 's/ //g' | sort -n | head -1`
    echo "$[baseId - 1]"
}

tmpDir=`mktemp -d /tmp/deaXXXX`

export PATH=`dirname $0`:$PATH

if [ $# -ne 1 ]; then
  error_exit "Argument error"
fi
deaFile=$1

if [ ! -f "$deaFile" ]; then
  error_exit "Can't find $deaFile"
fi


if [ `fuel env | tail -n +3 | grep -v '^$' | wc -l` -ne 1 ]; then
  error_exit "Not exactly one environment"
fi
envId=`fuel env | tail -n +3 | grep -v '^$' | awk '{ print $1 }'`

# Phase 1: Graft deployment information
fuel deployment --env $envId --default --dir $tmpDir || \
  error_exit "Could not dump environment"

for controller in `find $tmpDir -type f | grep -v compute`
do
  transplant_network_scheme.py $controller $deaFile controller || \
    error_exit "Failed to graft `basename $controller`"

  transplant_opnfv_settings.py $controller $deaFile controller || \
    error_exit "Failed to graft `basename $controller`"
done

for compute in `find $tmpDir -type f | grep compute`
do
  transplant_network_scheme.py $compute $deaFile compute || \
    error_exit "Failed to graft `basename $compute`"

  transplant_opnfv_settings.py $compute $deaFile compute || \
    error_exit "Failed to graft `basename $controller`"
done

fuel deployment --env $envId --upload --dir $tmpDir || \
  error_exit "Could not upload environment"

# Phase 2: Graft interface information
deaOffset=`getDeaNodeOffset`
echo "DEA offset: $deaOffset"

for clusterNodeId in `fuel node | grep True | awk '{ print $1}'`
do
    deaNodeId=$[clusterNodeId - deaOffset]
    echo "Node $clusterNodeId is $deaNodeId"
    fuel node --node-id $clusterNodeId --network --download --dir $tmpDir || \
        error_exit "Could not download node $clusterNodeId"

    transplant_interfaces.py ${tmpDir}/node_${clusterNodeId}/interfaces.yaml \
        $deaFile $deaNodeId || \
        error_exit "Failed to graft interfaces"

    fuel node --node-id $clusterNodeId --network --upload --dir $tmpDir || \
        error_exit "Could not upload node $clusterNodeId"
done



