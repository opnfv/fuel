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

All Fuel and "common" entities are protected by the `Apache License 2.0`_.

Important Notes
===============

This is the OPNFV ``Gambia`` release that implements the deploy stage of the
OPNFV CI pipeline via Fuel.

Fuel is based on the `MCP`_ installation tool chain.
More information available at `Mirantis Cloud Platform Documentation`_.

The goal of the ``Gambia`` release and this Fuel-based deployment process is
to establish a lab ready platform accelerating further development
of the OPNFV infrastructure.

Carefully follow the installation instructions.

Summary
=======

``Gambia`` release with the Fuel deployment toolchain will establish an OPNFV
target system on a Pharos compliant lab infrastructure. The current definition
of an OPNFV target system is OpenStack Queens combined with an SDN
controller, such as OpenDaylight. The system is deployed with OpenStack High
Availability (HA) for most OpenStack services.

Fuel also supports non-HA deployments, which deploys a
single controller, one gateway node and a number of compute nodes.

Fuel supports ``x86_64``, ``aarch64`` or ``mixed`` architecture clusters.

Furthermore, Fuel is capable of deploying scenarios in a ``baremetal``,
``virtual`` or ``hybrid`` fashion. ``virtual`` deployments use multiple VMs on
the Jump Host and internal networking to simulate the ``baremetal`` deployment.

For ``Gambia``, the typical use of Fuel as an OpenStack installer is
supplemented with OPNFV unique components such as:

- `OpenDaylight`_
- Open Virtual Network (``OVN``)

As well as OPNFV-unique configurations of the Hardware and Software stack.

This ``Gambia`` artifact provides Fuel as the deployment stage tool in the
OPNFV CI pipeline including:

- Automated (Jenkins, RTD) documentation build & publish (multiple documents);
- Automated (Jenkins) build & publish of Salt Master Docker image;
- Automated (Jenkins) deployment of ``Gambia`` running on baremetal or a nested
  hypervisor environment (KVM);
- Automated (Jenkins) validation of the ``Gambia`` deployment

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
| **Release date**                     | November 2nd, 2018                   |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Gambia 7.0 release             |
+--------------------------------------+--------------------------------------+

Version Change
--------------

Module Version Changes
~~~~~~~~~~~~~~~~~~~~~~

This is the first tracked version of the ``Gambia`` release with the Fuel
deployment toolchain. It is based on following upstream versions:

- MCP (``Q2`18`` GA release)

- OpenStack (``Queens`` release)

- OpenDaylight (``Fluorine`` release)

- Ubuntu (``16.04`` release)

Document Changes
~~~~~~~~~~~~~~~~

This is the ``Gambia`` 7.0 release.
It comes with the following documentation:

- :ref:`OPNFV Fuel Installation Instruction <fuel-installation>`

- Release notes (This document)

- :ref:`OPNFV Fuel Userguide <fuel-userguide>`

Reason for Version
------------------

Feature Additions
~~~~~~~~~~~~~~~~~

- ``multiarch`` cluster support;
- ``hybrid`` cluster support;
- ``PDF``/``IDF`` support for ``virtual`` PODs;
- ``baremetal`` support for noHA deployments;
- containerized Salt Master;
- ``OVN`` scenarios;

For an exhaustive list, see the `OPNFV Fuel JIRA: Gambia New features`_ filter.

Bug Corrections
~~~~~~~~~~~~~~~

For an exhaustive list, see the `OPNFV Fuel JIRA: Gambia Bugs (fixed)`_ filter.

Software Deliverables
~~~~~~~~~~~~~~~~~~~~~

- `fuel git repository`_ with multiarch (``x86_64``, ``aarch64`` or ``mixed``)
  installer script files

Documentation Deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~

- :ref:`OPNFV Fuel Installation Instruction <fuel-installation>`

- Release notes (This document)

- :ref:`OPNFV Fuel Userguide <fuel-userguide>`

Scenario Matrix
---------------

+-------------------------+---------------+-------------+------------+
|                         | ``baremetal`` | ``virtual`` | ``hybrid`` |
+=========================+===============+=============+============+
| os-nosdn-nofeature-noha |               | ``x86_64``  |            |
+-------------------------+---------------+-------------+------------+
| os-nosdn-nofeature-ha   | ``x86_64``,   |             |            |
|                         | ``aarch64``   |             |            |
+-------------------------+---------------+-------------+------------+
| os-nosdn-ovs-noha       |               | ``x86_64``  |            |
+-------------------------+---------------+-------------+------------+
| os-nosdn-ovs-ha         | ``x86_64``,   |             |            |
|                         | ``aarch64``   |             |            |
+-------------------------+---------------+-------------+------------+
| os-odl-nofeature-noha   |               | ``x86_64``  |            |
+-------------------------+---------------+-------------+------------+
| os-odl-nofeature-ha     | ``x86_64``,   |             |            |
|                         | ``aarch64``   |             |            |
+-------------------------+---------------+-------------+------------+
| os-odl-ovs-noha         |               | ``x86_64``  |            |
+-------------------------+---------------+-------------+------------+
| os-odl-ovs-ha           | ``x86_64``    |             |            |
+-------------------------+---------------+-------------+------------+
| os-ovn-nofeature-noha   |               | ``x86_64``  |            |
+-------------------------+---------------+-------------+------------+
| os-ovn-nofeature-ha     | ``aarch64``   |             |            |
+-------------------------+---------------+-------------+------------+

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

For an exhaustive list, see the `OPNFV Fuel JIRA: Gambia Known issues`_ filter.

Workarounds
-----------

For an exhaustive list, see the `OPNFV Fuel JIRA: Gambia Workarounds`_ filter.

Test Results
============

The ``Gambia`` 7.0 release with the Fuel deployment tool has undergone QA test
runs, see separate test results.

References
==========

For more information on the OPNFV ``Gambia`` 7.0 release, please see:

#. `OPNFV Home Page`_
#. `OPNFV Documentation`_
#. `OPNFV Software Downloads`_
#. `OPNFV Gambia Wiki Page`_
#. `OpenStack Queens Release Artifacts`_
#. `OpenStack Documentation`_
#. `OpenDaylight Artifacts`_
#. `Mirantis Cloud Platform Documentation`_

.. FIXME: cleanup unused refs, extend above list
.. _`OpenDaylight`: https://www.opendaylight.org/software
.. _`OpenDaylight Artifacts`: https://www.opendaylight.org/software/downloads
.. _`MCP`: https://www.mirantis.com/software/mcp/
.. _`Mirantis Cloud Platform Documentation`: https://docs.mirantis.com/mcp/latest/
.. _`fuel git repository`: https://git.opnfv.org/fuel
.. _`OpenStack Documentation`: https://docs.openstack.org
.. _`OpenStack Queens Release Artifacts`: https://www.openstack.org/software/queens
.. _`OPNFV Home Page`: https://www.opnfv.org
.. _`OPNFV Gambia Wiki Page`: https://wiki.opnfv.org/releases/Gambia
.. _`OPNFV Documentation`: https://docs.opnfv.org
.. _`OPNFV Software Downloads`: https://www.opnfv.org/software/download
.. _`Apache License 2.0`: https://www.apache.org/licenses/LICENSE-2.0
.. OPNFV Fuel Gambia JIRA filters
.. _`OPNFV Fuel JIRA: Gambia Bugs (fixed)`: https://jira.opnfv.org/issues/?filter=12503
.. _`OPNFV Fuel JIRA: Gambia New features`: https://jira.opnfv.org/issues/?filter=12504
.. _`OPNFV Fuel JIRA: Gambia Known issues`: https://jira.opnfv.org/issues/?filter=12505
.. _`OPNFV Fuel JIRA: Gambia Workarounds`: https://jira.opnfv.org/issues/?filter=12506
