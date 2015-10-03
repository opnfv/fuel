#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Simple expect script to start up ODL client and load feature set for DLUX and OVSDB
#  NOTE: THIS WILL BE REPLACED WITH A PROGRAMATIC METHOD SHORTLY
#################################################################################
#  Start up script for calling karaf / ODL inside a docker container.
#
#  This script will also call a couple expect scripts to load the feature set that we want


#ENV
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

#MAIN
echo "Starting up the da Sheilds..."
/opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/karaf server &
echo "Sleeping 5 bad hack"
sleep 10
echo "should see stuff listening now"
netstat -na
echo " should see proess running for karaf"
ps -efa
echo " Starting the packages we want"
/etc/init.d/speak.sh
echo "Printout the status - if its right, you should see 8181 appear now"
netstat -na
ps -efa



## This is a loop that keeps our container going currently, prinout the "status of karaf" to the docker logs every minute
## Cheap - but effective
while true;
do
        echo "Checking status of ODL:"
        /opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/status
        sleep 60
done


