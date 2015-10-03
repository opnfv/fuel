host_vm_dir=$WORK_DIR/vm
function tear_down_machines() {
    for i in host{0..4}
    do
        sudo virsh destroy $i 1>/dev/null 2>/dev/null
        sudo virsh undefine $i 1>/dev/null 2>/dev/null
        rm -rf $host_vm_dir/host$i
    done
}

function reboot_hosts() {
    log_warn "reboot_hosts do nothing"
}

function launch_host_vms() {
    tear_down_machines
    #function_bod
    mac_array=`echo $machines|sed 's/,/ /g'`
    log_info "bringing up pxe boot vms"
    i=0
    for mac in $mac_array; do
        log_info "creating vm disk for instance host${i}"
        vm_dir=$host_vm_dir/host$i
        mkdir -p $vm_dir
        sudo qemu-img create -f raw $vm_dir/disk.img ${VIRT_DISK}
        # create vm xml
     	sed -e "s/REPLACE_MEM/$VIRT_MEM/g" \
     	   -e "s/REPLACE_CPU/$VIRT_CPUS/g" \
     	   -e "s/REPLACE_NAME/host$i/g" \
     	   -e "s#REPLACE_IMAGE#$vm_dir/disk.img#g" \
     	   -e "s/REPLACE_BOOT_MAC/$mac/g" \
     	   -e "s/REPLACE_BRIDGE_MGMT/br_install/g" \
     	   -e "s/REPLACE_BRIDGE_TENANT/br_install/g" \
     	   -e "s/REPLACE_BRIDGE_PUBLIC/br_install/g" \
     	   -e "s/REPLACE_BRIDGE_STORAGE/br_install/g" \
     	   $COMPASS_DIR/deploy/template/vm/host.xml\
     	   > $vm_dir/libvirt.xml
	
        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start host$i
        let i=i+1
    done
}

function get_host_macs() {
    local config_file=$WORK_DIR/installer/compass-install/install/group_vars/all
    local mac_generator=${COMPASS_DIR}/deploy/mac_generator.sh
    local machines=

    chmod +x $mac_generator
    mac_array=`$mac_generator $VIRT_NUMBER`
    machines=`echo $mac_array|sed 's/ /,/g'`

    echo "test: true" >> $config_file
    echo "pxe_boot_macs: [${machines}]" >> $config_file
    
    echo $machines
}

