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

# Tools for installation on the libvirt server/base host
#
apt-get install -y libvirt-bin qemu-kvm tightvncserver virt-manager \
   sshpass fuseiso genisoimage blackbox xterm python-yaml python-netaddr \
   python-paramiko python-lxml python-pip
pip install scp
restart libvirt-bin