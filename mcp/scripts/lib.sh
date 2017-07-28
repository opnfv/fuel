#!/bin/bash
#
# Library of shell functions
#

generate_ssh_key() {
  [ -f "${SSH_KEY}" ] || ssh-keygen -f "${SSH_KEY}" -N ''
  install -o "${USER}" -m 0600 "${SSH_KEY}" /tmp/
}

get_base_image() {
  local base_image=$1

  mkdir -p images
  wget -P /tmp -nc "${base_image}"
}

cleanup_vms() {
  # clean up existing nodes
  for node in $(virsh list --name | grep -P '\w{3}\d{2}'); do
    virsh destroy "${node}"
  done
  for node in $(virsh list --name --all | grep -P '\w{3}\d{2}'); do
    virsh undefine --nvram "${node}"
  done
}

prepare_vms() {
  local -n vnodes=$1
  local base_image=$2

  cleanup_vms
  get_base_image "${base_image}"
  envsubst < user-data.template > user-data.sh

  for node in "${vnodes[@]}"; do
    # create/prepare images
    ./create-config-drive.sh -k "${SSH_KEY}.pub" -u user-data.sh \
       -h "${node}" "images/mcp_${node}.iso"
    cp "/tmp/${base_image/*\/}" "images/mcp_${node}.qcow2"
    qemu-img resize "images/mcp_${node}.qcow2" 100G
  done
}

create_networks() {
  local -n vnode_networks=$1
  # create required networks
  for net in "${vnode_networks[@]}"; do
    if virsh net-info "${net}" >/dev/null 2>&1; then
      virsh net-destroy "${net}"
      virsh net-undefine "${net}"
    fi
    # in case of custom network, host should already have the bridge in place
    if [ -f "net_${net}.xml" ]; then
      virsh net-define "net_${net}.xml"
      virsh net-autostart "${net}"
      virsh net-start "${net}"
    fi
  done
}

create_vms() {
  local -n vnodes=$1
  local -n vnodes_ram=$2
  local -n vnodes_vcpus=$3
  local -n vnode_networks=$4

  # prepare network args
  net_args=""
  for net in "${vnode_networks[@]}"; do
    net_type="network"
    # in case of custom network, host should already have the bridge in place
    if [ ! -f "net_${net}.xml" ]; then
      net_type="bridge"
    fi
    net_args="${net_args} --network ${net_type}=${net},model=virtio"
  done

  # create vms with specified options
  for node in "${vnodes[@]}"; do
    # shellcheck disable=SC2086
    virt-install --name "${node}" \
    --ram "${vnodes_ram[$node]}" --vcpus "${vnodes_vcpus[$node]}" \
    --cpu host-passthrough --accelerate ${net_args} \
    --disk path="$(pwd)/images/mcp_${node}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="$(pwd)/images/mcp_${node}.iso",device=cdrom \
    --noautoconsole
  done
}

update_pxe_network() {
  local -n vnode_networks=$1
  if virsh net-info "${vnode_networks[0]}" >/dev/null 2>&1; then
    # set static ip address for salt master node, only if managed via virsh
    # NOTE: below expr assume PXE network is always the first in domiflist
    virsh net-update "${vnode_networks[0]}" add ip-dhcp-host \
    "<host mac='$(virsh domiflist cfg01 | awk '/network/ {print $5; exit}')' name='cfg01' ip='${SALT_MASTER}'/>" --live
  fi
}

start_vms() {
  local -n vnodes=$1

  # start vms
  for node in "${vnodes[@]}"; do
    virsh start "${node}"
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
  while ((attempt <= total_attempts)); do
    # shellcheck disable=SC2086
    ssh ${SSH_OPTS} "ubuntu@${SALT_MASTER}" uptime
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
