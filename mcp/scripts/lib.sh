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
# Library of shell functions
#

function generate_ssh_key {
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
  local __baseurl
  local __subdir
  local __uname_r=$(uname -r)
  local __uname_m=$(uname -m)
  if [ "${__uname_m}" = 'x86_64' ]; then
    __baseurl='http://vault.centos.org/centos'
    __subdir='Source/SPackages'
    __srpm="kernel-${__uname_r%.${__uname_m}}.src.rpm"
  else
    __baseurl='http://vault.centos.org/altarch'
    __subdir="Source/${__uname_m}/Source/SPackages"
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

function mount_image {
  local image=$1
  local image_dir=$2
  OPNFV_MNT_DIR="${image_dir}/ubuntu"

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
  qemu-img resize "${image_dir}/${image}" 3G
  sudo qemu-nbd --connect="${OPNFV_NBD_DEV}" --aio=native --cache=none \
    "${image_dir}/${image}"
  sudo kpartx -av "${OPNFV_NBD_DEV}"
  sleep 5 # /dev/nbdNp1 takes some time to come up
  # Hardcode partition index to 1, unlikely to change for Ubuntu UCA image
  if sudo growpart "${OPNFV_NBD_DEV}" 1; then
    sudo kpartx -u "${OPNFV_NBD_DEV}"
    sudo e2fsck -pf "${OPNFV_MAP_DEV}"
    sudo resize2fs "${OPNFV_MAP_DEV}"
  fi
  # grub-update does not like /dev/nbd*, so use a loop device to work around it
  sudo losetup "${OPNFV_LOOP_DEV}" "${OPNFV_MAP_DEV}"
  mkdir -p "${OPNFV_MNT_DIR}"
  sudo mount "${OPNFV_LOOP_DEV}" "${OPNFV_MNT_DIR}"
  sudo mount -t proc proc "${OPNFV_MNT_DIR}/proc"
  sudo mount -t sysfs sys "${OPNFV_MNT_DIR}/sys"
  sudo mount -o bind /dev "${OPNFV_MNT_DIR}/dev"
  sudo mkdir -p "${OPNFV_MNT_DIR}/run/resolvconf"
  sudo cp /etc/resolv.conf "${OPNFV_MNT_DIR}/run/resolvconf"
  echo "GRUB_DISABLE_OS_PROBER=true" | \
    sudo tee -a "${OPNFV_MNT_DIR}/etc/default/grub"
  sudo sed -i -e 's/^\(GRUB_TIMEOUT\)=.*$/\1=1/g' -e 's/^GRUB_HIDDEN.*$//g' \
    "${OPNFV_MNT_DIR}/etc/default/grub"
}

function apt_repos_pkgs_image {
  local apt_key_urls=(${1//,/ })
  local all_repos=(${2//,/ })
  local pkgs_i=(${3//,/ })
  local pkgs_r=(${4//,/ })
  [ -n "${OPNFV_MNT_DIR}" ] || exit 1

  # APT keys
  if [ "${#apt_key_urls[@]}" -gt 0 ]; then
    for apt_key in "${apt_key_urls[@]}"; do
      sudo chroot "${OPNFV_MNT_DIR}" /bin/bash -c \
        "wget -qO - '${apt_key}' | apt-key add -"
    done
  fi
  # Additional repositories
  for repo_line in "${all_repos[@]}"; do
    # <repo_name>|<repo prio>|deb|[arch=<arch>]|<repo url>|<dist>|<repo comp>
    local repo=(${repo_line//|/ })
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
    sudo DEBIAN_FRONTEND="noninteractive" \
      chroot "${OPNFV_MNT_DIR}" apt-get update
    sudo DEBIAN_FRONTEND="noninteractive" FLASH_KERNEL_SKIP="true" \
      chroot "${OPNFV_MNT_DIR}" apt-get install -y "${pkgs_i[@]}"
  fi
  # Remove packages
  if [ "${#pkgs_r[@]}" -gt 0 ]; then
    sudo DEBIAN_FRONTEND="noninteractive" FLASH_KERNEL_SKIP="true" \
      chroot "${OPNFV_MNT_DIR}" apt-get purge -y "${pkgs_r[@]}"
  fi
  # Disable cloud-init metadata service datasource
  sudo mkdir -p "${OPNFV_MNT_DIR}/etc/cloud/cloud.cfg.d"
  echo "datasource_list: [ NoCloud, None ]" | sudo tee \
    "${OPNFV_MNT_DIR}/etc/cloud/cloud.cfg.d/95_real_datasources.cfg"
}

function cleanup_mounts {
  # Remove any mounts, loop and/or nbd devs created while patching base image
  if [ -n "${OPNFV_MNT_DIR}" ] && [ -d "${OPNFV_MNT_DIR}" ]; then
    if [ -f "${OPNFV_MNT_DIR}/boot/grub/grub.cfg" ]; then
      # Grub thinks it's running from a live CD
      sudo sed -i -e 's/^\s*set root=.*$//g' -e 's/^\s*loopback.*$//g' \
        "${OPNFV_MNT_DIR}/boot/grub/grub.cfg"
    fi
    sudo rm -f "${OPNFV_MNT_DIR}/run/resolvconf/resolv.conf"
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
    sudo kpartx -d "${OPNFV_NBD_DEV}" || true
    sudo qemu-nbd -d "${OPNFV_NBD_DEV}" || true
  fi
}

function cleanup_uefi {
  # Clean up Ubuntu boot entry if cfg01, kvm nodes online from previous deploy
  local cmd_str="ssh ${SSH_OPTS} ${SSH_SALT}"
  ping -c 1 -w 1 "${SALT_MASTER}" || return 0
  [ ! "$(hostname)" = 'cfg01' ] || cmd_str='eval'
  ${cmd_str} "sudo salt -C 'kvm* or cmp*' cmd.run \
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
    virsh undefine "${node}" --remove-all-storage --nvram || \
      virsh undefine "${node}" --remove-all-storage
  done
}

function prepare_vms {
  local base_image=$1; shift
  local image_dir=$1; shift
  local repos_pkgs_str=$1; shift # ^-sep list of repos, pkgs to install/rm
  local vnodes=("$@")
  local image=base_image_opnfv_fuel.img
  local vcp_image=${image%.*}_vcp.img
  local _o=${base_image/*\/}
  local _h=$(echo "${repos_pkgs_str}.$(md5sum "${image_dir}/${_o}")" | \
             md5sum | cut -c -8)
  local _tmp

  cleanup_uefi
  cleanup_vms
  get_base_image "${base_image}" "${image_dir}"
  IFS='^' read -r -a repos_pkgs <<< "${repos_pkgs_str}"

  echo "[INFO] Lookup cache / build patched base image for fingerprint: ${_h}"
  _tmp="${image%.*}.${_h}.img"
  if [ "${image_dir}/${_tmp}" -ef "${image_dir}/${image}" ]; then
    echo "[INFO] Patched base image found"
  else
    rm -f "${image_dir}/${image%.*}"*
    if [[ ! "${repos_pkgs_str}" =~ ^\^+$ ]]; then
      echo "[INFO] Patching base image ..."
      cp "${image_dir}/${_o}" "${image_dir}/${_tmp}"
      __kernel_modules "${image_dir}"
      mount_image "${_tmp}" "${image_dir}"
      apt_repos_pkgs_image "${repos_pkgs[@]:0:4}"
      cleanup_mounts
    else
      echo "[INFO] No patching required, using vanilla base image"
      ln -sf "${image_dir}/${_o}" "${image_dir}/${_tmp}"
    fi
    ln -sf "${image_dir}/${_tmp}" "${image_dir}/${image}"
  fi

  # Create config ISO and resize OS disk image for each foundation node VM
  for node in "${vnodes[@]}"; do
    if [[ "${node}" =~ ^(cfg01|mas01) ]]; then
      user_data='user-data.mcp.sh'
    else
      user_data='user-data.admin.sh'
    fi
    ./create-config-drive.sh -k "$(basename "${SSH_KEY}").pub" \
       -u "${user_data}" -h "${node}" "${image_dir}/mcp_${node}.iso"
    cp "${image_dir}/${image}" "${image_dir}/mcp_${node}.qcow2"
    qemu-img resize "${image_dir}/mcp_${node}.qcow2" 100G
    # Prepare dedicated drive for cinder on cmp nodes
    if [[ "${node}" =~ ^(cmp) ]]; then
      qemu-img create "${image_dir}/mcp_${node}_storage.qcow2" 100G
    fi
  done

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
      mount_image "${_tmp}" "${image_dir}"
      apt_repos_pkgs_image "${repos_pkgs[@]:4:4}"
      cleanup_mounts
      ln -sf "${image_dir}/${_tmp}" "${image_dir}/${vcp_image}"
    fi
  fi
}

function jumpserver_pkg_install {
  if [ -n "$(command -v apt-get)" ]; then
    pkg_type='deb'; pkg_cmd='sudo apt-get install -y'
  else
    pkg_type='rpm'; pkg_cmd='sudo yum install -y --skip-broken'
  fi
  eval "$(parse_yaml "./requirements_${pkg_type}.yaml")"
  for section in 'common' "$(uname -i)"; do
    section_var="requirements_pkg_${section}[*]"
    pkg_list+=" ${!section_var}"
  done
  # shellcheck disable=SC2086
  ${pkg_cmd} ${pkg_list}
}

function jumpserver_check_requirements {
  # shellcheck disable=SC2178
  local vnodes=$1; shift
  local br=("$@")
  local err_br_not_found='Linux bridge not found!'
  local err_br_virsh_net='is a virtual network, Linux bridge expected!'
  local warn_br_endpoint="Endpoints might be inaccessible from external hosts!"
  # MaaS requires a Linux bridge for PXE/admin
  if [[ "${vnodes}" =~ mas01 ]]; then
    if ! brctl showmacs "${br[0]}" >/dev/null 2>&1; then
      notify_e "[ERROR] PXE/admin (${br[0]}) ${err_br_not_found}"
    fi
    # Assume virsh network name matches bridge name (true if created by us)
    if virsh net-info "${br[0]}" >/dev/null 2>&1; then
      notify_e "[ERROR] ${br[0]} ${err_br_virsh_net}"
    fi
  fi
  # If virtual nodes are present, public should be a Linux bridge
  if [ "$(echo "${vnodes}" | wc -w)" -gt 2 ]; then
    if ! brctl showmacs "${br[3]}" >/dev/null 2>&1; then
      if [[ "${vnodes}" =~ mas01 ]]; then
        # Baremetal nodes *require* a proper public network
        notify_e "[ERROR] Public (${br[3]}) ${err_br_not_found}"
      else
        notify_n "[WARN] Public (${br[3]}) ${err_br_not_found}" 3
        notify_n "[WARN] ${warn_br_endpoint}" 3
      fi
    fi
    if virsh net-info "${br[3]}" >/dev/null 2>&1; then
      if [[ "${vnodes}" =~ mas01 ]]; then
        notify_e "[ERROR] ${br[3]} ${err_br_virsh_net}"
      else
        notify_n "[WARN] ${br[3]} ${err_br_virsh_net}" 3
        notify_n "[WARN] ${warn_br_endpoint}" 3
      fi
    fi
  fi
}

function create_networks {
  local vnode_networks=("$@")
  # create required networks, including constant "mcpcontrol"
  for net in "mcpcontrol" "${vnode_networks[@]}"; do
    if virsh net-info "${net}" >/dev/null 2>&1; then
      virsh net-destroy "${net}" || true
      virsh net-undefine "${net}"
    fi
    # in case of custom network, host should already have the bridge in place
    if [ -f "virsh_net/net_${net}.xml" ] && \
     [ ! -d "/sys/class/net/${net}/bridge" ]; then
      virsh net-define "virsh_net/net_${net}.xml"
      virsh net-autostart "${net}"
      virsh net-start "${net}"
    fi
  done
}

function create_vms {
  local image_dir=$1; shift
  # vnode data should be serialized with the following format:
  # '<name0>,<ram0>,<vcpu0>|<name1>,<ram1>,<vcpu1>[...]'
  IFS='|' read -r -a vnodes <<< "$1"; shift

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
    local vnode_networks=("$@")
    if [[ "${vnode_data[0]}" =~ ^(cfg01|mas01) ]]; then
      net_args=" --network network=mcpcontrol,model=virtio"
      # 3rd interface gets connected to PXE/Admin Bridge (cfg01, mas01)
      vnode_networks[2]="${vnode_networks[0]}"
    else
      net_args=" --network bridge=${vnode_networks[0]},model=virtio"
    fi
    for net in "${vnode_networks[@]:1}"; do
      net_args="${net_args} --network bridge=${net},model=virtio"
    done

    # dedicated storage drive for cinder on cmp nodes
    virt_extra_storage=
    if [[ "${vnode_data[0]}" =~ ^(cmp) ]]; then
      virt_extra_storage="--disk path=${image_dir}/mcp_${vnode_data[0]}_storage.qcow2,format=qcow2,bus=virtio,cache=none,io=native"
    fi

    # shellcheck disable=SC2086
    virt-install --name "${vnode_data[0]}" \
    --ram "${vnode_data[1]}" --vcpus "${vnode_data[2]}" \
    --cpu host-passthrough --accelerate ${net_args} \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    ${virt_extra_storage} \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="${image_dir}/mcp_${vnode_data[0]}.iso",device=cdrom \
    --noautoconsole \
    ${virt_extra_args}
  done
}

function update_mcpcontrol_network {
  # set static ip address for salt master node, MaaS node
  local cmac=$(virsh domiflist cfg01 2>&1| awk '/mcpcontrol/ {print $5; exit}')
  local amac=$(virsh domiflist mas01 2>&1| awk '/mcpcontrol/ {print $5; exit}')
  virsh net-update "mcpcontrol" add ip-dhcp-host \
    "<host mac='${cmac}' name='cfg01' ip='${SALT_MASTER}'/>" --live --config
  [ -z "${amac}" ] || virsh net-update "mcpcontrol" add ip-dhcp-host \
    "<host mac='${amac}' name='mas01' ip='${MAAS_IP}'/>" --live --config
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
    echo -e "\n[wait_for] Waiting for cmd to return success: ${cmdstr}"
    # shellcheck disable=SC2034
    for attempt in $(seq "${total_attempts}"); do
      echo "[wait_for] Attempt ${attempt}/${total_attempts%.*} for: ${cmdstr}"
      if [ "${total_attempts%.*}" = "${total_attempts}" ]; then
        eval "${cmdstr}" && echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      else
        ! (eval "${cmdstr}" || echo 'No response') |& tee /dev/stderr | \
           grep -Eq '(Not connected|No response)' && \
           echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      fi
      sleep "${sleep_time}"
    done
    echo "[wait_for] ERROR: Failed after max attempts: ${cmdstr}"
    return 1
  )
}

function do_sysctl_cfg {
  local _conf='/etc/sysctl.d/99-opnfv-fuel-bridge.conf'
  # https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf
  if modprobe br_netfilter bridge; then
    echo 'net.bridge.bridge-nf-call-arptables = 0' |& sudo tee "${_conf}"
    echo 'net.bridge.bridge-nf-call-iptables = 0'  |& sudo tee -a "${_conf}"
    echo 'net.bridge.bridge-nf-call-ip6tables = 0' |& sudo tee -a "${_conf}"
    # Some distros / sysadmins explicitly blacklist br_netfilter
    sudo sysctl -q -p "${_conf}" || true
  fi
}

function get_nova_compute_pillar_data {
  local value=$(salt -C 'I@nova:compute and *01*' pillar.get _param:"${1}" --out yaml | cut -d ' ' -f2)
  if [ "${value}" != "''" ]; then
    echo "${value}"
  fi
}
