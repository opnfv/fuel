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
        notify_n "[OK] MCP: Openstack installation finished succesfully!" 2
    else
        notify_n "[ERROR] MCP: Openstack installation threw a fatal error!"
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
    [-S storage-dir] [-L /path/to/log/file.tar.gz] \\
    [-f[f]] [-F] [-e | -E[E]] [-d] [-D]

$(notify "OPTIONS:" 2)
  -b  Base-uri for the stack-configuration structure
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

$(notify_i "Description:" 2)
Deploys the Fuel@OPNFV stack on the indicated lab resource.

This script provides the Fuel@OPNFV deployment abstraction.
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.

$(notify_i "Input parameters to the build script are:" 2)
-b Base URI to the configuration directory (needs to be provided in URI style,
   it can be a local resource: file:// or a remote resource http(s)://).
   A POD Descriptor File (PDF) and its Installer Descriptor File (IDF)
   companion should be available at:
   <base-uri>/labs/<lab-name>/<pod-name>.yaml
   <base-uri>/labs/<lab-name>/idf-<pod-name>.yaml
   The default is using the git submodule tracking 'OPNFV Pharos' in
   <./mcp/scripts/pharos>.
   An example config is provided inside current repo in
   <./mcp/config>, automatically linked as <./mcp/scripts/pharos/labs/local>.
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

$(notify_i "[NOTE] sudo & virsh priviledges are needed for this script to run" 3)

Example:

$(notify_i "sudo $(basename "$0") \\
  -b file:///home/jenkins/securedlab \\
  -l lf -p pod2 \\
  -s os-odl-nofeature-ha" 2)
EOF
}

#
# END of usage description
##############################################################################

##############################################################################
# BEGIN of variables to customize
#
CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
REPO_ROOT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
DEPLOY_DIR=$(cd "${REPO_ROOT_PATH}/mcp/scripts"; pwd)
STORAGE_DIR=$(cd "${REPO_ROOT_PATH}/mcp/deploy/images"; pwd)
DEPLOY_TYPE='baremetal'
BR_NAMES=('admin' 'mgmt' 'private' 'public')
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
while getopts "b:dDfEFl:L:p:Ps:S:he" OPTION
do
    case $OPTION in
        b)
            BASE_CONFIG_URI=${OPTARG}
            if [[ ! $BASE_CONFIG_URI =~ ${URI_REGEXP} ]]; then
                notify "[ERROR] -b $BASE_CONFIG_URI - invalid URI"
                usage
                exit 1
            fi
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
            if [[ "${TARGET_POD}" =~ virtual ]]; then
                DEPLOY_TYPE='virtual'
                # All vPODs will use 'local-virtual1' PDF/IDF for now
                TARGET_LAB='local'
                TARGET_POD='virtual1'
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
            notify_e "[ERROR] Unsupported arg, see -h for help"
            ;;
    esac
done

if [[ "$(sudo whoami)" != 'root' ]]; then
    notify_e "[ERROR] This script requires sudo rights"
fi

# Validate mandatory arguments are set
if [ -z "${TARGET_LAB}" ] || [ -z "${TARGET_POD}" ] || \
   [ -z "${DEPLOY_SCENARIO}" ]; then
    usage
    notify_e "[ERROR] At least one of the mandatory args is missing!"
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
    notify "[NOTE] Skipping distro pkg installation" 2
else
    notify "[NOTE] Installing required distro pkgs" 2
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
    notify_e "[ERROR] This script requires hypervisor access"
fi

# Collect jump server system information for deploy debugging
./sysinfo_print.sh

# Clone git submodules and apply our patches
make -C "${REPO_ROOT_PATH}/mcp/patches" deepclean patches-import

# Check scenario file existence
SCENARIO_DIR="../config/scenario"
if [ ! -f  "${SCENARIO_DIR}/${DEPLOY_TYPE}/${DEPLOY_SCENARIO}.yaml" ]; then
    notify_e "[ERROR] Scenario definition file is missing!"
fi

# Check defaults file existence
if [ ! -f  "${SCENARIO_DIR}/defaults-$(uname -i).yaml" ]; then
    notify_e "[ERROR] Scenario defaults file is missing!"
fi

# Expand jinja2 templates based on PDF data and env vars
do_templates "${REPO_ROOT_PATH}" "${BASE_CONFIG_URI}" "${STORAGE_DIR}" \
             "${TARGET_LAB}" "${TARGET_POD}"

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

# Determine 'admin', 'mgmt', 'private' and 'public' bridge names based on IDF
for ((i = 0; i < ${#BR_NAMES[@]}; i++)); do
    br_jump=$(eval echo "\$parameters__param_opnfv_jump_bridge_${BR_NAMES[i]}")
    if [ -n "${br_jump}" ] && [ "${br_jump}" != 'None' ]; then
        OPNFV_BRIDGES[${i}]="${br_jump}"
    fi
done
notify "[NOTE] Using bridges: ${OPNFV_BRIDGES[*]}" 2

# Infra setup
if [ ${DRY_RUN} -eq 1 ]; then
    notify "[NOTE] Dry run, skipping all deployment tasks" 2
    exit 0
elif [ ${USE_EXISTING_INFRA} -gt 0 ]; then
    notify "[NOTE] Use existing infra" 2
    check_connection
else
    generate_ssh_key
    prepare_vms "${base_image}" "${STORAGE_DIR}" "${virtual_repos_pkgs}" \
      "${virtual_nodes[@]}"
    create_networks "${OPNFV_BRIDGES[@]}"
    do_sysctl_cfg
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
    notify "[NOTE] Skip openstack cluster setup" 2
else
    for state in "${cluster_states[@]}"; do
        notify "[STATE] Applying state: ${state}" 2
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
