#!/usr/bin/env bash

#Clean script to uninstall provisioning server for Foreman/QuickStack
#author: Tim Rozet (trozet@redhat.com)
#
#Uses Vagrant and VirtualBox
#
#Destroys Vagrant VM running in /tmp/bgs_vagrant
#Shuts down all nodes found in Khaleesi settings
#Removes hypervisor kernel modules (VirtualBox)

##VARS
reset=`tput sgr0`
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`
##END VARS

##FUNCTIONS
display_usage() {
  echo -e "\n\n${blue}This script is used to uninstall Foreman/QuickStack Installer and Clean OPNFV Target System${reset}\n\n"
  echo -e "\nUsage:\n$0 [arguments] \n"
  echo -e "\n   -no_parse : No variable parsing into config. Flag. \n"
  echo -e "\n   -base_config : Full path of ksgen settings file to parse. Required.  Will provide BMC info to shutdown hosts.  Example:  -base_config /opt/myinventory.yml \n"
}

##END FUNCTIONS

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then
    display_usage
    exit 0
fi

echo -e "\n\n${blue}This script is used to uninstall Foreman/QuickStack Installer and Clean OPNFV Target System${reset}\n\n"
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
        *)
                display_usage
                exit 1
            ;;
esac
done


# Install ipmitool
# Major version is pinned to force some consistency for Arno
if ! yum list installed | grep -i ipmitool; then
  if ! yum -y install ipmitool-1*; then
    echo "${red}Unable to install ipmitool!${reset}"
    exit 1
  fi
else
  echo "${blue}Skipping ipmitool as it is already installed!${reset}"
fi

###find all the bmc IPs and number of nodes
node_counter=0
output=`grep bmc_ip $base_config | grep -Eo '[0-9]+.[0-9]+.[0-9]+.[0-9]+'`
for line in ${output} ; do
  bmc_ip[$node_counter]=$line
  ((node_counter++))
done

max_nodes=$((node_counter-1))

###find bmc_users per node
node_counter=0
output=`grep bmc_user $base_config | sed 's/\s*bmc_user:\s*//'`
for line in ${output} ; do
  bmc_user[$node_counter]=$line
  ((node_counter++))
done

###find bmc_pass per node
node_counter=0
output=`grep bmc_pass $base_config | sed 's/\s*bmc_pass:\s*//'`
for line in ${output} ; do
  bmc_pass[$node_counter]=$line
  ((node_counter++)) 
done

for mynode in `seq 0 $max_nodes`; do
  echo "${blue}Node: ${bmc_ip[$mynode]} ${bmc_user[$mynode]} ${bmc_pass[$mynode]} ${reset}"
  if ipmitool -I lanplus -P ${bmc_pass[$mynode]} -U ${bmc_user[$mynode]} -H ${bmc_ip[$mynode]} chassis power off; then
    echo "${blue}Node: $mynode, ${bmc_ip[$mynode]} powered off!${reset}"
  else
    echo "${red}Error: Unable to power off $mynode, ${bmc_ip[$mynode]} ${reset}"
    exit 1
  fi
done

###check to see if vbox is installed
vboxpkg=`rpm -qa | grep VirtualBox`
if [ $? -eq 0 ]; then
  skip_vagrant=0
else
  skip_vagrant=1
fi

###destroy vagrant
if [ $skip_vagrant -eq 0 ]; then
  cd /tmp/bgs_vagrant
  if vagrant destroy -f; then
    echo "${blue}Successfully destroyed Foreman VM ${reset}"
  else
    echo "${red}Unable to destroy Foreman VM ${reset}"
    echo "${blue}Checking if vagrant was already destroyed and no process is active...${reset}"
    if ps axf | grep vagrant; then
      echo "${red}Vagrant VM still exists...exiting ${reset}"
      exit 1
    else
      echo "${blue}Vagrant process doesn't exist.  Moving on... ${reset}"
    fi
  fi

  ###kill virtualbox
  echo "${blue}Killing VirtualBox ${reset}"
  killall virtualbox
  killall VBoxHeadless

  ###remove virtualbox
  echo "${blue}Removing VirtualBox ${reset}"
  yum -y remove $vboxpkg

else
  echo "${blue}Skipping Vagrant destroy + Vbox Removal as VirtualBox package is already removed ${reset}"
fi


###remove kernel modules
echo "${blue}Removing kernel modules ${reset}"
for kernel_mod in vboxnetadp vboxnetflt vboxpci vboxdrv; do
  if ! rmmod $kernel_mod; then
    if rmmod $kernel_mod 2>&1 | grep -i 'not currently loaded'; then
      echo "${blue} $kernel_mod is not currently loaded! ${reset}"
    else
      echo "${red}Error trying to remove Kernel Module: $kernel_mod ${reset}"
      exit 1
    fi
  else
    echo "${blue}Removed Kernel Module: $kernel_mod ${reset}"
  fi
done
