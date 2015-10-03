#!/usr/bin/env bash

#Script that install prerequisites
#author: Szilard Cserey (szilard.cserey@ericsson.com)
#
#Installs qemu-kvm, libvirt and prepares networking for Fuel VM

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`
private_interface='enp6s0'
public_interface='enp8s0'
pxe_bridge='pxebr'
fuel_gw_ip='10.20.0.1/16'
management_vid=300
management_interface="${private_interface}.${management_vid}"
##END VARS

##FUNCTIONS
###check whether qemu-kvm is installed, otherwise install it
install_qemu_kvm() {
  echo "${blue}Checking whether qemu-kvm is installed, otherwise install it${reset}"
  if ! rpm -qa | grep -iE 'qemu-kvm'; then
    echo "${blue}qemu-kvm is not installed, installing...${reset}"
    yum -y install qemu-kvm
  else
    echo "${green}OK!${reset}"
  fi
}

###check whether libvirt is installed, otherwise install it
install_libvirt() {
  echo "${blue}Checking whether libvirt is installed, otherwise install it${reset}"
  if ! rpm -qa | grep -iE 'libvirt'; then
    echo "${blue}libvirt is not installed, installing...${reset}"
    yum -y install libvirt
  else
    echo "${green}OK!${reset}"
  fi
}

###check whether kvm kernel module is loaded, otherwise load it
load_kvm_kernel_mod() {
  echo "${blue}Checking whether kvm kernel module is loaded, otherwise load it${reset}"
  if ! lsmod | grep -iE 'kvm'; then
    if [[ `lscpu | grep 'Vendor ID' | awk 'BEGIN { FS = ":" } ; {print $2}' | tr -d ' '` == 'GenuineIntel' ]]; then
      echo "${blue}Intel processor identified, loading kernel module kvm-intel${reset}"
      kernel_mod='kvm-intel'
      modprobe ${kernel_mod}
    fi
    if [[ `lscpu | grep 'Vendor ID' | awk 'BEGIN { FS = ":" } ; {print $2}' | tr -d ' '` == 'AuthenticAMD' ]]; then
      echo "${blue}AMD processor identified, loading kernel module kvm-amd${reset}"
      kernel_mod='kvm-amd'
      modprobe ${kernel_mod}
    fi
    if ! lsmod | grep -iE 'kvm'; then
      echo "${red}Failed to load kernel module ${kernel_mod}!${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi
}

###check whether libvirtd service is running otherwise start it
start_libvirtd_service() {
  echo "${blue}Checking whether libvirtd service is running otherwise start it${reset}"
  if ! sudo systemctl status libvirtd | grep -iE 'active \(running\)'; then
    echo "${blue}starting libvirtd service${reset}"
    systemctl start libvirtd
    if ! sudo systemctl status libvirtd | grep -iE 'active \(running\)'; then
      echo "${red}Failed to start libvirtd service!${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi
}


#Check whether interface exists
check_interface_exists() {
  if [ -z $1 ]; then
    echo "${red}Cannot check whether interface exists! No interface specified!${reset}"
    exit 1
  fi
  local interface=$1
  #Check whether interface exists
  echo "${blue}Checking whether interface ${interface} exists${reset}"
  if ! ip link show ${interface}; then
    echo "${red}Interface ${interface} does not exists!${reset}"
    exit 1
  else
    echo "${green}OK!${reset}"
  fi
}

#Check whether interface is UP
check_interface_up() {
  if [ -z $1 ]; then
    echo "${red}Cannot check whether interface is UP! No interface specified!${reset}"
    exit 1
  fi
  local interface=$1

  #Check whether interface is UP
  echo "${blue}Checking whether interface ${interface} is UP${reset}"
  link_state=$(ip link show ${interface} | grep -oP 'state \K[^ ]+')
  if [[ ${link_state} != 'UP' ]]; then
    echo "${blue}${interface} state is ${link_state}. Bringing it UP!${reset}"
    ip link set dev ${interface} up
    sleep 5
    link_state=$(ip link show ${interface} | grep -oP 'state \K[^ ]+')
    if [[ ${link_state} == 'DOWN' ]]; then
      echo "${red}Could not bring UP interface ${interface} link state is ${link_state}${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi
}

#Create VLAN interface
create_vlan_interface()  {
  if [ -z $1 ]; then
    echo "${red}Cannot create VLAN interface. No base interface specified!${reset}"
    exit 1
  fi
  if [ -z $2 ]; then
    echo "${red}Cannot create VLAN interface. No VLAN ID specified!${reset}"
    exit 1
  fi

  local base_interface=$1
  local vid=$2
  local interface="${base_interface}.${vid}"

  echo "${blue}Checking whether VLAN ${vid} interface ${interface} exists, otherwise create it${reset}"
  if ! ip link show ${interface}; then
    echo "${blue}Creating  VLAN ${vid} interface ${interface}${reset}"
    ip link add link ${base_interface} name ${interface} type vlan id ${vid}
  else
    echo "${green}OK!${reset}"
  fi

  #Check whether VLAN interface is UP
  check_interface_up ${interface}
}

###setup PXE Bridge
setup_pxe_bridge() {
  pxe_vid=0
  pxe_interface="${private_interface}.${pxe_vid}"
  #Check whether VLAN 0 (PXE) interface exists, otherwise create it
  create_vlan_interface ${private_interface} ${pxe_vid}

  #Check whether PXE bridge exists
  echo "${blue}Checking whether PXE bridge ${pxe_bridge} exists${reset}"
  if brctl show ${pxe_bridge} 2>&1 | grep 'No such device'; then
    echo "${blue}Creating PXE bridge ${pxe_bridge}${reset}"
    brctl addbr ${pxe_bridge}
  else
    echo "${green}OK!${reset}"
  fi

  #Add VLAN 0 (PXE) interface to PXE bridge
  echo "${blue}Checking whether VLAN 0 (PXE) interface ${pxe_interface} is added to PXE bridge ${pxe_bridge} exists${reset}"
  if ! brctl show ${pxe_bridge} 2>&1 | grep ${pxe_interface}; then
    echo "${blue}Adding VLAN 0 (PXE) interface ${pxe_interface} to PXE bridge ${pxe_bridge}${reset}"
    brctl addif ${pxe_bridge} ${pxe_interface}
    if ! brctl show ${pxe_bridge} 2>&1 | grep ${pxe_interface}; then
      echo "${red}Could not add VLAN 0 (PXE) interface ${pxe_interface} to PXE bridge ${pxe_bridge}${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi

  #Check whether PXE bridge is UP
  check_interface_up ${pxe_bridge}

  #Add Fuel Gateway IP Address to PXE bridge
  echo "${blue}Checking whether Fuel Gateway IP Address ${fuel_gw_ip} is assigned to PXE bridge ${pxe_bridge}${reset}"
  if ! ip addr show ${pxe_bridge} | grep ${fuel_gw_ip}; then
    echo "${blue}Adding Fuel Gateway IP Address ${fuel_gw_ip} to PXE bridge ${pxe_bridge}${reset}"
    sudo ip addr add ${fuel_gw_ip} dev ${pxe_bridge}
    if ! ip addr show ${pxe_bridge} | grep ${fuel_gw_ip}; then
      echo "${red}Could not add Fuel Gateway IP Address ${fuel_gw_ip} to PXE bridge ${pxe_bridge}${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi
}

###check whether access to public network is granted
check_access_enabled_to_public_network() {
  #Check whether IP forwarding is enabled
  echo "${blue}Checking whether IP Forwarding is enabled ${reset}"
  if ! sysctl net.ipv4.ip_forward | grep "net.ipv4.ip_forward = 1"; then
    sysctl -w net.ipv4.ip_forward=1
    if ! sysctl net.ipv4.ip_forward | grep "net.ipv4.ip_forward = 1"; then
      echo "${red}IP Forwarding could not be enabled!${reset}"
      exit 1
    fi
  else
    echo "${green}OK!${reset}"
  fi

  echo "${blue}Checking whether access is granted to public network through interface ${public_interface}${reset}"
  if ! sudo iptables -t nat -L POSTROUTING -v | grep "MASQUERADE.*${public_interface}.*anywhere.*anywhere"; then
    echo "${blue}Enable access to public network through interface ${public_interface}${reset}"
    iptables -t nat -A POSTROUTING -o ${public_interface} -j MASQUERADE
  else
    echo "${green}OK!${reset}"
  fi
}

###setup Openstack Management Interface
create_openstack_management_interface() {
  #Check whether Openstack Management interface exists, otherwise create it
  create_vlan_interface ${private_interface} ${management_vid}

  echo "${blue}Moving IP addresses from interface ${private_interface} to VLAN ${management_vid} interface ${management_interface}${reset}"
  private_interface_ip_addr_list=$(ip addr show ${private_interface} | grep -oP 'inet \K[^ ]+')
  if [[ ! -z ${private_interface_ip_addr_list} ]]; then
    echo -e "${blue}Found IP addresses on interface ${private_interface}:\n${private_interface_ip_addr_list}${reset}"
    for private_interface_ip_addr in ${private_interface_ip_addr_list}
    do
      echo "${blue}Removing IP address ${private_interface_ip_addr} from interface ${private_interface}${reset}"
      ip addr del ${private_interface_ip_addr} dev ${private_interface}
      if ip addr show ${private_interface} | grep ${private_interface_ip_addr}; then
        echo "${red}Could not remove IP address ${private_interface_ip_addr} from interface ${private_interface}${reset}"
        exit 1
      fi
      if ! ip addr show ${management_interface} | grep ${private_interface_ip_addr}; then
        echo "${blue}Adding IP address ${private_interface_ip_addr} to VLAN ${management_vid} interface ${management_interface}${reset}"
        ip addr add ${private_interface_ip_addr} dev ${management_interface}
        if ! ip addr show ${management_interface} | grep ${private_interface_ip_addr}; then
          echo "${red}Could not set IP address ${private_interface_ip_addr} to VLAN ${management_vid} interface ${management_interface}${reset}"
          exit 1
        fi
      else
        echo "${blue}VLAN ${management_vid} interface ${management_interface} already has assigned to itself this IP address ${private_interface_ip_addr}${reset}"
      fi
    done
  else
    echo "${red}No IP Address is assigned to interface ${private_interface}, there isn't any IP address to move to interface ${management_interface}${reset}"
  fi
}

##END FUNCTIONS

main() {
  install_qemu_kvm
  install_libvirt
  load_kvm_kernel_mod
  start_libvirtd_service
  check_interface_exists ${private_interface}
  check_interface_up ${private_interface}
  check_interface_exists ${public_interface}
  check_interface_up ${public_interface}
  setup_pxe_bridge
  check_access_enabled_to_public_network
  create_openstack_management_interface
}

main "$@"
