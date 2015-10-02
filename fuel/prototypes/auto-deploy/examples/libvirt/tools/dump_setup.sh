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

topdir=$(cd $(dirname $(readlink -f $BASH_SOURCE)); cd ..; pwd)
netdir=$topdir/conf/networks
vmdir=$topdir/conf/vms
vms="fuel-master controller1 compute4 compute5"
networks="fuel1 fuel2 fuel3 fuel4"


if [ "`whoami`" != "root" ]; then
  error_exit "You need be root to run this script"
fi

mkdir -p $netdir
mkdir -p $vmdir

if [ `ls -1 $netdir/ | wc -l` -ne 0 ]; then
  echo "There are files in $netdir already!"
  exit 1
elif [ `ls -1 $vmdir/ | wc -l` -ne 0 ]; then
  echo "There are files in $vmdir already!"
  exit 1
fi


# Check that no VM is up
for vm in $vms
do
    if [ "`virsh domstate $vm`" == "running" ]; then
        echo "Can't dump while VM are up: $vm"
        exit 1
    fi
done

# Dump all networks in the fuell* namespace
for net in $networks
do
  virsh net-dumpxml $net > $netdir/$net
done

# Dump all fuel-master, compute* and controller* VMs
for vm in $vms
do
  virsh dumpxml $vm > $vmdir/$vm
done

# Remove all attached ISOs, generalize disk file
for vm in $vmdir/*
do
  sed -i '/.iso/d' $vm
  sed -i "s/<source file='.*raw'/<source file='disk.raw'/" $vm
done

# Generalize all nets
for net in $netdir/*
do
  sed -i '/<uuid/d' $net
  sed -i '/<mac/d' $net
done
