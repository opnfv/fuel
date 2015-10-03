#!/bin/bash
#####################################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd.
# chigang@huawei.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#####################################################################################

# some packages or tools maybe use below filesystem
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

# install/remove packages
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get install libxslt-dev libxml2-dev libvirt-dev build-essential qemu-utils qemu-kvm libvirt-bin virtinst -y

#rm  /etc/resolv.conf
#rm -rf /tmp/*

umount /proc
umount /sys
umount /dev/pts