#!/bin/bash
# shellcheck disable=SC2034,SC2154,SC1091
set -ex
##############################################################################
# Copyright (c) 2017 Ericsson AB, Mirantis Inc., Enea AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# BEGIN of Exit handlers
#
do_exit () {
    clean
    echo "Exiting ..."
}
#
# End of Exit handlers
##############################################################################

##############################################################################
# BEGIN of usage description
#
usage ()
{
cat << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$(notify "$(basename "$0"): Deploy the Fuel@OPNFV MCP stack" 3)

$(notify "USAGE:" 2)
  $(basename "$0") -b base-uri -l lab-name -p pod-name -s deploy-scenario \\
    [-B PXE Bridge [-B Mgmt Bridge [-B Internal Bridge [-B Public Bridge]]]] \\
    [-S storage-dir] [-L /path/to/log/file.tar.gz]

$(notify "OPTIONS:" 2)
  -b  Base-uri for the stack-configuration structure
  -B  Bridge(s): 1st usage = PXE, 2nd = Mgmt, 3rd = Internal, 4th = Public
  -h  Print this message and exit
  -l  Lab-name
  -p  Pod-name
  -s  Deploy-scenario short-name
  -S  Storage dir for VM images
  -L  Deployment log path and file name

$(notify "DISABLED OPTIONS (not yet supported with MCP):" 3)
  -d  (disabled) Dry-run
  -e  (disabled) Do not launch environment deployment
  -f  (disabled) Deploy on existing Salt master
  -F  (disabled) Do only create a Salt master
  -i  (disabled) iso url
  -T  (disabled) Timeout, in minutes, for the deploy.

$(notify "Description:" 2)
Deploys the Fuel@OPNFV stack on the indicated lab resource.

This script provides the Fuel@OPNFV deployment abstraction.
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.

$(notify "Input parameters to the build script are:" 2)
-b Base URI to the configuration directory (needs to be provided in URI style,
   it can be a local resource: file:// or a remote resource http(s)://).
   A POD Descriptor File (PDF) should be available at:
   <base-uri>/labs/<lab-name>/<pod-name>.yaml
-B Bridges to be used by deploy script. It can be specified several times,
   or as a comma separated list of bridges, or both: -B br1 -B br2,br3
   First occurence sets PXE Brige, next Mgmt, then Internal and Public.
   For an empty value, the deploy script will use virsh to create the default
   expected network (e.g. -B pxe,,,public will use existing "pxe" and "public"
   bridges, respectively create "mgmt" and "internal").
   Note that a virtual network "mcpcontrol" is always created. For virtual
   deploys, "mcpcontrol" is also used for PXE, leaving the PXE bridge unused.
   For baremetal deploys, PXE bridge is used for baremetal node provisioning,
   while "mcpcontrol" is used to provision the infrastructure VMs only.
   Note: If a bridge name matches its default, a virtual network will be used,
         similar to omitting its value.
   The default is 'pxebr'.
-h Print this message and exit
-L Deployment log path and name, eg. -L /home/jenkins/job.log.tar.gz
-l Lab name as defined in the configuration directory, e.g. lf
-p POD name as defined in the configuration directory, e.g. pod2
-s Deployment-scenario, this points to a short deployment scenario name, which
   has to be defined in config directory (e.g. os-odl-nofeature-ha).
-S Storage dir for VM images, default is mcp/deploy/images

$(notify "Disabled input parameters (not yet supported with MCP):" 3)
-d (disabled) Dry-run - Produce deploy config files, but do not execute deploy
-f (disabled) Deploy on existing Salt master
-e (disabled) Do not launch environment deployment
-F (disabled) Do only create a Salt master
-T (disabled) Timeout, in minutes, for the deploy.
   It defaults to using the DEPLOY_TIMEOUT environment variable when defined.
-i (disabled) .iso image to be deployed (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)

$(notify "[NOTE] sudo & virsh priviledges are needed for this script to run" 3)

Example:

$(notify "sudo $(basename "$0") \\
  -b file:///home/jenkins/securedlab \\
  -l lf -p pod2 \\
  -s os-odl-nofeature-ha" 2)
EOF
}

#
# END of usage description
##############################################################################

##############################################################################
# BEGIN of colored notification wrapper
#
notify() {
    tput setaf "${2:-1}" || true
    echo -en "${1:-"[WARN] Unsupported opt arg: $3\\n"}"
    tput sgr0
}
#
# END of colored notification wrapper
##############################################################################

##############################################################################
# BEGIN of deployment clean-up
#
clean() {
    echo "Cleaning up deploy tmp directories"
}
#
# END of deployment clean-up
##############################################################################

##############################################################################
# BEGIN of variables to customize
#
SCRIPT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
DEPLOY_DIR=$(cd "${SCRIPT_PATH}/../mcp/scripts"; pwd)
STORAGE_DIR=$(cd "${SCRIPT_PATH}/../mcp/deploy/images"; pwd)
RECLASS_CLUSTER_DIR=$(cd "${SCRIPT_PATH}/../mcp/reclass/classes/cluster"; pwd)
DEPLOY_TYPE='baremetal'
OPNFV_BRIDGES=('pxebr' 'mgmt' 'internal' 'public')
URI_REGEXP='(file|https?|ftp)://.*'

export SSH_KEY=${SSH_KEY:-"/var/lib/opnfv/mcp.rsa"}
export SALT_MASTER=${INSTALLER_IP:-10.20.0.2}
export SALT_MASTER_USER=${SALT_MASTER_USER:-ubuntu}
export MAAS_IP=${MAAS_IP:-${SALT_MASTER%.*}.3}

# FIXME: should be determined from PDF
export MAAS_PXE_NETWORK=${MAAS_PXE_NETWORK:-192.168.11.0}

# Derivated from above global vars
export SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_KEY}"
export SSH_SALT="${SALT_MASTER_USER}@${SALT_MASTER}"

# Variables below are disabled for now, to be re-introduced or removed later
set +x
USE_EXISTING_FUEL=''
FUEL_CREATION_ONLY=''
NO_DEPLOY_ENVIRONMENT=''
DRY_RUN=0
if ! [ -z "${DEPLOY_TIMEOUT}" ]; then
    DEPLOY_TIMEOUT="-dt ${DEPLOY_TIMEOUT}"
else
    DEPLOY_TIMEOUT=""
fi
set -x
#
# END of variables to customize
##############################################################################

##############################################################################
# BEGIN of main
#
set +x
OPNFV_BRIDGE_IDX=0
while getopts "b:B:dfFl:L:p:s:S:T:i:he" OPTION
do
    case $OPTION in
        b)
            BASE_CONFIG_URI=${OPTARG}
            if [[ ! $BASE_CONFIG_URI =~ ${URI_REGEXP} ]]; then
                notify "[ERROR] -b $BASE_CONFIG_URI - invalid URI\n"
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
                OPNFV_BRIDGE_IDX=$((OPNFV_BRIDGE_IDX + 1))
            done
            IFS=${OIFS}
            ;;
        d)
            notify '' 3 "${OPTION}"; continue
            DRY_RUN=1
            ;;
        f)
            notify '' 3 "${OPTION}"; continue
            USE_EXISTING_FUEL='-nf'
            ;;
        F)
            notify '' 3 "${OPTION}"; continue
            FUEL_CREATION_ONLY='-fo'
            ;;
        e)
            notify '' 3 "${OPTION}"; continue
            NO_DEPLOY_ENVIRONMENT='-nde'
            ;;
        l)
            TARGET_LAB=${OPTARG}
            ;;
        L)
            DEPLOY_LOG="${OPTARG}"
            ;;
        p)
            TARGET_POD=${OPTARG}
            if [[ "${TARGET_POD}" =~ "virtual" ]]; then
                DEPLOY_TYPE='virtual'
            fi
            ;;
        s)
            DEPLOY_SCENARIO=${OPTARG}
            ;;
        S)
            if [[ ${OPTARG} ]]; then
                STORAGE_DIR="${OPTARG}"
            fi
            ;;
        T)
            notify '' 3 "${OPTION}"; continue
            DEPLOY_TIMEOUT="-dt ${OPTARG}"
            ;;
        i)
            notify '' 3 "${OPTION}"; continue
            ISO=${OPTARG}
            if [[ ! $ISO =~ ${URI_REGEXP} ]]; then
                notify "[ERROR] -i $ISO - invalid URI\n"
                usage
                exit 1
            fi
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            notify "[ERROR] Arguments not according to new argument style\n"
            exit 1
            ;;
    esac
done

if [[ "$(sudo whoami)" != 'root' ]]; then
    notify "This script requires sudo rights\n" 1>&2
    exit 1
fi

if ! virsh list >/dev/null 2>&1; then
    notify "This script requires hypervisor access\n" 1>&2
    exit 1
fi

# Validate mandatory arguments are set
if [ -z "${TARGET_LAB}" ] || [ -z "${TARGET_POD}" ] || \
   [ -z "${DEPLOY_SCENARIO}" ]; then
    notify "[ERROR] At least one of the mandatory args is missing!\n" 1>&2
    usage
    exit 1
fi

set -x

# Enable the automatic exit trap
trap do_exit SIGINT SIGTERM EXIT

# Set no restrictive umask so that Jenkins can remove any residuals
umask 0000

clean

pushd "${DEPLOY_DIR}" > /dev/null
# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.

# Install required packages
[ -n "$(command -v apt-get)" ] && sudo apt-get install -y \
  git make rsync mkisofs curl virtinst cpu-checker qemu-kvm
[ -n "$(command -v yum)" ] && sudo yum install -y --skip-broken \
  git make rsync genisoimage curl virt-install qemu-kvm

if [ "$(uname -i)" = "aarch64" ]; then
  [ -n "$(command -v apt-get)" ] && sudo apt-get install -y vgabios && \
  sudo ln -sf /usr/share/vgabios/vgabios.bin /usr/share/qemu/vgabios-stdvga.bin
  [ -n "$(command -v yum)" ] && sudo yum install -y --skip-broken vgabios
fi

# Convert Pharos-compatible POD Descriptor File (PDF) to reclass model input
BASE_CONFIG_PDF="${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}.yaml"
LOCAL_PDF="${STORAGE_DIR}/$(basename "${BASE_CONFIG_PDF}")"
LOCAL_PDF_RECLASS="${STORAGE_DIR}/pod_config.yml"
if ! curl --create-dirs -o "${LOCAL_PDF}" "${BASE_CONFIG_PDF}"; then
    if [ "${DEPLOY_TYPE}" = 'baremetal' ]; then
        notify "[ERROR] Could not retrieve PDF (Pod Descriptor File)!\n" 1>&2
        exit 1
    else
        notify "[WARN] Could not retrieve PDF (Pod Descriptor File)!\n" 3
    fi
elif ! ./pdf/generate_config.py -y "${LOCAL_PDF}" -j "pod_config.yml.j2" > \
   "${LOCAL_PDF_RECLASS}"; then
    notify "[ERROR] Could not convert PDF to reclass model input!\n" 1>&2
    exit 1
fi

# Check scenario file existence
SCENARIO_DIR="../config/scenario"
if [ ! -f  "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml" ]; then
    notify "[WARN] ${DEPLOY_SCENARIO}.yaml not found! \
            Setting simplest scenario (os-nosdn-nofeature-noha)\n" 3
    DEPLOY_SCENARIO='os-nosdn-nofeature-noha'
    if [ ! -f  "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml" ]; then
        notify "[ERROR] Scenario definition file is missing!\n" 1>&2
        exit 1
    fi
fi

# Check defaults file existence
if [ ! -f  "${SCENARIO_DIR}/defaults-$(uname -i).yaml" ]; then
    notify "[ERROR] Scenario defaults file is missing!\n" 1>&2
    exit 1
fi

# Get required infra deployment data
source lib.sh
eval "$(parse_yaml "${SCENARIO_DIR}/defaults-$(uname -i).yaml")"
eval "$(parse_yaml "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml")"
eval "$(parse_yaml \
    "${RECLASS_CLUSTER_DIR}/all-mcp-ocata-common/opnfv/pod_config.yml")"

export CLUSTER_DOMAIN=${cluster_domain}

declare -A virtual_nodes_ram virtual_nodes_vcpus
for node in "${virtual_nodes[@]}"; do
    virtual_custom_ram="virtual_${node}_ram"
    virtual_custom_vcpus="virtual_${node}_vcpus"
    virtual_nodes_ram[$node]=${!virtual_custom_ram:-$virtual_default_ram}
    virtual_nodes_vcpus[$node]=${!virtual_custom_vcpus:-$virtual_default_vcpus}
done

# Expand reclass and virsh network templates
for tp in "${RECLASS_CLUSTER_DIR}/all-mcp-ocata-common/opnfv/"*.template \
    net_*.template; do
        eval "cat <<-EOF
		$(<"${tp}")
		EOF" 2> /dev/null > "${tp%.template}"
done

# Map PDF networks 'admin', 'mgmt', 'private' and 'public' to bridge names
OPNFV_BRIDGE_IDX=0
for br_net in \
    "${parameters__param_opnfv_infra_config_address}" \
    "${parameters__param_opnfv_infra_config_deploy_address}" \
    "${parameters__param_opnfv_openstack_compute_node01_tenant_address}" \
    "${parameters__param_opnfv_openstack_compute_node01_external_address}"
do
    if [ -n "${br_net}" ]; then
        bridge=$(ip addr | awk "/${br_net%.*}./ {print \$NF; exit}")
        if [ -n "${bridge}" ]; then
            notify "[OK] Bridge found for net ${br_net%.*}.0: ${bridge}\n" 2
            OPNFV_BRIDGES[${OPNFV_BRIDGE_IDX}]="${bridge}"
        fi
    fi
    OPNFV_BRIDGE_IDX=$((OPNFV_BRIDGE_IDX + 1))
done
notify "[NOTE] Using bridges: ${OPNFV_BRIDGES[*]}\n" 2

# Infra setup
generate_ssh_key
prepare_vms virtual_nodes "${base_image}" "${STORAGE_DIR}"
create_networks OPNFV_BRIDGES
create_vms virtual_nodes virtual_nodes_ram virtual_nodes_vcpus \
    OPNFV_BRIDGES "${STORAGE_DIR}"
update_mcpcontrol_network
start_vms virtual_nodes
check_connection

./salt.sh "${LOCAL_PDF_RECLASS}"

# Openstack cluster setup
for state in "${cluster_states[@]}"; do
    notify "STATE: ${state}\n" 2
    # shellcheck disable=SC2086,2029
    ssh ${SSH_OPTS} "ubuntu@${SALT_MASTER}" \
        sudo "/root/fuel/mcp/config/states/${state} || true"
done

./log.sh "${DEPLOY_LOG}"

popd > /dev/null

#
# END of main
##############################################################################
