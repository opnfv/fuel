function get_host_macs() {
    local config_file=$WORK_DIR/installer/compass-install/install/group_vars/all
    local machines=`echo $HOST_MACS|sed 's/ /,/g'`

    echo "test: true" >> $config_file
    echo "pxe_boot_macs: [${machines}]" >> $config_file
    
    echo $machines
}
