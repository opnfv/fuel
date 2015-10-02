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


dha_f_err()
{
    local rc
    local cmd

    rc=$1
    shift

    echo "$@" >&2
    echo "Exit with code $rc" >&2

    exit $rc
}

dha_f_run()
{
  $@
  rc=$?
  if [ $rc -ne 0 ]; then
     dha_f_err $rc "running $@" >&2
     exit $rc
  fi
}

# Internal functions END
########################################################################


true=0
false=1

# API: Get the DHA API version supported by this adapter
dha_getApiVersion ()
{
    echo "1.0"
}

# API: Get the name of this adapter
dha_getAdapterName ()
{
    echo "libvirt"
}

# API: ### Node identity functions ###
# API: Node numbering is sequential.

# API: Get a list of all defined node ids, sorted in ascending order
dha_getAllNodeIds()
{
    dha_f_run $DHAPARSE $DHAFILE getNodes | sort -n
}


# API: Get ID for Fuel node ID
dha_getFuelNodeId()
{
    for node in `dha_getAllNodeIds`
    do
        if [ -n "`dha_f_run $DHAPARSE $DHAFILE getNodeProperty $node isFuel`" ]
        then
            echo $node
        fi
    done
}

# API: Get node property
# API: Argument 1: node id
# API: Argument 2: Property
dha_getNodeProperty()
{
    dha_f_run $DHAPARSE $DHAFILE getNodeProperty $1 $2
}


# API: Get MAC address for the PXE interface of this node. If not
# API: defined, an empty string will be returned.
# API: Argument 1: Node id
dha_getNodePxeMac()
{
    dha_getNodeProperty $1 pxeMac
}


### Node operation functions ###

# API: Use custom installation method for Fuel master?
# API: Returns 0 if true, 1 if false
dha_useFuelCustomInstall()
{
    $DHAPARSE $DHAFILE get fuelCustomInstall | grep -qi true
    rc=$?
    return $rc
}

# API: Fuel custom installation method
# API: Leaving the Fuel master powered on and booting from ISO at exit
# API: Argument 1: Full path to ISO file to install
dha_fuelCustomInstall()
{
    dha_useFuelCustomInstall || dha_f_err 1 "dha_fuelCustomInstall not supported"
    date
}

# API: Get power on strategy from DHA
# API: Returns one of two values:
# API:   all:        Power on all nodes simultaneously
# API:   sequence:   Power on node by node, wait for Fuel detection
dha_getPowerOnStrategy()
{
    local strategy

    strategy=`$DHAPARSE $DHAFILE get powerOnStrategy`

    if [ "$strategy" == "all" ]; then
        echo $strategy
    elif
        [ "$strategy" == "sequence" ]; then
        echo $strategy
    else
        dha_f_err 1 "Could not parse strategy from DHA, got $strategy"
    fi
}


# API: Power on node
# API: Argument 1: node id
dha_nodePowerOn()
{
    local state
    local virtName

    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    state=`virsh domstate $virtName`
    if [ "$state" == "shut off" ]; then
        dha_f_run virsh start $virtName
    fi
}

# API: Power off node
# API: Argument 1: node id
dha_nodePowerOff()
{
    local state
    local virtName

    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    state=`virsh domstate $virtName`
    if [ "$state" != "shut off" ]; then
        dha_f_run virsh destroy $virtName
    fi
}

# API: Reset node
# API: Argument 1: node id
dha_nodeReset()
{
    local virtName

    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    dha_f_run virsh reset $virtName
}

# Boot order and ISO boot file

# API: Is the node able to commit boot order without power toggle?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanSetBootOrderLive()
{
  return $false
}

# API: Set node boot order
# API: Argument 1: node id
# API: Argument 2: Space separated line of boot order - boot ids are "pxe", "disk" and "iso"
dha_nodeSetBootOrder()
{
    local id
    local bootline
    local virtName
    local order

    id=$1
    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    shift

    for order in $@
    do
        if [ "$order" == "pxe" ]; then
            bootline+="<boot dev='network'\/>\n"
        elif [ "$order" == "disk" ]; then
            bootline+="<boot dev='hd'/\>\n"
        elif [ "$order" == "iso" ]; then
            bootline+="<boot dev='cdrom'/\>\n"
        else
            error_exit "Unknown boot type: $order"
        fi
    done
    echo $bootline

    virsh dumpxml $virtName | grep -v "<boot dev.*>" | \
        sed "/<\/os>/i\
    ${bootline}" > $tmpdir/vm.xml || error_exit "Could not set bootorder"
    virsh define $tmpdir/vm.xml || error_exit "Could not set bootorder"

}

# API: Is the node able to operate on ISO media?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanSetIso()
{
  return $true
}

# API: Is the node able to insert add eject ISO files without power toggle?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanHandeIsoLive()
{
  return $true
}

# API: Insert ISO into virtualDVD
# API: Argument 1: node id
# API: Argument 2: iso file
dha_nodeInsertIso()
{
    local virtName
    local isoFile

    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    isoFile=$2
    virsh change-media $virtName --insert hdc $isoFile
}

# API: Eject ISO from virtual DVD
# API: Argument 1: node id
dha_nodeEjectIso()
{
    local virtName
    local isoFile

    virtName=`$DHAPARSE $DHAFILE getNodeProperty $1 libvirtName`
    isoFile=$2
    virsh change-media $virtName --eject hdc
}

# API: Wait until a suitable time to change the boot order to
# API: "disk iso" when ISO has been booted. Can't be too long, nor
# API: too short...
# API: We should make a smart trigger for this somehow...
dha_waitForIsoBoot()
{
    echo "waitForIsoBoot: No delay necessary for libvirt"
}

# API: Is the node able to reset its MBR?
# API: Returns 0 if true, 1 if false
dha_nodeCanZeroMBR()
{
    return $true
}

# API: Reset the node's MBR
dha_nodeZeroMBR()
{
    local fueldisk
    local disksize

    fueldisk=`virsh dumpxml $(dha_getNodeProperty $1 libvirtName) | \
     grep "<source file" | grep raw | sed "s/.*'\(.*\)'.*/\1/"`
    disksize=`ls -l $fueldisk | awk '{ print $5 }'`
    rm -f $fueldisk
    fallocate -l $disksize $fueldisk
}


# API: Entry point for dha functions
# API: Typically do not call "dha_node_zeroMBR" but "dha node_ZeroMBR"
# API:
# API: Before calling dha, the adapter file must gave been sourced with
# API: the DHA file name as argument
dha()
{
    if [ -z "$DHAFILE" ]; then
        error_exit "dha_setup has not been run"
    fi


    if type dha_$1 &>/dev/null; then
        cmd=$1
        shift
        dha_$cmd $@
        return $?
    else
        error_exit "No such function dha_$1 defined"
    fi
}

if [ "$1" == "api" ]; then
  egrep "^# API: |dha.*\(\)" $0 | sed 's/^# API: /# /' | grep -v dha_f_ | sed 's/)$/)\n/'
else
    dhatopdir=$(dirname $(readlink -f $BASH_SOURCE))
    DHAPARSE="$dhatopdir/dhaParse.py"
    DHAFILE=$1

    if [ ! -f $DHAFILE ]; then
        error_exit "No such DHA file: $DHAFILE"
    else
        echo "Adapter init"
        echo "$@"
        echo "DHAPARSE: $DHAPARSE"
        echo "DHAFILE: $DHAFILE"
    fi

fi
