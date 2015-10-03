=====================================================================================
OPNFV Release Note for the Arno release of OPNFV when using Fuel as a deployment tool
=====================================================================================


.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document compiles the release notes for the Arno release of OPNFV when using Fuel as a deployment tool.

License
=======

Arno release with the Fuel deployment tool Docs (c) by Jonas Bjurel (Ericsson AB)

Arno release with the Fuel deployment tool Docs are licensed under a Creative Commons Attribution 4.0 International License. You should have received a copy of the license along with this. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Version history
===============

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 1.0.0              | Jonas Bjurel       | Arno SR0 release   |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+

Important notes
===============

For the first OPNFV release (Arno), these notes introduce use of `OpenStack Fuel <https://wiki.openstack.org/wiki/Fuel>` for the deployment stage of the OPNFV continuous integration (CI) pipeline.  The goal of the Arno release and this Fuel-based deployment process is to establish a foundational platform accelerating further development of the OPNFV infrastructure.

Carefully follow the installation-instructions and pay special attention to the pre-deploy script that needs to be run before deployment is started.

Summary
=======

For Arno, the typical use of Fuel as an OpenStack installer is supplemented with OPNFV unique components such as `OpenDaylight <http://www.opendaylight.org/software>`_ version Helium as well as OPNFV-unique configurations.

This Arno artefact provides Fuel as the deployment stage tool in the OPNFV CI pipeline including:

- Documentation built by Jenkins
  - this document (release notes)
  - installation instructions
  - build-instructions
- The Arno Fuel installer image (.iso) built by Jenkins
- Automated deployment of Arno with running on bare metal or a nested hypervisor environment (KVM)
- Automated validation of the Arno deployment


Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | genesis/bgs                          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | genesis/arno.2015.1.0                |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | Arno Base Service release 0 (SR0)    |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | 2015-06-04                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Arno Base SR0 release          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Version change
--------------

Module version changes
~~~~~~~~~~~~~~~~~~~~~~
This is the first tracked release of genesis/fuel. It is based on following upstream versions:

- Fuel 6.0.1
- OpenStack Juno release
- OpenDaylight Helium-SR3

Document version changes
~~~~~~~~~~~~~~~~~~~~~~~~
This is the first tracked version of the fuel installer for OPNFV. It comes with the following documentation:

- OPNFV Installation instructions for Arno with Fuel as deployment tool
- OPNFV Release Notes for Arno use of Fuel as deployment tool
- OPNFV Build instructions for Arno with Fuel as deployment tool


Reason for version
------------------
Feature additions
~~~~~~~~~~~~~~~~~

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA:-                               | Baselining Fuel 6.0.1 for OPNFV      |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA:-                               | Integration of OpenDaylight          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Bug corrections
~~~~~~~~~~~~~~~

**JIRA TICKETS:**

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
|                                      |                                      |
| -                                    | -                                    |
+--------------------------------------+--------------------------------------+

Deliverables
------------

Software deliverables
~~~~~~~~~~~~~~~~~~~~~
Fuel-based installer iso file <arno.2015.1.0.fuel.iso>

Documentation deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~
- OPNFV Installation instructions for Arno release with the Fuel deployment tool - ver. 1.0.0
- OPNFV Build instructions for Arno release with the Fuel deployment tool - ver. 1.0.0
- OPNFV Release Note for Arno release with the Fuel deployment tool - ver. 1.0.0 (this document)

Known Limitations, Issues and Workarounds
=========================================

System Limitations
------------------

**Max number of blades:**   1 Fuel master, 3 Controllers, 20 Compute blades

**Min number of blades:**   1 Fuel master, 1 Controller, 1 Compute blade

**Storage:**    Ceph is the only supported storage configuration.

**Max number of networks:**   3800 (Needs special switch config.)


Known issues
------------

**JIRA TICKETS:**

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-57                         | The OpenDaylight Helium release is   |
|                                      | not fully functional and the         |
|                                      | resulting Fuel integration is not    |
|                                      | able to cope with the deficiancies.  |
|                                      | It is therefore not recommended to   |
|                                      | to enable this option.               |
|                                      | A functional integration of ODL      |
|                                      | version: Lithium is expected to be   |
|                                      | available in an upcomming service    |
|                                      | release.                             |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Workarounds
-----------
Current workaround for the JIRA: BGS-57 is not to enable OpenDaylight networking - see installation instructions.  


Test Result
===========

Arno release with the Fuel deployment tool has undergone QA test runs with the following results:

+--------------------------------------+--------------------------------------+
| **TEST-SUITE**                       | **Results:**                         |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| Tempest test suite 1:                | 27 out of 105 testcases fails        |
|                                      | see note (1) and note (2)            |
+--------------------------------------+--------------------------------------+
| Tempest test suite 2:                | 26 out of 100 testcases fails        |
|                                      | see note (1) and note (2)            |
+--------------------------------------+--------------------------------------+
| Tempest test suite 3:                | 14 out of 106 testcases fails        |
|                                      | see note (1) and note (2)            |
+--------------------------------------+--------------------------------------+
| Rally test suite suie 1:             | 10 out of 18 testcases fails         |
|                                      | see note (1) and note (3)            |
+--------------------------------------+--------------------------------------+
| ODL test suite suie                  | 7 out of 7 testcases fails           |
|                                      | see note (1) and note (4)            |
+--------------------------------------+--------------------------------------+
| vPING                                | OK                                   |
|                                      | see note (1)                         |
+--------------------------------------+--------------------------------------+

** - Note (1): Have been run with ODL controller active but not with integrated ODL networking VXLAN segmentation activated **
** - Note (2): see https://wiki.opnfv.org/r1_tempest **
** - Note (3): see https://wiki.opnfv.org/r1_rally_bench **
** - Note (4): see https://wiki.opnfv.org/r1_odl_suite **

References
==========
For more information on the OPNFV Arno release, please see http://wiki.opnfv.org/releases/arno.

:Authors: Jonas Bjurel (Ericsson)
:Version: 1.0.0

**Documentation tracking**

Revision: _sha1_

Build date:  _date_
