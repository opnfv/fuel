.. This document is protected/licensed under the following conditions
.. (c) Jonas Bjurel (Ericsson AB)
.. Licensed under a Creative Commons Attribution 4.0 International License.
.. You should have received a copy of the license along with this work.
.. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Fuel configuration
==================
This section provides guidelines on how to install and
configure the Brahmaputra release of OPNFV when using Fuel as a
deployment tool including required software and hardware
configurations.

For detailed instructions on how to install the Brahmaputra release using
Fuel, see *Reference 13* in section *"Fuel associated references"* below.

Pre-configuration activities
----------------------------

Planning the deployment

Before starting the installation of the Brahmaputra release of
OPNFV when using Fuel as a deployment tool, some planning must be
done.

Familiarize yourself with the Fuel by reading the
following documents:

- Fuel planning guide, please see *Reference: 8* in section *"Fuel associated references"* below.

- Fuel quick start guide, please see *Reference: 9* in section *"Fuel associated references"* below.

- Fuel operations guide, please see *Reference: 10* in section *"Fuel associated references"* below.

- Fuel Plugin Developers Guide, please see *Reference: 11* in section *"Fuel associated references"* below.

Before the installation can start, a number of deployment specific parameters must be collected, those are:

#. Provider sub-net and gateway information

#. Provider VLAN information

#. Provider DNS addresses

#. Provider NTP addresses

#. Network overlay you plan to deploy (VLAN, VXLAN, FLAT)

#. Monitoring Options you want to deploy (Ceilometer, Syslog, etc.)

#. How many nodes and what roles you want to deploy (Controllers, Storage, Computes)

#. Other options not covered in the document are available in the links above


Retrieving the ISO image
^^^^^^^^^^^^^^^^^^^^^^^^
First of all, the Fuel deployment ISO image needs to be retrieved, the
Fuel .iso image of the Brahmaputra release can be found at *Reference: 2*

Alternatively, you may build the .iso from source by cloning the
opnfv/fuel git repository. Detailed instructions on how to build
a Fuel OPNFV .iso can be found in *Reference: 14* at section *"Fuel associated references"* below.

Hardware requirements
---------------------
Following high level hardware requirements must be met:

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
|                    | note: These can be run on single NIC - or spread out |
|                    | over other nics as your hardware supports            |
+--------------------+------------------------------------------------------+

For information on compatible hardware types available for use, please see
*Reference: 11* in section *"Fuel associated references"* below.

Top of the rack (TOR) Configuration requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South); it also provides needed
connectivity for the Storage Area Network (SAN). To avoid traffic
congestion, it is strongly suggested that three physically separated
networks are used, that is: 1 physical network for administration and
control, one physical network for tenant private and public networks,
and one physical network for SAN. The switching connectivity can (but
does not need to) be fully redundant, in such case it and comprises a
redundant 10GE switch pair for each of the three physically separated
networks.

The physical TOR switches are **not** automatically configured from
the OPNFV reference platform. All the networks involved in the OPNFV
infrastructure as well as the provider networks and the private tenant
VLANs needs to be manually configured.

Jumphost configuration
----------------------
The Jumphost server, also known as the "Fuel master" provides needed
services/functions to deploy an OPNFV/OpenStack cluster as well functions
for cluster life-cycle management (extensions, repair actions and upgrades).

The Jumphost server requires 2 (4 if redundancy is required) Ethernet
interfaces - one for external management of the OPNFV installation,
and another for jump-host communication with the OPNFV cluster.

Install the Fuel jump-host
^^^^^^^^^^^^^^^^^^^^^^^^^^
Mount the Fuel Brahmaputra ISO file as a boot device to the jump host
server, reboot it, and install the Fuel Jumphost in accordance with installation instructions, see *Reference 13* in section *"Fuel associated references"*
below.


Platform components configuration
---------------------------------

Fuel-Plugins
^^^^^^^^^^^^
Fuel plugins enable you to install and configure additional capabilities for
your Fuel OPNFV based cloud, such as additional storage types, networking
functionality, or NFV features developed by OPNFV.

Fuel offers an open source framework for creating these plugins, so there’s
a wide range of capabilities that you can enable Fuel to add to your OpenStack
clouds.

The OPNFV Brahmaputra version of Fuel provides a set of pre-packaged plugins
developed by OPNFV:

+--------------------+------------------------------------------------------+
|  **Plugin name**   | **Short description**                                |
|                    |                                                      |
+====================+======================================================+
| OpenDaylight       | OpenDaylight provides an open-source SDN Controller  |
|                    | providing networking features such as L2 and L3      |
|                    | network control, "Service Function Chaining",        |
|                    | routing, networking policies, etc.                   |
|                    | More information on OpenDaylight in the OPNFV        |
|                    | Brahmaputra release can be found in a separate       |
|                    | section in this document.                            |
+--------------------+------------------------------------------------------+
| ONOS               | ONOS is another open-source SDN controller which     |
|                    | in essense fill the same role as OpenDaylight.       |
|                    | More information on ONOS in the OPNFV                |
|                    | Brahmaputra release can be found in a separate       |
|                    | section in this document.                            |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| BGP-VPN            | BGP-VPN provides an BGP/MPLS VPN service             |
|                    | More information on BGP-VPN in the OPNFV             |
|                    | Brahmaputra release can be found in a separate       |
|                    | section in this document.                            |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| OVS-NSH            | OVS-NSH provides a variant of Open-vSwitch           |
|                    | which supports "Network Service Headers" needed      |
|                    | for the "Service function chaining" feature          |
|                    | More information on "Service Function Chaining"      |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| OVS-NFV            | OVS-NFV provides a variant of Open-vSwitch           |
|                    | with carrier grade characteristics essential for     |
|                    | NFV workloads.                                       |
|                    | More information on OVS-NFV                          |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| KVM-NFV            | KVM-NFV provides a variant of KVM with improved      |
|                    | virtualization characteristics essential for NFV     |
|                    | workloads.                                           |
|                    | More information on KVM-NFV                          |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| VSPERF             | VSPERF provides a networking characteristics test    |
|                    | bench that facilitates characteristics/performance   |
|                    | evaluation of vSwithches                             |
|                    | More information on VSPERF                           |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+

*Additional third-party plugins can be found here:*
*https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/*
**Note: Plugins are not necessarilly compatible with each other, see section
"Configuration options, OPNFV scenarios" for compatibility information**

The plugins come prepackaged, ready to install. To do so follow the
installation instructions provided in *Reference 13* provided in section
*"Fuel associated references"* below.

Fuel environment
^^^^^^^^^^^^^^^^
A Fuel environment is an OpenStack instance managed by Fuel,
one Fuel instance can manage several OpenStack instances/environments
with different configurations, etc.

To create a Fuel instance, follow the instructions provided in the installation
instructions, see *Reference 13* in section *"Fuel associated references"* below.

Provisioning of aditional features and services
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Although the plugins have already previously been installed,
they are not per default enabled for the environment we just created.
The plugins of your choice need to be enabled and configured.

To enable a plugin, follow the installation instructions found in
*Reference 13*, provided in section *"Fuel associated references"* below.

For configuration of the plugins, please see section "Feature Configuration".

Networking
^^^^^^^^^^
All the networking aspects need to be configured in terms of:
- Interfaces/NICs
- VLANs
- Sub-nets
- Gateways
- User network segmentation (VLAN/VXLAN)
- DNS
- NTP
- etc.

For guidelines on how to configure networking, please refer to the
installation instructions found in *Reference 13* provided in section
*"Fuel associated references"* below.

Node allocation
^^^^^^^^^^^^^^^
Now, it is time to allocate the nodes in your OPNFV cluster to OpenStack-,
SDN-, and other feature/service roles. Some roles may require redundancy,
while others don't; Some roles may be co-located with other roles, while
others may not. The Fuel GUI will guide you in the allocation of roles and
will not permit you to perform invalid allocations.

For detailed guide-lines on node allocation, please refer to the installation instructions found in *Reference 13*, provided in section *"Fuel associated references"* below.

Off-line deployment
^^^^^^^^^^^^^^^^^^^
The OPNFV Brahmaputra version of Fuel can be deployed using on-line upstream
repositories (default) or off-line using built-in local repositories on the
Fuel jump-start server.

For instructions on how to configure Fuel for off-line deployment, please
refer to the installation instructions found in, *Reference 13*, provided
in section *"Fuel associated references"* below.

Deployment
^^^^^^^^^^
You should now be ready to deploy your OPNFV Brahmaputra environment - but before doing so you may want to verify your network settings.

For further details on network verification and deployment, please refer to
the installation instructions found in, *Reference 13*, provided in section
*"Fuel associated references"* below.

Fuel associated references
--------------------------

OPNFV
~~~~~

1) `OPNFV Home Page <www.opnfv.org>`_

2) `OPNFV documentation- and software downloads <https://www.opnfv.org/software/download>`_

OpenStack
~~~~~~~~~

3) `OpenStack Liberty Release artifacts <http://www.openstack.org/software/liberty>`_

4) `OpenStack documentation <http://docs.openstack.org>`_

OpenDaylight
~~~~~~~~~~~~

5) `OpenDaylight artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel
~~~~

6) `The Fuel OpenStack project <https://wiki.openstack.org/wiki/Fuel>`_

7) `Fuel documentation overview <https://docs.fuel-infra.org/openstack/fuel/fuel-8.0/>`_

8) `Fuel planning guide <https://docs.fuel-infra.org/openstack/fuel/fuel-8.0/mos-planning-guide.html>`_

9) `Fuel quick start guide <https://docs.mirantis.com/openstack/fuel/fuel-8.0/quickstart-guide.html>`_

10) `Fuel operations guide <https://docs.mirantis.com/openstack/fuel/fuel-8.0/operations.html>`_

11) `Fuel Plugin Developers Guide <https://wiki.openstack.org/wiki/Fuel/Plugins>`_

12) `Fuel OpenStack Hardware Compatibility List <https://www.mirantis.com/products/openstack-drivers-and-plugins/hardware-compatibility-list>`_

Fuel in OPNFV
~~~~~~~~~~~~~

13) `OPNFV Installation instruction for the Brahmaputra release of OPNFV when using Fuel as a deployment tool <http://artifacts.opnfv.org/fuel/brahmaputra/docs/installation-instruction.html`_

14) `OPNFV Build instruction for the Brahmaputra release of OPNFV when using Fuel as a deployment tool <http://artifacts.opnfv.org/fuel/brahmaputra/docs/build-instruction.html>`_

15) `OPNFV Release Note for the Brahmaputra release of OPNFV when using Fuel as a deployment tool <http://artifacts.opnfv.org/fuel/brahmaputra/docs/release-notes.html>`_
