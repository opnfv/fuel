This is an example setup for the libvirt DHA adapter which will setup
four libvirt networks:

fuel1: NATed network for management and admin
fuel2: Isolated network for storage
fuel3: Isolated network for private
fuel4: NATed network for public

Four VMs will be created:

fuel-master
controller1
compute4
compute5

Prerequisite: A Ubuntu 14.x host or later with sudo access.

Start by installing the necessary Ubuntu packages by running
"sudo install_ubuntu_packages.sh".

Then (re)generate the libvirt network and VM setup by running
"setup_vms.sh".

You can then run deploy.sh with the corresponding dea.yaml and
dha.yaml which can be found in the conf subdirectory.
