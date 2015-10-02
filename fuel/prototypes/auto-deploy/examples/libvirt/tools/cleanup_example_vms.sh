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


error_exit () {
    echo "$@"
    exit 1
}

topdir=$(cd $(dirname $(readlink -f $BASH_SOURCE)); cd ..; pwd)
netdir=$topdir/conf/networks
vmdir=$topdir/conf/vms

if [ ! -d $netdir ]; then
  error_exit "No net directory $netdir"
  exit 1
elif [ ! -d $vmdir ]; then
  error_exit "No VM directory $vmdir"
  exit 1
fi


if [ "`whoami`" != "root" ]; then
  error_exit "You need be root to run this script"
fi

for vm in $vmdir/*
do
    vmname=`basename $vm`
    virsh dumpxml $vmname >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        diskfile=`virsh dumpxml $vmname | grep "<source file=" | grep raw | \
            sed "s/.*<source file='\(.*\)'.*/\1/"`
        echo "Removing $vmname with disk $diskfile"
        virsh destroy $vmname 2>/dev/null
        virsh undefine $vmname
        rm -f $diskfile
    fi
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
done
