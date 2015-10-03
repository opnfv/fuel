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

#Install Oracle Java 7 jdk
echo "Installing JAVA 7"
apt-get update
add-apt-repository ppa:webupd8team/java -y
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
apt-get install oracle-java7-installer -y

#Install Maven 3
echo deb http://ppa.launchpad.net/natecarlson/maven3/ubuntu precise main >> /etc/apt/sources.list
echo deb-src http://ppa.launchpad.net/natecarlson/maven3/ubuntu precise main >> /etc/apt/sources.list
apt-get update || exit 1
sudo apt-get install -y --force-yes maven3 || exit 1
ln -s /usr/share/maven3/bin/mvn /usr/bin/mvn
