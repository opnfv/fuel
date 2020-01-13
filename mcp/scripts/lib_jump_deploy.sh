#!/bin/bash -e
# shellcheck disable=SC2155,SC1001,SC2015,SC2128
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Library of shell functions used by deploy script on jumpserver:
# - base cloud image (used by FN VMs and VCP VMs) processing:
#   * download;
#   * tooling for offline image modification (without libguestfs);
#   * package pre-installation (requires nbd, loop krn mods);
# - virtualized hosts processing:
#   * virsh-managed VMs boilerplate;
#   * salt master container tooling;
#   * virsh & docker network plumbing;
# etc.

##############################################################################
# private helper functions
##############################################################################

function __get_base_image {
  local base_image=$1
  local image_dir=$2

  mkdir -p "${image_dir}"
  wget --progress=dot:giga -P "${image_dir}" -N "${base_image}"
}

function __kernel_modules {
  # Load mandatory kernel modules: loop, nbd
  local image_dir=$1
  test -e /dev/loop-control || sudo modprobe loop
  if sudo modprobe nbd max_part=8 || sudo modprobe -f nbd max_part=8; then
    return 0
  fi
  if [ -e /dev/nbd0 ]; then return 0; fi  # nbd might be inbuilt
  # CentOS (or RHEL family in general) do not provide 'nbd' out of the box
  echo "[WARN] 'nbd' kernel module cannot be loaded!"
  if [ ! -e /etc/redhat-release ]; then
    echo "[ERROR] Non-RHEL system detected, aborting!"
    echo "[ERROR] Try building 'nbd' manually or install it from a 3rd party."
    exit 1
  fi

  # Best-effort attempt at building a non-maintaned kernel module
  local __baseurl='http://vault.centos.org/centos'
  local __subdir='Source/SPackages'
  local __uname_r=$(uname -r)
  local __uname_m=$(uname -m)
  if [ "${__uname_m}" = 'x86_64' ]; then
    __srpm="kernel-${__uname_r%.${__uname_m}}.src.rpm"
  else
    # NOTE: fmt varies across releases (e.g. kernel-alt-4.11.0-44.el7a.src.rpm)
    __srpm="kernel-alt-${__uname_r%.${__uname_m}}.src.rpm"
  fi

  local __found='n'
  local __versions=$(curl -s "${__baseurl}/" | grep -Po 'href="\K7\.[\d\.]+')
  for ver in ${__versions}; do
    for comp in os updates; do
      local url="${__baseurl}/${ver}/${comp}/${__subdir}/${__srpm}"
      if wget "${url}" -O "${image_dir}/${__srpm}" > /dev/null 2>&1; then
        __found='y'; break 2
      fi
    done
  done

  if [ "${__found}" = 'n' ]; then
    echo "[ERROR] Can't find the linux kernel SRPM for: ${__uname_r}"
    echo "[ERROR] 'nbd' module cannot be built, aborting!"
    echo "[ERROR] Try 'yum upgrade' or building 'nbd' krn module manually ..."
    exit 1
  fi

  rpm -ivh "${image_dir}/${__srpm}" 2> /dev/null
  mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
  # shellcheck disable=SC2016
  echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
  (
    cd ~/rpmbuild/SPECS
    rpmbuild -bp --nodeps --target="${__uname_m}" kernel*.spec
    cd ~/rpmbuild/BUILD/"${__srpm%.src.rpm}"/linux-*
    sed -i 's/^.*\(CONFIG_BLK_DEV_NBD\).*$/\1=m/g' .config
    # http://centosfaq.org/centos/nbd-does-not-compile-for-3100-514262el7x86_64
    if grep -Rq 'REQ_TYPE_DRV_PRIV' drivers/block; then
      sed -i 's/REQ_TYPE_SPECIAL/REQ_TYPE_DRV_PRIV/g' drivers/block/nbd.c
    fi
    gunzip -c "/boot/symvers-${__uname_r}.gz" > Module.symvers
    make prepare modules_prepare
    make M=drivers/block -j
    modinfo drivers/block/nbd.ko
    sudo mkdir -p "/lib/modules/${__uname_r}/extra/"
    sudo cp drivers/block/nbd.ko "/lib/modules/${__uname_r}/extra/"
  )
  sudo depmod -a
  sudo modprobe nbd max_part=8 || sudo modprobe -f nbd max_part=8
}

function __mount_image {
  local image=$1
  local image_dir=$2
  OPNFV_MNT_DIR="${image_dir}/mnt"

  # Find free nbd, loop devices
  for dev in '/sys/class/block/nbd'*; do
    if [ "$(cat "${dev}/size")" = '0' ]; then
      OPNFV_NBD_DEV=/dev/$(basename "${dev}")
      break
    fi
  done
  OPNFV_LOOP_DEV=$(sudo losetup -f)
  OPNFV_MAP_DEV=/dev/mapper/$(basename "${OPNFV_NBD_DEV}")p1
  export OPNFV_MNT_DIR OPNFV_LOOP_DEV
  [ -n "${OPNFV_NBD_DEV}" ] && [ -n "${OPNFV_LOOP_DEV}" ] || exit 1
  [[ "${MCP_OS:-}" =~ centos ]] || \
    qemu-img resize "${image_dir}/${image}" 3G
  sudo qemu-nbd --connect="${OPNFV_NBD_DEV}" --aio=native --cache=none \
    "${image_dir}/${image}"
  sudo kpartx -av "${OPNFV_NBD_DEV}"
  # Hardcode partition index to 1, unlikely to change for Ubuntu UCA image
  sudo partx -uvn 1:1 "${OPNFV_NBD_DEV}"
  if [[ "${MCP_OS:-}" =~ ubuntu ]] && sudo growpart "${OPNFV_NBD_DEV}" 1
  then
    if [ -e "${image_dir}/e2fsprogs" ]; then
      E2FSCK_PREFIX="${image_dir}/e2fsprogs/e2fsck/"
      RESIZE_PREFIX="${image_dir}/e2fsprogs/resize/"
    fi
    sudo kpartx -u "${OPNFV_NBD_DEV}"
    sudo "${E2FSCK_PREFIX}e2fsck" -pf "${OPNFV_MAP_DEV}"
    sudo "${RESIZE_PREFIX}resize2fs" "${OPNFV_MAP_DEV}"
  else
    sleep 5 # /dev/nbdNp1 takes some time to come up
  fi
  sudo partx -d "${OPNFV_NBD_DEV}"
  mkdir -p "${OPNFV_MNT_DIR}"
  if [ "$(uname -i)" = "aarch64" ] && [[ "${MCP_OS:-}" =~ centos ]]; then
    # AArch64 CentOS cloud image contains a broken shim binary
    # https://bugzilla.redhat.com/show_bug.cgi?id=1527283
    sudo mount "${OPNFV_MAP_DEV}" "${OPNFV_MNT_DIR}"
    sudo cp -f --remove-destination "${OPNFV_MNT_DIR}/EFI/BOOT/fbaa64.efi" \
                                    "${OPNFV_MNT_DIR}/EFI/BOOT/BOOTAA64.EFI"
    sudo umount -l "${OPNFV_MNT_DIR}"
    # AArch64 CentOS cloud image has root partition at index 4 instead of 1
    sudo mount "${OPNFV_MAP_DEV/p1/p4}" "${OPNFV_MNT_DIR}"
  else
    # grub-update does not like /dev/nbd*, so use a loop device to work around it
    sudo losetup "${OPNFV_LOOP_DEV}" "${OPNFV_MAP_DEV}"
    sudo mount "${OPNFV_LOOP_DEV}" "${OPNFV_MNT_DIR}"
  fi
  sudo mount -t proc proc "${OPNFV_MNT_DIR}/proc"
  sudo mount -t sysfs sys "${OPNFV_MNT_DIR}/sys"
  sudo mount -o bind /dev "${OPNFV_MNT_DIR}/dev"
  if [[ "${MCP_OS:-}" =~ ubuntu1804 ]]; then
    # Ubuntu Bionic (18.04) or newer defaults to using netplan.io, revert it
    sudo mkdir -p "${OPNFV_MNT_DIR}/run/systemd/resolve"
    echo "nameserver ${dns_public}" | sudo tee \
      "${OPNFV_MNT_DIR}/run/systemd/resolve/stub-resolv.conf"
    sudo chroot "${OPNFV_MNT_DIR}" systemctl stop \
      systemd-networkd.socket systemd-networkd \
      networkd-dispatcher systemd-networkd-wait-online systemd-resolved
    sudo chroot "${OPNFV_MNT_DIR}" systemctl disable \
      systemd-networkd.socket systemd-networkd \
      networkd-dispatcher systemd-networkd-wait-online systemd-resolved
    sudo chroot "${OPNFV_MNT_DIR}" systemctl mask \
      systemd-networkd.socket systemd-networkd \
      networkd-dispatcher systemd-networkd-wait-online systemd-resolved
    sudo chroot "${OPNFV_MNT_DIR}" apt --assume-yes purge nplan netplan.io
    echo "source /etc/network/interfaces.d/*" | \
      sudo tee "${OPNFV_MNT_DIR}/etc/network/interfaces"
  elif [[ "${MCP_OS:-}" =~ centos ]]; then
    sudo sed -i -e 's/^\(SELINUX\)=.*$/\1=permissive/g' \
      "${OPNFV_MNT_DIR}/etc/selinux/config"
  fi
  sudo rm -f "${OPNFV_MNT_DIR}/etc/resolv.conf"
  echo "nameserver ${dns_public}" | sudo tee \
    "${OPNFV_MNT_DIR}/etc/resolv.conf"
  echo "GRUB_DISABLE_OS_PROBER=true" | \
    sudo tee -a "${OPNFV_MNT_DIR}/etc/default/grub"
  sudo sed -i -e 's/^\(GRUB_TIMEOUT\)=.*$/\1=1/g' -e 's/^GRUB_HIDDEN.*$//g' \
    "${OPNFV_MNT_DIR}/etc/default/grub"
}

function __apt_repos_pkgs_image {
  local apt_key_urls=(${1//,/ })
  local all_repos=(${2//,/ })
  local pkgs_i=(${3//,/ })
  local pkgs_r=(${4//,/ })
  [ -n "${OPNFV_MNT_DIR}" ] || exit 1

  # NOTE: We don't support (yet) some features for non-APT repos: keys, prio

  # APT keys
  if [[ "${MCP_OS:-}" =~ ubuntu ]] && [ "${#apt_key_urls[@]}" -gt 0 ]; then
    for apt_key in "${apt_key_urls[@]}"; do
      sudo chroot "${OPNFV_MNT_DIR}" /bin/bash -c \
        "wget -qO - '${apt_key}' | apt-key add -"
    done
  fi
  # Additional repositories
  for repo_line in "${all_repos[@]}"; do
    # <repo_name>|<repo prio>|deb|[arch=<arch>]|<repo url>|<dist>|<repo comp>
    local repo=(${repo_line//|/ })

    if [[ "${MCP_OS:-}" =~ centos ]]; then
      cat <<-EOF | sudo tee "${OPNFV_MNT_DIR}/etc/yum.repos.d/${repo[0]}.repo"
		[${repo[0]}]
		baseurl=${repo[3]}
		enabled=1
		gpgcheck=0
		EOF
      continue
    fi
    [ "${#repo[@]}" -gt 5 ] || continue
    # NOTE: Names and formatting are compatible with Salt linux.system.repo
    cat <<-EOF | sudo tee "${OPNFV_MNT_DIR}/etc/apt/preferences.d/${repo[0]}"

		Package: *
		Pin: release a=${repo[-2]}
		Pin-Priority: ${repo[1]}

		EOF
    echo "${repo[@]:2}" | sudo tee \
      "${OPNFV_MNT_DIR}/etc/apt/sources.list.d/${repo[0]}.list"
  done
  # Install packages
  if [ "${#pkgs_i[@]}" -gt 0 ]; then
    if [[ "${MCP_OS:-}" =~ ubuntu ]]; then
      sudo DEBIAN_FRONTEND="noninteractive" \
        chroot "${OPNFV_MNT_DIR}" apt-get update
      sudo DEBIAN_FRONTEND="noninteractive" FLASH_KERNEL_SKIP="true" \
        chroot "${OPNFV_MNT_DIR}" apt-get install -y "${pkgs_i[@]}"
    else
      sudo chroot "${OPNFV_MNT_DIR}" yum install -y "${pkgs_i[@]}"
    fi
  fi
  # Remove packages
  if [ "${#pkgs_r[@]}" -gt 0 ]; then
    if [[ "${MCP_OS:-}" =~ ubuntu ]]; then
      sudo DEBIAN_FRONTEND="noninteractive" FLASH_KERNEL_SKIP="true" \
        chroot "${OPNFV_MNT_DIR}" apt-get purge -y "${pkgs_r[@]}"
    else
      sudo chroot "${OPNFV_MNT_DIR}" yum remove -y "${pkgs_r[@]}"
    fi
  fi
  # Disable cloud-init metadata service datasource
  sudo mkdir -p "${OPNFV_MNT_DIR}/etc/cloud/cloud.cfg.d"
  echo "datasource_list: [ NoCloud, None ]" | sudo tee \
    "${OPNFV_MNT_DIR}/etc/cloud/cloud.cfg.d/95_real_datasources.cfg"
}

function __cleanup_vms {
  # clean up existing nodes
  for node in $(${VIRSH} list --name | grep -P '\w{3}\d{2}'); do
    ${VIRSH} destroy "${node}" 2>/dev/null || true
  done
  for node in $(${VIRSH} list --name --all | grep -P '\w{3}\d{2}'); do
    ${VIRSH} domblklist "${node}" | awk '/^.da/ {print $2}' | \
      xargs --no-run-if-empty -I{} sudo rm -f {}
    ${VIRSH} undefine "${node}" --remove-all-storage --nvram || \
      ${VIRSH} undefine "${node}" --remove-all-storage
  done
}

##############################################################################
# public functions
##############################################################################

function prepare_vms {
  local base_image_f=$1; shift
  local base_image=${base_image_f%.xz}
  local image_dir=$1; shift
  local repos_pkgs_str=$1; shift # ^-sep list of repos, pkgs to install/rm
  local image=base_image_opnfv_fuel.img
  local vcp_image=${image%.*}_vcp.img
  local _o=${base_image/*\/}
  [ -n "${image_dir}" ] || exit 1

  cleanup_uefi
  __cleanup_vms
  __get_base_image "${base_image_f}" "${image_dir}"
  [ "${base_image}" == "${base_image_f}" ] || unxz -fk "${image_dir}/${_o}.xz"
  IFS='^' read -r -a repos_pkgs <<< "${repos_pkgs_str}"

  local _h=$(echo "${repos_pkgs_str}.$(md5sum "${image_dir}/${_o}")" | \
             md5sum | cut -c -8)
  local _tmp="${image%.*}.${_h}.img"
  echo "[INFO] Lookup cache / build patched base image for fingerprint: ${_h}"
  if [ "${image_dir}/${_tmp}" -ef "${image_dir}/${image}" ]; then
    echo "[INFO] Patched base image found"
  else
    # shellcheck disable=SC2115
    rm -rf "${image_dir}/${image%.*}"*
    if [[ ! "${repos_pkgs_str}" =~ ^\^+$ ]]; then
      echo "[INFO] Patching base image ..."
      cp "${image_dir}/${_o}" "${image_dir}/${_tmp}"
      __kernel_modules "${image_dir}"
      __mount_image "${_tmp}" "${image_dir}"
      __apt_repos_pkgs_image "${repos_pkgs[@]:0:4}"
      cleanup_mounts
    else
      echo "[INFO] No patching required, using vanilla base image"
      ln -sf "${image_dir}/${_o}" "${image_dir}/${_tmp}"
    fi
    ln -sf "${image_dir}/${_tmp}" "${image_dir}/${image}"
  fi

  # VCP VMs base image specific changes
  if [[ ! "${repos_pkgs_str}" =~ \^{3}$ ]] && [ -n "${repos_pkgs[*]:4}" ]; then
    echo "[INFO] Lookup cache / build patched VCP image for md5sum: ${_h}"
    _tmp="${vcp_image%.*}.${_h}.img"
    if [ "${image_dir}/${_tmp}" -ef "${image_dir}/${vcp_image}" ]; then
      echo "[INFO] Patched VCP image found"
    else
      echo "[INFO] Patching VCP image ..."
      cp "${image_dir}/${image}" "${image_dir}/${_tmp}"
      __kernel_modules "${image_dir}"
      __mount_image "${_tmp}" "${image_dir}"
      __apt_repos_pkgs_image "${repos_pkgs[@]:4:4}"
      cleanup_mounts
      ln -sf "${image_dir}/${_tmp}" "${image_dir}/${vcp_image}"
    fi
  fi
}

function create_networks {
  local all_vnode_networks=("$@")
  # create required networks
  for net in "mcpcontrol" "${all_vnode_networks[@]}"; do
    if ${VIRSH} net-info "${net}" >/dev/null 2>&1; then
      ${VIRSH} net-destroy "${net}" || true
      ${VIRSH} net-undefine "${net}"
    fi
    # in case of custom network, host should already have the bridge in place
    if [ -f "virsh_net/net_${net}.xml" ] && \
     [ ! -d "/sys/class/net/${net}/bridge" ]; then
      ${VIRSH} net-define "virsh_net/net_${net}.xml"
      ${VIRSH} net-autostart "${net}"
      ${VIRSH} net-start "${net}"
    fi
  done

  sudo ip link del veth_mcp0 || true
  sudo ip link del veth_mcp2 || true
  # Create systemd service for veth creation after reboot
  FUEL_VETHC_SERVICE="/etc/systemd/system/opnfv-fuel-vethc.service"
  FUEL_VETHA_SERVICE="/etc/systemd/system/opnfv-fuel-vetha.service"
  test -f /usr/sbin/ip && PREFIX=/usr/sbin || PREFIX=/sbin
  cat <<-EOF | sudo tee "${FUEL_VETHC_SERVICE}"
	[Unit]
	After=libvirtd.service
	Before=docker.service
	[Service]
	ExecStart=/bin/sh -ec '\
	  ${PREFIX}/ip link add veth_mcp0 type veth peer name veth_mcp1 && \
	  ${PREFIX}/ip link add veth_mcp2 type veth peer name veth_mcp3 && \
	  ${PREFIX}/ip link set veth_mcp0 up mtu 9000 && \
	  ${PREFIX}/ip link set veth_mcp1 up mtu 9000 && \
	  ${PREFIX}/ip link set veth_mcp2 up mtu 9000 && \
	  ${PREFIX}/ip link set veth_mcp3 up mtu 9000'
	EOF
  cat <<-EOF | sudo tee "${FUEL_VETHA_SERVICE}"
	[Unit]
	StartLimitInterval=200
	StartLimitBurst=10
	After=opnfv-fuel-vethc.service
	[Service]
	Restart=on-failure
	RestartSec=10
	ExecStartPre=/bin/sh -ec '\
	  ${PREFIX}/brctl showstp ${all_vnode_networks[0]} > /dev/null 2>&1 && \
	  ${PREFIX}/brctl showstp ${all_vnode_networks[1]} > /dev/null 2>&1'
	ExecStart=/bin/sh -ec '\
	  ${PREFIX}/brctl addif ${all_vnode_networks[0]} veth_mcp0 && \
	  ${PREFIX}/brctl addif ${all_vnode_networks[1]} veth_mcp2 && \
	  while ${PREFIX}/ip rule del to ${SALT_MASTER} iif docker0 table 200 2>/dev/null; do true; done && \
	  ${PREFIX}/ip rule add to ${SALT_MASTER} iif docker0 table 200 && \
	  ${PREFIX}/ip route replace ${SALT_MASTER} dev ${all_vnode_networks[0]} table 200'
	EOF
  sudo ln -sf "${FUEL_VETHC_SERVICE}" "/etc/systemd/system/multi-user.target.wants/"
  sudo ln -sf "${FUEL_VETHA_SERVICE}" "/etc/systemd/system/multi-user.target.wants/"
  sudo systemctl daemon-reload
  sudo systemctl restart opnfv-fuel-vethc
  sudo systemctl restart opnfv-fuel-vetha
}

function cleanup_all {
  local image_dir=$1; shift
  local all_vnode_networks=("$@")
  [ ! -e "${image_dir}/docker-compose" ] || COMPOSE_PREFIX="${image_dir}/"

  cleanup_uefi
  __cleanup_vms
  sudo ip link del veth_mcp0 || true
  sudo ip link del veth_mcp2 || true
  for net in "mcpcontrol" "${all_vnode_networks[@]}"; do
    if ${VIRSH} net-info "${net}" >/dev/null 2>&1; then
      ${VIRSH} net-destroy "${net}" || true
      ${VIRSH} net-undefine "${net}"
    fi
  done
  sudo rm -f "/etc/systemd/system/multi-user.target.wants/opnfv-fuel"* \
             "/etc/systemd/system/opnfv-fuel"*
  sudo systemctl daemon-reload
  "${COMPOSE_PREFIX}docker-compose" -f docker-compose/docker-compose.yaml down
}

function create_vms {
  local image_dir=$1; shift
  local image=base_image_opnfv_fuel.img
  # vnode data should be serialized with the following format:
  #   <name0>,<disks0>,<ram0>,<vcpu0>[,<sockets0>,<cores0>,<threads0>[,<cell0name0>,<cell0memory0>,
  #   <cell0cpus0>,<cell1name0>,<cell1memory0>,<cell1cpus0>]]|<name1>,...'
  IFS='|' read -r -a vnodes <<< "$1"; shift

  # AArch64: prepare arch specific arguments
  local virt_extra_args=""
  if [ "$(uname -i)" = "aarch64" ]; then
    # No Cirrus VGA on AArch64, use virtio instead
    virt_extra_args="$virt_extra_args --video=virtio"
  fi

  # create vms with specified options
  for serialized_vnode_data in "${vnodes[@]}"; do
    if [ -z "${serialized_vnode_data}" ]; then continue; fi
    IFS=',' read -r -a vnode_data <<< "${serialized_vnode_data}"
    IFS=';' read -r -a disks_data <<< "${vnode_data[1]}"

    # Create config ISO and resize OS disk image for each foundation node VM
    ./create-config-drive.sh -k "$(basename "${SSH_KEY}").pub" \
       -u 'user-data.sh' -h "${vnode_data[0]}" "${image_dir}/mcp_${vnode_data[0]}.iso"
    cp "${image_dir}/${image}" "${image_dir}/mcp_${vnode_data[0]}.qcow2"
    qemu-img resize "${image_dir}/mcp_${vnode_data[0]}.qcow2" "${disks_data[0]}"
    # Prepare additional drives if present
    idx=0
    virt_extra_storage=
    for dsize in "${disks_data[@]:1}"; do
      ((idx+=1))
      qcow_file="${image_dir}/mcp_${vnode_data[0]}_${idx}.qcow2"
      qemu-img create "${qcow_file}" "${dsize}"
      virt_extra_storage+=" --disk path=${qcow_file},format=qcow2,bus=virtio,cache=none,io=native"
    done

    # prepare VM CPU model, count, topology (optional), NUMA cells (optional, requires topo)
    local virt_cpu_args=' --cpu host-passthrough'
    local idx=7  # cell0.name index in serialized data
    while [ -n "${vnode_data[${idx}]}" ]; do
      virt_cpu_args+=",${vnode_data[${idx}]}.memory=${vnode_data[$((idx + 1))]}"
      virt_cpu_args+=",${vnode_data[${idx}]}.cpus=${vnode_data[$((idx + 2))]}"
      idx=$((idx + 3))
    done
    virt_cpu_args+=" --vcpus vcpus=${vnode_data[3]}"
    if [ -n "${vnode_data[6]}" ]; then
      virt_cpu_args+=",sockets=${vnode_data[4]},cores=${vnode_data[5]},threads=${vnode_data[6]}"
    fi

    # prepare network args
    local vnode_networks=("$@")
    local net_args=
    for net in "${vnode_networks[@]}"; do
      net_args="${net_args} --network bridge=${net},model=virtio"
    done

    [ ! -e "${image_dir}/virt-manager" ] || VIRT_PREFIX="${image_dir}/virt-manager/"
    # shellcheck disable=SC2086
    ${VIRT_PREFIX}${VIRSH/virsh/virt-install} --name "${vnode_data[0]}" \
    ${virt_cpu_args} --accelerate \
    ${net_args} \
    --ram "${vnode_data[2]}" \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    ${virt_extra_storage} \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.iso",device=cdrom \
    --noautoconsole \
    ${virt_extra_args}
  done
}

function reset_vms {
  local vnodes=("$@")
  local cmd_str="ssh ${SSH_OPTS} ${SSH_SALT}"

  # reset non-infrastructure vms, wait for them to come back online
  for node in "${vnodes[@]}"; do
    ${VIRSH} reset "${node}"
  done
  for node in "${vnodes[@]}"; do
    wait_for 20.0 "${cmd_str} sudo salt -C '${node}*' saltutil.sync_all"
  done
}

function start_vms {
  local vnodes=("$@")

  # start vms
  for node in "${vnodes[@]}"; do
    ${VIRSH} start "${node}"
    sleep $((RANDOM%5+1))
  done
}

function prepare_containers {
  local image_dir=$1
  [ -n "${image_dir}" ] || exit 1
  [ -n "${MCP_REPO_ROOT_PATH}" ] || exit 1
  [ ! -e "${image_dir}/docker-compose" ] || COMPOSE_PREFIX="${image_dir}/"

  "${COMPOSE_PREFIX}docker-compose" -f docker-compose/docker-compose.yaml down
  if [[ ! "${MCP_DOCKER_TAG}" =~ 'verify' ]]; then
    "${COMPOSE_PREFIX}docker-compose" -f docker-compose/docker-compose.yaml pull
  fi
  # overwrite hosts only on first container up, to preserve cluster nodes
  sudo cp docker-compose/files/hosts "${image_dir}/hosts"
  sudo rm -rf "${image_dir}/"{salt,pki,mas01/etc} "${image_dir}/nodes/"*
  find "${image_dir}/mas01/var/lib/" \
    -mindepth 2 -maxdepth 2 -not -name boot-resources \
    -exec sudo rm -rf {} \; || true
  mkdir -p "${image_dir}/"{salt/master.d,salt/minion.d}

  if grep -q -e 'maas' 'docker-compose/docker-compose.yaml'; then
    # Apparmor workaround for bind9 inside Docker containers using AUFS
    for profile in 'usr.sbin.ntpd' 'usr.sbin.named' \
                   'usr.sbin.dhcpd' 'usr.sbin.tcpdump' 'usr.bin.tcpdump'; do
      if [ -e "/etc/apparmor.d/${profile}" ] && \
       [ ! -e "/etc/apparmor.d/disable/${profile}" ]; then
        sudo ln -sf "/etc/apparmor.d/${profile}" "/etc/apparmor.d/disable/"
        sudo apparmor_parser -R "/etc/apparmor.d/${profile}" || true
      fi
    done
  fi
}

function start_containers {
  local image_dir=$1
  [ -n "${image_dir}" ] || exit 1
  [ ! -e "${image_dir}/docker-compose" ] || COMPOSE_PREFIX="${image_dir}/"
  if grep -q -e 'maas' 'docker-compose/docker-compose.yaml'; then
    chmod +x docker-compose/files/entrypoint*.sh
  fi
  "${COMPOSE_PREFIX}docker-compose" -f docker-compose/docker-compose.yaml up -d
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

function cleanup_mounts {
  # Remove any mounts, loop and/or nbd devs created while patching base image
  if [ -n "${OPNFV_MNT_DIR}" ] && [ -d "${OPNFV_MNT_DIR}" ]; then
    if [ -f "${OPNFV_MNT_DIR}/boot/grub/grub.cfg" ]; then
      # Grub thinks it's running from a live CD
      sudo sed -i -e 's/^\s*set root=.*$//g' -e 's/^\s*loopback.*$//g' \
        "${OPNFV_MNT_DIR}/boot/grub/grub.cfg"
    fi
    sync
    if mountpoint -q "${OPNFV_MNT_DIR}"; then
      sudo umount -l "${OPNFV_MNT_DIR}" || true
    fi
  fi
  if [ -n "${OPNFV_LOOP_DEV}" ] && \
    sudo losetup "${OPNFV_LOOP_DEV}" 1>&2 > /dev/null; then
      sudo losetup -d "${OPNFV_LOOP_DEV}"
  fi
  if [ -n "${OPNFV_NBD_DEV}" ]; then
    sudo partx -d "${OPNFV_NBD_DEV}" || true
    sudo kpartx -d "${OPNFV_NBD_DEV}" || true
    sudo qemu-nbd -d "${OPNFV_NBD_DEV}" || true
  fi
}
