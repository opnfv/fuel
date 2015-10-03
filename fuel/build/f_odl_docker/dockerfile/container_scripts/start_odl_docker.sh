#!/bin/bash
#  Ericsson Research Canada
#
#  Author: Daniel Smith <daniel.smith@ericsson.com>
#
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
