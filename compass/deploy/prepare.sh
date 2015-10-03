function prepare_env() {
    export PYTHONPATH=/usr/lib/python2.7/dist-packages:/usr/local/lib/python2.7/dist-packages
    sudo apt-get update -y
    sudo apt-get install mkisofs bc
    sudo apt-get install git python-pip python-dev -y
    sudo apt-get install libxslt-dev libxml2-dev libvirt-dev build-essential qemu-utils qemu-kvm libvirt-bin virtinst libmysqld-dev -y
    sudo pip install --upgrade pip
    sudo pip install --upgrade ansible
    sudo pip install --upgrade virtualenv
    sudo service libvirt-bin restart
   
    # prepare work dir
    sudo rm -rf $WORK_DIR
    mkdir -p $WORK_DIR
    mkdir -p $WORK_DIR/installer
    mkdir -p $WORK_DIR/vm
    mkdir -p $WORK_DIR/network
    mkdir -p $WORK_DIR/iso
    mkdir -p $WORK_DIR/venv

    if [[ ! -f centos.iso ]];then
        wget -O $WORK_DIR/iso/centos.iso $ISO_URL
    fi

    # copy compass
    mkdir -p $WORK_DIR/mnt
    sudo mount -o loop $WORK_DIR/iso/centos.iso $WORK_DIR/mnt
    cp -rf $WORK_DIR/mnt/compass/compass-core $WORK_DIR/installer/
    cp -rf $WORK_DIR/mnt/compass/compass-install $WORK_DIR/installer/
    sudo umount $WORK_DIR/mnt
    rm -rf $WORK_DIR/mnt

    chmod 755 $WORK_DIR -R
    virtualenv $WORK_DIR/venv
}
