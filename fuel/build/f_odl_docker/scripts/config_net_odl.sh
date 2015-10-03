#!/bin/bash
#
# Author: Daniel Smith (Ericsson)
#
# Script to update neutron configuration for OVSDB/ODL integratino
#
#  Usage - Set / pass CONTROL_HOST to your needs
#
CONTROL_HOST=172.30.9.70

# ENV
source ~/openrc

# VARS
ML2_CONF=/etc/neutron/plugins/ml2/ml2_conf.ini
MODE=0


# FUNCTIONS

# Update ml2_conf.ini
function update_ml2conf {
        echo "Backing up and modifying ml2_conf.ini"
        cp $ML2_CONF $ML2_CONF.bak
        sed -i -e 's/mechanism_drivers =openvswitch/mechanism_drivers = opendaylight/g' $ML2_CONF
        sed -i -e 's/tenant_network_types = flat,vlan,gre,vxlan/tenant_network_types = vxlan/g' $ML2_CONF
        cat "[ml2_odl]" >> $ML2_CONF
        cat "password = admin" >> $ML2_CONF
        cat "username = admin" >> $ML2_CONF
        cat "url = http://${CONTROL_HOST}:8080/controller/nb/v2/neutron" >> $ML2_CONF
}

function reset_neutrondb {
        echo "Reseting DB"
        mysql -e "drop database if exists neutron_ml2;"
        mysql -e "create database neutron_ml2 character set utf8;"
        mysql -e "grant all on neutron_ml2.* to 'neutron'@'%';"
        neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head
}

function restart_neutron {
        echo "Restarting Neutron Server"
        service neutron-server restart
        echo "Should see Neutron runing now"
        service neutron-server status
        echo "Shouldnt be any nets, but should work (return empty)"
        neutron net-list
}

function stop_neutron {
        echo "Stopping Neutron / OVS components"
        service  neutron-plugin-openvswitch-agent stop
        if [ $MODE == "0" ]
        then
                service neutron-server stop
        fi
}



function verify_ML2_working {
        echo "checking that we can talk via ML2 properly"
        curl -u admin:admin http://${CONTROL_HOST}:8080/controller/nb/v2/neutron/networks > /tmp/check_ml2
        if grep "network" /tmp/check_ml2
        then
                echo "Success - ML2 to ODL is working"
        else
                echo "im sorry Jim, but its dead"
        fi

}


function set_mode {
        if ls -l /var/lib/glance/images
        then
                echo "Controller Mode"
                MODE=0
        else
                echo "Compute Mode"
                MODE=1
        fi
}

function stop_ovs {
        echo "Stopping OpenVSwitch"
        service openvswitch-switch stop

}

function control_setup {
        echo "Modifying Controller"
        stop_neutron
        stop_ovs
        rm -rf /var/log/openvswitch/*
        mkdir -p /opt/opnfv/odl/ovs_back
        mv /etc/openvswitch/conf.db /opt/opnfv/odl/ovs_back/.
        mv /etc/openvswitch/.conf*lock* /opt/opnfv/odl/ovs_back/.
        service openvswitch-switch start
        ovs-vsctl set-manager tcp:172.30.9.70:6640
        ovs-vsctl add-br br-eth0
        ovs-vsctl add-br br-ex
        ovs-vsctl add-port br-eth0 eth0
        ovs-vsctl add-port br-eth0 br-eth0--br-ex
        ovs-vsctl add-port br-ex br-ex--br-eth0
        ovs-vsctl set interface br-ex--br-eth0 type=patch
        ovs-vsctl set interface br-eth0--br-ex type=patch
        ovs-vsctl set interface br-ex--br-eth0 options:peer=br-eth0--br-ex
        ovs-vsctl set interface br-eth0--br-ex options:peer=br-ex--br-eth0
        ifconfig br-ex 172.30.9.70/24 up
        service neutron-server restart

        echo "setting up networks"
        ip link add link eth1 name br-mgmt type vlan id 300
        ip link add link eth1 name br-storage type vlan id 301
        /etc/init.d/networking restart


        echo "Reset Neutron DB"
        #reset_neutrondb
        echo "Restarting Neutron Components"
        #restart_neutron
        echo "Verifying ODL ML2 plugin is working"
        verify_ML2_working

}

function compute_setup {
        echo "do compute stuff here"
        echo "stopping neutron openvswitch plugin"
        stop_neutron
        ip link add link eth1 name br-mgmt type vlan id 300
        ifconfig br-mgmt `grep address /etc/network/interfaces.d/ifcfg-br-mgmt | awk -F" " '{print $2}'`/24
        ip link add link eth1 name br-storage type vlan id 301
        ifconfig br-storage `grep address /etc/network/interfaces.d/ifcfg-br-storage | awk -F" " '{print $2}'`/24
        ifconfig eth1 `grep address /etc/network/interfaces.d/ifcfg-br-fw-mgmt | awk -F" " '{print $2}'`/24
        echo "set manager, and route for ODL controller"
        ovs-vsctl set-manager tcp:192.168.0.2:6640
        route add 172.17.0.1 gw 192.168.0.2
        verify_ML2_working
}


# MAIN
echo "Starting to make call"
update_ml2conf
echo "Check Mode"
set_mode

if [ $MODE == "0" ];
then
        echo "Calling control setup"
        control_setup
elif [ $MODE == "1" ];
then
        echo "Calling compute setup"
        compute_setup

else
        echo "Something is bad - call for help"
        exit
fi


