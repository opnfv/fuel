##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Deploy!
scp -q $deafile root@${fuelIp}:. || error_exit "Could not copy DEA file to Fuel"
echo "Uploading build tools to Fuel server"
ssh root@${fuelIp} rm -rf tools || error_exit "Error cleaning old tools structure"
scp -qrp $topdir/tools root@${fuelIp}:. || error_exit "Error copying tools"

echo "Uploading templating tols to Fuel server"
ssh root@${fuelIp} rm -rf create_templates || error_exit "Error cleaning old create_templates structure"
scp -qrp $topdir/../create_templates root@${fuelIp}:. || error_exit "Error copying create_templates"

# Refuse to run if environment already present
envcnt=`fuel env | tail -n +3 | grep -v '^$' | wc -l`
if [ $envcnt -ne 0 ]; then
  error_exit "Environment count is $envcnt"
fi

# Refuse to run if any nodes are up
nodeCnt=`numberOfNodesUp`
if [ $nodeCnt -ne 0 ]; then
  error_exit "Nodes are up (node count: $nodeCnt)"
fi

# FIXME: Add support for CentOS creation here
# Extract release ID for Ubuntu environment
ubuntucnt=`fuel release | grep Ubuntu | wc -l`
if [ $ubuntucnt -ne 1 ]; then
  error_exit "Not exacly one Ubuntu release found"
fi

# FIXME: Make release a property in the dea.yaml and use that instead!
ubuntuid=`fuel release | grep Ubuntu | awk '{ print $1 }'`

# Create environment
envName=`dea getProperty environment_name` || error_exit "Could not get environment name"
envMode=`dea getProperty environment_mode` || error_exit "Could not get environment mode"

fuel env create --name $envName \
    --rel $ubuntuid \
    --mode $envMode \
    --network-mode neutron \
    --net-segment-type vlan \
    || error_exit "Error creating environment"

envId=`ssh root@${fuelIp} fuel env | tail -n +3 | awk '{ print $1 }'` \
    || error_exit "Could not get environment id"

echo "Running transplant #1"
ssh root@${fuelIp} "cd tools; ./transplant1.sh ../`basename $deafile`" \
    || error_exit "Error running transplant sequence #1"

# Start VMs
strategy=`dha getPowerOnStrategy` || error_exit "Could not get power on strategy"
if [ $strategy == "all" ]; then
    echo "Starting all nodes at once"
    poweredOn=0
    for id in `dha getAllNodeIds`
    do
        if  [ $id -ne $fuelNodeId ]; then
            echo "Setting boot order pxe disk for node $id"
            dha nodeSetBootOrder $id "pxe disk" || "Could not set boot order for node"
            echo "Powering on node $id"
            dha nodePowerOn $id || error_exit "Could not power on node"
            poweredOn=$[poweredOn + 1]
        fi
    done
    # Wait for all nodes to be accounted for
    echo "Waiting for $poweredOn nodes to come up"
    while true
    do
        nodesUp=`numberOfNodesUp`
        echo -n "[${nodesUp}]"
        if [ $nodesUp -eq $poweredOn ]; then
            break
        fi
        sleep 10
    done
    echo "[${nodesUp}]"
else
    # Refuse to run if any nodes are defined
    totalNodeCnt=`numberOfNodes`
    if [ $totalNodeCnt -ne 0 ]; then
        error_exit "There are already ${totalNodeCnt} defined nodes, can not run power on in sequence!"
    fi
    echo "Starting nodes sequentially, waiting for Fuel detection until proceeding"
    for id in `dha getAllNodeIds`
    do
        if  [ $id -ne $fuelNodeId ]; then
            echo "Setting boot order pxe disk for node $id"
            dha nodeSetBootOrder $id "pxe disk" || "Could not set boot order for node"
            echo "Powering on node $id"
            dha nodePowerOn $id || error_exit "Could not power on node"
            # Wait for node count to increase
            waitForNode
        fi
    done
fi

# Set roles for detected hosts
for id in `dha getAllNodeIds`
do
    # If not a Fuel node
    if  [ $fuelNodeId -ne $id ]; then
        longMac=`dha getNodePxeMac $id` || \
            error_exit "Could not get MAC address for node $id from DHA"
        shortMac=`dea convertMacToShortMac $longMac`
        role="`dea getNodeRole $id`"
        echo "Setting role $role for Fuel node $shortMac (DEA node $id)"
        fuel node set --node-id $shortMac --role $role --env $envId \
            || error_exit "Could not set role for $node"
    fi
done

# Run pre-deploy with default input
# Need to set terminal as script does "clear" and needs curses support
ssh root@${fuelIp} "TERM=vt100 /opt/opnfv/pre-deploy.sh < /dev/null" \
    || error_exit "Pre-deploy failed"

# Inject node network config (will override pre-deploy Astute settings but we
# want to catch pre-deploy provisioning changes)
# TODO: There needs to be a function to adjust the NTP settings for clients
# TODO: to that of the actual set of controllers in this deployment.
echo "Running transplant #2"
ssh root@${fuelIp} "cd tools; ./transplant2.sh ../`basename $deafile`" \
    || error_exit "Error running transplant sequence #2"


# Deploy
echo "Deploying!"
ssh root@${fuelIp} "fuel deploy-changes --env $envId" >/dev/null 2>&1 || error_exit "Deploy failed"
echo "Deployment completed"
