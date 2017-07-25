#!/bin/bash
set -ex
##############################################################################
# Copyright (c) 2017 Ericsson AB, Mirantis Inc. and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

############################################################################
# BEGIN of Exit handlers
#
do_exit () {
    clean
    echo "Exiting ..."
}
#
# End of Exit handlers
############################################################################

############################################################################
# BEGIN of usage description
#
usage ()
{
cat << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
`basename $0`: Deploys the Fuel@OPNFV stack

usage: `basename $0` -b base-uri
       [-B PXE Bridge [-B Mgmt Bridge [-B Internal Bridge [-B Public Bridge]]]]
       [-f] [-F] [-H] -l lab-name -p pod-name -s deploy-scenario
       [-S image-dir] [-T timeout] -i iso
       -s deployment-scenario [-S optional Deploy-scenario path URI]
       [-R optional local relen repo (containing deployment Scenarios]

OPTIONS:
  -b  Base-uri for the stack-configuration structure
  -B  Bridge(s): 1st usage = PXE, 2nd = Mgmt, 3rd = Internal, 4th = Public
  -d  Dry-run
  -f  Deploy on existing Fuel master
  -e  Do not launch environment deployment
  -F  Do only create a Fuel master
  -h  Print this message and exit
  -H  No health check
  -l  Lab-name
  -L  Deployment log path and file name
  -p  Pod-name
  -s  Deploy-scenario short-name/base-file-name
  -S  Storage dir for VM images
  -T  Timeout, in minutes, for the deploy.
  -i  iso url

Description:
Deploys the Fuel@OPNFV stack on the indicated lab resource

This script provides the Fuel@OPNFV deployment abstraction
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.
Input parameters to the build script is:
-b Base URI to the configuration directory (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)
-B Bridges to be used by deploy script. It can be specified several times,
   or as a comma separated list of bridges, or both: -B br1 -B br2,br3
   First occurence sets PXE Brige, next Mgmt, then Internal and Public.
   For an empty value, the deploy script will use virsh to create the default
   expected network (e.g. -B pxe,,,public will use existing "pxe" and "public"
   bridges, respectively create "mgmt" and "internal").
   The default is pxebr.
-d Dry-run - Produces deploy config files (config/dea.yaml and
   config/dha.yaml), but does not execute deploy
-f Deploy on existing Fuel master
-e Do not launch environment deployment
-F Do only create a Fuel master
-h Print this message and exit
-H Do not run fuel built in health-check after successfull deployment
-l Lab name as defined in the configuration directory, e.g. lf
-L Deployment log path and name, eg. -L /home/jenkins/logs/job888.log.tar.gz
-p POD name as defined in the configuration directory, e.g. pod-1
-s Deployment-scenario, this points to a deployment/test scenario file as
   defined in the configuration directory:
   e.g fuel-ocl-heat-ceilometer_scenario_0.0.1.yaml
   or a deployment short-name as defined by scenario.yaml in the deployment
   scenario path.
-S Storage dir for VM images, default is fuel/deploy/images
-T Timeout, in minutes, for the deploy. It defaults to using the DEPLOY_TIMEOUT
   environment variable when defined, or to the default in deploy.py otherwise
-i .iso image to be deployed (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)

NOTE: Root priviledges are needed for this script to run


Examples:
sudo `basename $0` -b file:///home/jenkins/lab-config -l lf -p pod1 -s ha_odl-l3_heat_ceilometer -i file:///home/jenkins/myiso.iso
EOF
}

#
# END of usage description
############################################################################

############################################################################
# BEGIN of deployment clean-up
#
clean() {
    echo "Cleaning up deploy tmp directories"
    rm -rf ${SCRIPT_PATH}/ISO
}
#
# END of deployment clean-up
############################################################################

############################################################################
# BEGIN of shorthand variables for internal use
#
SCRIPT_PATH=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
DEPLOY_DIR=$(cd ${SCRIPT_PATH}/../mcp/scripts; pwd)
OPNFV_BRIDGES=('pxe' 'mgmt' 'internal' 'public')
NO_HEALTH_CHECK=''
USE_EXISTING_FUEL=''
FUEL_CREATION_ONLY=''
NO_DEPLOY_ENVIRONMENT=''
STORAGE_DIR=''
DRY_RUN=0
if ! [ -z $DEPLOY_TIMEOUT ]; then
    DEPLOY_TIMEOUT="-dt $DEPLOY_TIMEOUT"
else
    DEPLOY_TIMEOUT=""
fi
#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of main
#
OPNFV_BRIDGE_IDX=0
while getopts "b:B:dfFHl:L:p:s:S:T:i:he" OPTION
do
    case $OPTION in
        b)
            BASE_CONFIG_URI=${OPTARG}
            if [[ ! $BASE_CONFIG_URI == file://* ]] && \
               [[ ! $BASE_CONFIG_URI == http://* ]] && \
               [[ ! $BASE_CONFIG_URI == https://* ]] && \
               [[ ! $BASE_CONFIG_URI == ftp://* ]]; then
                echo "-b $BASE_CONFIG_URI - Not given in URI style"
                usage
                exit 1
            fi
            ;;
        B)
            OIFS=${IFS}
            IFS=','
            OPT_BRIDGES=($OPTARG)
            for bridge in "${OPT_BRIDGES[@]}"; do
                if [ -n "${bridge}" ]; then
                    OPNFV_BRIDGES[${OPNFV_BRIDGE_IDX}]="${bridge}"
                fi
                OPNFV_BRIDGE_IDX=$[OPNFV_BRIDGE_IDX + 1]
            done
            IFS=${OIFS}
            ;;
        d)
            DRY_RUN=1
            ;;
        f)
            USE_EXISTING_FUEL='-nf'
            ;;
        F)
            FUEL_CREATION_ONLY='-fo'
            ;;
        e)
            NO_DEPLOY_ENVIRONMENT='-nde'
            ;;
        H)
            NO_HEALTH_CHECK='-nh'
            ;;
        l)
            TARGET_LAB=${OPTARG}
            ;;
        L)
            DEPLOY_LOG="-log ${OPTARG}"
            ;;
        p)
            TARGET_POD=${OPTARG}
            ;;
        s)
            DEPLOY_SCENARIO=${OPTARG}
            ;;
        S)
            if [[ ${OPTARG} ]]; then
                STORAGE_DIR="-s ${OPTARG}"
            fi
            ;;
        T)
            DEPLOY_TIMEOUT="-dt ${OPTARG}"
            ;;
        i)
            ISO=${OPTARG}
            if [[ ! $ISO == file://* ]] && \
               [[ ! $ISO == http://* ]] && \
               [[ ! $ISO == https://* ]] && \
               [[ ! $ISO == ftp://* ]]; then
                echo "-i $ISO - Not given in URI style"
                usage
                exit 1
            fi
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            echo "${OPTION} is not a valid argument"
            echo "Arguments not according to new argument style"
            echo "Trying old-style compatibility mode"
            pushd ${DEPLOY_DIR} > /dev/null
            python deploy.py "$@"
            popd > /dev/null
            exit 0
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Enable the automatic exit trap
trap do_exit SIGINT SIGTERM EXIT

# Set no restrictive umask so that Jenkins can removeeee any residuals
umask 0000

clean

pushd ${DEPLOY_DIR} > /dev/null
# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.

# Install required packages
[ -n "$(command -v apt-get)" ] && apt-get install -y mkisofs curl virtinst cpu-checker qemu-kvm
[ -n "$(command -v yum)" ] && yum install -y genisoimage curl virt-install qemu-kvm

# Check scenario file existence
if [[ ! -f  ../config/${DEPLOY_SCENARIO}.yaml ]]; then
    echo "[WARN] ${DEPLOY_SCENARIO}.yaml not found, setting simplest scenario"
    DEPLOY_SCENARIO='os-nosdn-nofeature-noha'
fi

# Get required infra deployment data
source lib.sh
eval $(parse_yaml ../config/defaults.yaml)
eval $(parse_yaml ../config/${DEPLOY_SCENARIO}.yaml)

declare -A virtual_nodes_ram virtual_nodes_vcpus
for node in "${virtual_nodes[@]}"; do
    virtual_custom_ram="virtual_${node}_ram"
    virtual_custom_vcpus="virtual_${node}_vcpus"
    virtual_nodes_ram[$node]=${!virtual_custom_ram:-$virtual_default_ram}
    virtual_nodes_vcpus[$node]=${!virtual_custom_vcpus:-$virtual_default_vcpus}
done

export CLUSTER_DOMAIN=$cluster_domain
export SSH_KEY=${SSH_KEY:-mcp.rsa}
export SALT_MASTER=${SALT_MASTER_IP:-192.168.10.100}
export SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_KEY}"

# Infra setup
generate_ssh_key
prepare_vms virtual_nodes $base_image
create_networks OPNFV_BRIDGES
create_vms virtual_nodes virtual_nodes_ram virtual_nodes_vcpus OPNFV_BRIDGES
update_pxe_network OPNFV_BRIDGES
start_vms virtual_nodes
check_connection

./salt.sh

# Openstack cluster setup
for state in "${cluster_states[@]}"; do
    echo "STATE: $state"
    ssh ${SSH_OPTS} ubuntu@${SALT_MASTER} sudo /root/fuel/mcp/config/states/$state
done

## Disable Fuel deployment engine
#
# echo "python deploy-config.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dha.yaml -deab file://${DEPLOY_DIR}/config/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dea-pod-override.yaml -scenario-base-uri file://${DEPLOY_DIR}/scenario -scenario ${DEPLOY_SCENARIO} -plugins file://${DEPLOY_DIR}/config/plugins -output ${SCRIPT_PATH}/config"
#
# python deploy-config.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dha.yaml -deab file://${DEPLOY_DIR}/config/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dea-pod-override.yaml -scenario-base-uri file://${DEPLOY_DIR}/scenario -scenario ${DEPLOY_SCENARIO} -plugins file://${DEPLOY_DIR}/config/plugins -output ${SCRIPT_PATH}/config
#
# if [ $DRY_RUN -eq 0 ]; then
#     # Download iso if it doesn't already exists locally
#     if [[ $ISO == file://* ]]; then
#         ISO=${ISO#file://}
#     else
#         mkdir -p ${SCRIPT_PATH}/ISO
#         curl -o ${SCRIPT_PATH}/ISO/image.iso $ISO
#         ISO=${SCRIPT_PATH}/ISO/image.iso
#     fi
#     # Start deployment
#     echo "python deploy.py $DEPLOY_LOG $STORAGE_DIR $PXE_BRIDGE $USE_EXISTING_FUEL $FUEL_CREATION_ONLY $NO_HEALTH_CHECK $NO_DEPLOY_ENVIRONMENT -dea ${SCRIPT_PATH}/config/dea.yaml -dha ${SCRIPT_PATH}/config/dha.yaml -iso $ISO $DEPLOY_TIMEOUT"
#     python deploy.py $DEPLOY_LOG $STORAGE_DIR $PXE_BRIDGE $USE_EXISTING_FUEL $FUEL_CREATION_ONLY $NO_HEALTH_CHECK $NO_DEPLOY_ENVIRONMENT -dea ${SCRIPT_PATH}/config/dea.yaml -dha ${SCRIPT_PATH}/config/dha.yaml -iso $ISO $DEPLOY_TIMEOUT
# fi
popd > /dev/null

#
# END of main
############################################################################
