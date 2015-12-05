#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
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
cat | more << EOF
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

Examples:
`basename $0` -b file:///home/jenkins/config -l lf -p pod1 -s ODL-OVS_DPDK-KVM_NFV -i file://myiso.iso
EOF
}
#
# END of usage description
############################################################################

############################################################################
# BEGIN of shorthand variables for internal use
#
SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
DEPLOY_DIR=$(cd ${topdir}/../deploy; pwd)
#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of main
#
while getopts "b:l:p:i:h" OPTION
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
   [ -z $TARGET_POD ] [ -z $DEPLOY_SCENARIO ] || [ -z $ISO ]; then
    echo "Missing arguments"
    usage
    exit 1
fi

set -o errexit

pushd ${DEPLOY_DIR} > /dev/null

# Prepare the deploy config files based on lab/pod information, deployment
# scenario, etc.
python deploy-cofig.py -dha ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/dha.yaml -deab ${BASE_CONFIG_URI}/installers/fuel/dea_base.yaml -deao ${BASE_CONFIG_URI}/labs/${TARGET_LAB}/${TARGET_POD}/fuel/dea-pod-override.yaml -scenario ${BASE_CONFIG_URI}/deploy-scenarios/fuel/${DEPLOY_SCENARIO} -plugins ${BASE_CONFIG_URI}/installers/fuel/plugins -output ${SCRIPT_DIR}/config

# Start deployment
python deploy.py -dea ${SCRIPT_DIR}/config/dea.yaml -dha ${SCRIPT_DIR}/config/dea.yaml -iso $ISO
popd > /dev/null
exit 0
#
# END of main
############################################################################
