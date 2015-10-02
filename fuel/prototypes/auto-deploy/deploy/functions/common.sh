##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Common functions

error_exit () {
  echo "Error: $@" >&2
  exit 1
}

ssh() {
  SSHPASS="r00tme" sshpass -e ssh -o UserKnownHostsFile=${tmpdir}/known_hosts \
    -o StrictHostKeyChecking=no -o ConnectTimeout=15 "$@"
}

scp() {
  SSHPASS="r00tme" sshpass -e scp  -o UserKnownHostsFile=${tmpdir}/known_hosts \
    -o StrictHostKeyChecking=no -o ConnectTimeout=15 "$@"
}


fuel () {
  ssh root@`dea getFuelIp` "fuel $@"
}


# TODO: Move numberOfNodes into the DEA API
numberOfNodes() {
  fuel node | tail -n +3 | grep -v "^$" | wc -l
}

# TODO: Move numberOfNodesUp into the DEA API
numberOfNodesUp() {
  fuel node | tail -n +3  | grep -v "^$" | grep True | wc -l
}

# Currently not used!
# Wait for node count to increase
waitForNode() {
  local cnt
  local initCnt
  local expectCnt

  initCnt=`numberOfNodesUp`
  expectCnt=$[initCnt+1]
  while true
  do
    cnt=`numberOfNodesUp`
    if [ $cnt -eq $expectCnt ]; then
      break
    elif [ $cnt -lt $initCnt ]; then
      error_exit "Node count decreased while waiting, $initCnt -> $cnt"
    elif [ $cnt -gt $expectCnt ]; then
      error_exit "Node count exceeded expect count, $cnt > $expectCnt"
    fi
    sleep 10
    echo -n "[${cnt}]"
  done
  echo "[${cnt}]"
}
