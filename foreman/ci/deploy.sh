#!/usr/bin/env bash

#Deploy script to install provisioning server for Foreman/QuickStack
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#VagrantFile uses bootsrap.sh which Installs Khaleesi
#Khaleesi will install and configure Foreman/QuickStack
#
#Pre-requisties:
#Supports 3 or 4 network interface configuration
#Target system must be RPM based
#Ensure the host's kernel is up to date (yum update)
#Provisioned nodes expected to have following order of network connections (note: not all have to exist, but order is maintained):
#eth0- admin network
#eth1- private network (+storage network in 3 NIC config)
#eth2- public network
#eth3- storage network
#script assumes /24 subnet mask

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`

declare -A interface_arr
##END VARS

##FUNCTIONS
display_usage() {
  echo -e "\n\n${blue}This script is used to deploy Foreman/QuickStack Installer and Provision OPNFV Target System${reset}\n\n"
  echo -e "\n${green}Make sure you have the latest kernel installed before running this script! (yum update kernel +reboot)${reset}\n"
  echo -e "\nUsage:\n$0 [arguments] \n"
  echo -e "\n   -no_parse : No variable parsing into config. Flag. \n"
  echo -e "\n   -base_config : Full path of settings file to parse. Optional.  Will provide a new base settings file rather than the default.  Example:  -base_config /opt/myinventory.yml \n"
  echo -e "\n   -virtual : Node virtualization instead of baremetal. Flag. \n"
}

##find ip of interface
##params: interface name
function find_ip {
  ip addr show $1 | grep -Eo '^\s+inet\s+[\.0-9]+' | awk '{print $2}'
}

##finds subnet of ip and netmask
##params: ip, netmask
function find_subnet {
  IFS=. read -r i1 i2 i3 i4 <<< "$1"
  IFS=. read -r m1 m2 m3 m4 <<< "$2"
  printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}

##increments subnet by a value
##params: ip, value
##assumes low value
function increment_subnet {
  IFS=. read -r i1 i2 i3 i4 <<< "$1"
  printf "%d.%d.%d.%d\n" "$i1" "$i2" "$i3" "$((i4 | $2))"
}


##finds netmask of interface
##params: interface
##returns long format 255.255.x.x
function find_netmask {
  ifconfig $1 | grep -Eo 'netmask\s+[\.0-9]+' | awk '{print $2}'
}

##finds short netmask of interface
##params: interface
##returns short format, ex: /21
function find_short_netmask {
  echo "/$(ip addr show $1 | grep -Eo '^\s+inet\s+[\/\.0-9]+' | awk '{print $2}' | cut -d / -f2)"
}

##increments next IP
##params: ip
##assumes a /24 subnet
function next_ip {
  baseaddr="$(echo $1 | cut -d. -f1-3)"
  lsv="$(echo $1 | cut -d. -f4)"
  if [ "$lsv" -ge 254 ]; then
    return 1
  fi
  ((lsv++))
  echo $baseaddr.$lsv
}

##removes the network interface config from Vagrantfile
##params: interface
##assumes you are in the directory of Vagrantfile
function remove_vagrant_network {
  sed -i 's/^.*'"$1"'.*$//' Vagrantfile
}

##check if IP is in use
##params: ip
##ping ip to get arp entry, then check arp
function is_ip_used {
  ping -c 5 $1 > /dev/null 2>&1
  arp -n | grep "$1 " | grep -iv incomplete > /dev/null 2>&1
}

##find next usable IP
##params: ip
function next_usable_ip {
  new_ip=$(next_ip $1)
  while [ "$new_ip" ]; do
    if ! is_ip_used $new_ip; then
      echo $new_ip
      return 0
    fi
    new_ip=$(next_ip $new_ip)
  done
  return 1
}

##increment ip by value
##params: ip, amount to increment by
##increment_ip $next_private_ip 10
function increment_ip {
  baseaddr="$(echo $1 | cut -d. -f1-3)"
  lsv="$(echo $1 | cut -d. -f4)"
  incrval=$2
  lsv=$((lsv+incrval))
  if [ "$lsv" -ge 254 ]; then
    return 1
  fi
  echo $baseaddr.$lsv
}

##translates yaml into variables
##params: filename, prefix (ex. "config_")
##usage: parse_yaml opnfv_ksgen_settings.yml "config_"
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

##END FUNCTIONS

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then
    display_usage
    exit 0
fi

echo -e "\n\n${blue}This script is used to deploy Foreman/QuickStack Installer and Provision OPNFV Target System${reset}\n\n"
echo "Use -h to display help"
sleep 2

while [ "`echo $1 | cut -c1`" = "-" ]
do
    echo $1
    case "$1" in
        -base_config)
                base_config=$2
                shift 2
            ;;
        -no_parse)
                no_parse="TRUE"
                shift 1
            ;;
        -virtual)
                virtual="TRUE"
                shift 1
            ;;
        *)
                display_usage
                exit 1
            ;;
esac
done

##disable selinux
/sbin/setenforce 0

# Install EPEL repo for access to many other yum repos
# Major version is pinned to force some consistency for Arno
yum install -y epel-release-7*

# Install other required packages
# Major versions are pinned to force some consistency for Arno
if ! yum install -y binutils-2* gcc-4* make-3* patch-2* libgomp-4* glibc-headers-2* glibc-devel-2* kernel-headers-3* kernel-devel-3* dkms-2* psmisc-22*; then
  printf '%s\n' 'deploy.sh: Unable to install depdency packages' >&2
  exit 1
fi

##install VirtualBox repo
if cat /etc/*release | grep -i "Fedora release"; then
  vboxurl=http://download.virtualbox.org/virtualbox/rpm/fedora/\$releasever/\$basearch
else
  vboxurl=http://download.virtualbox.org/virtualbox/rpm/el/\$releasever/\$basearch
fi

cat > /etc/yum.repos.d/virtualbox.repo << EOM
[virtualbox]
name=Oracle Linux / RHEL / CentOS-\$releasever / \$basearch - VirtualBox
baseurl=$vboxurl
enabled=1
gpgcheck=1
gpgkey=https://www.virtualbox.org/download/oracle_vbox.asc
skip_if_unavailable = 1
keepcache = 0
EOM

##install VirtualBox
if ! yum list installed | grep -i virtualbox; then
  if ! yum -y install VirtualBox-4.3; then
    printf '%s\n' 'deploy.sh: Unable to install virtualbox package' >&2
    exit 1
  fi
fi

##install kmod-VirtualBox
if ! lsmod | grep vboxdrv; then
  if ! sudo /etc/init.d/vboxdrv setup; then
    printf '%s\n' 'deploy.sh: Unable to install kernel module for virtualbox' >&2
    exit 1
  fi
else
  printf '%s\n' 'deploy.sh: Skipping kernel module for virtualbox.  Already Installed'
fi

##install Ansible
if ! yum list installed | grep -i ansible; then
  if ! yum -y install ansible-1*; then
    printf '%s\n' 'deploy.sh: Unable to install Ansible package' >&2
    exit 1
  fi
fi

##install Vagrant
if ! rpm -qa | grep vagrant; then
  if ! rpm -Uvh https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.rpm; then
    printf '%s\n' 'deploy.sh: Unable to install vagrant package' >&2
    exit 1
  fi
else
  printf '%s\n' 'deploy.sh: Skipping Vagrant install as it is already installed.'
fi

##add centos 7 box to vagrant
if ! vagrant box list | grep chef/centos-7.0; then
  if ! vagrant box add chef/centos-7.0 --provider virtualbox; then
    printf '%s\n' 'deploy.sh: Unable to download centos7 box for Vagrant' >&2
    exit 1
  fi
else
  printf '%s\n' 'deploy.sh: Skipping Vagrant box add as centos-7.0 is already installed.'
fi

##install workaround for centos7
if ! vagrant plugin list | grep vagrant-centos7_fix; then
  if ! vagrant plugin install vagrant-centos7_fix; then
    printf '%s\n' 'deploy.sh: Warning: unable to install vagrant centos7 workaround' >&2
  fi
else
  printf '%s\n' 'deploy.sh: Skipping Vagrant plugin as centos7 workaround is already installed.'
fi

cd /tmp/

##remove bgs vagrant incase it wasn't cleaned up
rm -rf /tmp/bgs_vagrant

##clone bgs vagrant
##will change this to be opnfv repo when commit is done
if ! git clone -b v1.0 https://github.com/trozet/bgs_vagrant.git; then
  printf '%s\n' 'deploy.sh: Unable to clone vagrant repo' >&2
  exit 1
fi

cd bgs_vagrant

echo "${blue}Detecting network configuration...${reset}"
##detect host 1 or 3 interface configuration
#output=`ip link show | grep -E "^[0-9]" | grep -Ev ": lo|tun|virbr|vboxnet" | awk '{print $2}' | sed 's/://'`
output=`ifconfig | grep -E "^[a-zA-Z0-9]+:"| grep -Ev "lo|tun|virbr|vboxnet" | awk '{print $1}' | sed 's/://'`

if [ ! "$output" ]; then
  printf '%s\n' 'deploy.sh: Unable to detect interfaces to bridge to' >&2
  exit 1
fi

##find number of interfaces with ip and substitute in VagrantFile
if_counter=0
for interface in ${output}; do

  if [ "$if_counter" -ge 4 ]; then
    break
  fi
  interface_ip=$(find_ip $interface)
  if [ ! "$interface_ip" ]; then
    continue
  fi
  new_ip=$(next_usable_ip $interface_ip)
  if [ ! "$new_ip" ]; then
    continue
  fi
  interface_arr[$interface]=$if_counter
  interface_ip_arr[$if_counter]=$new_ip
  subnet_mask=$(find_netmask $interface)
  if [ "$if_counter" -eq 1 ]; then
    private_subnet_mask=$subnet_mask
    private_short_subnet_mask=$(find_short_netmask $interface)
  fi
  if [ "$if_counter" -eq 2 ]; then
    public_subnet_mask=$subnet_mask
    public_short_subnet_mask=$(find_short_netmask $interface)
  fi
  if [ "$if_counter" -eq 3 ]; then
    storage_subnet_mask=$subnet_mask
  fi
  sed -i 's/^.*eth_replace'"$if_counter"'.*$/  config.vm.network "public_network", ip: '\""$new_ip"\"', bridge: '\'"$interface"\'', netmask: '\""$subnet_mask"\"'/' Vagrantfile
  ((if_counter++))
done

##now remove interface config in Vagrantfile for 1 node
##if 1, 3, or 4 interfaces set deployment type
##if 2 interfaces remove 2nd interface and set deployment type
if [ "$if_counter" == 1 ]; then
  deployment_type="single_network"
  remove_vagrant_network eth_replace1
  remove_vagrant_network eth_replace2
  remove_vagrant_network eth_replace3
elif [ "$if_counter" == 2 ]; then
  deployment_type="single_network"
  second_interface=`echo $output | awk '{print $2}'`
  remove_vagrant_network $second_interface
  remove_vagrant_network eth_replace2
elif [ "$if_counter" == 3 ]; then
  deployment_type="three_network"
  remove_vagrant_network eth_replace3
else
  deployment_type="multi_network"
fi

echo "${blue}Network detected: ${deployment_type}! ${reset}"

if route | grep default; then
  echo "${blue}Default Gateway Detected ${reset}"
  host_default_gw=$(ip route | grep default | awk '{print $3}')
  echo "${blue}Default Gateway: $host_default_gw ${reset}"
  default_gw_interface=$(ip route get $host_default_gw | awk '{print $3}')
  case "${interface_arr[$default_gw_interface]}" in
           0)
             echo "${blue}Default Gateway Detected on Admin Interface!${reset}"
             sed -i 's/^.*default_gw =.*$/  default_gw = '\""$host_default_gw"\"'/' Vagrantfile
             node_default_gw=$host_default_gw
             ;;
           1)
             echo "${red}Default Gateway Detected on Private Interface!${reset}"
             echo "${red}Private subnet should be private and not have Internet access!${reset}"
             exit 1
             ;;
           2)
             echo "${blue}Default Gateway Detected on Public Interface!${reset}"
             sed -i 's/^.*default_gw =.*$/  default_gw = '\""$host_default_gw"\"'/' Vagrantfile
             echo "${blue}Will setup NAT from Admin -> Public Network on VM!${reset}"
             sed -i 's/^.*nat_flag =.*$/  nat_flag = true/' Vagrantfile
             echo "${blue}Setting node gateway to be VM Admin IP${reset}"
             node_default_gw=${interface_ip_arr[0]}
             public_gateway=$default_gw
             ;;
           3)
             echo "${red}Default Gateway Detected on Storage Interface!${reset}"
             echo "${red}Storage subnet should be private and not have Internet access!${reset}"
             exit 1
             ;;
           *)
             echo "${red}Unable to determine which interface default gateway is on..Exiting!${reset}"
             exit 1
             ;;
  esac
else
  #assumes 24 bit mask
  defaultgw=`echo ${interface_ip_arr[0]} | cut -d. -f1-3`
  firstip=.1
  defaultgw=$defaultgw$firstip
  echo "${blue}Unable to find default gateway.  Assuming it is $defaultgw ${reset}"
  sed -i 's/^.*default_gw =.*$/  default_gw = '\""$defaultgw"\"'/' Vagrantfile
  node_default_gw=$defaultgw
fi

if [ $base_config ]; then
  if ! cp -f $base_config opnfv_ksgen_settings.yml; then
    echo "{red}ERROR: Unable to copy $base_config to opnfv_ksgen_settings.yml${reset}"
    exit 1
  fi
fi

if [ $no_parse ]; then
echo "${blue}Skipping parsing variables into settings file as no_parse flag is set${reset}"

else

echo "${blue}Gathering network parameters for Target System...this may take a few minutes${reset}"
##Edit the ksgen settings appropriately
##ksgen settings will be stored in /vagrant on the vagrant machine
##if single node deployment all the variables will have the same ip
##interface names will be enp0s3, enp0s8, enp0s9 in chef/centos7

sed -i 's/^.*default_gw:.*$/default_gw:'" $node_default_gw"'/' opnfv_ksgen_settings.yml

##replace private interface parameter
##private interface will be of hosts, so we need to know the provisioned host interface name
##we add biosdevname=0, net.ifnames=0 to the kickstart to use regular interface naming convention on hosts
##replace IP for parameters with next IP that will be given to controller
if [ "$deployment_type" == "single_network" ]; then
  ##we also need to assign IP addresses to nodes
  ##for single node, foreman is managing the single network, so we can't reserve them
  ##not supporting single network anymore for now
  echo "{blue}Single Network type is unsupported right now.  Please check your interface configuration.  Exiting. ${reset}"
  exit 0

elif [[ "$deployment_type" == "multi_network" || "$deployment_type" == "three_network" ]]; then

  if [ "$deployment_type" == "three_network" ]; then
    sed -i 's/^.*network_type:.*$/network_type: three_network/' opnfv_ksgen_settings.yml
  fi

  sed -i 's/^.*deployment_type:.*$/  deployment_type: '"$deployment_type"'/' opnfv_ksgen_settings.yml

  ##get ip addresses for private network on controllers to make dhcp entries
  ##required for controllers_ip_array global param
  next_private_ip=${interface_ip_arr[1]}
  type=_private
  for node in controller1 controller2 controller3; do
    next_private_ip=$(next_usable_ip $next_private_ip)
    if [ ! "$next_private_ip" ]; then
       printf '%s\n' 'deploy.sh: Unable to find next ip for private network for control nodes' >&2
       exit 1
    fi
    sed -i 's/'"$node$type"'/'"$next_private_ip"'/g' opnfv_ksgen_settings.yml
    controller_ip_array=$controller_ip_array$next_private_ip,
  done

  ##replace global param for contollers_ip_array
  controller_ip_array=${controller_ip_array%?}
  sed -i 's/^.*controllers_ip_array:.*$/  controllers_ip_array: '"$controller_ip_array"'/' opnfv_ksgen_settings.yml

  ##now replace all the VIP variables.  admin//private can be the same IP
  ##we have to use IP's here that won't be allocated to hosts at provisioning time
  ##therefore we increment the ip by 10 to make sure we have a safe buffer
  next_private_ip=$(increment_ip $next_private_ip 10)

  grep -E '*private_vip|loadbalancer_vip|db_vip|amqp_vip|*admin_vip' opnfv_ksgen_settings.yml | while read -r line ; do
    sed -i 's/^.*'"$line"'.*$/  '"$line $next_private_ip"'/' opnfv_ksgen_settings.yml
    next_private_ip=$(next_usable_ip $next_private_ip)
    if [ ! "$next_private_ip" ]; then
       printf '%s\n' 'deploy.sh: Unable to find next ip for private network for vip replacement' >&2
       exit 1
    fi
  done

  ##replace foreman site
  next_public_ip=${interface_ip_arr[2]}
  sed -i 's/^.*foreman_url:.*$/  foreman_url:'" https:\/\/$next_public_ip"'\/api\/v2\//' opnfv_ksgen_settings.yml
  ##replace public vips
  next_public_ip=$(increment_ip $next_public_ip 10)
  grep -E '*public_vip' opnfv_ksgen_settings.yml | while read -r line ; do
    sed -i 's/^.*'"$line"'.*$/  '"$line $next_public_ip"'/' opnfv_ksgen_settings.yml
    next_public_ip=$(next_usable_ip $next_public_ip)
    if [ ! "$next_public_ip" ]; then
       printf '%s\n' 'deploy.sh: Unable to find next ip for public network for vip replcement' >&2
       exit 1
    fi
  done

  ##replace public_network param
  public_subnet=$(find_subnet $next_public_ip $public_subnet_mask)
  sed -i 's/^.*public_network:.*$/  public_network:'" $public_subnet"'/' opnfv_ksgen_settings.yml
  ##replace private_network param
  private_subnet=$(find_subnet $next_private_ip $private_subnet_mask)
  sed -i 's/^.*private_network:.*$/  private_network:'" $private_subnet"'/' opnfv_ksgen_settings.yml
  ##replace storage_network
  if [ "$deployment_type" == "three_network" ]; then
    sed -i 's/^.*storage_network:.*$/  storage_network:'" $private_subnet"'/' opnfv_ksgen_settings.yml
  else
    next_storage_ip=${interface_ip_arr[3]}
    storage_subnet=$(find_subnet $next_storage_ip $storage_subnet_mask)
    sed -i 's/^.*storage_network:.*$/  storage_network:'" $storage_subnet"'/' opnfv_ksgen_settings.yml
  fi

  ##replace public_subnet param
  public_subnet=$public_subnet'\'$public_short_subnet_mask
  sed -i 's/^.*public_subnet:.*$/  public_subnet:'" $public_subnet"'/' opnfv_ksgen_settings.yml
  ##replace private_subnet param
  private_subnet=$private_subnet'\'$private_short_subnet_mask
  sed -i 's/^.*private_subnet:.*$/  private_subnet:'" $private_subnet"'/' opnfv_ksgen_settings.yml

  ##replace public_dns param to be foreman server
  sed -i 's/^.*public_dns:.*$/  public_dns: '${interface_ip_arr[2]}'/' opnfv_ksgen_settings.yml

  ##replace public_gateway
  if [ -z "$public_gateway" ]; then
    ##if unset then we assume its the first IP in the public subnet
    public_subnet=$(find_subnet $next_public_ip $public_subnet_mask)
    public_gateway=$(increment_subnet $public_subnet 1)
  fi
  sed -i 's/^.*public_gateway:.*$/  public_gateway:'" $public_gateway"'/' opnfv_ksgen_settings.yml

  ##we have to define an allocation range of the public subnet to give
  ##to neutron to use as floating IPs
  ##we should control this subnet, so this range should work .150-200
  ##but generally this is a bad idea and we are assuming at least a /24 subnet here
  public_subnet=$(find_subnet $next_public_ip $public_subnet_mask)
  public_allocation_start=$(increment_subnet $public_subnet 150)
  public_allocation_end=$(increment_subnet $public_subnet 200)

  sed -i 's/^.*public_allocation_start:.*$/  public_allocation_start:'" $public_allocation_start"'/' opnfv_ksgen_settings.yml
  sed -i 's/^.*public_allocation_end:.*$/  public_allocation_end:'" $public_allocation_end"'/' opnfv_ksgen_settings.yml

else
  printf '%s\n' 'deploy.sh: Unknown network type: $deployment_type' >&2
  exit 1
fi

echo "${blue}Parameters Complete.  Settings have been set for Foreman. ${reset}"

fi

if [ $virtual ]; then
  echo "${blue} Virtual flag detected, setting Khaleesi playbook to be opnfv-vm.yml ${reset}"
  sed -i 's/opnfv.yml/opnfv-vm.yml/' bootstrap.sh
fi

echo "${blue}Starting Vagrant! ${reset}"

##stand up vagrant
if ! vagrant up; then
  printf '%s\n' 'deploy.sh: Unable to start vagrant' >&2
  exit 1
else
  echo "${blue}Foreman VM is up! ${reset}"
fi

if [ $virtual ]; then

##Bring up VM nodes
echo "${blue}Setting VMs up... ${reset}"
nodes=`sed -nr '/nodes:/{:start /workaround/!{N;b start};//p}' opnfv_ksgen_settings.yml | sed -n '/^  [A-Za-z0-9]\+:$/p' | sed 's/\s*//g' | sed 's/://g'`
##due to ODL Helium bug of OVS connecting to ODL too early, we need controllers to install first
##this is fix kind of assumes more than I would like to, but for now it should be OK as we always have
##3 static controllers
compute_nodes=`echo $nodes | tr " " "\n" | grep -v controller | tr "\n" " "`
controller_nodes=`echo $nodes | tr " " "\n" | grep controller | tr "\n" " "`
nodes=${controller_nodes}${compute_nodes}

for node in ${nodes}; do
  cd /tmp

  ##remove VM nodes incase it wasn't cleaned up
  rm -rf /tmp/$node

  ##clone bgs vagrant
  ##will change this to be opnfv repo when commit is done
  if ! git clone -b v1.0 https://github.com/trozet/bgs_vagrant.git $node; then
    printf '%s\n' 'deploy.sh: Unable to clone vagrant repo' >&2
    exit 1
  fi

  cd $node

  if [ $base_config ]; then
    if ! cp -f $base_config opnfv_ksgen_settings.yml; then
      echo "{red}ERROR: Unable to copy $base_config to opnfv_ksgen_settings.yml${reset}"
      exit 1
    fi
  fi

  ##parse yaml into variables
  eval $(parse_yaml opnfv_ksgen_settings.yml "config_")
  ##find node type
  node_type=config_nodes_${node}_type
  node_type=$(eval echo \$$node_type)

  ##find number of interfaces with ip and substitute in VagrantFile
  output=`ifconfig | grep -E "^[a-zA-Z0-9]+:"| grep -Ev "lo|tun|virbr|vboxnet" | awk '{print $1}' | sed 's/://'`

  if [ ! "$output" ]; then
    printf '%s\n' 'deploy.sh: Unable to detect interfaces to bridge to' >&2
    exit 1
  fi


  if_counter=0
  for interface in ${output}; do

    if [ "$if_counter" -ge 4 ]; then
      break
    fi
    interface_ip=$(find_ip $interface)
    if [ ! "$interface_ip" ]; then
      continue
    fi
    case "${if_counter}" in
           0)
             mac_string=config_nodes_${node}_mac_address
             mac_addr=$(eval echo \$$mac_string)
             mac_addr=$(echo $mac_addr | sed 's/:\|-//g')
             if [ $mac_addr == "" ]; then
                 echo "${red} Unable to find mac_address for $node! ${reset}"
                 exit 1
             fi
             ;;
           1)
             if [ "$node_type" == "controller" ]; then
               mac_string=config_nodes_${node}_private_mac
               mac_addr=$(eval echo \$$mac_string)
               if [ $mac_addr == "" ]; then
                 echo "${red} Unable to find private_mac for $node! ${reset}"
                 exit 1
               fi
             else
               ##generate random mac
               mac_addr=$(echo -n 00-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"')
             fi
             mac_addr=$(echo $mac_addr | sed 's/:\|-//g')
             ;;
           *)
             mac_addr=$(echo -n 00-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"')
             mac_addr=$(echo $mac_addr | sed 's/:\|-//g')
             ;;
    esac
    sed -i 's/^.*eth_replace'"$if_counter"'.*$/  config.vm.network "public_network", bridge: '\'"$interface"\'', :mac => '\""$mac_addr"\"'/' Vagrantfile
    ((if_counter++))
  done

  ##now remove interface config in Vagrantfile for 1 node
  ##if 1, 3, or 4 interfaces set deployment type
  ##if 2 interfaces remove 2nd interface and set deployment type
  if [ "$if_counter" == 1 ]; then
    deployment_type="single_network"
    remove_vagrant_network eth_replace1
    remove_vagrant_network eth_replace2
    remove_vagrant_network eth_replace3
  elif [ "$if_counter" == 2 ]; then
    deployment_type="single_network"
    second_interface=`echo $output | awk '{print $2}'`
    remove_vagrant_network $second_interface
    remove_vagrant_network eth_replace2
  elif [ "$if_counter" == 3 ]; then
    deployment_type="three_network"
    remove_vagrant_network eth_replace3
  else
    deployment_type="multi_network"
  fi

  ##modify provisioning to do puppet install, config, and foreman check-in
  ##substitute host_name and dns_server in the provisioning script
  host_string=config_nodes_${node}_hostname
  host_name=$(eval echo \$$host_string)
  sed -i 's/^host_name=REPLACE/host_name='$host_name'/' vm_nodes_provision.sh
  ##dns server should be the foreman server
  sed -i 's/^dns_server=REPLACE/dns_server='${interface_ip_arr[0]}'/' vm_nodes_provision.sh

  ## remove bootstrap and NAT provisioning
  sed -i '/nat_setup.sh/d' Vagrantfile
  sed -i 's/bootstrap.sh/vm_nodes_provision.sh/' Vagrantfile

  ## modify default_gw to be node_default_gw
  sed -i 's/^.*default_gw =.*$/  default_gw = '\""$node_default_gw"\"'/' Vagrantfile

  ## modify VM memory to be 4gig
  sed -i 's/^.*vb.memory =.*$/     vb.memory = 4096/' Vagrantfile

  echo "${blue}Starting Vagrant Node $node! ${reset}"

  ##stand up vagrant
  if ! vagrant up; then
    echo "${red} Unable to start $node ${reset}"
    exit 1
  else
    echo "${blue} $node VM is up! ${reset}"
  fi

done

 echo "${blue} All VMs are UP! ${reset}"

fi
