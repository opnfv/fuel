#!/bin/bash -e
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################


error_exit()
{
  echo "Error: $@"
  exit 1
}

if [ $# -ne 1 ]; then
  echo "Syntax: `basename $0` deafile"
  exit 1
fi

if [ ! -f $1 ]; then
    echo "No such DEA file: $1"
    exit 1
fi

tmpdir=$HOME/fueltmp2
rm -Rf $tmpdir
mkdir $tmpdir

topdir=$(dirname $(readlink -f $BASH_SOURCE))
. $topdir/functions/common.sh
. $topdir/functions/dea-api.sh $1

echo "API version: `dea getApiVersion`"

#echo "Cluster node id for node 1 is: `dea getClusterNodeId 1`"

err=1
echo "Verifying that expected functions are present..."
for function in \
    dea_getApiVersion \
    dea_getNodeRole \
    dea_getFuelIp \
    dea_getFuelNetmask \
    dea_getFuelGateway \
    dea_getFuelHostname \
    dea_getFuelDns \
    dea_convertMacToShortMac \
    dea_getProperty \
    dea_getClusterNodeId \
    dea
do
    if type $function &>/dev/null; then
        echo "$function: OK"
    else
        echo "$function: Missing!"
        err=0
    fi
done

if [ $err -eq 0 ]; then
    echo "Error in API!"
    exit 1
else
    echo "API functions OK."
    echo ""
fi

echo "Fuel IP address: `dea getFuelIp`"
echo "Fuel netmask: `dea getFuelNetmask`"
echo "Fuel gateway: `dea getFuelGateway`"
echo "Fuel hostname: `dea getFuelHostname`"
echo "Fuel DNS: `dea getFuelDns`"
echo "Short MAC of 11:22:33:44:55:66: `dea convertMacToShortMac 11:22:33:44:55:66`"

echo "Done"
