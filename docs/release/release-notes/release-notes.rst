.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

************************
OPNFV Fuel Release Notes
************************

Abstract
========

This document provides the release notes for ``Gambia`` release with the Fuel
deployment toolchain.

Starting with this release, both ``x86_64`` and ``aarch64`` architectures
are supported at the same time by the ``fuel`` codebase.

License
=======

All Fuel and "common" entities are protected by the `Apache 2.0 License`_.

Important Notes
===============

This is the OPNFV Gambia release that implements the deploy stage of the
OPNFV CI pipeline via Fuel.

Fuel is based on the `MCP`_ installation tool chain.
More information available at `Mirantis Cloud Platform Documentation`_.

The goal of the Gambia release and this Fuel-based deployment process is
to establish a lab ready platform accelerating further development
of the OPNFV infrastructure.

Carefully follow the installation instructions.

Summary
=======

## apex b
## FIXME
Gambia release with the Fuel deployment toolchain will establish an OPNFV
target system on a Pharos compliant lab infrastructure. The current definition
of an OPNFV target system is OpenStack Queens combined with an SDN
controller, such as OpenDaylight. The system is deployed with OpenStack High
Availability (HA) for most OpenStack services. SDN controllers are deployed
on every controller unless deploying with one the HA FD.IO scenarios.  Ceph
storage is used as Cinder backend, and is the only supported storage for
Fraser.  Ceph is setup as 3 OSDs and 3 Monitors, one OSD+Mon per Controller
node in an HA setup.  Apex also supports non-HA deployments, which deploys a
single controller and n number of compute nodes.  Furthermore, Apex is
capable of deploying scenarios in a bare metal or virtual fashion.  Virtual
deployments use multiple VMs on the Jump Host and internal networking to
simulate the a bare metal deployment.

- Documentation is built by Jenkins
- Salt Master Docker image is built by Jenkins
- Jenkins deploys a Fraser release with the Apex deployment toolchain
  bare metal, which includes 3 control+network nodes, and 2 compute nodes.

## apex e

For Gambia, the typical use of Fuel as an OpenStack installer is
supplemented with OPNFV unique components such as:

- `OpenDaylight`_

As well as OPNFV-unique configurations of the Hardware and Software stack.

This Gambia artifact provides Fuel as the deployment stage tool in the
OPNFV CI pipeline including:

- Documentation built by Jenkins

  - overall OPNFV documentation

  - this document (release notes)

  - installation instructions

- Automated deployment of Gambia with running on baremetal or a nested
  hypervisor environment (KVM)

- Automated validation of the Gambia deployment

Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | fuel                                 |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | opnfv-7.0.0                          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | Gambia 7.0                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | TBD     2018                         |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Gambia release                 |
+--------------------------------------+--------------------------------------+

Version Change
--------------

Module Version Changes
~~~~~~~~~~~~~~~~~~~~~~

This is the first tracked version of the Gambia release with the Fuel
deployment toolchain. It is based on following upstream versions:

- MCP (TBD release)

- OpenStack (Queens release)

- OpenDaylight (Fluorine release)

- Ubuntu (16.04 release)

Document Changes
~~~~~~~~~~~~~~~~
This is the Gambia 7.0 release.
It comes with the following documentation:

- :ref:`OPNFV Fuel Installation Instruction <fuel-installation>`

- Release notes (This document)

- :ref:`OPNFV Fuel Userguide <fuel-userguide>`

Reason for Version
==================

Feature Additions
-----------------

**JIRA TICKETS:**
None

Bug Corrections
---------------

**JIRA TICKETS:**

`Gambia 7.0 bug fixes  <https://jira.opnfv.org/issues/?filter=12318>`_

(Also See respective Integrated feature project's bug tracking)

Deliverables
------------

Software Deliverables
~~~~~~~~~~~~~~~~~~~~~

- `fuel git repository`_ with multiarch (x86_64, aarch64) installer script files

Documentation Deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~

- :ref:`OPNFV Fuel Installation Instruction <fuel-installation>`

- Release notes (This document)

- :ref:`OPNFV Fuel Userguide <fuel-userguide>`

Known Limitations, Issues and Workarounds
=========================================

System Limitations
------------------

- **Max number of blades:** 1 Jumpserver, 3 Controllers, 20 Compute blades

- **Min number of blades:** 1 Jumpserver

- **Storage:** Cinder is the only supported storage configuration

- **Max number of networks:** 65k


Known Issues
------------

**JIRA TICKETS:**

`Known issues <https://jira.opnfv.org/issues/?filter=12317>`_

(Also See respective Integrated feature project's bug tracking)

Workarounds
-----------

**JIRA TICKETS:**

None

(Also See respective Integrated feature project's bug tracking)

Test Results
============

The Gambia 7.0 release with the Fuel deployment tool has undergone QA test
runs, see separate test results.

References
==========

For more information on the OPNFV Gambia 7.0 release, please see:

#. `OPNFV Home Page`_
#. `OPNFV Documentation`_
#. `OPNFV Software Downloads`_
#. `OPNFV Gambia Wiki Page`_
#. `OpenStack Queens Release Artifacts`_
#. `OpenStack Documentation`_
#. `OpenDaylight Artifacts`_
#. `Mirantis Cloud Platform Documentation`_

.. _`OpenDaylight`: https://www.opendaylight.org/software
.. _`OpenDaylight Artifacts`: https://www.opendaylight.org/software/downloads
.. _`Apache 2.0 License`: http://www.apache.org/licenses/
.. _`MCP`: https://www.mirantis.com/software/mcp/
.. _`Mirantis Cloud Platform Documentation`: https://docs.mirantis.com/mcp/latest/
.. _`fuel git repository`: https://git.opnfv.org/fuel
.. _`OpenStack Documentation`: https://docs.openstack.org
.. _`OpenStack Queens Release Artifacts`: https://www.openstack.org/software/queens
.. _`OPNFV Home Page`: https://www.opnfv.org
.. _`OPNFV Gambia Wiki Page`: https://wiki.opnfv.org/releases/Gambia
.. _`OPNFV Documentation`: https://docs.opnfv.org
.. _`OPNFV Software Downloads`: https://www.opnfv.org/software/download
