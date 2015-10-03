# Foreman/QuickStack Automatic Deployment README

A simple bash script (deploy.sh) will provision out a Foreman/QuickStack VM Server and 4-5 other baremetal or VM nodes in an OpenStack HA + OpenDaylight environment.

##Pre-Requisites
####Baremetal:
* At least 5 baremetal servers, with 3 interfaces minimum, all connected to separate VLANs
* DHCP should not be running in any VLAN. Foreman will act as a DHCP server.
* On the baremetal server that will be your JumpHost, you need to have the 3 interfaces configured with IP addresses
* On baremetal JumpHost you will need an RPM based linux (CentOS 7 will do) with the kernel up to date (yum update kernel) + at least 2GB of RAM
* Nodes will need to be set to PXE boot first in priority, and off the first NIC, connected to the same VLAN as NIC 1 * of your JumpHost
* Nodes need to have BMC/OOB management via IPMI setup
* Internet access via first (Admin) or third interface (Public)
* No other hypervisors should be running on JumpHost

####VM Nodes:
* JumpHost with 3 interfaces, configured with IP, connected to separate VLANS
* DHCP should not be running in any VLAN.  Foreman will act as a DHCP Server
* On baremetal JumpHost you will need an RPM based linux (CentOS 7 will do) with the kernel up to date (yum update kernel) + at least 24GB of RAM
* Internet access via the first (Admin) or third interface (Public)
* No other hypervisors should be running on JumpHost

##How It Works

###deploy.sh:

* Detects your network configuration (3 or 4 usable interfaces)
* Modifies a “ksgen.yml” settings file and Vagrantfile with necessary network info
* Installs Vagrant and dependencies
* Downloads Centos7 Vagrant basebox, and issues a “vagrant up” to start the VM
* The Vagrantfile points to bootstrap.sh as the provisioner to takeover rest of the install

###bootstrap.sh:

* Is initiated inside of the VM once it is up
* Installs Khaleesi, Ansible, and Python dependencies
* Makes a call to Khaleesi to start a playbook: opnfv.yml + “ksgen.yml” settings file

###Khaleesi (Ansible):

* Runs through the playbook to install Foreman/QuickStack inside of the VM
* Configures services needed for a JumpHost: DHCP, TFTP, DNS
* Uses info from “ksgen.yml” file to add your nodes into Foreman and set them to Build mode

####Baremetal Only:
* Issues an API call to Foreman to rebuild all nodes
* Ansible then waits to make sure nodes come back via ssh checks
* Ansible then waits for puppet to run on each node and complete

####VM Only:
* deploy.sh then brings up 5 more Vagrant VMs
* Checks into Foreman and tells Foreman nodes are built
* Configures and starts puppet on each node

##Execution Instructions

* On your JumpHost, clone 'git clone https://github.com/trozet/bgs_vagrant.git' to as root to /root/

####Baremetal Only:
* Edit opnvf_ksgen_settings.yml → “nodes” section:

  * For each node, compute, controller1..3:
    * mac_address - change to mac_address of that node's Admin NIC (1st NIC)
    * bmc_ip - change to IP of BMC (out-of-band) IP
    * bmc_mac - same as above, but MAC address
    * bmc_user - IPMI username
    * bmc_pass - IPMI password

  * For each controller node:
    * private_mac - change to mac_address of node's Private NIC (2nd NIC)

* Execute deploy.sh via: ./deploy.sh -base_config /root/bgs_vagrant/opnfv_ksgen_settings.yml

####VM Only:
* Execute deploy.sh via: ./deploy.sh -virtual
* Install directory for each VM will be in /tmp (for example /tmp/compute, /tmp/controller1)

####Both Approaches:
* Install directory for foreman-server is /tmp/bgs_vagrant/ - This is where vagrant will be launched from automatically
* To access the VM you can 'cd /tmp/bgs_vagrant' and type 'vagrant ssh'
* To access Foreman enter the IP address shown in 'cat /tmp/bgs_vagrant/opnfv_ksgen_settings.yml | grep foreman_url'
* The user/pass by default is admin//octopus

##Redeploying
Make sure you run ./clean.sh for the baremetal deployment with your opnfv_ksgen_settings.yml file as "-base_config".  This will ensure that your nodes are turned off and that your VM is destroyed ("vagrant destroy" in the /tmp/bgs_vagrant directory).
For VM redeployment, make sure you "vagrant destroy" in each /tmp/<node> as well if you want to redeploy.  To check and make sure no VMs are still running on your Jumphost you can use "vboxmanage list runningvms".
