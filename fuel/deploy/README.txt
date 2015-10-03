
======== How to prepare and run the OPNFV Autodeployment =======

in fuel/build/deploy run these:



--- Step.1 Install prerequisites

sudo ./install-ubuntu-packages.sh






--- Step.2-A If wou want to deploy OPNFV cloud environment on top of KVM/Libvirt virtualization
             run the following environment setup script

sudo python setup_environment.py <storage_directory> <path_to_dha_file>

Example:
         sudo python setup_environment.py /mnt/images dha.yaml






--- Step.2-B If you want to deploy OPNFV cloud environment on baremetal run the
             following environment setup script

sudo python setup_vfuel.py <storage_directory> <path_to_dha_file>

Example:
         sudo python setup_vfuel.py /mnt/images dha.yaml


WARNING!:
setup_vfuel.py adds the following snippet into /etc/network/interfaces
making sure to replace in setup_vfuel.py interfafe 'p1p1.20' with your actual outbound
interface in order to provide network access to the Fuel master for DNS and NTP.

iface vfuelnet inet static
	bridge_ports em1
	address 10.40.0.1
	netmask 255.255.255.0
	pre-down iptables -t nat -D POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
	pre-down iptables -D FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"
	post-up iptables -t nat -A POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
	post-up iptables -A FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"






--- Step.3 Start Autodeployment
Make sure you use the right Deployment Environment Adapter and
Deployment Hardware Adaper configuration files:

       - for baremetal:  baremetal/dea.yaml   baremetal/dha.yaml

       - for libvirt:    libvirt/dea.yaml   libvirt/dha.yaml


sudo python deploy.py [-nf] <isofile> <deafile> <dhafile>

Example:
         sudo python deploy.py ~/ISO/opnfv.iso baremetal/dea.yaml baremetal/dha.yaml

