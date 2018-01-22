#!/bin/bash -e
# shellcheck disable=SC2034,SC2154,SC1090,SC1091
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
    local RC=$?
    cleanup_mounts > /dev/null 2>&1
    if [ ${RC} -eq 0 ]; then
        notify "\n[OK] MCP: Openstack installation finished succesfully!\n\n" 2
    else
        notify "\n[ERROR] MCP: Openstack installation threw a fatal error!\n\n"
    fi
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
  $(basename "$0") -l lab-name -p pod-name -s deploy-scenario \\
    [-b Lab Config Base URI] \\
    [-B PXE Bridge [-B Mgmt Bridge [-B Internal Bridge [-B Public Bridge]]]] \\
    [-S storage-dir] [-L /path/to/log/file.tar.gz] \\
    [-f[f]] [-F] [-e | -E[E]] [-d] [-D]

$(notify "OPTIONS:" 2)
  -b  Base-uri for the stack-configuration structure
  -B  Bridge(s): 1st usage = PXE, 2nd = Mgmt, 3rd = Internal, 4th = Public
  -d  Dry-run
  -D  Debug logging
  -e  Do not launch environment deployment
  -E  Remove existing VCP VMs (use twice to redeploy baremetal nodes)
  -f  Deploy on existing Salt master (use twice to also skip config sync)
  -F  Do only create a Salt master
  -h  Print this message and exit
  -l  Lab-name
  -p  Pod-name
  -P  Skip installation of package dependencies
  -s  Deploy-scenario short-name
  -S  Storage dir for VM images
  -L  Deployment log path and file name

$(notify "Description:" 2)
Deploys the Fuel@OPNFV stack on the indicated lab resource.

This script provides the Fuel@OPNFV deployment abstraction.
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.

$(notify "Input parameters to the build script are:" 2)
-b Base URI to the configuration directory (needs to be provided in URI style,
   it can be a local resource: file:// or a remote resource http(s)://).
   A POD Descriptor File (PDF) and its Installer Descriptor File (IDF)
   companion should be available at:
   <base-uri>/labs/<lab-name>/<pod-name>.yaml
   <base-uri>/labs/<lab-name>/idf-<pod-name>.yaml
   An example config is provided inside current repo in
   <./mcp/config>.
   The default is using the git submodule tracking 'OPNFV Pharos' in
   <./mcp/scripts/pharos>.
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
   The default is 'pxebr'.
-d Dry-run - Produce deploy config files, but do not execute deploy
-D Debug logging - Enable extra logging in sh deploy scripts (set -x)
-e Do not launch environment deployment
-E Remove existing VCP VMs. It will destroy and undefine all VCP VMs
   currently defined on cluster KVM nodes. If specified twice (e.g. -E -E),
   baremetal nodes (VCP too, implicitly) will be removed, then reprovisioned.
   Only applicable for baremetal deploys.
-f Deploy on existing Salt master. It will skip infrastructure VM creation,
   but it will still sync reclass configuration from current repo to Salt
   Master node. If specified twice (e.g. -f -f), config sync will also be
   skipped.
-F Do only create a Salt master
-h Print this message and exit
-L Deployment log path and name, eg. -L /home/jenkins/job.log.tar.gz
-l Lab name as defined in the configuration directory, e.g. lf
-p POD name as defined in the configuration directory, e.g. pod2
-P Skip installing dependency distro packages on current host
   This flag should only be used if you have kept back older packages that
   would be upgraded and that is undesirable on the current system.
   Note that without the required packages, deploy will fail.
-s Deployment-scenario, this points to a short deployment scenario name, which
   has to be defined in config directory (e.g. os-odl-nofeature-ha).
-S Storage dir for VM images, default is mcp/deploy/images

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
# BEGIN of variables to customize
#
CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
REPO_ROOT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
DEPLOY_DIR=$(cd "${REPO_ROOT_PATH}/mcp/scripts"; pwd)
STORAGE_DIR=$(cd "${REPO_ROOT_PATH}/mcp/deploy/images"; pwd)
RECLASS_CLUSTER_DIR=$(cd "${REPO_ROOT_PATH}/mcp/reclass/classes/cluster"; pwd)
DEPLOY_TYPE='baremetal'
OPNFV_BRIDGES=('pxebr' 'mgmt' 'internal' 'public')
URI_REGEXP='(file|https?|ftp)://.*'
BASE_CONFIG_URI="file://${REPO_ROOT_PATH}/mcp/scripts/pharos"

# Customize deploy workflow
DRY_RUN=${DRY_RUN:-0}
USE_EXISTING_PKGS=${USE_EXISTING_PKGS:-0}
USE_EXISTING_INFRA=${USE_EXISTING_INFRA:-0}
INFRA_CREATION_ONLY=${INFRA_CREATION_ONLY:-0}
NO_DEPLOY_ENVIRONMENT=${NO_DEPLOY_ENVIRONMENT:-0}
ERASE_ENV=${ERASE_ENV:-0}

source "${DEPLOY_DIR}/globals.sh"
source "${DEPLOY_DIR}/lib.sh"

#
# END of variables to customize
##############################################################################

##############################################################################
# BEGIN of main
#
set +x
OPNFV_BRIDGE_IDX=0
while getopts "b:B:dDfEFl:L:p:Ps:S:he" OPTION
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
                ((OPNFV_BRIDGE_IDX+=1))
            done
            IFS=${OIFS}
            ;;
        d)
            DRY_RUN=1
            ;;
        D)
            CI_DEBUG=1
            ;;
        f)
            ((USE_EXISTING_INFRA+=1))
            ;;
        F)
            INFRA_CREATION_ONLY=1
            ;;
        e)
            NO_DEPLOY_ENVIRONMENT=1
            ;;
        E)
            ((ERASE_ENV+=1))
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
        P)
            USE_EXISTING_PKGS=1
            ;;
        s)
            DEPLOY_SCENARIO=${OPTARG}
            ;;
        S)
            if [[ ${OPTARG} ]]; then
                STORAGE_DIR="${OPTARG}"
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
    notify "[ERROR] This script requires sudo rights\n" 1>&2
    exit 1
fi

# Validate mandatory arguments are set
if [ -z "${TARGET_LAB}" ] || [ -z "${TARGET_POD}" ] || \
   [ -z "${DEPLOY_SCENARIO}" ]; then
    notify "[ERROR] At least one of the mandatory args is missing!\n" 1>&2
    usage
    exit 1
fi

[[ "${CI_DEBUG}" =~ (false|0) ]] || set -x

# Enable the automatic exit trap
trap do_exit SIGINT SIGTERM EXIT

# Set no restrictive umask so that Jenkins can remove any residuals
umask 0000

pushd "${DEPLOY_DIR}" > /dev/null
# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.

# Install required packages on jump server
if [ ${USE_EXISTING_PKGS} -eq 1 ]; then
    notify "[NOTE] Skipping distro pkg installation\n" 2 1>&2
else
    notify "[NOTE] Installing required distro pkgs\n" 2 1>&2
    if [ -n "$(command -v apt-get)" ]; then
      pkg_type='deb'; pkg_cmd='sudo apt-get install -y'
    else
      pkg_type='rpm'; pkg_cmd='sudo yum install -y --skip-broken'
    fi
    eval "$(parse_yaml "./requirements_${pkg_type}.yaml")"
    for section in 'common' "${DEPLOY_TYPE}" "$(uname -m)"; do
      section_var="requirements_pkg_${section}[*]"
      pkg_list+=" ${!section_var}"
    done
    # shellcheck disable=SC2086
    ${pkg_cmd} ${pkg_list}
fi

if ! virsh list >/dev/null 2>&1; then
    notify "[ERROR] This script requires hypervisor access\n" 1>&2
    exit 1
fi

# Collect jump server system information for deploy debugging
./sysinfo_print.sh

# Clone git submodules and apply our patches
make -C "${REPO_ROOT_PATH}/mcp/patches" deepclean patches-import

# Convert Pharos-compatible POD Descriptor File (PDF) to reclass model input
PHAROS_GEN_CONFIG_SCRIPT="./pharos/config/utils/generate_config.py"
PHAROS_INSTALLER_ADAPTER="./pharos/config/installers/fuel/pod_config.yml.j2"
BASE_CONFIG_PDF="${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}.yaml"
BASE_CONFIG_IDF="${BASE_CONFIG_URI}/labs/${TARGET_LAB}/idf-${TARGET_POD}.yaml"
LOCAL_PDF="${STORAGE_DIR}/$(basename "${BASE_CONFIG_PDF}")"
LOCAL_IDF="${STORAGE_DIR}/$(basename "${BASE_CONFIG_IDF}")"
LOCAL_PDF_RECLASS="${STORAGE_DIR}/pod_config.yml"
if ! curl --create-dirs -o "${LOCAL_PDF}" "${BASE_CONFIG_PDF}"; then
    if [ "${DEPLOY_TYPE}" = 'baremetal' ]; then
        notify "[ERROR] Could not retrieve PDF (Pod Descriptor File)!\n" 1>&2
        exit 1
    else
        notify "[WARN] Could not retrieve PDF (Pod Descriptor File)!\n" 3
    fi
elif ! curl -o "${LOCAL_IDF}" "${BASE_CONFIG_IDF}"; then
    notify "[WARN] POD has no IDF (Installer Descriptor File)!\n" 3
elif ! "${PHAROS_GEN_CONFIG_SCRIPT}" -y "${LOCAL_PDF}" \
    -j "${PHAROS_INSTALLER_ADAPTER}" > "${LOCAL_PDF_RECLASS}"; then
    notify "[ERROR] Could not convert PDF to reclass model input!\n" 1>&2
    exit 1
fi

# Check scenario file existence
SCENARIO_DIR="../config/scenario"
if [ ! -f  "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml" ]; then
    notify "[WARN] ${DEPLOY_SCENARIO}.yaml not found!\n" 3
    notify "[WARN] Setting simplest scenario (os-nosdn-nofeature-noha)\n" 3
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
set +x
eval "$(parse_yaml "${SCENARIO_DIR}/defaults-$(uname -i).yaml")"
eval "$(parse_yaml "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml")"
eval "$(parse_yaml "${LOCAL_PDF_RECLASS}")"
[[ "${CI_DEBUG}" =~ (false|0) ]] || set -x

export CLUSTER_DOMAIN=${cluster_domain}

# Serialize vnode data as '<name0>,<ram0>,<vcpu0>|<name1>,<ram1>,<vcpu1>[...]'
for node in "${virtual_nodes[@]}"; do
    virtual_custom_ram="virtual_${node}_ram"
    virtual_custom_vcpus="virtual_${node}_vcpus"
    virtual_nodes_data+="${node},"
    virtual_nodes_data+="${!virtual_custom_ram:-$virtual_default_ram},"
    virtual_nodes_data+="${!virtual_custom_vcpus:-$virtual_default_vcpus}|"
done
virtual_nodes_data=${virtual_nodes_data%|}

# Serialize repos, packages to (pre-)install/remove for:
# - foundation node VM base image (virtual: all VMs, baremetal: cfg01|mas01)
# - virtualized control plane VM base image (only when VCP is used)
base_image_flavors=common
if [[ "${cluster_states[*]}" =~ virtual_control ]]; then
  base_image_flavors+=" control"
fi
for sc in ${base_image_flavors}; do
  for va in apt_keys apt_repos pkg_install pkg_remove; do
    key=virtual_${sc}_${va}
    eval "${key}=\${${key}[@]// /|}"
    eval "${key}=\${${key}// /,}"
    virtual_repos_pkgs+="${!key}^"
  done
done
virtual_repos_pkgs=${virtual_repos_pkgs%^}

# Expand reclass and virsh network templates
for tp in "${RECLASS_CLUSTER_DIR}/all-mcp-arch-common/opnfv/"*.template \
    net_*.template; do
        eval "cat <<-EOF
		$(<"${tp}")
		EOF" 2> /dev/null > "${tp%.template}"
done

# Convert Pharos-compatible PDF to reclass network definitions
if [ "${DEPLOY_TYPE}" = 'baremetal' ]; then
    find "${RECLASS_CLUSTER_DIR}" -name '*.j2' | while read -r tp
    do
        if ! "${PHAROS_GEN_CONFIG_SCRIPT}" -y "${LOCAL_PDF}" \
          -j "${tp}" > "${tp%.j2}"; then
             notify "[ERROR] Could not convert PDF to reclass network defs!\n"
             exit 1
        fi
    done
fi

# Map PDF networks 'admin', 'mgmt', 'private' and 'public' to bridge names
BR_NAMES=('admin' 'mgmt' 'private' 'public')
BR_NETS=( \
    "${paramaters__param_opnfv_infra_maas_pxe_address}" \
    "${parameters__param_opnfv_infra_config_address}" \
    "${parameters__param_opnfv_openstack_compute_node01_tenant_address}" \
    "${parameters__param_opnfv_openstack_compute_node01_external_address}" \
)
for ((i = 0; i < ${#BR_NETS[@]}; i++)); do
    br_jump=$(eval echo "\$parameters__param_opnfv_jump_bridge_${BR_NAMES[i]}")
    if [ -n "${br_jump}" ] && [ "${br_jump}" != 'None' ] && \
       [ -d "/sys/class/net/${br_jump}/bridge" ]; then
            notify "[OK] Bridge found for '${BR_NAMES[i]}': ${br_jump}\n" 2
            OPNFV_BRIDGES[${i}]="${br_jump}"
    elif [ -n "${BR_NETS[i]}" ]; then
        bridge=$(ip addr | awk "/${BR_NETS[i]%.*}./ {print \$NF; exit}")
        if [ -n "${bridge}" ] && [ -d "/sys/class/net/${bridge}/bridge" ]; then
            notify "[OK] Bridge found for net ${BR_NETS[i]%.*}.0: ${bridge}\n" 2
            OPNFV_BRIDGES[${i}]="${bridge}"
        fi
    fi
done
notify "[NOTE] Using bridges: ${OPNFV_BRIDGES[*]}\n" 2

# Infra setup
if [ ${DRY_RUN} -eq 1 ]; then
    notify "[NOTE] Dry run, skipping all deployment tasks\n" 2 1>&2
    exit 0
elif [ ${USE_EXISTING_INFRA} -gt 0 ]; then
    notify "[NOTE] Use existing infra\n" 2 1>&2
    check_connection
else
    generate_ssh_key
    prepare_vms "${base_image}" "${STORAGE_DIR}" "${virtual_repos_pkgs}" \
      "${virtual_nodes[@]}"
    create_networks "${OPNFV_BRIDGES[@]}"
    create_vms "${STORAGE_DIR}" "${virtual_nodes_data}" "${OPNFV_BRIDGES[@]}"
    update_mcpcontrol_network
    start_vms "${virtual_nodes[@]}"
    check_connection
fi
if [ ${USE_EXISTING_INFRA} -lt 2 ]; then
    wait_for 5 "./salt.sh ${LOCAL_PDF_RECLASS}"
fi

# Openstack cluster setup
set +x
if [ ${INFRA_CREATION_ONLY} -eq 1 ] || [ ${NO_DEPLOY_ENVIRONMENT} -eq 1 ]; then
    notify "[NOTE] Skip openstack cluster setup\n" 2
else
    for state in "${cluster_states[@]}"; do
        notify "[STATE] Applying state: ${state}\n" 2
        # shellcheck disable=SC2086,2029
        wait_for 5 "ssh ${SSH_OPTS} ${SSH_SALT} sudo \
            CI_DEBUG=$CI_DEBUG ERASE_ENV=$ERASE_ENV \
            /root/fuel/mcp/config/states/${state}"
    done
fi

./log.sh "${DEPLOY_LOG}"

popd > /dev/null

#
# END of main
##############################################################################
