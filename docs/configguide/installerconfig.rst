.. This document is protected/licensed under the following conditions
.. (c) Jonas Bjurel (Ericsson AB)
.. Licensed under a Creative Commons Attribution 4.0 International License.
.. You should have received a copy of the license along with this work.
.. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Fuel configuration
==================
This section provides brief guidelines on how to install and
configure the Brahmaputra release of OPNFV when using Fuel as a
deployment tool including required software and hardware
configurations.

Although the available installation options gives a high degree of
freedom in how the system is set-up including architecture, services
and features, etc. said permutations may not provide an OPNFV
compliant reference architecture. This section provides a
step-by-step guide that results in an OPNFV Brahmaputra compliant
deployment.

The audience of this section is assumed to have knowledge in
networking and Unix/Linux administration.

Pre-configuration activities
----------------------------

Planning the deployment

Before starting the installation of the Brahmaputra release of
OPNFV when using Fuel as a deployment tool, some planning must be
done.

Next, familiarize yourself with the Fuel by reading the
following documents:

- Fuel planning guide
  <https://docs.mirantis.com/openstack/fuel/fuel-7.0/planning-guide.html>

- Fuel user guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html>

- Fuel operations guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/operations.html>


A number of deployment specific parameters must be collected, those are:

#.     Provider sub-net and gateway information

#.     Provider VLAN information

#.     Provider DNS addresses

#.     Provider NTP addresses

#.     Network Topology you plan to Deploy (VLAN, GRE(VXLAN), FLAT)

#.     Linux Distro you intend to deploy.

#.     How many nodes and what roles you want to deploy (Controllers,
Storage, Computes)

#.     Monitoring Options you want to deploy (Ceilometer, MongoDB).

#.     Other options not covered in the document are available in the
links above


Retrieving the ISO image
^^^^^^^^^^^^^^^^^^^^^^^^
First of all, the Fuel deployment ISO image needs to be retrieved, the
.iso image of the Brahmaputra release of OPNFV when using Fuel as
a deployment tool can be found at: <TODO>

NOTE: TO BE UPDATED WITH FINAL B-RELASE ARTIFACT

Alternatively, you may build the .iso from source by cloning the
opnfv/fuel git repository. Detailed instructions on how to build
a Fuel OPNFV .iso can be found here: <TODO>


Hardware configuration
----------------------
The following minimum hardware requirements must be met for the
installation of Brahmaputra using Fuel:

Hardware requirements
^^^^^^^^^^^^^^^^^^^^^
Following high level hardware requirements must be met:

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

For a detailed hardware compatibility matrix - please see:
<https://www.mirantis.com/products/openstack-drivers-and-plugins/hardware-compatibility-list/>

Top of the rack (TOR) Configuration requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South bound connectivity); it also provides needed
connectivity for the storage Area Network (SAN). To avoid traffic
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

Manual configuration of the Brahmaputra hardware platform should
be carried out according to the Pharos specification TODO-<insert link
to Pharos ARNO SR1 Specification>

Jumphost configuration
-----------------------
The Jumphost server requires 2 (4 if redundancy is required) ethernet
interfaces - one for external management of the OPNFV installation,
and another for jump-host communication with the OPNFV cluster.

Install the Fuel jump-host
^^^^^^^^^^^^^^^^^^^^^^^^^^
Mount the Fuel Brahmaputra ISO file as a boot device to the jump host
server, reboot it, and install the Fuel Jumphost in accordance with the
instructions found here: <TODO>


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
+--------------------+------------------------------------------------------+
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
| OVS-NFV            | OVS-NSH provides a variant of Open-vSwitch           |
|                    | with carrier grade characteristics essential for     |
|                    | NFV workloads.                                       |
|                    | More information on OVS-NFV                          |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| KVM-NFV            | OVS-NSH provides a variant of KVM with improved      |
|                    | virtualization characteristics essential for NFV     |
|                    | workloads.                                           |
|                    | More information on KVM-NFV                          |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| VSPERF             | VSPERF provides a networking characteristics test    |
|                    | bench that facilitats characteristics/performance    |
|                    | evaluation of vSwithches                             |
|                    | More information on VSPERF                           |
|                    | in the OPNFV Brahmaputra release can be found in a   |
|                    | in a separate section in this document.              |
|                    |                                                      |
+--------------------+------------------------------------------------------+

*Additional third-party plugins can be found here:*
*https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/*
**Note: Plugins are not necessarilly compatible with each other, see section XYZ
for compatibility information**

The plugins come prepackaged, ready to install. To do so follow the
instructions provided here: <TODO>

Fuel environment
^^^^^^^^^^^^^^^^
A Fuel environment is an OpenStack instance managed by Fuel,
one Fuel instance can manage several OpenStack instances with
different configurations.
To create a Fuel instance, follollw the instructions provided
here: <TODO>

Provisioning of aditional features and services
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Although the plugins have already previously been installed,
they are not per default enabled for the environment we just created.
The plugins of you choice need to be enabled and configured.

To enable a plugin, follow the instructions below or refere to the intallation instructions here:

- In the FUEL UI of your Enviornment, click the "Settings" Tab

- On the left hand side, select the name of the plugin you want enable and click, "enable".

- Configure the plugins according to the respective feature configuration sections in this document.

- Click "Save Settings" at the bottom to Save your changes

For configuration of the plugins, please refer to the corresponding feature in the ????? <TODO>

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
installation instructions here: <TODO>

Node allocation
^^^^^^^^^^^^^^^
Now, it is time to allocate the nodes in your OPNFV cluster to OpenStack-,
SDN-, and other feature/service roles. Some roles may require redundancy,
while others don't; Some roles may be co-located with other roles, while
others may not. The Fuel GUI will guide you in the allocation of roles and
will not permit you to perform invalid allocations.
For detailed guide-lines on node allocation, please refer to the installation instructions: <TODO>

Off-line deployment
^^^^^^^^^^^^^^^^^^^
The OPNFV Brahmaputra version of Fuel can be deployed uing on-line upstream
repositories (default) or off-line using built-in local repositories on the
Fuel jump-start server.
For instructions on how to configure Fuel for off-line deployment, please
refer to the installation instructions: <TODO>

Deployment
^^^^^^^^^^
You should now be ready to deploy your OPNFV Brahmaputra environment - but before doing so you may want to verify your network settings.
For further details on network verification and deployment, please refer to
the installation instructions: <TODO>
