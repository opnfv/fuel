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


dha_f_ipmi()
{

    local nodeId
    local ipmiIp
    local ipmiUser
    local ipmiPass
    local i

    nodeId=$1
    shift

    ipmiIp=$($DHAPARSE $DHAFILE getNodeProperty $nodeId ipmiIp)
    ipmiUser=$($DHAPARSE $DHAFILE getNodeProperty $nodeId ipmiUser)
    ipmiPass=$($DHAPARSE $DHAFILE getNodeProperty $nodeId ipmiPass)

    test -n "$ipmiIp" || error_exit "Could not get IPMI IP"
    test -n "$ipmiUser" || error_exit "Could not get IPMI username"
    test -n "$ipmiPass" || error_exit "Could not get IPMI password"

    # Repeat three times for good measure (some hardware seems
    # weird)
    for i in 1 2
    do
        ipmitool -I lanplus -A password -H $ipmiIp -U $ipmiUser -P $ipmiPass \
            $@ >/dev/null 2>&1
        sleep 1
    done
    ipmitool -I lanplus -A password -H $ipmiIp -U $ipmiUser -P $ipmiPass \
        $@
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
    echo "ipmi"
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
    if [ ! -e $1 ]; then
	error_exit "Could not access ISO file $1"
    fi

    dha_useFuelCustomInstall || dha_f_err 1 "dha_fuelCustomInstall not supported"

    fuelIp=`dea getFuelIp` || error_exit "Could not get fuel IP"
    fuelNodeId=`dha getFuelNodeId` || error_exit "Could not get fuel node id"
    virtName=`$DHAPARSE $DHAFILE getNodeProperty $fuelNodeId libvirtName`

    # Power off the node
    virsh destroy $virtName
    sleep 5

    # Zero the MBR
    fueldisk=`virsh dumpxml $virtName | \
     grep "<source file" | grep raw | sed "s/.*'\(.*\)'.*/\1/"`
    disksize=`ls -l $fueldisk | awk '{ print $5 }'`
    rm -f $fueldisk
    fallocate -l $disksize $fueldisk

    # Set the boot order
    for order in disk iso
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

    virsh dumpxml $virtName | grep -v "<boot dev.*>" | \
        sed "/<\/os>/i\
    ${bootline}" > $tmpdir/vm.xml || error_exit "Could not set bootorder"
    virsh define $tmpdir/vm.xml || error_exit "Could not set bootorder"


    # Get name of CD device
    cdDev=`virsh domblklist $virtName | tail -n +3 | awk '{ print $1 }' | grep ^hd`

    # Eject and insert ISO
    virsh change-media $virtName --config --eject $cdDev
    sleep 5
    virsh change-media $virtName --config --insert $cdDev $1 || error_exit "Could not insert CD $1"
    sleep 5

    virsh start $virtName || error_exit "Could not start $virtName"
    sleep 5

    # wait for node up
    echo "Waiting for Fuel master to accept SSH"
    while true
    do
	ssh root@${fuelIp} date 2>/dev/null
	if [ $? -eq 0 ]; then
	    break
	fi
	sleep 10
    done

    # Wait until fuelmenu is up
    echo "Waiting for fuelmenu to come up"
    menuPid=""
    while [ -z "$menuPid" ]
    do
	menuPid=`ssh root@${fuelIp} "ps -ef" 2>&1 | grep fuelmenu | grep -v grep | awk '{ print $2 }'`
	sleep 10
    done

    # This is where we inject our own astute.yaml settings
    scp -q $deafile root@${fuelIp}:. || error_exit "Could not copy DEA file to Fuel"
    echo "Uploading build tools to Fuel server"
    ssh root@${fuelIp} rm -rf tools || error_exit "Error cleaning old tools structure"
    scp -qrp $topdir/tools root@${fuelIp}:. || error_exit "Error copying tools"
    echo "Running transplant #0"
    ssh root@${fuelIp} "cd tools; ./transplant0.sh ../`basename $deafile`" \
	|| error_exit "Error running transplant sequence #0"



    # Let the Fuel deployment continue
    echo "Found menu as PID $menuPid, now killing it"
    ssh root@${fuelIp} "kill $menuPid" 2>/dev/null

    # Wait until installation complete
    echo "Waiting for bootstrap of Fuel node to complete"
    while true
    do
	ssh root@${fuelIp} "ps -ef" 2>/dev/null \
	    | grep -q /usr/local/sbin/bootstrap_admin_node
	if [ $? -ne 0 ]; then
	    break
	fi
	sleep 10
    done

    echo "Waiting for one minute for Fuel to stabilize"
    sleep 1m

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
    local nodeId

    nodeId=$1
    state=$(dha_f_ipmi $1 chassis power status) || error_exit "Could not get IPMI power status"
    echo "state $state"


    if [ "$(echo $state | sed 's/.* //')" == "off" ]; then
        dha_f_ipmi $1 chassis power on
    fi
}

# API: Power off node
# API: Argument 1: node id
dha_nodePowerOff()
{
    local nodeId

    nodeId=$1
    state=$(dha_f_ipmi $1 chassis power status) || error_exit "Could not get IPMI power status"
    echo "state $state"


    if [ "$(echo $state | sed 's/.* //')" != "off" ]; then
        dha_f_ipmi $1 chassis power off
    fi
}

# API: Reset node
# API: Argument 1: node id
dha_nodeReset()
{
    local nodeId

    nodeId=$1
    state=$(dha_f_ipmi $1 chassis power reset) || error_exit "Could not get IPMI power status"
    echo "state $state"


    if [ "$(echo $state | sed 's/.* //')" != "off" ]; then
        dha_f_ipmi $1 chassis power reset
    fi
}

# Boot order and ISO boot file

# API: Is the node able to commit boot order without power toggle?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanSetBootOrderLive()
{
  return $true
}

# API: Set node boot order
# API: Argument 1: node id
# API: Argument 2: Space separated line of boot order - boot ids are "pxe", "disk" and "iso"
# Strategy for IPMI: Always set boot order to persistent except in the case of CDROM.
dha_nodeSetBootOrder()
{
    local id
    local order

    id=$1
    shift
    order=$1

    if [ "$order" == "pxe" ]; then
	dha_f_ipmi $id chassis bootdev pxe options=persistent || error_exit "Could not get IPMI power status"
    elif [ "$order" == "iso" ]; then
	dha_f_ipmi $id chassis bootdev cdrom || error_exit "Could not get IPMI power status"
    elif [ "$order" == "disk" ]; then
	dha_f_ipmi $id chassis bootdev disk options=persistent  || error_exit "Could not get IPMI power status"
    else
        error_exit "Unknown boot type: $order"
    fi
}

# API: Is the node able to operate on ISO media?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanSetIso()
{
  return $false
}

# API: Is the node able to insert add eject ISO files without power toggle?
# API: Argument 1: node id
# API: Returns 0 if true, 1 if false
dha_nodeCanHandeIsoLive()
{
  return $false
}

# API: Insert ISO into virtualDVD
# API: Argument 1: node id
# API: Argument 2: iso file
dha_nodeInsertIso()
{
    error_exit "Node can not handle InsertIso"
}

# API: Eject ISO from virtual DVD
# API: Argument 1: node id
dha_nodeEjectIso()
{
    error_exit "Node can not handle InsertIso"
}

# API: Wait until a suitable time to change the boot order to
# API: "disk iso" when ISO has been booted. Can't be too long, nor
# API: too short...
# API: We should make a smart trigger for this somehow...
dha_waitForIsoBoot()
{
    echo "waitForIsoBoot: Not used by ipmi"
}

# API: Is the node able to reset its MBR?
# API: Returns 0 if true, 1 if false
dha_nodeCanZeroMBR()
{
    return $false
}

# API: Reset the node's MBR
dha_nodeZeroMBR()
{
    error_exit "Node $1 does not support ZeroMBR"
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
