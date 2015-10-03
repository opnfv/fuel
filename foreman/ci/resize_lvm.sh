#!/usr/bin/env bash

#script for resizing volumes in Foreman/QuickStack VM
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses resize_partition.sh
#
#Pre-requisties:
#Vagrant box disk size already resized
#Partition already resized

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`

##END VARS

echo "${blue}Resizing physical volume${reset}"
if ! pvresize /dev/sda2; then
  echo "${red}Unable to resize physical volume${reset}"
  exit 1
else
  new_part_size=`pvdisplay | grep -Eo "PV Size\s*[0-9]+\." | awk {'print $3'} | tr -d .`
  echo "${blue}New physical volume size: ${new_part_size}${reset}"
fi

echo "${blue}Resizing logical volume${reset}"
if ! lvextend /dev/mapper/centos-root -r -l +100%FREE; then
  echo "${red}Unable to resize logical volume${reset}"
  exit 1
else
  new_fs_size=`df -h | grep centos-root | awk '{print $2}'`
  echo "${blue}Filesystem resized to: ${new_fs_size}${reset}"
fi
