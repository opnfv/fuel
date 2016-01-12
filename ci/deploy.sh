#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
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

usage: `basename $0` -b base-uri -l lab-name -p pod-name -i iso
       -s deployment-scenario [-S optional Deploy-scenario path URI]
       [-R optional local relen repo (containing deployment Scenarios]

OPTIONS:
  -b  Base-uri for the stack-configuration structure
  -d  Dry-run

  -l  Lab-name
  -p  Pod-name
  -s  Deploy-scenario short-name/base-file-name
  -i  iso url

Description:
Deploys the Fuel@OPNFV stack on the indicated lab resource

This script provides the Fuel@OPNFV deployment abstraction
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.
Input parameters to the build script is:
-b Base URI to the configuration directory (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)
-d Dry-run - - Produces deploy config files (config/dea.yaml and
   config/dha.yaml), but does not execute deploy
-l Lab name as defined in the configuration directory, e.g. lf
-p POD name as defined in the configuration directory, e.g. pod-1
-s Deployment-scenario, this points to a deployment/test scenario file as
   defined in the configuration directory:
   e.g fuel-ocl-heat-ceilometer_scenario_0.0.1.yaml
   or a deployment short-name as defined by scenario.yaml in the deployment
   scenario path.
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
DEPLOY_DIR=$(cd ${SCRIPT_PATH}/../deploy; pwd)
DRY_RUN=0
#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of main
#
while getopts "b:dl:p:s:i:h" OPTION
do
    case $OPTION in
        b)
            BASE_CONFIG_URI=${OPTARG}
            ;;
        d)
            DRY_RUN=1
            ;;
        l)
            TARGET_LAB=${OPTARG}
            ;;
        p)
            TARGET_POD=${OPTARG}
            ;;
        s)
            DEPLOY_SCENARIO=${OPTARG}
            ;;
        i)
            ISO=${OPTARG}
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

if [ -z $BASE_CONFIG_URI ] || [ -z $TARGET_LAB ] || \
   [ -z $TARGET_POD ] || [ -z $DEPLOY_SCENARIO ] || \
   [ -z $ISO ]; then
    echo "Arguments not according to new argument style"
    echo "Trying old-style compatibility mode"
    pushd ${DEPLOY_DIR} > /dev/null
    python deploy.py "$@"
    popd > /dev/null
    exit 0
fi

# Enable the automatic exit trap
trap do_exit SIGINT SIGTERM EXIT

# Set no restrictive umask so that Jenkins can removeeee any residuals
umask 0000

clean

pushd ${DEPLOY_DIR} > /dev/null
# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.

echo "python deploy-config.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dha.yaml -deab ${DEPLOY_DIR}/config/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dea-pod-override.yaml -scenario-base-uri ${DEPLOY_DIR}/scenario -scenario ${DEPLOY_SCENARIO} -plugins ${DEPLOY_DIR}/config/plugins -output ${SCRIPT_PATH}/config"


python deploy-config.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dha.yaml -deab file://${DEPLOY_DIR}/config/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dea-pod-override.yaml -scenario-base-uri file://${DEPLOY_DIR}/scenario -scenario ${DEPLOY_SCENARIO} -plugins file://${DEPLOY_DIR}/config/plugins -output ${SCRIPT_PATH}/config

if [ $DRY_RUN -eq 0 ]; then
    # Download iso if it doesn't already exists locally
    if [[ $ISO == file://* ]]; then
        ISO=${ISO#file://}
    else
        mkdir -p ${SCRIPT_PATH}/ISO
        curl -o ${SCRIPT_PATH}/ISO/image.iso $ISO
        ISO=${SCRIPT_PATH}/ISO/image.iso
    fi
    # Start deployment
    echo "python deploy.py -dea ${SCRIPT_PATH}/config/dea.yaml -dha ${SCRIPT_PATH}/config/dha.yaml -iso $ISO"
    python deploy.py -dea ${SCRIPT_PATH}/config/dea.yaml -dha ${SCRIPT_PATH}/config/dha.yaml -iso $ISO
fi
popd > /dev/null

#
# END of main
############################################################################
