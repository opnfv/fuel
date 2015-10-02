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

if [ $# -lt 2 ]; then
    error_exit "`basename $0`: <deafile> <dhafile> <comment>"
fi

deafile=$1
dhafile=$2
shift 2

if [ $# -ne 0 ]; then
    comment="$@"
else
    comment=""
fi

if [ -f $deafile ]; then
    error_exit "$deafile already exists"
elif [ -f $dhafile ]; then
    error_exit "$dhafile already exists"
fi

# Create headers

cat >$deafile << EOF
title: Deployment Environment Adapter (DEA)
# DEA API version supported
version: 1.1
created: `date`
comment: $comment
EOF

cat >$dhafile << EOF
title: Deployment Hardware Adapter (DHA)
# DHA API version supported
version: 1.1
created: `date`
comment: $comment

# Adapter to use for this definition
adapter: 

# Node list.
# Mandatory properties are id and role.
# The MAC address of the PXE boot interface for Fuel is not
# mandatory to be defined.
# All other properties are adapter specific.

EOF

if [ `fuel env | tail -n +3 | grep -v '^$' | wc -l` -ne 1 ]; then
    error_exit "Not exactly one environment"
fi
envId=`fuel env | tail -n +3 | grep -v '^$' | awk '{ print $1 }'`

computeId=`fuel node | grep compute | grep True | head -1 | awk '{ print $1}'`
controllerId=`fuel node | grep controller | grep True | head -1 | awk '{ print $1}'`

if [ -z "$computeId" ]; then
    error_exit "Could not find any compute node"
elif [ -z "$controllerId" ]; then
    error_exit "Could not find any controller node"
fi

fuel deployment --env $envId --download --dir $tmpDir > /dev/null || \
    error_exit "Could not get deployment info"
fuel settings --env $envId --download --dir $tmpDir > /dev/null || \
    error_exit "Could not get settings"
fuel network --env $envId --download --dir $tmpDir > /dev/null || \
    error_exit "Could not get network settings"

# Create node structure for DEA mapping to the DHA
# Note! Nodes will be renumbered to always start with id 1
echo "nodes:" >> $deafile
echo "nodes:" >> $dhafile
minNode=`fuel node | tail -n +3 | sed 's/ .*//' | sort -n | head -1`
for realNodeId in `fuel node | tail -n +3 | sed 's/ .*//' | sort -n`
do
    nodeId=$[realNodeId - minNode + 1]
    role=`fuel node --node-id $realNodeId | tail -n +3 | cut -d "|" -f 7 | sed 's/ //g'` || \
        error_exit "Could not get role for node $realNodeId"

    if [ -z "$role" ]; then
        error_exit "Node $realNodeId has no role - is this environment really deployed?"
    fi

    fuel node --node-id $realNodeId --network --download --dir $tmpDir > /dev/null || \
        error_exit "Could not get network info for node $controllerId"

    generate_node_info.py $nodeId $role $tmpDir/node_${realNodeId}/interfaces.yaml $dhafile | \
        grep -v "^nodes:" >> $deafile || \
        error_exit "Could not extract info for node $realNodeId"
done

cat >>$dhafile <<EOF
# Adding the Fuel node as node id $[nodeId + 1] which may not be correct - please
# adjust as needed.
EOF
generate_fuel_node_info.py $[nodeId +1] $dhafile || \
    error_exit "Could not extract info for the Fuel node"

# Environment mode
echo "environment_mode: `fuel env | tail -n +3 | cut -d "|" -f 4 | sed 's/ //g' | sed 's/ha_compact/ha/'`" \
    >>$deafile || error_exit "Could not get environment mode"

echo "environment_name: `fuel env | tail -n +3 | cut -d "|" -f 3 | sed 's/ //g'`" \
    >>$deafile || error_exit "Could not get environment mode"

reap_fuel_settings.py $deafile fuel || \
    error_exit "Could not extract Fuel node settings"

# TODO: Potentially move the network scheme into each node of the DEA nodes structure
# TODO: instead (this may be too generic to support all node types)
reap_network_scheme.py $tmpDir/deployment_${envId}/*controller_${controllerId}.yaml \
    $deafile controller || error_exit "Could not extract network scheme for controller"

# TODO: Potentially move the network scheme into each node of the DEA nodes structure
# TODO: instead (this may be too generic to support all node types)
reap_network_scheme.py $tmpDir/deployment_${envId}/compute_${computeId}.yaml $deafile \
    compute ||  error_exit "Could not extract network scheme for compute"

reap_opnfv_astute.py $tmpDir/deployment_${envId}/*controller_${controllerId}.yaml \
    $tmpDir/deployment_${envId}/compute_${computeId}.yaml ${deafile} || \
    error_exit "Could not extract opnfv info from astute"

reap_network_settings.py $tmpDir/network_${envId}.yaml $deafile network || \
    error_exit "Could not extract network settings"


reap_settings.py $tmpDir/settings_${envId}.yaml $deafile settings || \
    error_exit "Could not extract settings"

# Last part of the DHA file
cat >>$dhafile << EOF

# Deployment power on strategy
# all:      Turn on all nodes at once. There will be no correlation
#           between the DHA and DEA node numbering. MAC addresses
#           will be used to select the node roles though.
# sequence: Turn on the nodes in sequence starting with the lowest order
#           node and wait for the node to be detected by Fuel. Not until
#           the node has been detected and assigned a role will the next
#           node be turned on.
powerOnStrategy: sequence

# If fuelCustomInstall is set to true, Fuel is assumed to be installed by
# calling the DHA adapter function "dha_fuelCustomInstall()"  with two
# arguments: node ID and the ISO file name to deploy. The custom install
# function is then to handle all necessary logic to boot the Fuel master
# from the ISO and then return.
# Allowed values: true, false

fuelCustomInstall: false
EOF

# Cleanup due to a currently unknown Fuel behavior adding this
# output at certain stages, this information should not be present:
sed -i '/ management_vip: ' $deafile
sed -i '/ public_vip: ' $deafile


echo "DEA file is available at $deafile"
echo "DHA file is available at $dhafile (this is just a template)"
