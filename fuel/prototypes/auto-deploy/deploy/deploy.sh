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

# Setup locations
topdir=$(dirname $(readlink -f $BASH_SOURCE))
exampledir=$(cd $topdir/../examples; pwd)
functions=${topdir}/functions

# Define common functions
. ${functions}/common.sh

exit_handler() {
  # Remove safety catch
  kill -9 `ps -p $killpid -o pid --no-headers` \
        `ps --ppid $killpid -o pid --no-headers`\
  > /dev/null 2>&1
}

usage()
{
    cat <<EOF
Syntax: `basename $0` [-nf] <isofile> <deafile> <dhafile>
Arguments
  -nf   Do not install Fuel master
EOF
}


# maximum allowed deploy time (default three hours)
MAXDEPLOYTIME=${MAXDEPLOYTIME-3h}

####### MAIN ########

time0=`date +%s`

if [ "`whoami`" != "root" ]; then
  error_exit "You need be root to run this script"
fi

# Set initial veriables
nofuel=1


# Check for arguments
if [ "$1" == "-nf" ]; then
    nofuel=0
    shift
fi

if [ $# -ne 3 ]; then
    usage
    exit 1
fi

# Setup tmpdir - if TMPDIR env variable is set, use that one
# else create in $HOME/fueltmp
if [ -n "${TMPDIR}" ]; then
    if [ -d ${TMPDIR} ]; then
        tmpdir=${TMPDIR}/fueltmp
        echo "Using TMPDIR=${TMPDIR}, so tmpdir=${tmpdir}"
    else
        error_exit "No such directory for TMPDIR: ${TMPDIR}"
    fi
else
    tmpdir=${HOME}/fueltmp
    echo "Default: tmpdir=$tmpdir"
fi

# Umask must be changed so files created are readable by qemu
umask 0022

if [ -d $tmpdir ]; then
  rm -Rf $tmpdir || error_exit "Could not remove tmpdir $tmpdir"
fi
mkdir $tmpdir || error_exit "Could not create tmpdir $tmpdir"

isofile=$(cd `dirname $1`; echo `pwd`/`basename $1`)
deafile=$(cd `dirname $2`; echo `pwd`/`basename $2`)
dhafile=$(cd `dirname $3`; echo `pwd`/`basename $3`)

if [ ! -f $isofile ]; then
  error_exit "Could not find ISO file $isofile"
elif [ ! -f $deafile ]; then
  error_exit "Could not find DEA file $deafile"
elif [ ! -f $dhafile ]; then
  error_exit "Could not find DHA file $dhafile"
fi

# Connect adapter
adapter=`grep "^adapter: " $dhafile | sed 's/.*: //'`
if [ -z "$adapter" ]; then
    error_exit "No adapter in DHA file!"
elif [ ! -f $topdir/dha-adapters/${adapter}.sh ]; then
    error_exit "Could not find adapter for $adapter"
else
    . $topdir/dha-adapters/${adapter}.sh $dhafile
fi

# Connect DEA API
. ${topdir}/functions/dea-api.sh $deafile

# Enable safety catch
echo "Enabling auto-kill if deployment exceeds $MAXDEPLOYTIME"
(sleep $MAXDEPLOYTIME; echo "Auto-kill of deploy after a timeout of $MAXDEPLOYTIME"; kill $$) &
killpid=$!

# Enable exit handler
trap exit_handler exit

# Get Fuel node information
fuelIp=`dea getFuelIp` || error_exit "Could not get Fuel IP"
fuelNetmask=`dea getFuelNetmask` || error_exit "Could not get Fuel netmask"
fuelGateway=`dea getFuelGateway` || error_exit "Could not get Fuel Gateway"
fuelHostname=`dea getFuelHostname` || error_exit "Could not get Fuel hostname"
fuelDns=`dea getFuelDns` || error_exit "Could not get Fuel DNS"
fuelNodeId=`dha getFuelNodeId` || error_exit "Could not get fuel node id"
dha useFuelCustomInstall
fuelCustom=$?

# Stop all VMs
for id in `dha getAllNodeIds`
do
  if [ $nofuel -eq 0 -o $fuelCustom -eq 0 ]; then
      if  [ $fuelNodeId -ne $id ]; then
          echo "Powering off id $id"
          dha nodePowerOff $id
      fi
  else
      echo "Powering off id $id"
      dha nodePowerOff $id
  fi
done

# Install the Fuel master
if [ $nofuel -eq 1 ]; then
    echo "Patching iso file"

    deployiso="${tmpdir}/deploy-`basename $isofile`"
    ${functions}/patch-iso.sh $isofile $deployiso $tmpdir \
        $fuelIp $fuelNetmask $fuelGateway $fuelHostname $fuelDns \
        || error_exit "Failed to patch ISO"

    # Swap isofiles from now on
    isofile=$deployiso
    if dha useFuelCustomInstall; then
        echo "Custom Fuel install"
        dha fuelCustomInstall $isofile || error_exit "Failed to run Fuel custom install"
    else
        echo "Ordinary Fuel install"
        . ${functions}/install_iso.sh || error_exit "Failed to install Fuel"
    fi
else
    echo "Not installing Fuel master"
fi

. ${functions}/deploy_env.sh

echo "Waiting for one minute for deploy to stabilize"
sleep 1m

echo "Verifying node status after deployment"
# Any node with non-ready status?
ssh root@${fuelIp} fuel node 2>/dev/null | tail -n +3 | cut -d "|" -f 2 | \
  sed 's/ //g' | grep -v ready | wc -l | grep -q "^0$"
if [ $? -ne 0 ]; then
  echo -e "Deploy failed to verify\n"
  ssh root@${fuelIp} fuel node 2>/dev/null
  error_exit "Exiting with error status"
else
  echo -e "Deployment verified\n"
  ssh root@${fuelIp} fuel node 2>/dev/null
  echo -e "\nNow running sanity and smoke health checks"
  echo -e "\n\n"
  ssh root@${fuelIp} fuel health --env ${envId} --check sanity,smoke \
      --force
  if [ $? -eq 0 ]; then
      echo "Health checks passed!"
  else
      error_exit "One or several health checks failed!"
  fi

  time1=`date +%s`
  echo "Total deployment time: $[(time1-time0)/60] minutes"
  exit 0
fi
