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
  echo "Error: $@" >&2
  exit 1
}

if [ $# -ne 2 ]; then
  echo "Syntax: `basename $0` adaptername dhafile"
  exit 1
fi

if [ ! -f dha-adapters/${1}.sh ]; then
    echo "No such adapter file: $1"
    exit 1
elif [ ! -f $2 ]; then
    echo "No such DHA file: $2"
    exit 1
fi

. dha-adapters/${1}.sh $2


err=1
echo "Verifying that expected functions are present..."
for function in \
    dha_getApiVersion  \
    dha_getAdapterName  \
    dha_getAllNodeIds \
    dha_getFuelNodeId \
    dha_getNodeProperty \
    dha_getNodePxeMac \
    dha_useFuelCustomInstall \
    dha_fuelCustomInstall \
    dha_getPowerOnStrategy \
    dha_nodePowerOn \
    dha_nodePowerOff \
    dha_nodeReset \
    dha_nodeCanSetBootOrderLive \
    dha_nodeSetBootOrder \
    dha_nodeCanSetIso \
    dha_nodeCanHandeIsoLive \
    dha_nodeInsertIso \
    dha_nodeEjectIso \
    dha_waitForIsoBoot \
    dha_nodeCanZeroMBR \
    dha_nodeZeroMBR \
    dha
do
    if type $function &>/dev/null; then
        echo "$function: OK"
    else
        echo "$function: Missing!"
        err=0
    fi
done


echo "Adapter API version: `dha getApiVersion`"
echo "Adapter name: `dha getAdapterName`"

echo "All PXE MAC addresses:"
for id in `(dha getAllNodeIds) | sort`
do
    if [ "`dha getAdapterName`" == "libvirt" ]; then
        libvirtName=`dha getNodeProperty $id libvirtName`
    else
        libvirtName=""
    fi

    if [ $id == "`dha getFuelNodeId`" ]; then
        echo "$id: `dha getNodeProperty $id pxeMac` $libvirtName  <--- Fuel master"
    else
        echo "$id: `dha getNodeProperty $id pxeMac` $libvirtName"
    fi
done


echo -n "Using Fuel custom install: "
if dha useFuelCustomInstall; then
  echo "yes"
else
  echo "no"
fi


echo -n "Can set boot order live: "
if dha nodeCanSetBootOrderLive; then
  echo "yes"
else
  echo "no"
fi

echo -n "Can operate on ISO media: "
if dha nodeCanSetIso; then
  echo "yes"
else
  echo "no"
fi

echo -n "Can insert/eject ISO without power toggle: "
if dha nodeCanHandeIsoLive; then
  echo "yes"
else
  echo "no"
fi

echo -n "Can erase the boot disk MBR: "
if dha nodeCanZeroMBR; then
  echo "yes"
else
  echo "no"
fi

echo "Done"
