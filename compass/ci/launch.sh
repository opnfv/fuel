#set -x
WORK_DIR=$COMPASS_DIR/ci/work

if [[ $# -ge 1 ]];then
    CONF_NAME=$1
else
    CONF_NAME=cluster
fi

source ${COMPASS_DIR}/ci/log.sh
source ${COMPASS_DIR}/deploy/conf/${CONF_NAME}.conf
source ${COMPASS_DIR}/deploy/prepare.sh
source ${COMPASS_DIR}/deploy/network.sh

if [[ ! -z $VIRT_NUMBER ]];then
    source ${COMPASS_DIR}/deploy/host_vm.sh
else
    source ${COMPASS_DIR}/deploy/host_baremetal.sh
fi

source ${COMPASS_DIR}/deploy/compass_vm.sh
source ${COMPASS_DIR}/deploy/deploy_host.sh

######################### main process

if ! prepare_env;then
    echo "prepare_env failed"
    exit 1
fi

log_info "########## get host mac begin #############"
machines=`get_host_macs`
if [[ -z $machines ]];then
    log_error "get_host_macs failed"
    exit 1
fi

log_info "deploy host macs: $machines"
export machines

log_info "########## set up network begin #############"
if ! create_nets;then
    log_error "create_nets failed"
    exit 1
fi

if ! launch_compass;then
    log_error "launch_compass failed"
    exit 1
fi
if [[ ! -z $VIRT_NUMBER ]];then
    if ! launch_host_vms;then
        log_error "launch_host_vms failed"
        exit 1
    fi
fi
if ! deploy_host;then
    #tear_down_machines
    #tear_down_compass
    exit 1
else
    #tear_down_machines
    #tear_down_compass
    exit 0
fi
