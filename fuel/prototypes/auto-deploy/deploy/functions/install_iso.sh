##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

fuelIp=`dea getFuelIp` || error_exit "Could not get fuel IP"
fuelNodeId=`dha getFuelNodeId` || error_exit "Could not get fuel node id"


if dha nodeCanZeroMBR $fuelNodeId; then
  echo "Node $fuelNodeId capable of zeroing MBR so doing that..."
  dha nodeZeroMBR $fuelNodeId || error_exit "Failed to zero Fuel MBR"
  dha nodeSetBootOrder $fuelNodeId  "disk iso"
elif dha nodeCanSetBootOrderLive; then
  echo "Node can change ISO boot order live"
  dha nodeSetBootOrder $fuelNodeId  "iso disk"
else
  error_exit "No way to install Fuel node"
fi

sleep 3
dha nodeEjectIso $fuelNodeId
dha nodeInsertIso $fuelNodeId $isofile

sleep 3
dha nodePowerOn $fuelNodeId

# Switch back boot order to disk, hoping that node is now up

# FIXME: Can we do a smarter and more generic detection of when the
# FIXME: kickstart procedure has started? Then th dha_waitForIsoBoot
# FIXME: can be removed. Setting and IP already in the kickstart install
# FIXME: and ping-wait for that?
dha waitForIsoBoot

dha nodeSetBootOrder $fuelNodeId "disk iso"

# wait for node up
echo "Waiting for Fuel master to accept SSH"
while true
do
  ssh root@${fuelIp} date 2>/dev/null
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 10
done

# Wait until fuelmenu is up
echo "Waiting for fuelmenu to come up"
menuPid=""
while [ -z "$menuPid" ]
do
  menuPid=`ssh root@${fuelIp} "ps -ef" 2>&1 | grep fuelmenu | grep -v grep | awk '{ print $2 }'`
  sleep 10
done

# This is where we inject our own astute.yaml settings
scp -q $deafile root@${fuelIp}:. || error_exit "Could not copy DEA file to Fuel"
echo "Uploading build tools to Fuel server"
ssh root@${fuelIp} rm -rf tools || error_exit "Error cleaning old tools structure"
scp -qrp $topdir/tools root@${fuelIp}:. || error_exit "Error copying tools"
echo "Running transplant #0"
ssh root@${fuelIp} "cd tools; ./transplant0.sh ../`basename $deafile`" \
    || error_exit "Error running transplant sequence #0"



# Let the Fuel deployment continue
echo "Found menu as PID $menuPid, now killing it"
ssh root@${fuelIp} "kill $menuPid" 2>/dev/null

# Wait until installation complete
echo "Waiting for bootstrap of Fuel node to complete"
while true
do
  ssh root@${fuelIp} "ps -ef" 2>/dev/null \
    | grep -q /usr/local/sbin/bootstrap_admin_node
  if [ $? -ne 0 ]; then
    break
  fi
  sleep 10
done

echo "Waiting for one minute for Fuel to stabilize"
sleep 1m
