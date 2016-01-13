========================================================================================================
OPNFV Installation instruction for the Brahmaputra release of OPNFV when using Fuel as a deployment tool
========================================================================================================

.. contents:: Table of Contents
   :backlinks: none

Abstract
========
This document describes how to install the Brahmaputra release of
OPNFV when using Fuel as a deployment tool, covering  it's usage,
limitations, dependencies and required system resources.

License
=======
Brahmaputra release of OPNFV when using Fuel as a deployment tool
Docs (c) by Jonas Bjurel (Ericsson AB)

This document is licensed under a Creative Commons Attribution 4.0
International License. You should have received a copy of the license
along with this. If not, see
<http://creativecommons.org/licenses/by/4.0/>.

Version history
===============
+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 1.0.0              | Jonas Bjurel       | Installation       |
|                    |                    | (Ericsson AB)      | instruction for    |
|                    |                    |                    | the Arno release   |
|		     |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-09-27	     | 1.1.0              | Daniel Smith       | ARNO SR1-RC1       |
|                    |                    |  (Ericsson AB)     | update             |
|		     |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-11-19         | 2.0.0              | Daniel Smith       | B-Rel WP1 update   |
|		     |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2016-02-02         | 2.0.1              | Jonas Bjurel       | Minor updates      |
|		     |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+

Introduction
============

This document provides guidelines on how to install and
configure the Brahmaputra release of OPNFV when using Fuel as a
deployment tool, including required software and hardware configurations.

Although the available installation options gives a high degree of
freedom in how the system is set-up, including architecture, services
and features, etc. said permutations may not provide an OPNFV
compliant reference architecture. This instruction provides a
step-by-step guide that results in an OPNFV Brahmaputra compliant
deployment.

The audience of this document is assumed to have good knowledge in
networking and Unix/Linux administration.

Preface
=======
Before starting the installation of the Brahmaputra release of
OPNFV, using Fuel as a deployment tool, some planning must be
done.

Retrieving the ISO image
------------------------

First of all, the Fuel deployment ISO image needs to be retrieved, the
.iso image of the Brahmaputra release of OPNFV when using Fuel as
a deployment tool can be found at <TODO>   NOTE:
TO BE UPDATED WITH FINAL B-REL ARTIFACT


Building the ISO image
----------------------


Alternatively, you may build the .iso from source by cloning the
opnfv/genesis git repository.  To retrieve the repository for the Brahmaputra
release use the following command:

$git clone https://<linux foundation uid>@gerrit.opnf.org/gerrit/fuel

Check-out the Brahmaputra release tag to set the branch to the
baseline required to replicate the Brahmaputra release:

$ git checkout stable/<TODO>

Go to the fuel directory and build the .iso:

$ cd fuel/build; make all

For more information on how to build, please see "OPNFV Build
instructions for - Brahmaputra release of OPNFV when using Fuel as
a deployment tool which you retrieved with the repository at
</fuel/fuel/docs/src/build-instructions.rst> <TODO>

Next, familiarize yourself with the Fuel by reading the following documents:

- Fuel planning guide
  <https://docs.mirantis.com/openstack/fuel/fuel-7.0/planning-guide.html>

- Fuel user guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html>

- Fuel operations guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/operations.html>

- Fuel Plugin Developers Guide <https://wiki.openstack.org/wiki/Fuel/Plugins>

A number of deployment specific parameters must be collected, those are:

#.     Provider sub-net and gateway information

#.     Provider VLAN information

#.     Provider DNS addresses

#.     Provider NTP addresses

#.     Network Topology you plan to Deploy (VLAN, VXLAN, FLAT)

#.     How many nodes and what roles you want to deploy (Controllers, Storage, Computes)

#.     Monitoring Options you want to deploy (Ceilometer, MongoDB).

#.     Other options not covered in the document are available in the links above


This information will be needed for the configuration procedures
provided in this document.

Hardware requirements
=====================

The following minimum hardware requirements must be met for the
installation of Brahmaputra using Fuel:

+--------------------+------------------------------------------------------+
| **HW Aspect**      | **Requirement**                                      |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **# of nodes**     | Minimum 5 (3 for non redundant deployment):          |
|                    |                                                      |
|                    | - 1 Fuel deployment master (may be virtualized)      |
|                    |                                                      |
|                    | - 3(1) Controllers (1 colocated mongo/ceilometer     |
|                    |   role, 2 Ceph-OSD roles)                            |
|                    |                                                      |
|                    | - 1 Compute (1 co-located Ceph-OSD role)             |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **CPU**            | Minimum 1 socket x86_AMD64 with Virtualization       |
|                    | support                                              |
+--------------------+------------------------------------------------------+
| **RAM**            | Minimum 16GB/server (Depending on VNF work load)     |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **Disk**           | Minimum 256GB 10kRPM spinning disks                  |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **Networks**       | 4 Tagged VLANs (PUBLIC, MGMT, STORAGE, PRIVATE)      |
|                    |                                                      |
|                    | 1 Un-Tagged VLAN for PXE Boot - ADMIN Network        |
|                    |                                                      |
|                    | note: These can be run on single NIC - or spread out |
|                    | over other nics as your hardware supports            |
+--------------------+------------------------------------------------------+

Help with Hardware Requirements
===============================

Calculate hardware requirements:

Refer to the OpenStack Hardware Compability List:
<https://www.mirantis.com/products/openstack-drivers-and-plugins/hardware-compatibility-list/>
for more information on various hardware types available for use.

When choosing the hardware on which you will deploy your OpenStack
environment, you should think about:

        - CPU -- Consider the number of virtual machines that you plan
          to deploy in your cloud environment and the CPU per virtual
          machine.
        - Memory -- Depends on the amount of RAM assigned per virtual
          machine and the controller node.
        - Storage -- Depends on the local drive space per virtual
          machine, remote volumes that can be attached to a virtual
          machine, and object storage.
        - Networking -- Depends on the Choose Network Topology, the
          network bandwidth per virtual machine, and network storage.


Top of the rack (TOR) Configuration requirements
================================================

The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South); it also provides needed connectivity for
the storage Area Network (SAN). 
To avoid traffic congestion, it is strongly suggested that three 
physically separated networks are used, that is: 1 physical network 
for administration and control, one physical network for tenant private
and public network, and one physical network for SAN.
The switching connectivity can (but does not need to) be fully redundant,
in such case it and comprises a redundant 10GE switch pair for each of the
three physically separated networks.

The physical TOR switches are **not** automatically configured from
the Fuel OPNFV reference platform. All the networks involved in the OPNFV
infrastructure as well as the provider networks and the private tenant
VLANs needs to be manually configured.

Manual configuration of the Brahmaputra hardware platform should
be carried out according to the Pharos specification:
<https://wiki.opnfv.org/pharos/pharos_specification>

OPNFV Software installation and deployment
==========================================

This section describes the installation of the OPNFV installation
server (Fuel master) as well as the deployment of the full OPNFV
reference platform stack across a server cluster.

Install Fuel master
-------------------
#. Mount the Brahmaputra Fuel ISO file as a boot device to the jump host server.

#. Reboot the jump host to establish the Fuel server.

   - The system now boots from the ISO image.

   - Select 'Fuel Install (Static IP)' (See figure below)

   - Press [Enter].

   .. figure:: img/grub-1.png
   
#. Wait until screen Fuel setup is shown (Note: This can take up to 30 minutes).

#. In the 'Fuel User' section - Confirm/change the default password (See figure below)
   - Enter 'admin' in the Fuel password input

   - Enter 'admin' in the Confim password input

   - Select 'Check' and press [Enter]

   .. figure:: img/fuelmenu1.png

#. In the 'Network Setup' section - Configure DHCP/Static IP information for your FUEL node - For example, ETH0 is 10.20.0.2/24 for FUEL booting and ETH1 is DHCP in your corporate/lab network (see figure below).

   - Configure eth1 or other network interfaces here as well (if you have them present on your FUEL server).

   .. figure:: img/fuelmenu2.png

#. In the 'PXE Setup' section (see figure below) - Change the following fields to appropriate values (example below):

   - DHCP Pool Start 10.20.0.3

   - DHCP Pool End 10.20.0.254

   - DHCP Pool Gateway  10.20.0.2 (ip of Fuel node)

   .. figure:: img/fuelmenu3.png

#. In the 'DNS & Hostname' section (see figure below) - Change the following fields to appropriate values:

   - Hostname <OPNFV Region name>-fuel

   - Domain <Domain Name>

   - Search Domain <Search Domain Name>

   - External DNS

   - Hostname to test DNS <Hostname to test DNS>

   - Select 'Check' and press [Enter]

   .. figure:: img/fuelmenu4.png


#. OPTION TO ENABLE PROXY SUPPORT - In the 'Bootstrap Image' section (see figure below), edit the following fields to define a proxy.
   **NOTE:** cannot be used in tandem with local repo support

   - Navigate to 'HTTP proxy' and input your http proxy address

   - Select 'Check' and press [Enter]

   .. figure:: img/fuelmenu5.png

#. In the 'Time Sync' section (see figure below) - Change the following fields to appropriate values:

   - NTP Server 1 <Customer NTP server 1>

   - NTP Server 2 <Customer NTP server 2>

   - NTP Server 3 <Customer NTP server 3>

   .. figure:: img/fuelmenu6.png

#. Start the installation.

   - Select Quit Setup and press Save and Quit.

   - Installation starts, wait until a screen with logon credentials is shown.


Boot the Node Servers
---------------------

After the Fuel Master node has rebooted from the above step and is at
the login prompt, you should boot the Node Servers (Your
Compute/Control/Storage blades (nested or real) with a PXE booting
scheme so that the FUEL Master can pick them up for control.

#. Enable PXE booting

    - For every controller and compute server: enable PXE Booting as
      the first boot device in the BIOS boot order menu and hard disk
      as the second boot device in the same menu.

#. Reboot all the control and compute blades.

#. Wait for the availability of nodes showing up in the Fuel GUI.

    - Connect to the FUEL UI via the URL provided in the Console
      (default: https://10.20.0.2:8443)

    - Wait until all nodes are displayed in top right corner of the
      Fuel GUI: Total nodes and Unallocated nodes (see figure below).

   .. figure:: img/nodes.png


Install Aditional Plugins/Features on the FUEL node
---------------------------------------------------

#. SSH to your FUEL node   (e.g. root@10.20.0.2  pwd: r00tme)

#. Select wanted plugins/features from the /opt/opnfv/ directory.

#. Install the wanted plugin with the command "fuel plugins --install /opt/opnfv/<plugin-name>-<version>.<arch>.rpm"
   
   Expected output: "Plugin ....... was successfully installed." (see figure below)

   .. figure:: img/plugin_install.png

Create an OPNFV Environment
---------------------------

#. Connect to Fuel WEB UI with a browser (default: https://10.20.0.2:8443) (login admin/admin)

#. Create and name a new OpenStack environment, to be installed.

   .. figure:: img/newenv.png
    
#. Select <Liberty on Ubuntu 14.04> and press "Next"

#. Select compute virtulization method.

   - Select QEMU-KVM as hypervisor and press "Next"

#. Select network mode.

   - Select Neutron with ML2 plugin

   - Select Neutron with tunneling segmentation (Required when using the ODL or ONOS plugins)

   - Press "Next"

#. Select Storage Back-ends.

   - Select Ceph for block storage and press "Next"

#. Select additional services you wish to install.

   - Check option <Install Celiometer (OpenStack Telemetry)> and press "Next"

#. Create the new environment.

   - Click "Create" Button

Configure the network environment
---------------------------------

#. Open the environment you previously created.

#. Open the networks tab and select the default Node Networks group to the left (see figure below).

   .. figure:: img/network.png

#. Update the Public network configuration and change the following fields to appropriate values:

   - CIDR to <CIDR for Public IP Addresses>

   - IP Range Start to <Public IP Address start>

   - IP Range End to <Public IP Address end>

   - Gateway to <Gateway for Public IP Addresses>

   - Check VLAN tagging.

   - Set appropriate VLAN id.
    
#. Update the Storage Network Configuration

   - Set CIDR to appropriate value  (default 192.168.1.0/24)

   - Set IP Range Start to appropriate value (default 192.168.1.1)

   - Set IP Range End to appropriate value (default 192.168.1.254)

   - Set vlan to appropriate value  (default 102)

#. Update the Management network configuration.

   - Set CIDR to appropriate value (default 192.168.0.0/24)

   - Set IP Range Start to appropriate value (default 192.168.0.1)

   - Set IP Range End to appropriate value (default 192.168.0.254)

   - Check VLAN tagging.

   - Set appropriate VLAN id. (default 101)

#. Update the Private Network Information

   - Set CIDR to appropriate value (default 192.168.2.0/24

   - Set IP Range Start to appropriate value (default 192.168.2.1)

   - Set IP Range End to appropriate value (default 192.168.2.254)

   - Check and set VLAN tag appropriately (default 103)

#. Select the Neutron L3 Node Networks group to the left.

   .. figure:: img/neutronl3.png

#. Update the Floating Network configuration.

   - Set the Floating IP range start (default 172.16.0.130)

   - Set the Floating IP range end (default 172.16.0.254)

   - Set the Floating network name (default admin_floating_net)

#. Update the Internal Network configuration.

   - Set Internal network CIDR to an appropriate value (default 192.168.111.0/24)

   - Set Internal network gateway to an appropriate value

   - Set the Internal network name (default admin_internal_net)

#. Update the Guest OS DNS servers.

   - Set Guest OS DNS Server values appropriately

#. Save Settings.

#. Select the Other Node Networks group to the left (see figure below).

   .. figure:: img/other.png

#. Update the Public network assignment.

   - Check the box for "Asign public network to all nodes"
     (Required by OpenDaylight)

#. Update Host OS DNS Servers.

   - Provide the DNS server settings

#. Update Host OS NTP Servers.

   - Provide the NTP server settings

Select Hypervisor type
----------------------

#. In the FUEL UI of your Enviornment, click the "Settings" Tab

#. Select Compute on the left side pane (see figure below)

   - Check the KVM box and press "Save settings"

   .. figure:: img/compute.png

Enable Plugins
--------------

#. In the FUEL UI of your Enviornment, click the "Settings" Tab

#. Select Other on the left side pane (see figure below)

   - Enable and configure the plugins of your choice

   .. figure:: img/plugins.png

Allocate nodes to environment and assign functional roles
---------------------------------------------------------

#. Click on the "Nodes" Tab in the FUEL WEB UI (see figure below).

    .. figure:: img/addnodes.png

#. Assign roles (see figure below).

    - Click on "+Add Nodes" button

    - Check "Controller", "Telemetry - MongoDB"  and optionally an SDN Controller
      role (OpenDaylight controller/ONOS) in the Assign Roles Section.

    - Check 1 node which you want to act as a Controller from the bottom half of the screen

    - Click <Apply Changes>.

    - Click on "+Add Nodes" button

    - Check the "Controller" and "Storage - Ceph OSD" roles.

    - Check the 2 next nodes you want to act as Controllers from the bottom half of the screen

    - Click <Apply Changes>

    - Click on "+Add Nodes" button

    - Check the "Compute" and "Storage - Ceph OSD" roles.

    - Check the Nodes you want to act as Computes from the bottom half of the screen

    - Click <Apply Changes>.

    .. figure:: img/computelist.png

#. Configure interfaces (see figure below).

    - Check Select <All> to select all allocated nodes

    - Click <Configure Interfaces>

    - Assign interfaces (bonded) for mgmt-, admin-, private-, public-
      and storage networks

    - Click Apply

    .. figure:: img/interfaceconf.png


OPTIONAL - Set Local Mirror Repos
---------------------------------

The following steps can be executed if you are in an environment with
no connection to the internet. The Fuel server delivers a local repo
that can be used for installation / deployment of openstack.

#. In the Fuel UI of your Environment, click the Settings Tab and
select General from the left pane.

   - Replace the URI values for the "Name" values outlined below:

   - "ubuntu" URI="deb http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "ubuntu-security" URI="deb
     http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "ubuntu-updates" URI="deb
     http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "mos-updates"  URI="deb
     http://<ip-of-fuel-server>:8080/mos-ubuntu mos8.0-updates main
     restricted"
   - "mos-security" URI="deb
     http://<ip-of-fuel-server>:8080/mos-ubuntu mos8.0-security main
     restricted"
   - "mos-holdback" URI="deb
     http://<ip-of-fuel-server>:8080/mos-ubuntu mos8.0-holdback main
     restricted"

   - Click "Save Settings" at the bottom to Save your changes

Verify Networks
---------------

It is important that the Verify Networks action is performed be done as it will
ensure that you can not only communicate on the networks you have setup, but can
fetch the packages needed for a succesful deployment.

#. From the FUEL UI in your Environment, Select the Networks Tab and select "Connectivity check" on the left pane (see figure below)

   - Select "Verify Networks"

   - Continue to fix your topology (physical switch, etc) until the
     "Verification Succeeded and "Your network is configured correctly"
     message is shown
     
   .. figure:: img/verifynet.png


Deploy Your Environment
-----------------------

38. Deploy the environment.

    - In the Fuel GUI, click on the Dashboard Tab.

    - Click on 'Deploy Changes' in the 'Ready to Deploy?' Section

    - Examine any information notice that pops up and click 'Deploy'

    Wait for your deployment to complete, you can view the 'Dashboard'
    Tag to see the progress and status of your deployment.

Installation health-check
=========================

#. Perform system health-check (see figure below)

    - Click the "Health Check" tab inside your Environment in the FUEL Web UI

    - Check "Select All" and Click "Run Tests"

    - Allow tests to run and investigate results where appropriate

    .. figure:: img/health.png

References
==========

OPNFV
-----

`OPNFV Home Page <www.opnfv.org>`_

OpenStack
---------

`OpenStack Liberty Release artifacts <http://www.openstack.org/software/liberty>`_

`OpenStack documentation <http://docs.openstack.org>`_

OpenDaylight
------------

`OpenDaylight artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel
----

`Fuel documentation <https://wiki.openstack.org/wiki/Fuel>`_
