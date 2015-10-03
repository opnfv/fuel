==================================================================================================
OPNFV Installation instructions for the Arno release of OPNFV when using Fuel as a deployment tool
==================================================================================================

.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document describes how to install the Arno release of OPNFV when using Fuel as a deployment tool covering it's limitations, dependencies and required system resources.

License
=======
Arno release of OPNFV when using Fuel as a deployment tool Docs (c) by Jonas Bjurel (Ericsson AB)

Arno release of OPNFV when using Fuel as a deployment tool Docs are licensed under a Creative Commons Attribution 4.0 International License. You should have received a copy of the license along with this. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Version history
===============

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 1.0.0              | Jonas Bjurel       | Installation       |
|                    |                    | (Ericsson AB)      | instructions for   |
|                    |                    |                    | the Arno release   |
+--------------------+--------------------+--------------------+--------------------+


Introduction
============

This document describes providing guidelines on how to install and configure the Arno release of OPNFV when using Fuel as a deployment tool including required software and hardware configurations.

Although the available installation options gives a high degree of freedom in how the system is set-up including architecture, services and features, etc. said permutations may not provide an OPNFV compliant reference architecture. This instruction provides a step-by-step guide that results in an OPNFV Arno compliant deployment.

The audience of this document is assumed to have good knowledge in networking and Unix/Linux administration.

Preface
=======

Before starting the installation of the Arno release of OPNFV when using Fuel as a deployment tool, some planning must be done.

Retrieving the ISO image
------------------------

First of all, the Fuel deployment ISO image needs to be retrieved, the .iso image of the Arno release of OPNFV when using Fuel as a deployment tool can be found at http://artifacts.opnfv.org/arno.2015.1.0/fuel/arno.2015.1.0.fuel.iso

Building the ISO image
----------------------

Alternatively, you may build the .iso from source by cloning the opnfv/genesis git repository.  To retrieve the repository for the Arno release use the following command:

<git clone https://<linux foundation uid>@gerrit.opnf.org/gerrit/genesis>

Check-out the Arno release tag to set the branch to the baseline required to replicate the Arno release:

<cd genesis; git checkout arno.2015.1.0>

Go to the fuel directory and build the .iso:

<cd fuel/build; make all>

For more information on how to build, please see "OPNFV Build instructions for - Arno release of OPNFV when using Fuel as a deployment tool which you retrieved with the repository at </genesis/fuel/docs/src/build-instructions.rst>

Next, familiarize yourself with the Fuel 6.0.1 version by reading the following documents:

- Fuel planning guide <http://docs.mirantis.com/openstack/fuel/fuel-6.0/planning-guide.html#planning-guide>

- Fuel user guide <http://docs.mirantis.com/openstack/fuel/fuel-6.0/user-guide.html#user-guide>

- Fuel operations guide <http://docs.mirantis.com/openstack/fuel/fuel-6.0/operations.html#operations-guide>

A number of deployment specific parameters must be collected, those are:

1.     Provider sub-net and gateway information

2.     Provider VLAN information

3.     Provider DNS addresses

4.     Provider NTP addresses

This information will be needed for the configuration procedures provided in this document.

Hardware requirements
=====================

The following minimum hardware requirements must be met for the installation of Arno using Fuel:

+--------------------+------------------------------------------------------+
| **HW Aspect**      | **Requirement**                                      |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **# of servers**   | Minimum 5 (3 for non redundant deployment):          |
|                    |                                                      |
|                    | - 1 Fuel deployment master (may be virtualized)      |
|                    |                                                      |
|                    | - 3(1) Controllers                                   |
|                    |                                                      |
|                    | - 1 Compute                                          |
+--------------------+------------------------------------------------------+
| **CPU**            | Minimum 1 socket x86_AMD64 Ivy bridge 1.6 GHz        |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **RAM**            | Minimum 16GB/server (Depending on VNF work load)     |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **Disk**           | Minimum 256GB 10kRPM spinning disks                  |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **NICs**           | - 2(1)x10GE Niantec for Private/Public (Redundant)   |
|                    |                                                      |
|                    | - 2(1)x10GE Niantec for SAN (Redundant)              |
|                    |                                                      |
|                    | - 2(1)x1GE for admin (PXE) and control (RabitMQ,etc) |
|                    |                                                      |
+--------------------+------------------------------------------------------+

Top of the rack (TOR) Configuration requirements
================================================

The switching infrastructure provides connectivity for the OPNFV infrastructure operations, tenant networks (East/West) and provider connectivity (North/South bound connectivity); it also provides needed connectivity for the storage Area Network (SAN). To avoid traffic congestion, it is strongly suggested that three physically separated networks are used, that is: 1 physical network for administration and control, one physical network for tenant private and public networks, and one physical network for SAN. The switching connectivity can (but does not need to) be fully redundant, in such case it and comprises a redundant 10GE switch pair for each of the three physically separated networks.

The physical TOR switches are **not** automatically configured from the OPNFV reference platform. All the networks involved in the OPNFV infrastructure as well as the provider networks and the private tenant VLANs needs to be manually configured.


Manual configuration of the Arno hardware platform should be carried out according to the Pharos specification http://artifacts.opnfv.org/arno.2015.1.0/docs/pharos-spec.arno.2015.1.0.pdf

OPNFV Software installation and deployment
==========================================

This section describes the installation of the OPNFV installation server (Fuel master) as well as the deployment of the full OPNFV reference platform stack across a server cluster.

Install Fuel master
-------------------
1. Mount the built arno.2015.1.0.fuel.iso file as a boot device to the jump host server.

2. Reboot the jump host to establish the Fuel server.

   - The system now boots from the ISO image.

3. Change the grub boot parameters

   - When the grub boot menu shows up - Press Tab to edit the kernel parameters

   - Change <showmenu=no> to <showmenu=yes>.

   - Change <netmask=255.255.255.0> to <netmask=255.255.0.0>.

   - Press [Enter].

4. Wait until screen Fuel setup is shown (Note: This can take up to 30 minutes).

5. Select PXE Setup and change the following fields to appropriate values (example below):

   - Static Pool Start 10.20.0.3

   - Static Pool End 10.20.0.254

   - DHCP Pool Start 10.20.128.3

   - DHCP Pool End 10.20.128.254

6. Select DNS & Hostname and change the following fields to appropriate values:

   - Hostname <OPNFV Region name>-fuel

   - Domain <Domain Name>

   - Search Domain <Search Domain Name>

   - Hostname to test DNS <Hostname to test DNS>

7. Select Time Sync and change the following fields to appropriate values:

   - NTP Server 1 <Customer NTP server 1>

   - NTP Server 2 <Customer NTP server 2>

   - NTP Server 3 <Customer NTP server 3>

   **Note: This step is only to pass the network sanity test, the actual ntp parameters will be set with the pre-deploy script.**

8. Start the installation.

   - Select Quit Setup and press Save and Quit.

   - Installation starts, wait until a screen with logon credentials is shown.

   Note: This will take about 15 minutes.

Create an OPNFV Environment
---------------------------

9. Connect to Fuel with a browser towards port 8000

10. Create and name a new OpenStack environment, to be installed.

11. Select <Juno on Ubuntu> or <Juno on CentOS> as per your which in the "OpenStack Release" field.

12. Select deployment mode.

    - Select the Multi-node with HA.

13. Select compute node mode.

    - Select KVM as hypervisor (unless you're not deploying bare metal or nested KVM/ESXI).

14. Select network mode.

    - Select Neutron with VLAN segmentation

    ** Note: This will later be overridden to VXLAN by OpenDaylight.**

15. Select Storage Back-ends.

    - Select Ceph for Cinder and default for glance.

16. Select additional services.

    - Check option <Install Celiometer (OpenStack Telemetry)>.

17. Create the new environment.

Configure the OPNFV environment
-------------------------------

18. Enable PXE booting

    - For every controller and compute server: enable PXE Booting as the first boot device in the BIOS boot order menu and hard disk as the second boot device in the same menu.

19. Reboot all the control and compute blades.

20. Wait for the availability of nodes showing up in the Fuel GUI.

    - Wait until all nodes are displayed in top right corner of the Fuel GUI: <total number of server> TOTAL NODES and <total number of servers> UNALLOCATED NODES.

21. Open the environment you previously created.

22. Open the networks tab.

23. Update the public network configuration.

    Change the following fields to appropriate values:

    - IP Range Start to <Public IP Address start>

    - IP Range End to <Public IP Address end>

    - CIDR to <CIDR for Public IP Addresses>

    - Gateway to <Gateway for Public IP Addresses>

    - Check VLAN tagging.

    - Set appropriate VLAN id.

24. Update the management network configuration.

    - Set CIDR to 172.16.255.128/25 (or as per your which).

    - Check VLAN tagging.

    - Set appropriate VLAN id.

25. Update the Neutron L2 configuration.

    - Set VLAN ID range.

26. Update the Neutron L3 configuration.

    - Set Internal network CIDR to an appropriate value

    - Set Internal network gateway to an appropriate value

    - Set Floating IP ranges.

    - Set DNS Servers

27. Save Settings.

28. Click "verify network" to check the network set-up consistency and connectivity

29. Update the storage configuration.

30. Open the nodes tab.

31. Assign roles.

    - Check <Controller and Telemetry MongoDB>.

    - Check the three servers you want to be installed as Controllers in pane <Assign Role>.

    - Click <Apply Changes>.

    - Check <Compute>.

    - Check nodes to be installed as compute nodes in pane Assign Role.

    - Click <Apply Changes>.

32. Configure interfaces.

    - Check Select <All> to select all nodes with Control, Telemetry, MongoDB and Compute node roles.

    - Click <Configure Interfaces>

    - Screen Configure interfaces on number of <number of nodes> nodes is shown.

    - Assign interfaces (bonded) for mgmt-, admin-, private-, public- and storage networks

Deploy the OPNFV environment
----------------------------
**NOTE: Before the deployment is performed, the OPNFV pre-deploy script must be run**

35. Run the pre-deploy script.
    Log on as root to the Fuel node.
    Print Fuel environment Id (fuel env)
    #> id | status | name | mode | release_id | changes <id>| new | <CEE Region name>| ha_compact | 2 | <ite specific information>

36. Run the pre-deployment script (/opt/opnfv/pre-deploy.sh <id>)
    As prompted for-, set the DNS servers to go into /etc/resolv.conf.
    As prompted for-, set any Hosts file additions for controllers and compute nodes. You will be prompted for name, FQDN and IP for each entry. Press return when prompted for a name when you have completed your input.
    As prompted for-, set NTP upstream configuration for controllers. You will be prompted for a NTP server each entry. Press return when prompted for a NTP server when you have completed your input.

37. Deploy the environment.
    In the Fuel GUI, click Deploy Changes.

Installation health-check
=========================

38. Perform system health-check
Now that the OPNFV environment has been created, and before the post installation configurations is started, perform a system health check from the Fuel GUI:

- Select the “Health check” TAB.
- Select all test cases
- And click “Run tests”

All test cases should pass.

Post installation and deployment actions
========================================

Activate OpenDaylight and VXLAN network segmentation
----------------------------------------------------
** Note: With the current release, the OpenDaylight option is experimental!**
** Note: With ODL enabled, L3 features will no longer be available **
The activation of ODL within a deployed Fuel system is a two part process.

The first part involves staging the ODL container, i.e. starting the ODL container itself.
The second part involves a reconfiguration of the underlying networking components to enable VXLAN tunneling.
The staging of the ODL container works without manual intervention except for editing with a valid DNS IP for your system

For the second part - the reconfiguration of the networking, the script <config_net_odl.sh> is provided as a baseline example to show what needs to be configured for your system system setup. Since there are many variants of valid networking topologies, this script will not be 100% correct in all deployment cases and some manual script modifications maybe required.

39. Enable the ODL controller
ssh to any of the OpenStack controllers and issue the following command as root user: </opt/opnfv/odl/stage_odl.sh>
This script will start ODL, load modules and make the Controller ready for use.
** Note: - The script should only be ran on a single controller (even if the system is setup in a High Availability OpenStack mode). **

40. Verify that the OpenDaylight GUI is accessible
Point your browser to the following URL: <http://{ODL-CONTROLLER-IP}:8181/dlux/index.html> and login:
Username: Admin
Password: Admin

41. Reconfiguring the networking and switch to VXLAN network segmentation
ssh to all of the nodes and issue the following command </opt/opnfv/odl/config_net_odl.sh> in the order specified below:
a. All compute nodes
b. All OpenStack controller nodes except the one running the ODL-controller
c. The OpenStack controller also running the ODL controller

This script will reconfigure the networking from VLAN Segregation to VXLAN mode.

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

:Authors: Jonas Bjurel (Ericsson AB)
:Version: 1.0.0

**Documentation tracking**

Revision: _sha1_

Build date: _date_
