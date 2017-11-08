#!/bin/bash -e
##############################################################################
# Copyright (c) 2017 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Library of shell functions
#

function generate_ssh_key {
  # shellcheck disable=SC2155
  local mcp_ssh_key=$(basename "${SSH_KEY}")
  local user=${USER}
  if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != 'root' ]; then
    user=${SUDO_USER}
  fi

  if [ -f "${SSH_KEY}" ]; then
    cp "${SSH_KEY}" .
    ssh-keygen -f "${mcp_ssh_key}" -y > "${mcp_ssh_key}.pub"
  fi

  [ -f "${mcp_ssh_key}" ] || ssh-keygen -f "${mcp_ssh_key}" -N ''
  sudo install -D -o "${user}" -m 0600 "${mcp_ssh_key}" "${SSH_KEY}"
}

function get_base_image {
  local base_image=$1
  local image_dir=$2

  mkdir -p "${image_dir}"
  wget -P "${image_dir}" -N "${base_image}"
}

function cleanup_uefi {
  # Clean up Ubuntu boot entry if cfg01, kvm nodes online from previous deploy
  # shellcheck disable=SC2086
  ssh ${SSH_OPTS} "${SSH_SALT}" "sudo salt -C 'kvm* or cmp*' cmd.run \
    \"which efibootmgr > /dev/null 2>&1 && \
    efibootmgr | grep -oP '(?<=Boot)[0-9]+(?=.*ubuntu)' | \
    xargs -I{} efibootmgr --delete-bootnum --bootnum {}; \
    rm -rf /boot/efi/*\"" || true
}

function cleanup_vms {
  # clean up existing nodes
  for node in $(virsh list --name | grep -P '\w{3}\d{2}'); do
    virsh destroy "${node}"
  done
  for node in $(virsh list --name --all | grep -P '\w{3}\d{2}'); do
    virsh domblklist "${node}" | awk '/^.da/ {print $2}' | \
      xargs --no-run-if-empty -I{} sudo rm -f {}
    virsh undefine "${node}" --remove-all-storage --nvram
  done
}

function prepare_vms {
  local base_image=$1; shift
  local image_dir=$1; shift
  local vnodes=("$@")

  cleanup_uefi
  cleanup_vms
  get_base_image "${base_image}" "${image_dir}"
  # shellcheck disable=SC2016
  envsubst '${SALT_MASTER},${CLUSTER_DOMAIN}' < \
    user-data.template > user-data.sh

  for node in "${vnodes[@]}"; do
    # create/prepare images
    ./create-config-drive.sh -k "$(basename "${SSH_KEY}").pub" -u user-data.sh \
       -h "${node}" "${image_dir}/mcp_${node}.iso"
    cp "${image_dir}/${base_image/*\/}" "${image_dir}/mcp_${node}.qcow2"
    qemu-img resize "${image_dir}/mcp_${node}.qcow2" 100G
  done
}

function create_networks {
  local vnode_networks=("$@")
  # create required networks, including constant "mcpcontrol"
  # FIXME(alav): since we renamed "pxe" to "mcpcontrol", we need to make sure
  # we delete the old "pxe" virtual network, or it would cause IP conflicts.
  # FIXME(alav): The same applies for "fuel1" virsh network.
  for net in "fuel1" "pxe" "mcpcontrol" "${vnode_networks[@]}"; do
    if virsh net-info "${net}" >/dev/null 2>&1; then
      virsh net-destroy "${net}" || true
      virsh net-undefine "${net}"
    fi
    # in case of custom network, host should already have the bridge in place
    if [ -f "net_${net}.xml" ] && [ ! -d "/sys/class/net/${net}/bridge" ]; then
      virsh net-define "net_${net}.xml"
      virsh net-autostart "${net}"
      virsh net-start "${net}"
    fi
  done
}

function create_vms {
  local image_dir=$1; shift
  IFS='|' read -r -a vnodes <<< "$1"; shift
  local vnode_networks=("$@")

  # AArch64: prepare arch specific arguments
  local virt_extra_args=""
  if [ "$(uname -i)" = "aarch64" ]; then
    # No Cirrus VGA on AArch64, use virtio instead
    virt_extra_args="$virt_extra_args --video=virtio"
  fi

  # create vms with specified options
  for serialized_vnode_data in "${vnodes[@]}"; do
    IFS=',' read -r -a vnode_data <<< "${serialized_vnode_data}"

    # prepare network args
    net_args=" --network network=mcpcontrol,model=virtio"
    if [ "${vnode_data[0]}" = "mas01" ]; then
      # MaaS node's 3rd interface gets connected to PXE/Admin Bridge
      vnode_networks[2]="${vnode_networks[0]}"
    fi
    for net in "${vnode_networks[@]:1}"; do
      net_args="${net_args} --network bridge=${net},model=virtio"
    done

    # shellcheck disable=SC2086
    virt-install --name "${vnode_data[0]}" \
    --ram "${vnode_data[1]}" --vcpus "${vnode_data[2]}" \
    --cpu host-passthrough --accelerate ${net_args} \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.iso",device=cdrom \
    --noautoconsole \
    ${virt_extra_args}
  done
}

function update_mcpcontrol_network {
  # set static ip address for salt master node, MaaS node
  # shellcheck disable=SC2155
  local cmac=$(virsh domiflist cfg01 2>&1| awk '/mcpcontrol/ {print $5; exit}')
  # shellcheck disable=SC2155
  local amac=$(virsh domiflist mas01 2>&1| awk '/mcpcontrol/ {print $5; exit}')
  virsh net-update "mcpcontrol" add ip-dhcp-host \
    "<host mac='${cmac}' name='cfg01' ip='${SALT_MASTER}'/>" --live
  [ -z "${amac}" ] || virsh net-update "mcpcontrol" add ip-dhcp-host \
    "<host mac='${amac}' name='mas01' ip='${MAAS_IP}'/>" --live
}

function start_vms {
  local vnodes=("$@")

  # start vms
  for node in "${vnodes[@]}"; do
    virsh start "${node}"
    sleep $((RANDOM%5+1))
  done
}

function check_connection {
  local total_attempts=60
  local sleep_time=5

  set +e
  echo '[INFO] Attempting to get into Salt master ...'

  # wait until ssh on Salt master is available
  # shellcheck disable=SC2034
  for attempt in $(seq "${total_attempts}"); do
    # shellcheck disable=SC2086
    ssh ${SSH_OPTS} "ubuntu@${SALT_MASTER}" uptime
    case $? in
      0) echo "${attempt}> Success"; break ;;
      *) echo "${attempt}/${total_attempts}> ssh server ain't ready yet, waiting for ${sleep_time} seconds ..." ;;
    esac
    sleep $sleep_time
  done
  set -e
}

function parse_yaml {
  local prefix=$2
  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -e 's|---||g' -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
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

function wait_for {
  # Execute in a subshell to prevent local variable override during recursion
  (
    local total_attempts=$1; shift
    local cmdstr=$*
    local sleep_time=10
    echo "[NOTE] Waiting for cmd to return success: ${cmdstr}"
    # shellcheck disable=SC2034
    for attempt in $(seq "${total_attempts}"); do
      # shellcheck disable=SC2015
      eval "${cmdstr}" && return 0 || true
      echo -n '.'; sleep "${sleep_time}"
    done
    return 1
  )
}
