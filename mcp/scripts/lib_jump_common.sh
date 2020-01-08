#!/bin/bash -e
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Library of shell functions used by build / deploy scripts on jumpserver:
# - distro package requirements installation (e.g. DEB, RPM);
# - other package requirements from custom sources (e.g. docker);
# - jumpserver prerequisites validation (e.g. network bridges);
# - distro configuration (e.g. udev, sysctl);
# etc.

##############################################################################
# private helper functions
##############################################################################

function __parse_yaml {
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

##############################################################################
# public functions
##############################################################################

function jumpserver_pkg_install {
  local req_type=$1
  if [ -n "$(command -v apt-get)" ]; then
    pkg_type='deb'; pkg_cmd='sudo apt-get install -y'
  else
    pkg_type='rpm'; pkg_cmd='sudo yum install -y --skip-broken'
  fi
  eval "$(__parse_yaml "./requirements_${pkg_type}.yaml")"
  for section in 'common' "$(uname -i)"; do
    section_var="${req_type}_${section}[*]"
    pkg_list+=" ${!section_var}"
  done
  # shellcheck disable=SC2086
  ${pkg_cmd} ${pkg_list}
}

function jumpserver_check_requirements {
  # shellcheck disable=SC2178
  local states=$1; shift
  # shellcheck disable=SC2178
  local vnodes=$1; shift
  local br=("$@")
  local err_br_not_found='Linux bridge not found!'
  local err_br_virsh_net='is a virtual network, Linux bridge expected!'
  local warn_br_endpoint="Endpoints might be inaccessible from external hosts!"
  # MaaS requires a Linux bridge for PXE/admin
  if [[ "${states}" =~ maas ]]; then
    if ! brctl showmacs "${br[0]}" >/dev/null 2>&1; then
      notify_e "[ERROR] PXE/admin (${br[0]}) ${err_br_not_found}"
    fi
    # Assume virsh network name matches bridge name (true if created by us)
    if ${VIRSH} net-info "${br[0]}" >/dev/null 2>&1; then
      notify_e "[ERROR] ${br[0]} ${err_br_virsh_net}"
    fi
  fi
  # If virtual nodes are present, public should be a Linux bridge
  if [ -n "${vnodes}" ]; then
    if ! brctl showmacs "${br[3]}" >/dev/null 2>&1; then
      if [[ "${states}" =~ maas ]]; then
        # Baremetal nodes *require* a proper public network
        notify_e "[ERROR] Public (${br[3]}) ${err_br_not_found}"
      else
        notify_n "[WARN] Public (${br[3]}) ${err_br_not_found}" 3
        notify_n "[WARN] ${warn_br_endpoint}" 3
      fi
    fi
    if ${VIRSH} net-info "${br[3]}" >/dev/null 2>&1; then
      if [[ "${states}" =~ maas ]]; then
        notify_e "[ERROR] ${br[3]} ${err_br_virsh_net}"
      else
        notify_n "[WARN] ${br[3]} ${err_br_virsh_net}" 3
        notify_n "[WARN] ${warn_br_endpoint}" 3
      fi
    fi
    # https://bugs.launchpad.net/ubuntu/+source/qemu/+bug/1797332
    if lsb_release -d | grep -q -e 'Ubuntu 16.04'; then
      if uname -r | grep -q -e '^4\.4\.'; then
        notify_n "[WARN] Host kernel too old; nested virtualization issues!" 3
        notify_n "[WARN] apt install linux-generic-hwe-16.04 && reboot" 3
        notify_e "[ERROR] Please upgrade the kernel and reboot!"
      fi
    fi
  fi
}

function docker_install {
  local image_dir=$1
  # Mininum effort attempt at installing Docker if missing
  if ! docker --version; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    # On RHEL distros, the Docker service should be explicitly started
    sudo systemctl start docker
  else
    DOCKER_VER=$(docker version --format '{{.Server.Version}}')
    if [ "${DOCKER_VER%%.*}" -lt 2 ]; then
      notify_e "[ERROR] Docker version ${DOCKER_VER} is too old, please upgrade it."
    fi
  fi
  # Distro-provided docker-compose might be simply broken (Ubuntu 16.04, CentOS 7)
  if ! docker-compose --version > /dev/null 2>&1 || \
      [ "$(docker-compose version --short | tr -d '.')" -lt 1220 ] && \
      [ "$(uname -m)" = 'x86_64' ]; then
    COMPOSE_BIN="${image_dir}/docker-compose"
    COMPOSE_VERSION='1.22.0'
    notify_n "[WARN] Using docker-compose ${COMPOSE_VERSION} in ${COMPOSE_BIN}" 3
    if [ ! -e "${COMPOSE_BIN}" ]; then
      COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}"
      sudo curl -L "${COMPOSE_URL}/docker-compose-$(uname -s)-$(uname -m)" -o "${COMPOSE_BIN}"
      sudo chmod +x "${COMPOSE_BIN}"
    fi
  fi
}

function e2fsprogs_install {
  local image_dir=$1
  E2FS_VER=$(e2fsck -V 2>&1 | grep -Pzo "e2fsck \K1\.\d{2}")
  if [ "${E2FS_VER//./}" -lt 143 ]; then
    E2FS_TGZ="${image_dir}/e2fsprogs.tar.gz"
    E2FS_VER='1.43.9'
    E2FS_URL="https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-${E2FS_VER}.tar.gz"
    notify_n "[WARN] Using e2fsprogs ${E2FS_VER} from ${E2FS_TGZ}" 3
    if [ ! -e "${E2FS_TGZ}" ]; then
      curl -L "${E2FS_URL}" -o "${E2FS_TGZ}"
      mkdir -p "${image_dir}/e2fsprogs"
      tar xzf "${E2FS_TGZ}" -C "${image_dir}/e2fsprogs" --strip-components=1
      cd "${image_dir}/e2fsprogs" || exit 1
      ./configure
      make
      cd - || exit 1
    fi
  fi
}

function virtinst_install {
  local image_dir=$1
  VIRT_VER=$(virt-install --version 2>&1)
  if [ "${VIRT_VER//./}" -lt 140 ]; then
    VIRT_TGZ="${image_dir}/virt-manager.tar.gz"
    VIRT_VER='1.4.3'
    VIRT_URL="https://github.com/virt-manager/virt-manager/archive/v${VIRT_VER}.tar.gz"
    notify_n "[WARN] Using virt-install ${VIRT_VER} from ${VIRT_TGZ}" 3
    if [ ! -e "${VIRT_TGZ}" ]; then
      curl -L "${VIRT_URL}" -o "${VIRT_TGZ}"
      mkdir -p "${image_dir}/virt-manager"
      tar xzf "${VIRT_TGZ}" -C "${image_dir}/virt-manager" --strip-components=1
    fi
  fi
}

function do_udev_cfg {
  local _conf='/etc/udev/rules.d/99-opnfv-fuel-vnet-mtu.rules'
  # http://linuxaleph.blogspot.com/2013/01/how-to-network-jumbo-frames-to-kvm-guest.html
  echo 'SUBSYSTEM=="net", ACTION=="add|change", KERNEL=="vnet*", RUN+="/bin/sh -c '"'/bin/sleep 1; /sbin/ip link set %k mtu 9000'\"" |& sudo tee "${_conf}"
  echo 'SUBSYSTEM=="net", ACTION=="add|change", KERNEL=="*-nic", RUN+="/bin/sh -c '"'/bin/sleep 1; /sbin/ip link set %k mtu 9000'\"" |& sudo tee -a "${_conf}"
  sudo udevadm control --reload
  sudo udevadm trigger
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
