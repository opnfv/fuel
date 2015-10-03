#!/usr/bin/env bash

#NAT setup script to setup NAT from Admin -> Public interface
#on a Vagrant VM
#Called by Vagrantfile in conjunction with deploy.sh
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses nat_setup.sh which sets up NAT
#

##make sure firewalld is stopped and disabled
if ! systemctl stop firewalld; then
  printf '%s\n' 'nat_setup.sh: Unable to stop firewalld' >&2
  exit 1
fi

systemctl disable firewalld

# Install iptables
# Major version is pinned to force some consistency for Arno
if ! yum -y install iptables-services-1*; then
  printf '%s\n' 'nat_setup.sh: Unable to install iptables-services' >&2
  exit 1
fi

##start and enable iptables service
if ! systemctl start iptables; then
  printf '%s\n' 'nat_setup.sh: Unable to start iptables-services' >&2
  exit 1
fi

systemctl enable iptables

##enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

##Configure iptables
/sbin/iptables -t nat -I POSTROUTING -o enp0s10 -j MASQUERADE
/sbin/iptables -I FORWARD 1 -i enp0s10 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -I FORWARD 1 -i enp0s8 -o enp0s10 -j ACCEPT
/sbin/iptables -I INPUT 1 -j ACCEPT
/sbin/iptables -I OUTPUT 1 -j ACCEPT

