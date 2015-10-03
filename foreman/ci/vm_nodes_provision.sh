#!/usr/bin/env bash

#bootstrap script for VM OPNFV nodes
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses vm_nodes_provision.sh which configures linux on nodes
#Depends on Foreman being up to be able to register and apply puppet
#
#Pre-requisties:
#Target system should be Centos7 Vagrant VM

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`

host_name=REPLACE
dns_server=REPLACE
##END VARS

##set hostname
echo "${blue} Setting Hostname ${reset}"
hostnamectl set-hostname $host_name

##remove NAT DNS
echo "${blue} Removing DNS server on first interface ${reset}"
if ! grep 'PEERDNS=no' /etc/sysconfig/network-scripts/ifcfg-enp0s3; then
  echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
  systemctl restart NetworkManager
fi

if ! ping www.google.com -c 5; then 
  echo "${red} No internet connection, check your route and DNS setup ${reset}"
  exit 1
fi

# Install EPEL repo for access to many other yum repos
# Major version is pinned to force some consistency for Arno
yum install -y epel-release-7*

# Update device-mapper-libs, needed for libvirtd on compute nodes
# Major version is pinned to force some consistency for Arno
if ! yum -y upgrade device-mapper-libs-1*; then
   echo "${red} WARN: Unable to upgrade device-mapper-libs...nova-compute may not function ${reset}"
fi

# Install other required packages
# Major version is pinned to force some consistency for Arno
echo "${blue} Installing Puppet ${reset}"
if ! yum install -y puppet-3*; then
  printf '%s\n' 'vm_nodes_provision.sh: failed to install required packages' >&2
  exit 1
fi

echo "${blue} Configuring puppet ${reset}"
cat > /etc/puppet/puppet.conf << EOF

[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = \$vardir/ssl

[agent]
pluginsync      = true
report          = true
ignoreschedules = true
daemon          = false
ca_server       = foreman-server.opnfv.com
certname        = $host_name
environment     = production
server          = foreman-server.opnfv.com
runinterval     = 600

EOF

# Setup puppet to run on system reboot
/sbin/chkconfig --level 345 puppet on

/usr/bin/puppet agent --config /etc/puppet/puppet.conf -o --tags no_such_tag --server foreman-server.opnfv.com --no-daemonize

sync

# Inform the build system that we are done.
echo "Informing Foreman that we are built"
wget -q -O /dev/null --no-check-certificate http://foreman-server.opnfv.com:80/unattended/built

echo "Starting puppet"
systemctl start puppet
