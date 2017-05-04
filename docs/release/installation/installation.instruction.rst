.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

========
Abstract
========

This document describes how to install the Danube release of
OPNFV when using Fuel as a deployment tool, covering its usage,
limitations, dependencies and required system resources.

============
Introduction
============

This document provides guidelines on how to install and
configure the Danube release of OPNFV when using Fuel as a
deployment tool, including required software and hardware configurations.

Although the available installation options give a high degree of
freedom in how the system is set-up, including architecture, services
and features, etc., said permutations may not provide an OPNFV
compliant reference architecture. This instruction provides a
step-by-step guide that results in an OPNFV Danube compliant
deployment.

The audience of this document is assumed to have good knowledge in
networking and Unix/Linux administration.

=======
Preface
=======

Before starting the installation of the Danube release of
OPNFV, using Fuel as a deployment tool, some planning must be
done.

Retrieving the ISO image
========================

First of all, the Fuel deployment ISO image needs to be retrieved, the
Fuel .iso image of the Danube release can be found at `OPNFV Downloads <https://www.opnfv.org/software/download>`_.

Building the ISO image
======================

Alternatively, you may build the Fuel .iso from source by cloning the
opnfv/fuel git repository. To retrieve the repository for the Danube
release use the following command:

.. code-block:: bash

    $ git clone https://gerrit.opnfv.org/gerrit/fuel

Check-out the Danube release tag to set the HEAD to the
baseline required to replicate the Danube release:

.. code-block:: bash

    $ git checkout danube.2.0

Go to the fuel directory and build the .iso:

.. code-block:: bash

    $ cd fuel/build; make all

For more information on how to build, please see :ref:`Build instruction for Fuel\@OPNFV <fuel-development-overview-build-label>`

Other preparations
==================

Next, familiarize yourself with Fuel by reading the following documents:

- `Fuel Installation Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-install-guide.html>`_

- `Fuel User Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide.html>`_

- `Fuel Developer Guide <http://docs.openstack.org/developer/fuel-docs/devdocs/develop.html>`_

- `Fuel Plugin Developers Guide <http://docs.openstack.org/developer/fuel-docs/plugindocs/fuel-plugin-sdk-guide.html>`_

Prior to installation, a number of deployment specific parameters must be collected, those are:

#.     Provider sub-net and gateway information

#.     Provider VLAN information

#.     Provider DNS addresses

#.     Provider NTP addresses

#.     Network overlay you plan to deploy (VLAN, VXLAN, FLAT)

#.     How many nodes and what roles you want to deploy (Controllers, Storage, Computes)

#.     Monitoring options you want to deploy (Ceilometer, Syslog, etc.).

#.     Other options not covered in the document are available in the links above


This information will be needed for the configuration procedures
provided in this document.

=====================
Hardware requirements
=====================

The following minimum hardware requirements must be met for the
installation of Danube using Fuel:

+--------------------+------------------------------------------------------+
| **HW Aspect**      | **Requirement**                                      |
|                    |                                                      |
+====================+======================================================+
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
|                    | Note: These can be allocated to a single NIC -       |
|                    | or spread out over multiple NICs as your hardware    |
|                    | supports.                                            |
+--------------------+------------------------------------------------------+

===============================
Help with Hardware Requirements
===============================

Calculate hardware requirements:

For information on compatible hardware types available for use, please see `Fuel OpenStack Hardware Compatibility List <https://www.mirantis.com/software/hardware-compatibility/>`_.

When choosing the hardware on which you will deploy your OpenStack
environment, you should think about:

- CPU -- Consider the number of virtual machines that you plan to deploy in your cloud environment and the CPU per virtual machine.

- Memory -- Depends on the amount of RAM assigned per virtual machine and the controller node.

- Storage -- Depends on the local drive space per virtual machine, remote volumes that can be attached to a virtual machine, and object storage.

- Networking -- Depends on the Choose Network Topology, the network bandwidth per virtual machine, and network storage.

================================================
Top of the rack (TOR) Configuration requirements
================================================

The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South); it also provides needed connectivity for
the Storage Area Network (SAN).
To avoid traffic congestion, it is strongly suggested that three
physically separated networks are used, that is: 1 physical network
for administration and control, one physical network for tenant private
and public networks, and one physical network for SAN.
The switching connectivity can (but does not need to) be fully redundant,
in such case it comprises a redundant 10GE switch pair for each of the
three physically separated networks.

The physical TOR switches are **not** automatically configured from
the Fuel OPNFV reference platform. All the networks involved in the OPNFV
infrastructure as well as the provider networks and the private tenant
VLANs needs to be manually configured.

Manual configuration of the Danube hardware platform should
be carried out according to the `OPNFV Pharos Specification
<https://wiki.opnfv.org/display/pharos/Pharos+Specification>`_.

==========================================
OPNFV Software installation and deployment
==========================================

This section describes the installation of the OPNFV installation
server (Fuel master) as well as the deployment of the full OPNFV
reference platform stack across a server cluster.

Install Fuel master
===================

#. Mount the Danube Fuel ISO file/media as a boot device to the jump host server.

#. Reboot the jump host to establish the Fuel server.

   - The system now boots from the ISO image.

   - Select "Fuel Install (Static IP)" (See figure below)

   - Press [Enter].

   .. figure:: img/grub-1.png

#. Wait until the Fuel setup screen is shown (Note: This can take up to 30 minutes).

#. In the "Fuel User" section - Confirm/change the default password (See figure below)

   - Enter "admin" in the Fuel password input

   - Enter "admin" in the Confirm password input

   - Select "Check" and press [Enter]

   .. figure:: img/fuelmenu1.png

#. In the "Network Setup" section - Configure DHCP/Static IP information for your FUEL node - For example, ETH0 is 10.20.0.2/24 for FUEL booting and ETH1 is DHCP in your corporate/lab network (see figure below).

   - Configure eth1 or other network interfaces here as well (if you have them present on your FUEL server).

   .. figure:: img/fuelmenu2.png

#. In the "PXE Setup" section (see figure below) - Change the following fields to appropriate values (example below):

   - DHCP Pool Start 10.20.0.4

   - DHCP Pool End 10.20.0.254

   - DHCP Pool Gateway  10.20.0.2 (IP address of Fuel node)

   .. figure:: img/fuelmenu3.png

#. In the "DNS & Hostname" section (see figure below) - Change the following fields to appropriate values:

   - Hostname

   - Domain

   - Search Domain

   - External DNS

   - Hostname to test DNS

   - Select <Check> and press [Enter]

   .. figure:: img/fuelmenu4.png


#. OPTION TO ENABLE PROXY SUPPORT - In the "Bootstrap Image" section (see figure below), edit the following fields to define a proxy. (**NOTE:** cannot be used in tandem with local repository support)

   - Navigate to "HTTP proxy" and enter your http proxy address

   - Select <Check> and press [Enter]

   .. figure:: img/fuelmenu5.png

#. In the "Time Sync" section (see figure below) - Change the following fields to appropriate values:

   - NTP Server 1 <Customer NTP server 1>

   - NTP Server 2 <Customer NTP server 2>

   - NTP Server 3 <Customer NTP server 3>

   .. figure:: img/fuelmenu6.png

#. Start the installation.

   - Select Quit Setup and press Save and Quit.

   - The installation will now start, wait until the login screen is shown.

Boot the Node Servers
=====================

After the Fuel Master node has rebooted from the above steps and is at
the login prompt, you should boot the Node Servers (Your
Compute/Control/Storage blades, nested or real) with a PXE booting
scheme so that the FUEL Master can pick them up for control.

#. Enable PXE booting

   - For every controller and compute server: enable PXE Booting as the first boot device in the BIOS boot order menu, and hard disk as the second boot device in the same menu.

#. Reboot all the control and compute blades.

#. Wait for the availability of nodes showing up in the Fuel GUI.

   - Connect to the FUEL UI via the URL provided in the Console (default: https://10.20.0.2:8443)

   - Wait until all nodes are displayed in top right corner of the Fuel GUI: Total nodes and Unallocated nodes (see figure below).

   .. figure:: img/nodes.png

Install additional Plugins/Features on the FUEL node
====================================================

#. SSH to your FUEL node (e.g. root@10.20.0.2  pwd: r00tme)

#. Select wanted plugins/features from the /opt/opnfv/ directory.

#. Install the wanted plugin with the command

    .. code-block:: bash

        $ fuel plugins --install /opt/opnfv/<plugin-name>-<version>.<arch>.rpm

    Expected output (see figure below):

    .. code-block:: bash

        Plugin ....... was successfully installed.

   .. figure:: img/plugin_install.png

Create an OpenStack Environment
===============================

#. Connect to Fuel WEB UI with a browser (default: https://10.20.0.2:8443) (login: admin/admin)

#. Create and name a new OpenStack environment, to be installed.

   .. figure:: img/newenv.png

#. Select "<Mitaka on Ubuntu 14.04>" and press <Next>

#. Select "compute virtulization method".

   - Select "QEMU-KVM as hypervisor" and press <Next>

#. Select "network mode".

   - Select "Neutron with ML2 plugin"

   - Select "Neutron with tunneling segmentation" (Required when using the ODL or ONOS plugins)

   - Press <Next>

#. Select "Storage Back-ends".

   - Select "Ceph for block storage" and press <Next>

#. Select "additional services" you wish to install.

   - Check option "Install Ceilometer and Aodh" and press <Next>

#. Create the new environment.

   - Click <Create> Button

Configure the network environment
=================================

#. Open the environment you previously created.

#. Open the networks tab and select the "default" Node Networks group to on the left pane (see figure below).

   .. figure:: img/network.png

#. Update the Public network configuration and change the following fields to appropriate values:

   - CIDR to <CIDR for Public IP Addresses>

   - IP Range Start to <Public IP Address start>

   - IP Range End to <Public IP Address end>

   - Gateway to <Gateway for Public IP Addresses>

   - Check <VLAN tagging>.

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

   - Check <VLAN tagging>.

   - Set appropriate VLAN id. (default 101)

#. Update the Private Network Information

   - Set CIDR to appropriate value (default 192.168.2.0/24

   - Set IP Range Start to appropriate value (default 192.168.2.1)

   - Set IP Range End to appropriate value (default 192.168.2.254)

   - Check <VLAN tagging>.

   - Set appropriate VLAN tag (default 103)

#. Select the "Neutron L3" Node Networks group on the left pane.

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

#. Select the "Other" Node Networks group on the left pane (see figure below).

   .. figure:: img/other.png

#. Update the Public network assignment.

   - Check the box for "Assign public network to all nodes" (Required by OpenDaylight)

#. Update Host OS DNS Servers.

   - Provide the DNS server settings

#. Update Host OS NTP Servers.

   - Provide the NTP server settings

Select Hypervisor type
======================

#. In the FUEL UI of your Environment, click the "Settings" Tab

#. Select "Compute" on the left side pane (see figure below)

   - Check the KVM box and press "Save settings"

   .. figure:: img/compute.png

Enable Plugins
==============

#. In the FUEL UI of your Environment, click the "Settings" Tab

#. Select Other on the left side pane (see figure below)

   - Enable and configure the plugins of your choice

   .. figure:: img/plugins.png

Allocate nodes to environment and assign functional roles
=========================================================

#. Click on the "Nodes" Tab in the FUEL WEB UI (see figure below).

    .. figure:: img/addnodes.png

#. Assign roles (see figure below).

    - Click on the <+Add Nodes> button

    - Check <Controller>, <Telemetry - MongoDB>  and optionally an SDN Controller role (OpenDaylight controller/ONOS) in the "Assign Roles" Section.

    - Check one node which you want to act as a Controller from the bottom half of the screen

    - Click <Apply Changes>.

    - Click on the <+Add Nodes> button

    - Check the <Controller> and <Storage - Ceph OSD> roles.

    - Check the two next nodes you want to act as Controllers from the bottom half of the screen

    - Click <Apply Changes>

    - Click on <+Add Nodes> button

    - Check the <Compute> and <Storage - Ceph OSD> roles.

    - Check the Nodes you want to act as Computes from the bottom half of the screen

    - Click <Apply Changes>.

    .. figure:: img/computelist.png

#. Configure interfaces (see figure below).

    - Check Select <All> to select all allocated nodes

    - Click <Configure Interfaces>

    - Assign interfaces (bonded) for mgmt-, admin-, private-, public- and storage networks

    - Click <Apply>

    .. figure:: img/interfaceconf.png


Target specific configuration
=============================

#. Set up targets for provisioning with non-default "Offloading Modes"

   Some target nodes may require additional configuration after they are
   PXE booted (bootstrapped); the most frequent changes are in defaults
   for ethernet devices' "Offloading Modes" settings (e.g. some targets'
   ethernet drivers may strip VLAN traffic by default).

   If your target ethernet drivers have wrong "Offloading Modes" defaults,
   in "Configure interfaces" page (described above), expand affected
   interface's "Offloading Modes" and [un]check the relevant settings
   (see figure below):

   .. figure:: img/offloadingmodes.png

#. Set up targets for "Verify Networks" with non-default "Offloading Modes"

   **NOTE**: Check *Reference 15* for an updated and comprehensive list of
   known issues and/or limitations, including "Offloading Modes" not being
   applied during "Verify Networks" step.

   Setting custom "Offloading Modes" in Fuel GUI will only apply those settings
   during provisiong and **not** during "Verify Networks", so if your targets
   need this change, you have to apply "Offloading Modes" settings by hand
   to bootstrapped nodes.

   **E.g.**: Our driver has "rx-vlan-filter" default "on" (expected "off") on
   the Openstack interface(s) "eth1", preventing VLAN traffic from passing
   during "Verify Networks".

   - From Fuel master console identify target nodes admin IPs (see figure below):

     .. code-block:: bash

         $ fuel nodes

     .. figure:: img/fuelconsole1.png

   - SSH into each of the target nodes and disable "rx-vlan-filter" on the
     affected physical interface(s) allocated for OpenStack traffic (eth1):

     .. code-block:: bash

         $ ssh root@10.20.0.6 ethtool -K eth1 rx-vlan-filter off

   - Repeat the step above for all affected nodes/interfaces in the POD.

Verify Networks
===============

It is important that the Verify Networks action is performed as it will verify
that communicate works for the networks you have setup, as well as check that
packages needed for a successful deployment can be fetched.

#. From the FUEL UI in your Environment, Select the Networks Tab and select "Connectivity check" on the left pane (see figure below)

   - Select <Verify Networks>

   - Continue to fix your topology (physical switch, etc) until the "Verification Succeeded" and "Your network is configured correctly" message is shown

   .. figure:: img/verifynet.png

Deploy Your Environment
=======================

#. Deploy the environment.

    - In the Fuel GUI, click on the "Dashboard" Tab.

    - Click on <Deploy Changes> in the "Ready to Deploy?" section

    - Examine any information notice that pops up and click <Deploy>

    Wait for your deployment to complete, you can view the "Dashboard"
    Tab to see the progress and status of your deployment.

=========================
Installation health-check
=========================

#. Perform system health-check (see figure below)

    - Click the "Health Check" tab inside your Environment in the FUEL Web UI

    - Check <Select All> and Click <Run Tests>

    - Allow tests to run and investigate results where appropriate

    .. figure:: img/health.png


=============
Release Notes
=============

Please refer to the :ref:`Release Notes <fuel-release-notes-label>` article.

==========
References
==========

OpenStack

3) `OpenStack Newton Release Artifacts <http://www.openstack.org/software/newton>`_
4) `OpenStack Documentation <http://docs.openstack.org>`_

OpenDaylight

5) `OpenDaylight Artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel

6) `The Fuel OpenStack Project <https://wiki.openstack.org/wiki/Fuel>`_
7) `Fuel Documentation Overview <http://docs.openstack.org/developer/fuel-docs>`_
8) `Fuel Installation Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-install-guide.html>`_
9) `Fuel User Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide.html>`_
10) `Fuel Developer Guide <http://docs.openstack.org/developer/fuel-docs/devdocs/develop.html>`_
11) `Fuel Plugin Developers Guide <http://docs.openstack.org/developer/fuel-docs/plugindocs/fuel-plugin-sdk-guide.html>`_
12) `Fuel OpenStack Hardware Compatibility List <https://www.mirantis.com/software/hardware-compatibility/>`_

