#!/bin/bash -e
# shellcheck disable=SC2034,SC2154,SC1090,SC1091,SC2155
##############################################################################
# Copyright (c) 2018 Ericsson AB, Mirantis Inc., Enea AB and others.
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
        notify_n "[OK] MCP: Installation of $DEPLOY_SCENARIO finished succesfully!" 2
    else
        notify_n "[ERROR] MCP: Installation  of $DEPLOY_SCENARIO threw a fatal error!"
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
$(notify "$(basename "$0"): Deploy the OPNFV Fuel MCP stack" 3)

$(notify "USAGE:" 2)
  $(basename "$0") -l lab-name -p pod-name -s deploy-scenario \\
    [-b Lab Config Base URI] \\
    [-S storage-dir] [-L /path/to/log/file.tar.gz] \\
    [-f] [-F[F]] [-e[e] | -E[E]] [-d] [-D] [-N] [-m] \\
    [-o operating-system]

$(notify "OPTIONS:" 2)
  -b  Base-uri for the stack-configuration structure
  -d  Dry-run
  -D  Debug logging
  -e  Do not launch environment deployment (use twice to skip cloud setup)
  -E  Remove existing VCP VMs (use twice to redeploy baremetal nodes)
  -f  Deploy on existing Salt master (use twice or more to skip states)
  -F  Same as -e, do not launch environment deployment (legacy option)
  -h  Print this message and exit
  -l  Lab-name
  -p  Pod-name
  -o  Use specified operating system for jumpserver/VCP VMs
  -P  Skip installation of package dependencies
  -s  Deploy-scenario short-name
  -S  Storage dir for VM images and other deploy artifacts
  -L  Deployment log path and file name
  -m  Use single socket CPU compute nodes (only affects virtual computes)
  -N  Experimental: Do not virtualize control plane (novcp)

$(notify_i "Description:" 2)
Deploys the OPNFV Fuel stack on the indicated lab resource.

This script provides the OPNFV Fuel deployment abstraction.
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
-d Dry-run - Produce deploy config files, but do not execute deploy
-D Debug logging - Enable extra logging in sh deploy scripts (set -x)
-e Do not launch environment deployment
   If specified twice (e.g. -e -e), only the operating system and networks
   will be provisioned, skipping cloud installation.
-E Remove existing VCP VMs. It will destroy and undefine all VCP VMs
   currently defined on cluster KVM nodes. If specified twice (e.g. -E -E),
   baremetal nodes (VCP too, implicitly) will be removed, then reprovisioned.
   Only applicable for baremetal deploys.
   If specified 3 times, a complete uninstallation (cleanup) will be performed
   on the jumpserver (even for virtual deploys): VMs, virsh networks,
   containers, networks, services etc.
-f Deploy on existing Salt master. It will skip infrastructure VM creation,
   but it will still sync reclass configuration from current repo to Salt
   Master node.
   Each additional use skips one more state file. For example, -fff would
   skip the first 3 state files (e.g. virtual_init, maas, baremetal_init).
-F Same as -e, do not launch environment deployment (legacy option)
-h Print this message and exit
-L Deployment log path and name, eg. -L /home/jenkins/job.log.tar.gz
-l Lab name as defined in the configuration directory, e.g. lf
-p POD name as defined in the configuration directory, e.g. pod2
-m Use single socket compute nodes. Instead of using default NUMA-enabled
   topology for virtual compute nodes created via libvirt, configure a
   single guest CPU socket.
-N Experimental: Instead of virtualizing the control plane (VCP), deploy
   control plane directly on baremetal nodes
-o Operating system to be preinstalled on jumpserver VMs (for virtual/hybrid
   deployments) and/or VCP VMs (for baremetal deployments).
   Defaults to 'ubuntu1804' (Bionic).
-P Skip installing dependency distro packages on current host
   This flag should only be used if you have kept back older packages that
   would be upgraded and that is undesirable on the current system.
   Note that without the required packages, deploy will fail.
-s Deployment-scenario, this points to a short deployment scenario name, which
   has to be defined in config directory (e.g. os-odl-nofeature-ha).
-S Storage dir for VM images, default is /var/lib/opnfv/tmpdir
   It is recommended to store the deploy artifacts on a fast disk, outside of
   the current git repository (so clean operations won't erase it).

$(notify_i "[NOTE] sudo & virsh priviledges are needed for this script to run" 3)

Example:

$(notify_i "sudo $(basename "$0") \\
  -b file:///home/jenkins/securedlab \\
  -l lf -p pod2 \\
  -s os-odl-nofeature-ha \\
  -S /home/jenkins/tmpdir" 2)
EOF
}

#
# END of usage description
##############################################################################

##############################################################################
# BEGIN of variables to customize
#
CI_DEBUG=${CI_DEBUG:-0}; [[ "${CI_DEBUG}" =~ (false|0) ]] || set -x
MCP_REPO_ROOT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
DEPLOY_DIR=$(cd "${MCP_REPO_ROOT_PATH}/mcp/scripts"; pwd)
MCP_STORAGE_DIR='/var/lib/opnfv/tmpdir'
URI_REGEXP='(file|https?|ftp)://.*'
BASE_CONFIG_URI="file://${MCP_REPO_ROOT_PATH}/mcp/scripts/pharos"
OPNFV_BRANCH=$(sed -ne 's/defaultbranch=//p' "${MCP_REPO_ROOT_PATH}/.gitreview")
DEF_DOCKER_TAG=$(basename "${OPNFV_BRANCH/master/latest}")

# Customize deploy workflow
DRY_RUN=${DRY_RUN:-0}
USE_EXISTING_PKGS=${USE_EXISTING_PKGS:-0}
USE_EXISTING_INFRA=${USE_EXISTING_INFRA:-0}
MCP_NO_DEPLOY_ENVIRONMENT=${MCP_NO_DEPLOY_ENVIRONMENT:-0}
ERASE_ENV=${ERASE_ENV:-0}
MCP_VCP=${MCP_VCP:-1}
MCP_DOCKER_TAG=${MCP_DOCKER_TAG:-${DEF_DOCKER_TAG}}
MCP_CMP_SS=${MCP_CMP_SS:-0}
MCP_OS=${MCP_OS:-ubuntu1804}

source "${DEPLOY_DIR}/globals.sh"
source "${DEPLOY_DIR}/lib.sh"
source "${DEPLOY_DIR}/lib_template.sh"
source "${DEPLOY_DIR}/lib_jump_common.sh"
source "${DEPLOY_DIR}/lib_jump_deploy.sh"

#
# END of variables to customize
##############################################################################

##############################################################################
# BEGIN of main
#
set +x
while getopts "b:dDfEFl:L:No:p:Ps:S:he" OPTION
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
        F|e)
            ((MCP_NO_DEPLOY_ENVIRONMENT+=1))
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
        m)
            MCP_CMP_SS=1
            ;;
        N)
            MCP_VCP=0
            ;;
        o)
            MCP_OS=${OPTARG}
            ;;
        p)
            TARGET_POD=${OPTARG}
            ;;
        P)
            USE_EXISTING_PKGS=1
            ;;
        s)
            DEPLOY_SCENARIO=${OPTARG}
            ;;
        S)
            if [[ ${OPTARG} ]]; then
                MCP_STORAGE_DIR="${OPTARG}"
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
sudo mkdir -p "${MCP_STORAGE_DIR}"
sudo chown -R "${USER}:${USER}" "${MCP_STORAGE_DIR}"
if [ ${USE_EXISTING_PKGS} -eq 1 ]; then
    notify "[NOTE] Skipping distro pkg installation" 2
else
    notify "[NOTE] Installing required distro pkgs" 2
    jumpserver_pkg_install 'deploy'
    docker_install "${MCP_STORAGE_DIR}"
    virtinst_install "${MCP_STORAGE_DIR}"
    # Ubuntu 18.04 cloud image requires newer e2fsprogs
    if [[ "${MCP_OS:-}" =~ ubuntu1804 ]]; then
        e2fsprogs_install "${MCP_STORAGE_DIR}"
    fi
fi

if ! ${VIRSH} list >/dev/null 2>&1; then
    notify_e "[ERROR] This script requires hypervisor access"
fi

# Collect jump server system information for deploy debugging
./sysinfo_print.sh

# Clone git submodules and apply our patches
make -C "${MCP_REPO_ROOT_PATH}/mcp/patches" deepclean patches-import

# Check scenario file existence
SCENARIO_DIR="$(readlink -f "../config/scenario")"
if [ ! -f "${SCENARIO_DIR}/${DEPLOY_SCENARIO}.yaml" ] && \
   [ ! -f "${SCENARIO_DIR}/${DEPLOY_SCENARIO}.yaml.j2" ]; then
    notify_e "[ERROR] Scenario definition file is missing!"
fi

# key might not exist yet ...
generate_ssh_key
export MAAS_SSH_KEY="$(cat "$(basename "${SSH_KEY}").pub")"

# Expand jinja2 templates based on PDF data and env vars
[[ "${DEPLOY_SCENARIO}" =~ -ha$ ]] || MCP_VCP=0
export MCP_REPO_ROOT_PATH MCP_VCP MCP_STORAGE_DIR MCP_DOCKER_TAG MCP_CMP_SS \
       MCP_JUMP_ARCH=$(uname -i) MCP_DEPLOY_SCENARIO="${DEPLOY_SCENARIO}" \
       MCP_NO_DEPLOY_ENVIRONMENT MCP_OS MCP_KERNEL_VER
do_templates_scenario "${MCP_STORAGE_DIR}" "${TARGET_LAB}" "${TARGET_POD}" \
                      "${BASE_CONFIG_URI}" "${SCENARIO_DIR}" \
                      "${SCENARIO_DIR}/${DEPLOY_SCENARIO}.yaml"
do_templates_cluster  "${MCP_STORAGE_DIR}" "${TARGET_LAB}" "${TARGET_POD}" \
                      "${MCP_REPO_ROOT_PATH}" \
                      "${SCENARIO_DIR}/defaults.yaml"

# Determine additional data (e.g. jump bridge names) based on XDF
source "${DEPLOY_DIR}/xdf_data.sh"

# Jumpserver prerequisites check
notify "[NOTE] Using bridges: ${OPNFV_BRIDGES[*]}" 2
jumpserver_check_requirements "${cluster_states[*]}" "${virtual_nodes[*]}" \
                              "${OPNFV_BRIDGES[@]}"

# Infra setup
if [ ${DRY_RUN} -eq 1 ]; then
    notify "[NOTE] Dry run, skipping all deployment tasks" 2
    exit 0
elif [ ${ERASE_ENV} -gt 2 ]; then
    notify "[NOTE] Uninstall / cleanup all jumpserver Fuel resources" 2
    cleanup_all "${MCP_STORAGE_DIR}" "${OPNFV_BRIDGES[@]}"
    exit 0
elif [ ${USE_EXISTING_INFRA} -gt 0 ]; then
    notify "[NOTE] Use existing infra: skip first ${USE_EXISTING_INFRA} states" 2
    notify "[STATE] Skipping: ${cluster_states[*]::${USE_EXISTING_INFRA}}" 2
else
    prepare_vms "${base_image}" "${MCP_STORAGE_DIR}" "${virtual_repos_pkgs}"
    create_networks "${OPNFV_BRIDGES[@]}"
    do_sysctl_cfg
    do_udev_cfg
    create_vms "${MCP_STORAGE_DIR}" "${virtual_nodes_data}" "${OPNFV_BRIDGES[@]}"
    start_vms "${virtual_nodes[@]}"

    # https://github.com/docker/libnetwork/issues/1743
    # rm -f /var/lib/docker/network/files/local-kv.db
    sudo systemctl restart docker
    prepare_containers "${MCP_STORAGE_DIR}"
fi

start_containers "${MCP_STORAGE_DIR}"
check_connection

# Openstack cluster setup
set +x
if [ ${MCP_NO_DEPLOY_ENVIRONMENT} -eq 1 ]; then
    notify "[NOTE] Skip openstack cluster setup" 2
else
    for state in "${cluster_states[@]:${USE_EXISTING_INFRA}}"; do
        notify "[STATE] Applying state: ${state}" 2
        # shellcheck disable=SC2086,2029
        wait_for 5 "ssh ${SSH_OPTS} ${SSH_SALT} sudo \
            CI_DEBUG=$CI_DEBUG ERASE_ENV=$ERASE_ENV \
            /root/fuel/mcp/config/states/${state}"
        if [ "${state}" = 'maas' ]; then
            # For hybrid PODs (virtual + baremetal nodes), the virtual nodes
            # should be reset to force a DHCP request from MaaS DHCP
            reset_vms "${virtual_nodes[@]}"
        fi
    done

    ./log.sh "${DEPLOY_LOG}"
fi

popd > /dev/null

#
# END of main
##############################################################################
