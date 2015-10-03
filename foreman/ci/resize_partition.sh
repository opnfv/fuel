#!/usr/bin/env bash

#script for extending disk partition in Foreman/QuickStack VM
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses resize_partition.sh
#
#Pre-requisties:
#Vagrant box disk size already resized

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`

##END VARS

echo "${blue}Extending partition...${reset}"
echo "d
2
n
p



p
t
2
8e
w
"|fdisk /dev/sda; true
