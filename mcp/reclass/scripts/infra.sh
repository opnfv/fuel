#!/bin/bash

BASE_IMAGE=https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
declare -A NODES=( [cfg01]=4096 [ctl01]=8192 [ctl02]=8192 [ctl03]=8192 [gtw01]=2048 [cmp01]=6144 )

# get required packages
apt-get install -y mkisofs curl virtinst cpu-checker qemu-kvm

# generate ssh key
[ -f $SSH_KEY ] || ssh-keygen -f $SSH_KEY -N ''
cp $SSH_KEY /tmp/

# get base image
mkdir -p images
wget -P /tmp -nc $BASE_IMAGE

# generate cloud-init user data
envsubst < user-data.template > user-data.sh

for node in "${!NODES[@]}"; do
  # clean up existing nodes
  if [ "$(virsh domstate $node 2>/dev/null)" == 'running' ]; then
    virsh destroy $node
    virsh undefine $node
  fi

  # create/prepare images
  [ -f images/mcp_${node}.iso ] || ./create-config-drive.sh -k ${SSH_KEY}.pub -u user-data.sh -h ${node} images/mcp_${node}.iso
  cp /tmp/${BASE_IMAGE/*\/} images/mcp_${node}.qcow2
  qemu-img resize images/mcp_${node}.qcow2 100G
done

# create required networks
for net in pxe mgmt internal public; do
  if virsh net-info $net >/dev/null 2>&1; then
    virsh net-destroy ${net}
    virsh net-undefine ${net}
  fi
  virsh net-define net_${net}.xml
  virsh net-autostart ${net}
  virsh net-start ${net}
done

# create vms with specified options
for node in "${!NODES[@]}"; do
  virt-install --name ${node} --ram ${NODES[$node]} --vcpus=2 --cpu host --accelerate \
  --network network:pxe,model=virtio \
  --network network:mgmt,model=virtio \
  --network network:internal,model=virtio \
  --network network:public,model=virtio \
  --disk path=$(pwd)/images/mcp_${node}.qcow2,format=qcow2,bus=virtio,cache=none,io=native \
  --os-type linux --os-variant none \
  --boot hd --vnc --console pty --autostart --noreboot \
  --disk path=$(pwd)/images/mcp_${node}.iso,device=cdrom
done

# set static ip address for salt master node
virsh net-update pxe add ip-dhcp-host \
"<host mac='$(virsh domiflist cfg01 | awk '/pxe/ {print $5}')' name='cfg01' ip='$SALT_MASTER'/>" --live

# start vms
for node in "${!NODES[@]}"; do
  virsh start ${node}
  sleep $[RANDOM%5+1]
done

CONNECTION_ATTEMPTS=60
SLEEP=5

# wait until ssh on Salt master is available
echo "Attempting to ssh to Salt master ..."
ATTEMPT=1

while (($ATTEMPT <= $CONNECTION_ATTEMPTS)); do
  ssh $SSH_OPTS ubuntu@$SALT_MASTER uptime
  case $? in
    (0) echo "${ATTEMPT}> Success"; break ;;
    (*) echo "${ATTEMPT}/${CONNECTION_ATTEMPTS}> ssh server ain't ready yet, waiting for ${SLEEP} seconds ..." ;;
  esac
  sleep $SLEEP
  ((ATTEMPT+=1))
done
