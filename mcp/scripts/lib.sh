#
# Library of shell functions
#

generate_ssh_key() {
  [ -f "$SSH_KEY" ] || ssh-keygen -f ${SSH_KEY} -N ''
  install -o $USER -m 0600 ${SSH_KEY} /tmp/
}

get_base_image() {
  local base_image=$1

  mkdir -p images
  wget -P /tmp -nc $base_image
}

cleanup_vms() {
  # clean up existing nodes
  for node in $(virsh list --name --all | grep -P '\w{3}\d{2}'); do
    virsh destroy $node
    virsh undefine $node
  done
}

prepare_vms() {
  local -n vnodes=$1
  local base_image=$2

  cleanup_vms
  get_base_image $base_image
  envsubst < user-data.template > user-data.sh

  for node in "${vnodes[@]}"; do
    # create/prepare images
    ./create-config-drive.sh -k ${SSH_KEY}.pub -u user-data.sh -h ${node} images/mcp_${node}.iso
    cp /tmp/${base_image/*\/} images/mcp_${node}.qcow2
    qemu-img resize images/mcp_${node}.qcow2 100G
  done
}

create_networks() {
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
}

create_vms() {
  local -n vnodes=$1
  local -n vnodes_ram=$2
  local -n vnodes_vcpus=$3

  # create vms with specified options
  for node in "${vnodes[@]}"; do
    virt-install --name ${node} --ram ${vnodes_ram[$node]} --vcpus ${vnodes_vcpus[$node]} --cpu host --accelerate \
    --network network:pxe,model=virtio \
    --network network:mgmt,model=virtio \
    --network network:internal,model=virtio \
    --network network:public,model=virtio \
    --disk path=$(pwd)/images/mcp_${node}.qcow2,format=qcow2,bus=virtio,cache=none,io=native \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path=$(pwd)/images/mcp_${node}.iso,device=cdrom \
    --noautoconsole
  done
}

update_pxe_network() {
  # set static ip address for salt master node
  virsh net-update pxe add ip-dhcp-host \
  "<host mac='$(virsh domiflist cfg01 | awk '/pxe/ {print $5}')' name='cfg01' ip='$SALT_MASTER'/>" --live
}

start_vms() {
  local -n vnodes=$1

  # start vms
  for node in "${vnodes[@]}"; do
    virsh start ${node}
    sleep $[RANDOM%5+1]
  done
}

check_connection() {
  local total_attempts=60
  local sleep_time=5
  local attempt=1

  set +e
  echo '[INFO] Attempting to get into Salt master ...'

  # wait until ssh on Salt master is available
  while (($attempt <= $total_attempts)); do
    ssh ${SSH_OPTS} ubuntu@${SALT_MASTER} uptime
    case $? in
      0) echo "${attempt}> Success"; break ;;
      *) echo "${attempt}/${total_attempts}> ssh server ain't ready yet, waiting for ${sleep_time} seconds ..." ;;
    esac
    sleep $sleep_time
    ((attempt+=1))
  done
  set -e
}

parse_yaml() {
  local prefix=$2
  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
  awk -F"$fs" '{
  indent = length($1)/2;
  vname[indent] = $2;
  for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
          vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
          printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
      }
  }' | sed 's/_=/+=/g'
}
