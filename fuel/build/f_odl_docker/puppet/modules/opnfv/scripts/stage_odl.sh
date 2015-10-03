#!/bin/bash
#   Author: Daniel Smith (Ericsson)
#   Stages ODL Controlleer
#   Inputs:  odl_docker_image.tar
#   Usage:  ./stage_odl.sh

# ENVS
source ~/.bashrc
source ~/openrc

LOCALPATH=/opt/opnfv/odl
DOCKERBIN=docker-latest
ODLIMGNAME=odl_docker_image.tar
DNS=8.8.8.8
HOST_IP=`ifconfig br-ex | grep -i "inet addr" | awk -F":" '{print $2}' | awk -F" " '{print $1}'`



# DEBUG ECHOS
echo $LOCALPATH
echo $DOCKERBIN
echo $ODLIMGNAME
echo $DNS
echo $HOST_IP


# Set DNS to someting external and default GW - ODL requires a connection to the internet
sed -i -e 's/nameserver 10.20.0.2/nameserver 8.8.8.8/g' /etc/resolv.conf
route delete default gw 10.20.0.2
route add default gw 172.30.9.1

# Start Docker daemon and in background
echo "Starting Docker"
chmod +x $LOCALPATH/$DOCKERBIN
$LOCALPATH/$DOCKERBIN -d &
#courtesy sleep for virtual env
sleep 2

# Import the ODL Container
echo "Importing ODL Container"
$LOCALPATH/$DOCKERBIN load -i $LOCALPATH/$ODLIMGNAME

# Start ODL, load DLUX and OVSDB modules
echo "Removing any old install found - file not found is ok here"
$LOCALPATH/$DOCKERBIN rm odl_docker
echo "Starting up ODL controller in Daemon mode - no shell possible"
$LOCALPATH/$DOCKERBIN  run --name odl_docker -p 8181:8181 -p 8185:8185 -p 9000:9000 -p 1099:1099 -p 8101:8101 -p 6633:6633 -p 43506:43506 -p 44444:44444 -p 6653:6653 -p 12001:12001 -p 6400:6400 -p 6640:6640 -p 8080:8080 -p 7800:7800 -p 55130:55130 -p 52150:52150 -p 36826:26826 -i -d -t loving_daniel

# Following, you should see the docker ps listed and a port opened
echo " you should reach ODL controller at http://HOST_IP:8181/dlux/index.html"
$LOCALPATH/$DOCKERBINNAME ps -a
netstat -lnt


