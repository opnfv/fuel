#!/bin/bash
# script to remove bridges and reset networking for ODL


#VARS
MODE=0
DNS=8.8.8.8

#ENV
source ~/openrc

# GET IPS for that node
function get_ips {
	BR_MGMT=`grep address /etc/network/ifcfg_backup/ifcfg-br-mgmt | awk -F" " '{print $2}'`
	BR_STORAGE=`grep address /etc/network/ifcfg_backup/ifcfg-br-storage | awk -F" " '{print $2}'`
	BR_FW_ADMIN=`grep address /etc/network/ifcfg_backup/ifcfg-br-fw-admin | awk -F" " '{print $2}'`
	BR_EX=`grep address /etc/network/ifcfg_backup/ifcfg-br-ex | awk -F" " '{print $2}'`
	DEF_NETMASK=255.255.255.0
	DEF_GW=172.30.9.1
}

function backup_ifcfg {
        echo " backing up "
        mkdir -p /etc/network/ifcfg_backup
        mv /etc/network/interfaces.d/ifcfg-br-ex /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-br-fw-admin /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-br-mgmt /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-br-storage /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-br-prv /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-eth0 /etc/network/ifcfg_backup/.
        mv /etc/network/interfaces.d/ifcfg-eth1 /etc/network/ifcfg_backup/.
        rm -rf /etc/network/interfaces.d/ifcfg-eth1.300
        rm -rf /etc/network/interfaces.d/ifcfg-eth1.301
        rm -rf /etc/network/interfaces.d/ifcfg-eth1
        rm -rf /etc/network/interfaces.d/ifcfg-eth0

}


function create_ifcfg_br_mgmt {
        echo "migrating br_mgmt"
        echo "auto eth1.300" >> /etc/network/interfaces.d/ifcfg-eth1.300
        echo "iface eth1.300 inet static" >> /etc/network/interfaces.d/ifcfg-eth1.300
        echo "     address $BR_MGMT" >> /etc/network/interfaces.d/ifcfg-eth1.300
        echo "     netmask $DEF_NETMASK" >> /etc/network/interfaces.d/ifcfg-eth1.300
}

function create_ifcfg_br_storage {
        echo "migration br_storage"
        echo "auto eth1.301" >> /etc/network/interfaces.d/ifcfg-eth1.301
        echo "iface eth1.301 inet static" >> /etc/network/interfaces.d/ifcfg-eth1.301
        echo "     address $BR_STORAGE" >> /etc/network/interfaces.d/ifcfg-eth1.301
        echo "     netmask $DEF_NETMASK" >> /etc/network/interfaces.d/ifcfg-eth1.301
}

function create_ifcfg_br_fw_admin {
        echo " migratinng br_fw_admin"
        echo "auto eth1" >> /etc/network/interfaces.d/ifcfg-eth1
        echo "iface eth1 inet static" >> /etc/network/interfaces.d/ifcfg-eth1
        echo "     address $BR_FW_ADMIN" >> /etc/network/interfaces.d/ifcfg-eth1
        echo "     netmask $DEF_NETMASK" >> /etc/network/interfaces.d/ifcfg-eth1
}

function create_ifcfg_eth0 {
        echo "migratinng br-ex to eth0 - temporarily"
        echo "auto eth0" >> /etc/network/interfaces.d/ifcfg-eth0
        echo "iface eth0 inet static" >> /etc/network/interfaces.d/ifcfg-eth0
        echo "     address $BR_EX" >> /etc/network/interfaces.d/ifcfg-eth0
        echo "     netmask $DEF_NETMASK" >> /etc/network/interfaces.d/ifcfg-eth0
        echo "     gateway $DEF_GW" >> /etc/network/interfaces.d/ifcfg-eth0
}

function set_mode {
	if [ -d "/var/lib/glance/images" ]
	then 
		echo " controller "
		MODE=0
	else 
		echo " compute "
		MODE=1
	fi
}


function stop_ovs {
        echo "Stopping OpenVSwitch"
        service openvswitch-switch stop

}

function start_ovs {
        echo "Starting OVS"
        service openvswitch-switch start
        ovs-vsctl show
}


function clean_ovs {
        echo "cleaning OVS DB"
        stop_ovs
        rm -rf /var/log/openvswitch/*
        mkdir -p /opt/opnfv/odl/ovs_back
        cp -pr /etc/openvswitch/* /opt/opnfv/odl/ovs_back/.
        rm -rf /etc/openvswitch/conf.db
        echo "restarting OVS - you should see Nothing there"
        start_ovs
}



function reboot_me {
        reboot
}

function allow_challenge {
	sed -i -e 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
	service ssh restart
}

function clean_neutron {
	subnets=( `neutron subnet-list | awk -F" " '{print $2}' | grep -v id | sed '/^$/d'` )
	networks=( `neutron net-list | awk -F" " '{print $2}' | grep -v id | sed '/^$/d'` )
	ports=( `neutron port-list | awk -F" " '{print $2}' | grep -v id | sed '/^$/d'` )
	routers=( `neutron router-list | awk -F" " '{print $2}' | grep -v id | sed '/^$/d'` )

	#display all elements
	echo "SUBNETS: ${subnets[@]} "
	echo "NETWORKS: ${networks[@]} "
	echo "PORTS: ${ports[@]} "
	echo "ROUTERS: ${routers[@]} "
	
	
	# get port and subnet for each router
	for i in "${routers[@]}"
	do
        	routerport=( `neutron router-port-list $i | awk -F" " '{print $2}' | grep -v id |  sed '/^$/d' `)
        	routersnet=( `neutron router-port-list $i | awk -F" " '{print $8}' | grep -v fixed |  sed '/^$/d' | sed 's/,$//' | sed -e 's/^"//'  -e 's/"$//' `)
	done

	echo "ROUTER PORTS: ${routerport[@]} "
	echo "ROUTER SUBNET: ${routersnet[@]} "
	
	#remove router subnets
	echo "router-interface-delete"
	for i in "${routersnet[@]}"
	do
		neutron router-interface-delete ${routers[0]} $i
	done

	#remove subnets
	echo "subnet-delete"
	for i in "${subnets[@]}"
	do
		neutron subnet-delete $i
	done

	#remove nets
	echo "net-delete"
	for i in "${networks[@]}"
	do
		neutron net-delete $i
	done

	#remove routers
	echo "router-delete"
	for i in "${routers[@]}"
	do
        	neutron router-delete $i
	done

	#remove ports
	echo "port-delete"
	for i in "${ports[@]}"
	do
        	neutron port-delete $i
	done

	#remove subnets
	echo "subnet-delete second pass"
	for i in "${subnets[@]}"
	do
        	neutron subnet-delete $i
	done

}

function set_dns {
	sed -i -e 's/nameserver 10.20.0.2/nameserver $DNS/g' /etc/resolv.conf
}


#OUTPUT

function check {
	echo $BR_MGMT
	echo $BR_STORAGE
	echo $BR_FW_ADMIN
	echo $BR_EX
}

### MAIN


set_mode
backup_ifcfg
get_ips
create_ifcfg_br_mgmt
create_ifcfg_br_storage
create_ifcfg_br_fw_admin
if [ $MODE == "0" ]
then
        create_ifcfg_eth0
fi
allow_challenge
clean_ovs
check
reboot_me


