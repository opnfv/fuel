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

Although the available installation options provide a high de.g.ee of
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
==================

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
Hardware requirements for virtual deploys
=========================================

The following minimum hardware requirements must be met for the virtual
installation of Euphrates using Fuel:

+----------------------------+--------------------------------------------------------+
| **HW Aspect**              | **Requirement**                                        |
|                            |                                                        |
+============================+========================================================+
| **1 Jumpserver**           | A physical node (also called Foundation Node) that     |
|                            | hosts a Salt Master VM and each of the VM nodes in     |
|                            | the virtual deploy                                     |
+----------------------------+--------------------------------------------------------+
| **CPU**                    | Minimum 1 socket with Virtualization support           |
+----------------------------+--------------------------------------------------------+
| **RAM**                    | Minimum 32GB/server (Depending on VNF work load)       |
+----------------------------+--------------------------------------------------------+
| **Disk**                   | Minimum 100GB (SSD or SCSI (15krpm) highly recommended |
+----------------------------+--------------------------------------------------------+


===========================================
Hardware requirements for baremetal deploys
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

Manual configuration of the Euphrates hardware platform should
be carried out according to the `OPNFV Pharos Specification
<https://wiki.opnfv.org/display/pharos/Pharos+Specification>`_.

==========================================
OPNFV Software installation and deployment
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


Steps to start the automatic deploy
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

       $ git checkout 5.0.2

#. Start the deploy script

   .. code-block:: bash

       $ ci/deploy.sh -l <lab_name> \
                      -p <pod_name> \
                      -b <URI to the PDF file> \
                      -s <scenario> \
                      -B <list of admin, public and management bridges>

Examples
--------
#. Virtual deploy

   .. code-block:: bash

      $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                     -l ericsson \
                     -p virtual_kvm \
                     -s os-nosdn-nofeature-noha

#. Baremetal deploy

A x86 deploy on pod1 from Ericsson lab

   .. code-block:: bash

      $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                     -l ericsson \
                     -p pod1 \
                     -s os-nosdn-nofeature-ha \
                     -B pxebr

An aarch64 deploy on pod5 from Arm lab

   .. code-block:: bash

      $ ci/deploy.sh -b file:///home/jenkins/tmpdir/securedlab \
                     -l arm \
                     -p pod5 \
                     -s os-nosdn-nofeature-ha \
                     -B pxebr


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
