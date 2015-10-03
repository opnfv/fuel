function tear_down_machines() {
    virtmachines=$(sudo virsh list --name |grep pxe)
    for virtmachine in $virtmachines; do
        echo "destroy $virtmachine"
        sudo virsh destroy $virtmachine
        if [[ "$?" != "0" ]]; then
            echo "destroy instance $virtmachine failed"
            exit 1
        fi
    done

    sudo virsh  list --all|grep shut|awk '{print $2}'|xargs -n 1 sudo virsh undefine

    vol_names=$(sudo virsh vol-list default |grep .img | awk '{print $1}')
    for vol_name in $vol_names; do
        echo "virsh vol-delete $vol_name"
        sudo virsh vol-delete  $vol_name  --pool default
        if [[ "$?" != "0" ]]; then
            echo "vol-delete $vol_name failed!"
            exit 1
        fi
    done
}
