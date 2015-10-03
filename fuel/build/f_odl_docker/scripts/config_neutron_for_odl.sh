#!/bin/bash
CONTROL_HOST=172.17.0.3

# ENV
source ~/openrc



# VARS
ML2_CONF=/etc/neutron/plugins/ml2/ml2_conf.ini
MODE=0


# FUCNTIONS


# Update ml2_conf.ini
function update_ml2conf {
        echo "Backing up and modifying ml2_conf.ini"
        cp $ML2_CONF $ML2_CONF.bak
        sed -i -e 's/mechanism_drivers =openvswitch/mechanism_drivers = opendaylight/g' $ML2_CONF
#!/bin/bash
CONTROL_HOST=172.17.0.3

# ENV
source ~/openrc



# VARS
ML2_CONF=/etc/neutron/plugins/ml2/ml2_conf.ini
MODE=0


# FUCNTIONS


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
        if df -k | grep glance
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
        echo "do control stuff here"
        echo "Reset Neutron DB"
        #reset_neutrondb
        echo "Restarting Neutron Components"
        #restart_neutron
        echo "Verifying ODL ML2 plugin is working"
        verify_ML2_working

}

function compute_setup {
        echo "do compute stuff here"
        stop_neutron
        verify_ML2_working
}


# MAIN
echo "Starting to make call"
#update_ml2conf
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


