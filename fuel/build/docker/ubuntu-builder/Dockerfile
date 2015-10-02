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

FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties \
    make python-setuptools python-all dpkg-dev debhelper \
    fuseiso git genisoimage bind9-host wget curl lintian tmux lxc iptables \
    ca-certificates sudo apt-utils lsb-release dosfstools

RUN echo "ALL ALL=NOPASSWD: ALL" > /etc/sudoers.d/open-sudo
RUN chmod 0440 /etc/sudoers.d/open-sudo
RUN chmod 4755 /bin/fusermount

ADD ./setcontext /root/setcontext
RUN chmod +x /root/setcontext
ADD ./enable_dockerx2 /root/enable_dockerx2
RUN chmod +x /root/enable_dockerx2

VOLUME /var/lib/docker
