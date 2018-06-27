#!/bin/bash -ex
##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Collect jump server system information for deploy debugging
#

# HW info
cat /proc/cpuinfo
free -mh
df -h

# Network info
brctl show
ip a
route -n
sudo iptables -S

# Distro & pkg info
cat /etc/*-release
uname -a

# Misc info
sudo losetup -a
