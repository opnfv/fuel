#!/bin/bash
#  Ericsson Canada Inc.
#  Authoer: Daniel Smith
#
#   A helper script to install and setup the ODL docker conatiner on the controller
#
#
#   Inputs:  odl_docker_image.tar
#
#   Usage:  ./start_odl_docker.sh
echo "DEPRECATED - USE stage_odl.sh instead  - this will be removed shortly once automated deployment is working - SR1"


# ENVS
source ~/.bashrc
source ~/openrc

# VARS

# Switch for Dev mode - uses apt-get on control to cheat and get docker installed locally rather than from puppet source

DEV=1

# Switch for 1:1 port mapping of EXPOSED ports in Docker to the host, if set to 0, then random ports will be used - NOTE: this doesnt work for all web services X port on Host --> Y port in Container,
# especially for SSL/HTTPS cases. Be aware.

MATCH_PORT=1

LOCALPATH=/opt/opnfv/odl
DOCKERBINNAME=docker-latest
DOCKERIMAGENAME=odl_docker_image.tar
DNS=8.8.8.8
HOST_IP=`ifconfig br-fw-admin  | grep -i "inet addr" | awk -F":" '{print $2}' | awk -F" " '{print $1}'`


# Set this to "1" if you want to have your docker container startup into a shell


ENABLE_SHELL=1


echo " Fetching Docker "
if [ "$DEV" -eq "1" ];
# If testing Locally (on a control node) you can set DEV=1 to enable apt-get based install on the control node (not desired target, but good for testing).
then
        echo "Dev Mode - Fetching from Internet";
        echo " this wont work in production builds";
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
        mkdir -p $LOCALPATH
        wget https://get.docker.com/builds/Linux/x86_64/docker-latest -O $LOCALPATH/$DOCKERBINNAME
        wget http://ftp.us.debian.org/debian/pool/main/d/docker.io/docker.io_1.3.3~dfsg1-2_amd64.deb
        chmod 777 $LOCALPATH/$DOCKERBINNAME
        echo "done ";
else
        echo "Using Binaries delivered from Puppet"
	echo "Starting Docker in Daemon mode"
	chmod +x $LOCALPATH/$DOCKERBINNAME
	$LOCALPATH/$DOCKERBINNAME -d &

  # wait until docker will be fully initialized
  # before any further action against just started docker
  sleep 5
fi


# We need to perform some cleanup of the Openstack Environment
echo "TODO -- This should be automated in the Fuel deployment at some point"
echo "However, the timing should come after basic tests are running, since this "
echo " part will remove the subnet router association that is deployed automativally"
echo " via fuel. Refer to the ODL + Openstack Integration Page "

# Import the ODL container into docker

echo "Importing ODL container into docker"
$LOCALPATH/$DOCKERBINNAME load -i $LOCALPATH/$DOCKERIMAGENAME

echo " starting up ODL - DLUX and Mapping Ports"
if [ "$MATCH_PORT" -eq "1" ]
then
        echo "Starting up Docker..."
        $LOCALPATH/$DOCKERBINNAME rm odl_docker
fi

if [ "$ENABLE_SHELL" -eq "1" ];
then
        echo "Starting Container in Interactive Mode (/bin/bash will be provided, you will need to run ./start_odl_docker.sh inside the container yourself)"
        $LOCALPATH/$DOCKERBINNAME run --name odl_docker -p 8181:8181 -p 8185:8185 -p 9000:9000 -p 1099:1099 -p 8101:8101 -p 6633:6633 -p 43506:43506 -p 44444:44444 -p 6653:6653 -p 12001:12001 -p 6400:6400 -p 6640:6640 -p 8080:8080 -p 7800:7800 -p 55130:55130 -p 52150:52150 -p 36826:26826 -i -t loving_daniel  /bin/bash
else
        echo "Starting Conatiner in Daemon mode - no shell will be provided and docker attach will not provide shell)"
        $LOCALPATH/$DOCKERBINNAME run --name odl_docker -p 8181:8181 -p 8185:8185 -p 9000:9000 -p 1099:1099 -p 8101:8101 -p 6633:6633 -p 43506:43506 -p 44444:44444 -p 6653:6653 -p 12001:12001 -p 6400:6400 -p 6640:6640 -p 8080:8080 -p 7800:7800 -p 55130:55130 -p 52150:52150 -p 36826:26826 -i -d -t loving_daniel
        echo "should see the process listed here in docker ps -a"
        $LOCALPATH/$DOCKERBINNAME ps -a;
        echo "Match Port  enabled, you can reach the DLUX login at: "
        echo "http://$HOST_IP:8181/dlux.index.html"
fi
