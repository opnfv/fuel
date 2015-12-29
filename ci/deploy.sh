#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

############################################################################
# BEGIN of usage description
#
usage ()
{
cat << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
`basename $0`: Deploys the Fuel@OPNFV stack

usage: `basename $0` -b base-uri -l lab-name -p pod-name -i iso

OPTIONS:
  -b  Base-uri for the stack-configuration structure
  -l  Lab-name
  -p  Pod-name
  -s  Deploy-scenario
  -i  iso url

Description:
Deploys the Fuel@OPNFV stack on the indicated lab resource

This script provides the Fuel@OPNFV deployment abstraction
It depends on the OPNFV official configuration directory/file structure
and provides a fairly simple mechanism to execute a deployment.
Input parameters to the build script is:
-b Base URI to the configuration directory (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)
-l Lab name as defined in the configuration directory, e.g. lf
-p POD name as defined in the configuration directory, e.g. pod-1
-s Deployment-scenario, this points to a deployment/test scenario file as
   defined in the configuration directory:
   e.g fuel-ocl-heat-ceilometer_scenario_0.0.1.yaml
-i .iso image to be deployed (needs to be provided in a URI
   style, it can be a local resource: file:// or a remote resource http(s)://)

For more information on the official configuration directory/file structure
please see the README file in this directory

Examples:
`basename $0` -b file:///home/jenkins/config -l lf -p pod1 -s fuel-ocl-heat-ceilometer_scenario_0.0.1.yaml -i file:///home/jenkins/myiso.iso
EOF
}

#
# END of usage description
############################################################################

############################################################################
# BEGIN of shorthand variables for internal use
#
SCRIPT_PATH=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
DEPLOY_DIR=$(cd ${SCRIPT_PATH}/../deploy; pwd)
#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of main
#
while getopts "b:l:p:s:i:h" OPTION
do
    case $OPTION in
        b)
            BASE_CONFIG_URI=${OPTARG}
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
            usage
            exit 1
            ;;
    esac
done

if [ -z $BASE_CONFIG_URI ] || [ -z $TARGET_LAB ] || \
   [ -z $TARGET_POD ] || [ -z $DEPLOY_SCENARIO ] || [ -z $ISO ]; then
    echo "Missing arguments"
    usage
    exit 1
fi

set -o errexit

pushd ${DEPLOY_DIR} > /dev/null
# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.
python deploy-config.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dha.yaml -deab ${BASE_CONFIG_URI}/installers/fuel/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/config/dea-pod-override.yaml -scenario ${BASE_CONFIG_URI}/deploy-scenarios/fuel/${DEPLOY_SCENARIO} -plugins ${BASE_CONFIG_URI}/installers/fuel/plugins -output ${SCRIPT_PATH}/config

# Download iso if it doesn't already exists locally
# TBD (Be a little more clever: dont copy if local)
if [[ $ISO == file://* ]]; then
    ISO=${ISO#file://}
    exit
else
    mkdir -p ${SCRIPT_PATH}/ISO
    curl -o ${SCRIPT_PATH}/ISO/image.iso $ISO
    ISO=${SCRIPT_PATH}/ISO/image.iso
fi
# Start deployment
python deploy.py -dea ${SCRIPT_PATH}/config/dea.yaml -dha ${SCRIPT_PATH}/config/dea.yaml -iso $ISO
popd > /dev/null

# TBD: Upload the test-section of the scenario yaml file to the fuel master:
# var/www/test.yaml

# Clean-up
echo "Cleaning up ci tmp directories"
rm -rf ${SCRIPT_PATH}/config
rm -rf ${SCRIPT_PATH}/ISO
exit 0
#
# END of main
############################################################################
