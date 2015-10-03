function destroy_nets() {
    sudo virsh net-destroy mgmt > /dev/null 2>&1
    sudo virsh net-undefine mgmt > /dev/null 2>&1
    
    sudo virsh net-destroy install > /dev/null 2>&1
    sudo virsh net-undefine install > /dev/null 2>&1
    rm -rf $COMPASS_DIR/deploy/work/network/*.xml
}

function setup_om_bridge() {
    local device=$1
    local gw=$2
    ip link set br_install down
    ip addr flush $device
    brctl delbr br_install

    brctl addbr br_install
    brctl addif br_install $device
    ip link set br_install up

    shift;shift
    for ip in $*;do
        ip addr add $ip dev br_install
    done

    route add default gw $gw
}

function setup_om_nat() {
    # create install network
    sed -e "s/REPLACE_BRIDGE/br_install/g" \
        -e "s/REPLACE_NAME/install/g" \
        -e "s/REPLACE_GATEWAY/$INSTALL_GW/g" \
        -e "s/REPLACE_MASK/$INSTALL_MASK/g" \
        -e "s/REPLACE_START/$INSTALL_IP_START/g" \
        -e "s/REPLACE_END/$INSTALL_IP_END/g" \
        $COMPASS_DIR/deploy/template/network/nat.xml \
        > $WORK_DIR/network/install.xml
    
    sudo virsh net-define $WORK_DIR/network/install.xml
    sudo virsh net-start install
}

function create_nets() {
    destroy_nets
    
    # create mgmt network
    sed -e "s/REPLACE_BRIDGE/br_mgmt/g" \
        -e "s/REPLACE_NAME/mgmt/g" \
        -e "s/REPLACE_GATEWAY/$MGMT_GW/g" \
        -e "s/REPLACE_MASK/$MGMT_MASK/g" \
        -e "s/REPLACE_START/$MGMT_IP_START/g" \
        -e "s/REPLACE_END/$MGMT_IP_END/g" \
        $COMPASS_DIR/deploy/template/network/nat.xml \
        > $WORK_DIR/network/mgmt.xml
    
    sudo virsh net-define $WORK_DIR/network/mgmt.xml
    sudo virsh net-start mgmt
    
    # create install network
    if [[ ! -z $VIRT_NUMBER ]];then
        setup_om_nat
    else
        mask=`echo $INSTALL_MASK | awk -F'.' '{print ($1*(2^24)+$2*(2^16)+$3*(2^8)+$4)}'`
        mask_len=`echo "obase=2;${mask}"|bc|awk -F'0' '{print length($1)}'`
        setup_om_bridge $OM_NIC $OM_GW $INSTALL_GW/$mask_len $OM_IP
    fi

}

