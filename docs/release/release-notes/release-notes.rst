.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

========
Abstract
========

This document compiles the release notes for the Euphrates release of
OPNFV when using Fuel as a deployment tool. This is an unified documentation
for both x86_64 and aarch64 architectures. All information is common for
both architectures except when explicitly stated.


===============
Important Notes
===============

These notes provides release information for the use of Fuel as deployment
tool for the Euphrates release of OPNFV.

The goal of the Euphrates release and this Fuel-based deployment process is
to establish a lab ready platform accelerating further development
of the OPNFV infrastructure.

Carefully follow the installation-instructions.

=======
Summary
=======

For Euphrates, the typical use of Fuel as an OpenStack installer is
supplemented with OPNFV unique components such as:

- `OpenDaylight <http://www.opendaylight.org/software>`_
- `Open vSwitch for NFV <https://wiki.opnfv.org/ovsnfv>`_

As well as OPNFV-unique configurations of the Hardware and Software stack.

This Euphrates artifact provides Fuel as the deployment stage tool in the
OPNFV CI pipeline including:

- Documentation built by Jenkins

  - overall OPNFV documentation

  - this document (release notes)

  - installation instructions

- Automated deployment of Euphrates with running on bare metal or a nested
  hypervisor environment (KVM)

- Automated validation of the Euphrates deployment

============
Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | fuel/armband                         |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | opnfv-5.0.2                          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | Euphrates 5.0                        |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | October 20 2017                      |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | Euphrates alignment to Released      |
|                                      | MCP 1.0 baseline + features and      |
|                                      | bug-fixes for the following          |
|                                      | feaures:                             |
|                                      |                                      |
|                                      | - Open vSwitch for NFV               |
|                                      | - OpenDaylight                       |
+--------------------------------------+--------------------------------------+

Version Change
==============

Module Version Changes
----------------------
This is the Euphrates 5.0 release.
It is based on following upstream versions:

- MCP 1.0 Base Release

- OpenStack Ocata Release

- OpenDaylight

Document Changes
----------------
This is the Euphrates 5.0 release.
It comes with the following documentation:

- Installation instructions

- Release notes (This document)

Reason for Version
==================

Feature Additions
-----------------

**JIRA TICKETS:**
`Euphrates 5.0 new features  <https://jira.opnfv.org/issues/?filter=12029>`_

Bug Corrections
---------------

**JIRA TICKETS:**

`Euphrates 5.0 bug fixes  <https://jira.opnfv.org/issues/?filter=12027>`_

(Also See respective Integrated feature project's bug tracking)

Deliverables
============

Software Deliverables
---------------------

- `Fuel@x86_64 installer script files <https://git.opnfv.org/fuel>`_

- `Fuel@aarch64 installer script files <https://git.opnfv.org/armband>`_

Documentation Deliverables
--------------------------

- Installation instructions

- Release notes (This document)

=========================================
Known Limitations, Issues and Workarounds
=========================================

System Limitations
==================

- **Max number of blades:** 1 Jumpserver, 3 Controllers, 20 Compute blades

- **Min number of blades:** 1 Jumpserver

- **Storage:** Cinder is the only supported storage configuration

- **Max number of networks:** 65k


Known Issues
============

**JIRA TICKETS:**

`Known issues <https://jira.opnfv.org/issues/?filter=12028>`_

(Also See respective Integrated feature project's bug tracking)

Workarounds
===========

**JIRA TICKETS:**

-

(Also See respective Integrated feature project's bug tracking)

============
Test Results
============
The Euphrates 5.0 release with the Fuel deployment tool has undergone QA test
runs, see separate test results.

==========
References
==========
For more information on the OPNFV Euphrates 5.0 release, please see:

OPNFV
=====

1) `OPNFV Home Page <http://www.opnfv.org>`_
2) `OPNFV Documentation <http://docs.opnfv.org>`_
3) `OPNFV Software Downloads <https://www.opnfv.org/software/download>`_

OpenStack
=========

4) `OpenStack Ocata Release Artifacts <http://www.openstack.org/software/ocata>`_

5) `OpenStack Documentation <http://docs.openstack.org>`_

OpenDaylight
============

6) `OpenDaylight Artifacts <http://www.opendaylight.org/software/downloads>`_

Fuel
====

7) `Mirantis Cloud Platform Documentation <https://docs.mirantis.com/mcp/latest>`_
