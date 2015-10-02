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



########################################################################
# Internal functions BEGIN



dea_f_err()
{
    local rc
    local cmd

    rc=$1
    shift

    if [ -n "$rc" ]; then
        echo "Error ($rc): $@" >&2
    else
        echo "Error: $@" >&2
    fi
}

dea_f_run()
{
  $@
  rc=$?
  if [ $rc -ne 0 ]; then
     dea_f_err $rc "Error running $@"
     return $rc
  fi
}

# Internal functions END
########################################################################

true=0
false=1

# API: Get the DEA API version supported by this adapter
dea_getApiVersion ()
{
    echo "1.0"
}


# API: Node numbering is sequential.


# API: Get the role for this node
# API: Argument 1: node id
dea_getNodeRole()
{
    $DEAPARSE $DEAFILE getNodeRole $@

}

# API: Get IP address of Fuel master
dea_getFuelIp()
{
    $DEAPARSE $DEAFILE getProperty fuel ADMIN_NETWORK ipaddress
}

# API: Get netmask Fuel master
dea_getFuelNetmask()
{
    $DEAPARSE $DEAFILE getProperty fuel ADMIN_NETWORK netmask
}

# API: Get gateway address of Fuel master
# FIXME: This is currently not in the DEA, so make the gatway the ..1
# FiXME: of the IP
dea_getFuelGateway()
{
    $DEAPARSE $DEAFILE getProperty fuel ADMIN_NETWORK ipaddress | \
         sed 's/.[0-9]*$/.1/'
}

# API: Get gateway address of Fuel master
dea_getFuelHostname()
{
    $DEAPARSE $DEAFILE getProperty fuel HOSTNAME
}

# API: Get DNS address of Fuel master
dea_getFuelDns()
{
    $DEAPARSE $DEAFILE getProperty fuel DNS_UPSTREAM
}

# API: Convert a normal MAC to a Fuel short mac for --node-id
dea_convertMacToShortMac()
{
    echo $1 | sed 's/.*..:..:..:..:\(..:..\).*/\1/' | tr [A-Z] [a-z]
}


# API: Get property from DEA file
# API: Argument 1: search path, as e.g. "fuel ADMIN_NETWORK ipaddress"
dea_getProperty()
{
    $DEAPARSE $DEAFILE getProperty $@
}

# API: Convert DHA node id to Fuel cluster node id
# API: Look for lowest Fuel node number, this will be DHA node 1
# API: Argument: node id
dea_getClusterNodeId()
{
    local baseId
    local inId
    local fuelIp

    inId=$1
    fuelIp=`dea_getFuelIp`

    baseId=`ssh root@${fuelIp} fuel node | tail -n +3 | awk '{ print $1 }'| sed 's/ //g' | sort -n | head -1`
    echo "$[inId + baseId - 1]"
}

# API: Entry point for dea functions
# API: Typically do not call "dea_node_zeroMBR" but "dea node_ZeroMBR"
# API:
# API: Before calling dea, the adapter file must gave been sourced with
# API: the DEA file name as argument
dea()
{
    if [ -z "$DEAFILE" ]; then
        error_exit "dea_setup has not been run"
    fi


    if type dea_$1 &>/dev/null; then
        cmd=$1
        shift
        dea_$cmd $@
        return $?
    else
        error_exit "No such function dea_$1 defined"
    fi
}

if [ "$1" == "api" ]; then
  egrep "^# API: |dea.*\(\)" $0 | sed 's/^# API: /# /' | grep -v dea_f_ | sed 's/)$/)\n/'
else
    deatopdir=$(dirname $(readlink -f $BASH_SOURCE))
    DEAPARSE="$deatopdir/deaParse.py"
    DEAFILE=$1

    if [ ! -f $DEAFILE ]; then
        error_exit "No such DEA file: $DEAFILE"
    else
        echo "Adapter init"
        echo "$@"
        echo "DEAPARSE: $DEAPARSE"
        echo "DEAFILE: $DEAFILE"
    fi
fi



