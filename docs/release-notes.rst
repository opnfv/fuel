============================================================================================
OPNFV Release Note for the Brahmaputra release of OPNFV when using Fuel as a deployment tool
============================================================================================

.. contents:: Table of Contents
   :backlinks: none

Abstract
========

This document compiles the release notes for the Brahmaputra release of
OPNFV when using Fuel as a deployment tool.

License
=======

Brahmaputra release with the Fuel deployment tool Docs (c) by Jonas
Bjurel (Ericsson AB)

This document is licensed under a Creative Commons Attribution 4.0
International License.

You should have received a copy of the license along with this document.
If not, see <http://creativecommons.org/licenses/by/4.0/>.

Important notes
===============

These notes provides release information for the use of Fuel as deployment
tool for the Brahmaputra release of OPNFV.

The goal of the Brahmaputra release and this Fuel-based deployment process is
to establish a lab ready platform accelerating further development
of the OPNFV infrastructure.

Carefully follow the installation-instructions.

Summary
=======

For Brahmaputra, the typical use of Fuel as an OpenStack installer is
supplemented with OPNFV unique components such as:

- `OpenDaylight <http://www.opendaylight.org/software>`_ version "Berylium RC1 as"

- `ONOS <http://onosproject.org/>`_ version "Drake"

- `Service function chaining <https://wiki.opnfv.org/service_function_chaining>`_

- `SDN distributed routing and VPN <https://wiki.opnfv.org/sdnvpn>`_

- `NFV Hypervisors-KVM <https://wiki.opnfv.org/nfv-kvm>`_

- `Open vSwitch for NFV <https://wiki.opnfv.org/ovsnfv>`_

- `VSPERF <https://wiki.opnfv.org/characterize_vswitch_performance_for_telco_nfv_use_cases>`_

As well as OPNFV-unique configurations of the Hardware- and Software stack.

This Brahmaputra artifact provides Fuel as the deployment stage tool in the
OPNFV CI pipeline including:

- Documentation built by Jenkins

  - overall OPNFV documentation

  - this document (release notes)

  - installation instructions

  - build-instructions

- The Brahmaputra Fuel installer image (.iso) built by Jenkins

- Automated deployment of Brahmaputra with running on bare metal or a nested hypervisor environment (KVM)

- Automated validation of the Brahmaputra deployment


Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | fuel                                 |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | fuel/<TODO>                          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | Brahmaputra base release             |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | <TODO>                               |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | Brahmaputra base release             |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Version change
--------------

Module version changes
~~~~~~~~~~~~~~~~~~~~~~
This is the second tracked release of genesis/fuel. It is based on
following upstream versions:

- Fuel 8.0 pre-release

- OpenStack Liberty release

- OpenDaylight Beryllium pre-release

- ONOS Drake release

Document changes
~~~~~~~~~~~~~~~~
This is the third tracked version of the fuel installer for OPNFV. It
comes with the following documentation:

- OPNFV Installation instructions for Brahmaputra with Fuel as deployment tool - **Changed**

- OPNFV Release Notes for Brahmaputra use of Fuel as deployment tool - **Changed**

- OPNFV Build instructions for Brahmaputra with Fuel as deployment tool - **Changed**

Reason for version
------------------
Feature additions
~~~~~~~~~~~~~~~~~

**JIRA TICKETS:**

`New features <https://jira.opnfv.org/browse/FUEL-81?jql=project%20%3D%20FUEL%20AND%20issuetype%20in%20%28Improvement%2C%20%22New%20Feature%22%2C%20Story%2C%20Sub-task%29%20AND%20status%20in%20%28Resolved%2C%20Closed%29%20AND%20resolution%20%3D%20Fixed%20AND%20labels%20in%20%28Fuel-B-WP1%2C%20R2%2C%20brahmaputra%29>`_

Bug corrections
~~~~~~~~~~~~~~~

**JIRA TICKETS:**

`Bug-fixes <https://jira.opnfv.org/browse/FUEL-96?jql=project%20%3D%20FUEL%20AND%20issuetype%20%3D%20Bug%20AND%20status%20in%20%28Resolved%2C%20Closed%29%20AND%20resolution%20%3D%20Fixed%20AND%20labels%20in%20%28Fuel-B-WP1%2C%20R2%2C%20brahmaputra%29>`_

Deliverables
------------

Software deliverables
~~~~~~~~~~~~~~~~~~~~~

Fuel-based installer iso file <TODO>

Documentation deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~

- OPNFV Installation instructions for Brahmaputra release with the Fuel deployment tool

- OPNFV Build instructions for Brahmaputra release with the Fuel deployment
  tool

- OPNFV Release Note for Brahmaputra release with the Fuel deployment tool - (this document)

Known Limitations, Issues and Workarounds
=========================================

System Limitations
------------------

- **Max number of blades:** 1 Fuel master, 3 Controllers, 20 Compute blades

- **Min number of blades:** 1 Fuel master, 1 Controller, 1 Compute blade

- **Storage:** Ceph is the only supported storage configuration.

- **Max number of networks:** 65k


Known issues
------------

**JIRA TICKETS:**

`Known issues <https://jira.opnfv.org/browse/FUEL-99?jql=project%20%3D%20FUEL%20AND%20issuetype%20%3D%20Bug%20AND%20status%20in%20%28Open%2C%20%22In%20Progress%22%2C%20Reopened%29>`_

Workarounds
-----------

-

Test results
============
The Brahmaputra release with the Fuel deployment tool has undergone QA test
runs with the following results:
<TODO>

References
==========
For more information on the OPNFV Brahmaputra release, please see
<TODO>
 
