#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Jonas Bjurel and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################


############################################################################
# BEGIN of usage
#
usage() {
    cat | more << EOF
usage:
$0 [install_deps]|[install_repos]|[build_deb]|[build_rpm]|[generate_cache_id]|[clean]|[help]
EOF
}
#
# END of usage
############################################################################

############################################################################
# BEGIN of install_repos
#
install_repos() {
    echo "========================================================================="
    echo "Cloning OpenContrail repositories into $SANDBOX_DIR directory"
    rm -rf $SANDBOX_DIR
    mkdir -p $SANDBOX_DIR
    pushd $SANDBOX_DIR
    git config --global user.email "fuel@opnfv.org"
    git config --global user.name "Fuel@OPNFV"
    git config --global color.ui false
    repo init -u https://github.com/Juniper/contrail-vnc.git
    cp $MANIFEST .repo/.
    repo sync
    pushd $SCRIPT_PATH && ./patch.sh && popd
    python third_party/fetch_packages.py
    python distro/third_party/fetch_packages.py
    mkdir -p build
    ln -s ../tools/packaging/build/package_configs build/
#    if [ "$OPENSTACK_RELEASE" == "juno" ]; then
#        pushd ${SANDBOX_DIR}/openstack/neutron_plugin
#        git cherry-pick 3189155
#        popd
#    fi

    sudo apt-get install `cat tools/packages/debian/contrail/debian/builddep.${UBUNTU_RELEASE}  | tr -d '\n\t '| tr ',' ' '`
    popd
}
#
# END of install_repos
############################################################################

############################################################################
# BEGIN of fetch_repo_sha
#
fetch_repo_sha() {
    pushd $SCRIPT_PATH
    # Temporary workaround, should go away once Docker rebuilds when docker
    # is rebuild at change of Dockerfile.
    sudo apt-get install -y libxml2-utils
    CONTRAIL_DEFAULT_BRANCH=$(xmllint --xpath '//manifest/default/@revision' manifest.xml | sed -r 's/revision=\"([^\"]+)\"/\1/g')
    CONTRAIL_REPOS=$(xmllint --xpath '//manifest/project/@name' manifest.xml  | sed -r 's/name=\"([^\"]+)\"/\1/g')
    for repo in $CONTRAIL_REPOS
    do
        SPECIFIC_BRANCH=$(xmllint --xpath "string(/manifest/project[@name=\"${repo}\"]/@revision)" manifest.xml)
        if [ ! -z $SPECIFIC_BRANCH ]; then
            echo $(git ls-remote --heads https://github.com/Juniper/${repo}.git | grep $SPECIFIC_BRANCH | awk {'print $1'})
        else
            echo $(git ls-remote --heads https://github.com/Juniper/${repo}.git | grep $CONTRAIL_DEFAULT_BRANCH | awk {'print $1'})
        fi
    done
    popd
}
#
# END of fetch_repo_sha
############################################################################

############################################################################
# BEGIN of install_deps
#
install_deps() {
    pushd ${SCRIPT_PATH}
    echo "========================================================================="
    echo "Installing needed OpenContrail dependencies."
    sudo apt-get update -y
    sudo apt-add-repository -y ppa:opencontrail/ppa
    sudo apt-get update -y

    # Generic package dependencies
    sudo apt-get install -y autoconf automake bison debhelper flex libcurl4-openssl-dev libexpat-dev libgettextpo0 libprotobuf-dev libtool libxml2-utils make protobuf-compiler python-all python-dev python-lxml python-setuptools python-sphinx ruby-ronn scons unzip vim-common libsnmp-python libipfix libipfix-dev librdkafka-dev librdkafka1 phablet-tools rng-tools ant default-jdk javahelper libcommons-codec-java libhttpcore-java liblog4j1.2-java nodejs module-assistant build-essential

    # Aditional package dependencies required for Ubuntu 14.04 Trusty
    sudo apt-get install -y libboost-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-program-options-dev libboost-python-dev libboost-regex-dev libboost-system-dev libboost-thread-dev google-mock libgoogle-perftools-dev liblog4cplus-dev libtbb-dev libhttp-parser-dev libxml2-dev libicu-dev
    echo "ocl: Target kernel: ${TARGET_UBUNTU_KERNEL}"
    echo "ocl: Build kernel: $(uname -r)"
    if [ "${TARGET_UBUNTU_KERNEL}" == "$(uname -r)" ]; then
        echo "ocl: Target- and build kernel versions matching"
        echo "ocl: Using kernel header package linux-headers-${TARGET_UBUNTU_KERNEL}"
        sudo apt-get install -y linux-headers-${TARGET_UBUNTU_KERNEL}
    else
        echo "ocl: Target- and build kernel versions does not match"
        echo "ocl: Installing kernel source for ${LINUX_MAJOR} and will build kernel modules against it"
        sudo mkdir -p /lib/modules/$(uname -r)
        apt-get source linux-source-${LINUX_MAJOR}
        sudo rm -rf /lib/modules/$(uname -r)/build
        sudo ln -s ${SCRIPT_PATH}/linux-${LINUX_MAJOR} /lib/modules/$(uname -r)/build
        pushd /lib/modules/$(uname -r)/build
        sudo make olddefconfig
        sudo make prepare
        sudo make scripts
        popd
    fi
    popd
}
#
# END of install_deps
############################################################################

############################################################################
# BEGIN of build
#
build() {
    pushd $SANDBOX_DIR
    mkdir -p $PACKAGES_DIR
    KEY_UUID=$(uuidgen)
    cat > gpg.fuelopnfv <<EOF
%echo Generating a basic OpenPGP key for Fuel@OPNFV/OpenContrail
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Fuel@opnfv
Name-Comment: $KEY_UUID
Name-Email: jonas.bjurel@ericsson.com
Expire-Date: 0
%commit
%echo done
EOF
    # Provide entropy by enabling HW random generator
    sudo rngd -r /dev/urandom
    gpg --batch --gen-key gpg.fuelopnfv
    KEYID=$(gpg --list-secret-key | grep ${KEY_UUID} -B2 | head -n -1 | awk '{print $2}' | cut -d '/' -f2)
    pushd tools/packaging/common/debian
    TAG=$CONTRAIL_BUILD CONTRAIL_SKU=$OPENSTACK_RELEASE make contrail \
        ifmap-server \
        ifmap-python-client \
        contrail-nova-vif-deb \
        contrail-vrouter-init-deb \
        contrail-vrouter-common-deb \
        contrail-web-core-deb \
        contrail-web-controller-deb \
        contrail-web-server-manager-deb \
        contrail-nodemgr-deb \
        contrail-setup-deb \
        contrail-openstack-icehouse-deb \
        contrail-openstack-analytics-deb \
        contrail-openstack-config-deb \
        contrail-openstack-control-deb \
        contrail-openstack-database-deb \
        contrail-openstack-vrouter-deb \
        contrail-openstack-webui-deb \
        contrail-fabric-utils-deb \
        contrail-test-deb \
        libvirt-deb \
        contrail-openstack-dashboard-deb \
        contrail-ostack-dashboard-deb \
        contrail-heat-deb \
        neutron-plugin-contrail-deb \
        contrail-vmware-utils-deb
##        contrail-openstack-ha-deb \
    popd
    FINGERPRINT=$(gpg --list-secret-keys --with-colons --fingerprint | sed -n 's/^fpr:::::::::\([[:alnum:]]\+\):/\1/p' | grep ${KEYID})
    gpg --batch --yes --delete-secret-and-public-key $FINGERPRINT
    mkdir -p $PACKAGES_DIR
    find ${SANDBOX_DIR}/build -type f -name "*.deb" -exec cp {} ${PACKAGES_DIR}/ \;
    popd
}
#
# END of build
############################################################################

############################################################################
# BEGIN of clean
#
clean() {
rm -rf $SANDBOX_DIR
rm -rf $PACKAGES_DIR
}
#
# END of clean
############################################################################

############################################################################
# BEGIN of main
#
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`

SANDBOX_DIR=${SCRIPT_PATH}/SANDBOX
PACKAGES_DIR=${SCRIPT_PATH}/fuel-plugin-contrail/repositories/ubuntu

MANIFEST=${SCRIPT_PATH}/manifest.xml
LINUX_MAJOR=$(echo ${TARGET_UBUNTU_KERNEL} | cut -d "-" -f 1)
LINUX_MINOR=$(echo ${TARGET_UBUNTU_KERNEL} | cut -d "-" -f 2)

case "${1}" in
   "install_deps")
        install_deps
        ;;

    "install_repos")
        install_repos
        ;;

    "build_deb")
        build
        ;;

    "build_rpm")
        echo "\"build_rpm\" is not yet supported"
        exit 1
        ;;

    "generate_cache_id")
        fetch_repo_sha
        echo $(sha1sum $0 | awk {'print $1'})
        echo $(sha1sum $MANIFEST | awk {'print $1'})
        ;;

    "clean")
        clean
        ;;

    "help")
        usage
        ;;

    *)
        echo "Argument errors"
        usage
        exit 1
        ;;
esac
exit 0
#
# END of main
############################################################################
