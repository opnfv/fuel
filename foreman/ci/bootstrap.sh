#!/usr/bin/env bash

#bootstrap script for installing/running Khaleesi in Foreman/QuickStack VM
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses bootsrap.sh which Installs Khaleesi
#Khaleesi will install and configure Foreman/QuickStack
#
#Pre-requisties:
#Target system should be Centos7
#Ensure the host's kernel is up to date (yum update)

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`

##END VARS


# Install EPEL repo for access to many other yum repos
# Major version is pinned to force some consistency for Arno
yum install -y epel-release-7*

# Install other required packages
if ! yum -y install python-pip python-virtualenv gcc git sshpass ansible python-requests; then
  printf '%s\n' 'bootstrap.sh: failed to install required packages' >&2
  exit 1
fi

cd /opt

echo "Cloning khaleesi to /opt"

if [ ! -d khaleesi ]; then
  if ! git clone -b opnfv https://github.com/trozet/khaleesi.git; then
    printf '%s\n' 'bootstrap.sh: Unable to git clone khaleesi' >&2
    exit 1
  fi
fi

cd khaleesi

cp ansible.cfg.example ansible.cfg

echo "Completed Installing Khaleesi"

cd /opt/khaleesi/

ansible localhost -m setup -i local_hosts

./run.sh --no-logs --use /vagrant/opnfv_ksgen_settings.yml playbooks/opnfv.yml
