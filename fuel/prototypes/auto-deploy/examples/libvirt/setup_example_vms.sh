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

exit_handler() {
    rm $tmpfile
}


error_exit () {
    echo "$@"
    exit 1
}

trap exit_handler EXIT

# You can change these disk sizes to adapt to your needs
fueldisk="30G"
controllerdisk="20G"
computedisk="20G"


topdir=$(dirname $(readlink -f $BASH_SOURCE))
netdir=$topdir/conf/networks
vmdir=$topdir/conf/vms
tmpfile=`mktemp /tmp/XXXXX`

if [ ! -d $netdir ]; then
  error_exit "No net directory $netdir"
  exit 1
elif [ ! -d $vmdir ]; then
  error_exit "No VM directory $vmdir"
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Argument error."
  echo "`basename $0` <path to storage dir>"
  exit 1
fi

if [ "`whoami`" != "root" ]; then
  error_exit "You need be root to run this script"
fi

echo "Cleaning up"
tools/cleanup_example_vms.sh

storagedir=$1

if [ ! -d $storagedir ]; then
  error_exit "Could not find storagedir directory $storagedir"
fi

# Create storage space and patch it in
for vm in $vmdir/*
do
    vmname=`basename $vm`
    virsh dumpxml $vmname >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Found vm $vmname, deleting"
        virsh destroy $vmname
        virsh undefine $vmname
        sleep 10

    fi


    storage=${storagedir}/`basename ${vm}`.raw
    if [ -f ${storage} ]; then
        echo "Storage already present, removing: $storage"
        rm $storage
    fi

    echo `basename $vm` | grep -q fuel-master && size=$fueldisk
    echo `basename $vm` | grep -q controller && size=$controllerdisk
    echo `basename $vm` | grep -q compute && size=$computedisk

    echo "Creating ${size} GB of storage in ${storage}"
    fallocate -l ${size} ${storage} || \
        error_exit "Could not create storage"
    sed "s:<source file='disk.raw':<source file='${storage}':" $vm >$tmpfile
    virsh define $tmpfile
done

for net in $netdir/*
do
    netname=`basename $net`
    virsh net-dumpxml $netname >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Found net $netname, deleting"
        virsh net-destroy $netname
        virsh net-undefine $netname
    fi
    virsh net-define $net
    virsh net-autostart $netname
    virsh net-start $netname
done
