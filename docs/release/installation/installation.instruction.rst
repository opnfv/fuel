.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

========
Abstract
========

This document describes how to install the Euphrates release of
OPNFV when using Fuel as a deployment tool, covering its usage,
limitations, dependencies and required system resources.
This is an unified documentation for both x86_64 and aarch64
architectures. All information is common for both architectures
except when explicitly stated.

============
Introduction
============

This document provides guidelines on how to install and
configure the Euphrates release of OPNFV when using Fuel as a
deployment tool, including required software and hardware configurations.

Although the available installation options provide a high degree of
freedom in how the system is set up, including architecture, services
and features, etc., said permutations may not provide an OPNFV
compliant reference architecture. This document provides a
step-by-step guide that results in an OPNFV Euphrates compliant
deployment.

The audience of this document is assumed to have good knowledge of
networking and Unix/Linux administration.

=======
Preface
=======

Before starting the installation of the Euphrates release of
OPNFV, using Fuel as a deployment tool, some planning must be
done.

Preparations
============

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

=========================================
Hardware Requirements for Virtual Deploys
=========================================

The following minimum hardware requirements must be met for the virtual
installation of Euphrates using Fuel:

+----------------------------+--------------------------------------------------------+
| **HW Aspect**              | **Requirement**                                        |
|                            |                                                        |
+============================+========================================================+
| **1 Jumpserver**           | A physical node (also called Foundation Node) that     |
|                            | will host a Salt Master VM and each of the VM nodes in |
|                            | the virtual deploy                                     |
+----------------------------+--------------------------------------------------------+
| **CPU**                    | Minimum 1 socket with Virtualization support           |
+----------------------------+--------------------------------------------------------+
| **RAM**                    | Minimum 32GB/server (Depending on VNF work load)       |
+----------------------------+--------------------------------------------------------+
| **Disk**                   | Minimum 100GB (SSD or SCSI (15krpm) highly recommended |
+----------------------------+--------------------------------------------------------+


===========================================
Hardware Requirements for Baremetal Deploys
===========================================

The following minimum hardware requirements must be met for the baremetal
installation of Euphrates using Fuel:

+-------------------------+------------------------------------------------------+
| **HW Aspect**           | **Requirement**                                      |
|                         |                                                      |
+=========================+======================================================+
| **# of nodes**          | Minimum 5                                            |
|                         |                                                      |
|                         | - 3 KVM servers which will run all the controller    |
|                         |   services                                           |
|                         |                                                      |
|                         | - 2 Compute nodes                                    |
|                         |                                                      |
+-------------------------+------------------------------------------------------+
| **CPU**                 | Minimum 1 socket with Virtualization support         |
+-------------------------+------------------------------------------------------+
| **RAM**                 | Minimum 16GB/server (Depending on VNF work load)     |
+-------------------------+------------------------------------------------------+
| **Disk**                | Minimum 256GB 10kRPM spinning disks                  |
+-------------------------+------------------------------------------------------+
| **Networks**            | 4 VLANs (PUBLIC, MGMT, STORAGE, PRIVATE) - can be    |
|                         | a mix of tagged/native                               |
|                         |                                                      |
|                         | 1 Un-Tagged VLAN for PXE Boot - ADMIN Network        |
|                         |                                                      |
|                         | Note: These can be allocated to a single NIC -       |
|                         | or spread out over multiple NICs                     |
+-------------------------+------------------------------------------------------+
| **1 Jumpserver**        | A physical node (also called Foundation Node) that   |
|                         | hosts the Salt Master and MaaS VMs                   |
+-------------------------+------------------------------------------------------+
| **Power management**    | All targets need to have power management tools that |
|                         | allow rebooting the hardware and setting the boot    |
|                         | order (e.g. IPMI)                                    |
+-------------------------+------------------------------------------------------+

**NOTE:** All nodes including the Jumpserver must have the same architecture (either x86_64 or aarch64).

**NOTE:** For aarch64 deployments an UEFI compatible firmware with PXE support is needed (e.g. EDK2).


===============================
Help with Hardware Requirements
===============================

Calculate hardware requirements:

For information on compatible hardware types available for use, please see `Fuel OpenStack Hardware Compatibility List <https://www.mirantis.com/software/hardware-compatibility/>`_.

When choosing the hardware on which you will deploy your OpenStack
environment, you should think about:

- CPU -- Consider the number of virtual machines that you plan to deploy in your cloud environment and the CPUs per virtual machine.

- Memory -- Depends on the amount of RAM assigned per virtual machine and the controller node.

- Storage -- Depends on the local drive space per virtual machine, remote volumes that can be attached to a virtual machine, and object storage.

- Networking -- Depends on the Choose Network Topology, the network bandwidth per virtual machine, and network storage.

================================================
Top of the Rack (TOR) Configuration Requirements
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

Manual configuration of the Euphrates hardware platform should
be carried out according to the `OPNFV Pharos Specification
<https://wiki.opnfv.org/display/pharos/Pharos+Specification>`_.

============================
OPNFV Software Prerequisites
============================

The Jumpserver node should be pre-provisioned with an operating system,
according to the Pharos specification. Relevant network bridges should
also be pre-configured (e.g. admin, management, public).

Fuel@OPNFV has been validated by CI using the following distributions
installed on the Jumpserver:

   - CentOS 7 (recommended by Pharos specification);
   - Ubuntu Xenial;

**NOTE:** The install script expects 'libvirt' to be installed and running
on the Jumpserver. In case the packages are missing, the script will install
them; but depending on the OS distribution, the user might have to start the
'libvirtd' service manually.

==========================================
OPNFV Software Installation and Deployment
==========================================

This section describes the process of installing all the components needed to
deploy the full OPNFV reference platform stack across a server cluster.

The installation is done with Mirantis Cloud Platform (MCP), which is based on
a reclass model. This model provides the formula inputs to Salt, to make the deploy
automatic based on deployment scenario.
The reclass model covers:

   - Infrastucture node definition: Salt Master node (cfg01) and MaaS node (mas01)
   - Openstack node defition: Controler nodes (ctl01, ctl02, ctl03) and Compute nodes (cmp001, cmp002)
   - Infrastructure components to install (software packages, services etc.)
   - Openstack components and services (rabbitmq, galera etc.), as well as all configuration for them


Automatic Installation of a Virtual POD
=======================================

For virtual deploys all the targets are VMs on the Jumpserver. The deploy script will:

   - Create a Salt Master VM on the Jumpserver which will drive the installation
   - Create the bridges for networking with virsh (only if a real bridge does not already exists for a given network)
   - Install Openstack on the targets
      - Leverage Salt to install & configure Openstack services

.. figure:: img/fuel_virtual.png
   :align: center
   :alt: Fuel@OPNFV Virtual POD Network Layout Examples

   Fuel@OPNFV Virtual POD Network Layout Examples

   +-----------------------+------------------------------------------------------------------------+
   | cfg01                 | Salt Master VM                                                         |
   +-----------------------+------------------------------------------------------------------------+
   | ctl01                 | Controller VM                                                          |
   +-----------------------+------------------------------------------------------------------------+
   | cmp01/cmp02           | Compute VMs                                                            |
   +-----------------------+------------------------------------------------------------------------+
   | gtw01                 | Gateway VM with neutron services (dhcp agent, L3 agent, metadata, etc) |
   +-----------------------+------------------------------------------------------------------------+
   | odl01                 | VM on which ODL runs (for scenarios deployed with ODL)                 |
   +-----------------------+------------------------------------------------------------------------+


In this figure there are examples of two virtual deploys:
   - Jumphost 1 has only virsh bridges, created by the deploy script
   - Jumphost 2 has a mix of linux and virsh briges; when linux bridge exist for a specified network,
     the deploy script will skip creating a virsh bridge for it

**Note**: A virtual network "mcpcontrol" is always created. For virtual deploys, "mcpcontrol" is also used
for Admin, leaving the PXE/Admin bridge unused.


Automatic Installation of a Baremetal POD
=========================================

The baremetal installation process can be done by editing the information about
hardware and enviroment in the reclass files, or by using a Pod Descriptor File (PDF).
This file contains all the information about the hardware and network of the deployment
the will be fed to the reclass model during deployment.

The installation is done automatically with the deploy script, which will:

   - Create a Salt Master VM on the Jumpserver which will drive the installation
   - Create a MaaS Node VM on the Jumpserver which will provision the targets
   - Install Openstack on the targets
      - Leverage MaaS to provision baremetal nodes with the operating system
      - Leverage Salt to configure the operatign system on the baremetal nodes
      - Leverage Salt to install & configure Openstack services

.. figure:: img/fuel_baremetal.png
   :align: center
   :alt: Fuel@OPNFV Baremetal POD Network Layout Example

   Fuel@OPNFV Baremetal POD Network Layout Example

   +-----------------------+---------------------------------------------------------+
   | cfg01                 | Salt Master VM                                          |
   +-----------------------+---------------------------------------------------------+
   | mas01                 | MaaS Node VM                                            |
   +-----------------------+---------------------------------------------------------+
   | kvm01..03             | Baremetals which hold the VMs with controller functions |
   +-----------------------+---------------------------------------------------------+
   | cmp001/cmp002         | Baremetal compute nodes                                 |
   +-----------------------+---------------------------------------------------------+
   | prx01/prx02           | Proxy VMs for Nginx                                     |
   +-----------------------+---------------------------------------------------------+
   | msg01..03             | RabbitMQ Service VMs                                    |
   +-----------------------+---------------------------------------------------------+
   | dbs01..03             | MySQL service VMs                                       |
   +-----------------------+---------------------------------------------------------+
   | mdb01..03             | Telemetry VMs                                           |
   +-----------------------+---------------------------------------------------------+
   | odl01                 | VM on which ODL runs (for scenarios deployed with ODL)  |
   +-----------------------+---------------------------------------------------------+
   | Tenant VM             | VM running in the cloud                                 |
   +-----------------------+---------------------------------------------------------+

In the baremetal deploy all bridges but "mcpcontrol" are linux bridges. For the Jumpserver, if they are already created
they will be used; otherwise they will be created. For the targets, the bridges are created by the deploy script.

**Note**: A virtual network "mcpcontrol" is always created. For baremetal deploys, PXE bridge is used for
baremetal node provisioning, while "mcpcontrol" is used to provision the infrastructure VMs only.


Steps to Start the Automatic Deploy
===================================

These steps are common both for virtual and baremetal deploys.

#. Clone the Fuel code from gerrit

   For x86_64

   .. code-block:: bash

       $ git clone https://git.opnfv.org/fuel
       $ cd fuel

   For aarch64

   .. code-block:: bash

       $ git clone https://git.opnfv.org/armband
       $ cd armband

#. Checkout the Euphrates release

   .. code-block:: bash

       $ git checkout opnfv-5.0.2

#. Start the deploy script

   .. code-block:: bash

       $ ci/deploy.sh -l <lab_name> \
                      -p <pod_name> \
                      -b <URI to configuration repo containing the PDF file> \
                      -s <scenario> \
                      -B <list of admin, management, private and public bridges>

Examples
--------
#. Virtual deploy

   To start a virtual deployment, it is required to have the `virtual` keyword
   while specifying the pod name to the installer script.

   It will create the required bridges and networks, configure Salt Master and
   install OpenStack.

      .. code-block:: bash

         $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                        -l ericsson \
                        -p virtual_kvm \
                        -s os-nosdn-nofeature-noha

   Once the deployment is complete, the OpenStack Dashboard, Horizon is
   available at http://<controller VIP>:8078, e.g. http://10.16.0.101:8078.
   The administrator credentials are **admin** / **opnfv_secret**.

#. Baremetal deploy

   A x86 deploy on pod2 from Linux Foundation lab

      .. code-block:: bash

          $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                         -l lf \
                         -p pod2 \
                         -s os-nosdn-nofeature-ha \
                         -B pxebr,br-ctl

      .. figure:: img/lf_pod2.png
         :align: center
         :alt: Fuel@OPNFV LF POD2 Network Layout

         Fuel@OPNFV LF POD2 Network Layout

   Once the deployment is complete, the SaltStack Deployment Documentation is
   available at http://<Proxy VIP>:8090, e.g. http://172.30.10.103:8090.

   An aarch64 deploy on pod5 from Arm lab

      .. code-block:: bash

         $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                        -l arm \
                        -p pod5 \
                        -s os-nosdn-nofeature-ha \
                        -B admin7_br0,mgmt7_br0,,public7_br0

      .. figure:: img/arm_pod5.png
         :align: center
         :alt: Fuel@OPNFV ARM POD5 Network Layout

         Fuel@OPNFV ARM POD5 Network Layout

   Once the deployment is complete, the SaltStack Deployment Documentation is
   available at http://<Proxy VIP>:8090, e.g. http://10.0.8.103:8090.


Pod Descriptor Files
====================

Descriptor files provide the installer with an abstraction of the target pod
with all its hardware characteristics and required parameters. This information
is split into two different files:
Pod Descriptor File (PDF) and Installer Descriptor File (IDF).


The Pod Descriptor File is a hardware and network description of the pod
infrastructure. The information is modeled under a yaml structure.
A reference file with the expected yaml structure is available at
*mcp/config/labs/local/pod1.yaml*

A common network section describes all the internal and provider networks
assigned to the pod. Each network is expected to have a vlan tag, IP subnet and
attached interface on the boards. Untagged vlans shall be defined as "native".

The hardware description is arranged into a main "jumphost" node and a "nodes"
set for all target boards. For each node the following characteristics
are defined:

- Node parameters including CPU features and total memory.
- A list of available disks.
- Remote management parameters.
- Network interfaces list including mac address, speed and advanced features.
- IP list of fixed IPs for the node

**Note**: the fixed IPs are ignored by the MCP installer script and it will instead
assign based on the network ranges defined under the pod network configuration.


The Installer Descriptor File extends the PDF with pod related parameters
required by the installer. This information may differ per each installer type
and it is not considered part of the pod infrastructure. Fuel installer relies
on the IDF model to map the networks to the bridges on the foundation node and
to setup all node NICs by defining the expected OS device name and bus address.


The file follows a yaml structure and a "fuel" section is expected. Contents and
references must be aligned with the PDF file. The IDF file must be named after
the PDF with the prefix "idf-". A reference file with the expected structure
is available at *mcp/config/labs/local/idf-pod1.yaml*


=============
Release Notes
=============

Please refer to the :ref:`Release Notes <fuel-release-notes-label>` article.

==========
References
==========

OPNFV

1) `OPNFV Home Page <http://www.opnfv.org>`_
2) `OPNFV documentation <http://docs.opnfv.org>`_
3) `Software downloads <https://www.opnfv.org/software/download>`_

OpenStack

4) `OpenStack Ocata Release Artifacts <http://www.openstack.org/software/ocata>`_
5) `OpenStack Documentation <http://docs.openstack.org>`_

OpenDaylight

6) `OpenDaylight Artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel

7) `Mirantis Cloud Platform Documentation <https://docs.mirantis.com/mcp/latest>`_

Salt

8) `Saltstack Documentation <https://docs.saltstack.com/en/latest/topics>`_
9) `Saltstack Formulas <http://salt-formulas.readthedocs.io/en/latest/develop/overview-reclass.html>`_

Reclass

10) `Reclass model <http://reclass.pantsfullofunix.net>`_
