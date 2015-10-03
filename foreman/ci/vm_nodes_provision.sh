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
host_ip=REPLACE
domain_name=REPLACE
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

##modify /etc/resolv.conf to point to foreman
echo "${blue} Configuring resolv.conf with DNS: $dns_server ${reset}"
cat > /etc/resolv.conf << EOF
search $domain_name
nameserver $dns_server
nameserver 8.8.8.8

EOF

##modify /etc/hosts to add own IP for rabbitmq workaround
host_short_name=`echo $host_name | cut -d . -f 1`
echo "${blue} Configuring hosts with: $host_name $host_ip ${reset}"
cat > /etc/hosts << EOF
$host_ip  $host_short_name $host_name
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

if ! ping www.google.com -c 5; then
  echo "${red} No internet connection, check your route and DNS setup ${reset}"
  exit 1
fi

##install EPEL
if ! yum repolist | grep "epel/"; then
  if ! rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm; then
    printf '%s\n' 'vm_provision_nodes.sh: Unable to configure EPEL repo' >&2
    exit 1
  fi
else
  printf '%s\n' 'vm_nodes_provision.sh: Skipping EPEL repo as it is already configured.'
fi

##install device-mapper-libs
##needed for libvirtd on compute nodes
if ! yum -y upgrade device-mapper-libs; then
   echo "${red} WARN: Unable to upgrade device-mapper-libs...nova-compute may not function ${reset}"
fi

echo "${blue} Installing Puppet ${reset}"
##install puppet
if ! yum list installed | grep -i puppet; then
  if ! yum -y install puppet; then
    printf '%s\n' 'vm_nodes_provision.sh: Unable to install puppet package' >&2
    exit 1
  fi
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
ca_server       = foreman-server.$domain_name
certname        = $host_name
environment     = production
server          = foreman-server.$domain_name
runinterval     = 600

EOF

# Setup puppet to run on system reboot
/sbin/chkconfig --level 345 puppet on

/usr/bin/puppet agent --config /etc/puppet/puppet.conf -o --tags no_such_tag --server foreman-server.$domain_name --no-daemonize

sync

# Inform the build system that we are done.
echo "Informing Foreman that we are built"
wget -q -O /dev/null --no-check-certificate http://foreman-server.$domain_name:80/unattended/built

echo "Starting puppet"
systemctl start puppet
