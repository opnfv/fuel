==================================================================================================
OPNFV Installation instructions for the Arno release of OPNFV when using Fuel as a deployment tool
==================================================================================================

.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document describes how to install the Arno SR1 release of OPNFV when using Fuel as a deployment tool covering it's limitations, dependencies and required system resources.

License
=======
Arno SR1 release of OPNFV when using Fuel as a deployment tool Docs (c) by Jonas Bjurel (Ericsson AB)

Arno SR1 release of OPNFV when using Fuel as a deployment tool Docs are licensed under a Creative Commons Attribution 4.0 International License. You should have received a copy of the license along with this. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Version history
===============

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 1.0.0              | Jonas Bjurel       | Installation       |
|                    |                    | (Ericsson AB)      | instructions for   |
|                    |                    |                    | the Arno release   |
|		     |                    |                    |                    |
| 2015-09-27	     | 1.1.0              | Daniel Smith       | ARNO SR1-RC1       |
|                    |                    |  (Ericsson AB)     | update             |
|		     |                    |                    |                    |
|		     |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+


Introduction
============

This document describes providing guidelines on how to install and configure the Arno SR1 release of OPNFV when using Fuel as a deployment tool including required software and hardware configurations.

Although the available installation options gives a high degree of freedom in how the system is set-up including architecture, services and features, etc. said permutations may not provide an OPNFV compliant reference architecture. This instruction provides a step-by-step guide that results in an OPNFV Arno SR1 compliant deployment.

The audience of this document is assumed to have good knowledge in networking and Unix/Linux administration.

Preface
=======

Before starting the installation of the Arno SR1 release of OPNFV when using Fuel as a deployment tool, some planning must be done.

Retrieving the ISO image
------------------------

First of all, the Fuel deployment ISO image needs to be retrieved, the .iso image of the Arno SR1 release of OPNFV when using Fuel as a deployment tool can be found at http://artifacts.opnfv.org/arno.2015.2.0/fuel/arno.2015.2.0.fuel.iso


Building the ISO image
----------------------


Alternatively, you may build the .iso from source by cloning the opnfv/genesis git repository.  To retrieve the repository for the Arno release use the following command:

- git clone https://<linux foundation uid>@gerrit.opnf.org/gerrit/genesis

Check-out the Arno SR1 release tag to set the branch to the baseline required to replicate the Arno SR1 release:

- cd genesis; git checkout stable/arno2015.2.0

Go to the fuel directory and build the .iso:

- cd fuel/build; make all

For more information on how to build, please see "OPNFV Build instructions for - Arno SR1 release of OPNFV when using Fuel as a deployment tool which you retrieved with the repository at </genesis/fuel/docs/src/build-instructions.rst>

Next, familiarize yourself with the Fuel 6.1 version by reading the following documents:

- Fuel planning guide <https://docs.mirantis.com/openstack/fuel/fuel-6.1/planning-guide.html>

- Fuel user guide <http://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#user-guide>

- Fuel operations guide <http://docs.mirantis.com/openstack/fuel/fuel-6.1/operations.html#operations-guide>

- Fuel Plugin Developers Guide <https://wiki.openstack.org/wiki/Fuel/Plugins>

A number of deployment specific parameters must be collected, those are:

1.     Provider sub-net and gateway information

2.     Provider VLAN information

3.     Provider DNS addresses

4.     Provider NTP addresses

5.     Network Topology you plan to Deploy (VLAN, GRE(VXLAN), FLAT)

6.     Linux Distro you intend to deploy.

7.     How many nodes and what roles you want to deploy (Controllers, Storage, Computes)

8.     Monitoring Options you want to deploy (Ceilometer, MongoDB).

9.     Other options not covered in the document are available in the links above


This information will be needed for the configuration procedures provided in this document.

Hardware requirements
=====================

The following minimum hardware requirements must be met for the installation of Arno SR1 using Fuel:

+--------------------+------------------------------------------------------+
| **HW Aspect**      | **Requirement**                                      |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **# of nodes**     | Minimum 6 (3 for non redundant deployment):          |
|                    |                                                      |
|                    | - 1 Fuel deployment master (may be virtualized)      |
|                    |                                                      |
|                    | - 3(1) Controllers                                   |
|                    |                                                      |
|                    | - 1 Compute                                          |
|                    |                                                      |
|                    | - 1 Ceilometer (VM option)                           |
+--------------------+------------------------------------------------------+
| **CPU**            | Minimum 1 socket x86_AMD64 with Virtualization       |
|                    |   support                                            |
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
|                    |  over other nics as your hardware supports           |
+--------------------+------------------------------------------------------+

Help with Hardware Requirements
===============================


Calculate hardware requirements:

You can use the Fuel Hardware Calculator <https://www.mirantis.com/openstack-services/bom-calculator/> to calculate the hardware required for your OpenStack environment.

When choosing the hardware on which you will deploy your OpenStack environment, you should think about:

        - CPU -- Consider the number of virtual machines that you plan to deploy in your cloud environment and the CPU per virtual machine.
        - Memory -- Depends on the amount of RAM assigned per virtual machine and the controller node.
        - Storage -- Depends on the local drive space per virtual machine, remote volumes that can be attached to a virtual machine, and object storage.
        - Networking -- Depends on the Choose Network Topology, the network bandwidth per virtual machine, and network storage.


Top of the rack (TOR) Configuration requirements
================================================

The switching infrastructure provides connectivity for the OPNFV infrastructure operations, tenant networks (East/West) and provider connectivity (North/South bound connectivity); it also provides needed connectivity for the storage Area Network (SAN). To avoid traffic congestion, it is strongly suggested that three physically separated networks are used, that is: 1 physical network for administration and control, one physical network for tenant private and public networks, and one physical network for SAN. The switching connectivity can (but does not need to) be fully redundant, in such case it and comprises a redundant 10GE switch pair for each of the three physically separated networks.

The physical TOR switches are **not** automatically configured from the OPNFV reference platform. All the networks involved in the OPNFV infrastructure as well as the provider networks and the private tenant VLANs needs to be manually configured.

Manual configuration of the Arno SR1 hardware platform should be carried out according to the Pharos specification TODO-<insert link to Pharos ARNO SR1 Specification>

OPNFV Software installation and deployment
==========================================

This section describes the installation of the OPNFV installation server (Fuel master) as well as the deployment of the full OPNFV reference platform stack across a server cluster.

Install Fuel master
-------------------
1. Mount the Arno SR1 ISO  file as a boot device to the jump host server.

2. Reboot the jump host to establish the Fuel server.

   - The system now boots from the ISO image.

   - Select 'DVD Fuel Install (Static IP)'

   - Press [Enter].

3. Wait until screen Fuel setup is shown (Note: This can take up to 30 minutes).

4. Configure DHCP/Static IP information for your FUEL node - For example, ETH0 is 10.20.0.2/24 for FUEL booting and ETH1 is DHCP in your corporate/lab network.

   - Configure eth1 or other network interfaces here as well (if you have them present on your FUEL server).

5. Select PXE Setup and change the following fields to appropriate values (example below):

   - DHCP Pool Start 10.20.0.3

   - DHCP Pool End 10.20.0.254

   - DHCP Pool Gateway  10.20.0.2 (ip of Fuel node)

   - Hostname <OPNFV Region name>-fuel

   - Domain <Domain Name>

   - Search Domain <Search Domain Name>

   - Hostname to test DNS <Hostname to test DNS>

6. Select Time Sync and change the following fields to appropriate values:

   - NTP Server 1 <Customer NTP server 1>

   - NTP Server 2 <Customer NTP server 2>

   - NTP Server 3 <Customer NTP server 3>

7. Start the installation.

   - Select Quit Setup and press Save and Quit.

   - Installation starts, wait until a screen with logon credentials is shown.


Boot the Node Servers
---------------------

After the Fuel Master node has rebooted from the above step and is at the login prompt, you should boot the Node Servers (Your Compute/Control/Storage blades (nested or real)) with a PXE Booting Scheme so that the FUEL 
Master can pick them up for control.

8. Enable PXE booting

    - For every controller and compute server: enable PXE Booting as the first boot device in the BIOS boot order menu and hard disk as the second boot device in the same menu.

9. Reboot all the control and compute blades.

10. Wait for the availability of nodes showing up in the Fuel GUI.

    - Wait until all nodes are displayed in top right corner of the Fuel GUI: <total number of server> TOTAL NODES and <total number of servers> UNALLOCATED NODES.



Install ODL Plugin on FUEL node
-------------------------------

11. SSH to your FUEL node   (e.g. root@10.20.0.2  pwd: r00tme)

12. Verify the plugin exists at /opt/opnfv/opendaylight-0.6-0.6.1-1.noarch.rpm

13. Install the plugin with the command

    - "fuel plugins --install /opt/opnfv/opendaylight-0.6-0.6.1-1.noarch.rpm"

    - Expected output: "Plugin  opendaylight-0.6-0.6.1-1.noarch.rpm was successfully installed."


Create an OPNFV Environment
---------------------------

14. Connect to Fuel WEB UI with a browser towards port http://<ip of fuel server>:8000 (login admin/admin)

15. Create and name a new OpenStack environment, to be installed.

16. Select <Juno on Ubuntu> or <Juno on CentOS> as per your which in the "OpenStack Release" field and press "Next"

17. Select compute virtulization method.

    - Select KVM as hypervisor (or one of your choosing) and press "Next"

18. Select network mode.

    - Select Neutron with GRE segmentation and press "Next"

    Note: this is the supportted method when using the ODL installation, other options will not work with the plugin and this Instruction Set.

19. Select Storage Back-ends.

    - Select "Yes, use Ceph" if you intend to deploy Ceph Backends and press "Next"


20. Select additional services you wish to install.

    - Check option <Install Celiometer (OpenStack Telemetry)> and press "Next"
	Note: If you use Ceilometer and you only have 5 nodes, you may have to run in a 3/1/1 (controller/ceilo-mongo/compute) configuration. Suggest adding more compute nodes

21. Create the new environment.

    - Click "Create" Button

Configure the OPNFV environment
-------------------------------

22. Enable PXE booting (if you haven't done this already)

    - For every controller and compute server: enable PXE Booting as the first boot device in the BIOS boot order menu and hard disk as the second boot device in the same menu.

23. Wait for the availability of nodes showing up in the Fuel GUI.

    - Wait until all nodes are displayed in top right corner of the Fuel GUI: <total number of server> TOTAL NODES and <total number of servers> UNALLOCATED NODES.

24. Open the environment you previously created.

25. Open the networks tab.

26. Update the Public network configuration.

    Change the following fields to appropriate values:

    - IP Range Start to <Public IP Address start>

    - IP Range End to <Public IP Address end>

    - CIDR to <CIDR for Public IP Addresses>

    - Check VLAN tagging.

    - Set appropriate VLAN id.

    - Gateway to <Gateway for Public IP Addresses>

    - Set floating ip ranges


27. Update the Storage Network Configuration

    - Set CIDR to appropriate value  (default 192.168.1.0/24)

    - Set vlan to appropriate value  (default 102)

28. Update the Management network configuration.

    - Set CIDR to appropriate value (default 192.168.0.0/24)

    - Check VLAN tagging.

    - Set appropriate VLAN id. (default 101)

29. Update the Private Network Information

    - Set CIDR to appropriate value (default 192.168.2.0/24

    - Check and set VLAN tag appropriately (default 103)

30. Update the Neutron L3 configuration.

    - Set Internal network CIDR to an appropriate value

    - Set Internal network gateway to an appropriate value

    - Set Guest OS DNS Server values appropriately

31. Save Settings.

32. Click on the "Nodes" Tab in the FUEL WEB UI.

33. Assign roles.

    - Click on "+Add Nodes" button

    - Check "Controller" and the "Storage-Ceph OSD"  in the Assign Roles Section

    - Check the 3 Nodes you want to act as Controllers from the bottom half of the screen

    - Click <Apply Changes>.

    - Click on "+Add Nodes" button

    - Check "Compute" in the Assign Roles Section

    - Check the Nodes that you want to act as Computes from the bottom half of the screen

    - Click <Apply Changes>.


34. Configure interfaces.

    - Check Select <All> to select all nodes with Control, Telemetry, MongoDB and Compute node roles.

    - Click <Configure Interfaces>

    - Screen Configure interfaces on number of <number of nodes> nodes is shown.

    - Assign interfaces (bonded) for mgmt-, admin-, private-, public- and storage networks

    - Note: Set MTU level to at least MTU=2090 (recommended MTU=2140 for SDN over VXLAN Usage) for each network

    - Click Apply

Enable ODL
----------

35. In the FUEL UI of your Enviornment, click the "Settings" Tab

    - Enable OpenStack debug logging (in the Common Section) - optional

    - Check the OpenDaylight Lithium Plugin Section

    - Check to enable VXLAN

    - Modify VNI and Port Range if desired

    - Click "Save Settings" at the bottom to Save.


OPTIONAL - Set Local Mirror Repos
---------------------------------

The following steps can be executed if you are in an environment with no connection to the internet.  The Fuel server delivers a local repo that can be used for 
installation / deployment of openstack.

36.  In the Fuel UI of your Environment, click the Settings Tab and scroll to the Repositories Section.

   - Replace the URI values for the "Name" values outlined below:

   - "ubuntu" URI="deb http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "ubuntu-security" URI="deb http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "ubuntu-updates" URI="deb http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
   - "mos-updates"  URI="deb http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-updates main restricted"
   - "mos-security" URI="deb http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-security main restricted"
   - "mos-holdback" URI="deb http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-holdback main restricted"

   - Click "Save Settings" at the bottom to Save your changes

Verify Networks
---------------

Its is important that Verify Networks be done as it will ensure that you can not only communicate on the networks you have setup, but can fetch the packages needed for a succesful
deployment.

37.  From the FUEL UI in your Environment, Select the Networks Tab

   - At the bottom of the page, Select "Verify Networks"

   - Continue to fix your topology (physical switch, etc) until the "Verification Succeeded - Your network is configured correctly" message is shown

Deploy Your Environment
-----------------------

38. Deploy the environment.
    In the Fuel GUI, click Deploy Changes.

    - Wait until your Environment is deployed and the Horizon URI to connect is displayed in the FUEL GUI for your Environment

Installation health-check
=========================

39. Perform system health-check

    - Click the "Health Check" tab inside your Environment in the FUEL Web UI

    - Check "Select All" and Click "Run Tests"

	Note: Live-Migraition test will fail (Bug in ODL currently), you can skip this test in the list if you choose to not see the error message, simply uncheck it in the list

    - Allow tests to run and investigate results where appropriate

40. Verify that the OpenDaylight GUI is accessible

Point your browser to the following URL: http://{Controller-VIP}:8181/index.html> and login:

    - Username: admin
    - Password: admin

References
==========

OPNFV
-----

`OPNFV Home Page <www.opnfv.org>`_

`OPNFV Genesis project page <https://wiki.opnfv.org/get_started>`_

OpenStack
---------

`OpenStack Juno Release artifacts <http://www.openstack.org/software/juno>`_

`OpenStack documentation <http://docs.openstack.org>`_

OpenDaylight
------------

`OpenDaylight artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel
----

`Fuel documentation <https://wiki.openstack.org/wiki/Fuel>`_

:Authors: Daniel Smith (Ericsson AB)
:Version: 1.1.0

**Documentation tracking**

Revision: _sha1_

Build date: _date
