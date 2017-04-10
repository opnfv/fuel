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
ENV http_proxy INSERT_HTTP_PROXY
ENV https_proxy INSERT_HTTPS_PROXY
ENV no_proxy INSERT_NO_PROXY
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties \
    make python-setuptools python-all dpkg-dev debhelper ruby-json \
    fuseiso git genisoimage bind9-host wget curl lintian tmux lxc iptables \
    ca-certificates sudo apt-utils lsb-release dosfstools debmirror p7zip-full \
    build-essential ruby-dev rubygems-integration python-pip git rpm createrepo syslinux

RUN gem install fpm
RUN pip install git+https://github.com/openstack/fuel-plugins
# fuel-infra key
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BCE5CC461FA22B08

RUN echo "ALL ALL=NOPASSWD: ALL" > /etc/sudoers.d/open-sudo
RUN echo "Defaults env_keep += \"ftp_proxy http_proxy https_proxy no_proxy RSYNC_PROXY RSYNC_CONNECT_PROG npm_config_registry\"" > /etc/sudoers.d/keep-proxies
# Keeping PWD is needed to build as root
RUN echo "Defaults env_keep += \"PWD\"" > /etc/sudoers.d/keep-pwd
# Keeping variables for ISO build
RUN echo "Defaults env_keep += \"MIRROR_UBUNTU MIRROR_UBUNTU_ROOT MIRROR_MOS_UBUNTU MIRROR_MOS_UBUNTU_ROOT MIRROR_FUEL LATEST_TARGET_UBUNTU UBUNTU_ARCH\"" > /etc/sudoers.d/keep-mos
RUN chmod 0440 /etc/sudoers.d/open-sudo
RUN chmod 0440 /etc/sudoers.d/keep-proxies
RUN chmod 0440 /etc/sudoers.d/keep-pwd
RUN chmod 0440 /etc/sudoers.d/keep-mos
RUN chmod 4755 /bin/fusermount

ADD ./setcontext /root/setcontext
RUN chmod +x /root/setcontext

VOLUME /var/lib/docker
