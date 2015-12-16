=========================================================================================
OPNFV Release Note for the Arno SR1 release of OPNFV when using Fuel as a deployment tool
=========================================================================================


.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document compiles the release notes for the Arno SR1 release of
OPNFV when using Fuel as a deployment tool.

License
=======

Arno SR1 release with the Fuel deployment tool Docs (c) by Jonas
Bjurel (Ericsson AB)

Arno SR1 release with the Fuel deployment tool Docs are licensed under
a Creative Commons Attribution 4.0 International License. You should
have received a copy of the license along with this. If not, see
<http://creativecommons.org/licenses/by/4.0/>.


Version history
===============

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 1.0.0              | Jonas Bjurel       | Arno SR0 release   |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-09-28         | 1.1.3              | Jonas Bjurel       | Arno SR1 release   |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+

Important notes
===============

For the first OPNFV release (Arno), these notes introduce use of
`OpenStack Fuel <https://wiki.openstack.org/wiki/Fuel>` for the
deployment stage of the OPNFV continuous integration (CI) pipeline.
The goal of the Arno release and this Fuel-based deployment process is
to establish a foundational platform accelerating further development
of the OPNFV infrastructure.


Carefully follow the installation-instructions and pay special
attention to the pre-deploy script that needs to be run before
deployment is started.


Summary
=======

For Arno SR1, the typical use of Fuel as an OpenStack installer is
supplemented with OPNFV unique components such as `OpenDaylight
<http://www.opendaylight.org/software>`_ version Helium as well as
OPNFV-unique configurations.


This Arno artefact provides Fuel as the deployment stage tool in the
OPNFV CI pipeline including:


- Documentation built by Jenkins
  - this document (release notes)
  - installation instructions
  - build-instructions
- The Arno Fuel installer image (.iso) built by Jenkins
- Automated deployment of Arno with running on bare metal or a nested
  hypervisor environment (KVM)
- Automated validation of the Arno deployment


Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | genesis/bgs                          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | genesis/arno.2015.2.0                |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | Arno Base Service release 1 (SR1)    |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | 2015-10-01                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Arno Base SR1 release          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Version change
--------------

Module version changes
~~~~~~~~~~~~~~~~~~~~~~
This is the second tracked release of genesis/fuel. It is based on
following upstream versions:

- Fuel 6.1.0
- OpenStack Juno release
- OpenDaylight Litium release

Document version changes
~~~~~~~~~~~~~~~~~~~~~~~~
This is the second tracked version of the fuel installer for OPNFV. It
comes with the following documentation:

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
| JIRA: FUEL-4                         | Baselining Fuel 6.0.1 for OPNFV      |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: FUEL-17                        | Integration of OpenDaylight          |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Bug corrections
~~~~~~~~~~~~~~~

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

Deliverables
------------

Software deliverables
~~~~~~~~~~~~~~~~~~~~~
Fuel-based installer iso file <arno.2015.2.0.fuel.iso>

Documentation deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~
- OPNFV Installation instructions for Arno release with the Fuel
  deployment tool - ver. 1.1.0
- OPNFV Build instructions for Arno release with the Fuel deployment
  tool - ver. 1.1.0
- OPNFV Release Note for Arno release with the Fuel deployment tool -
  ver. 1.1.3 (this document)

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
| JIRA: FUEL-43                        | VMs not accessible through SSH due   |
|                                      | to VXLAN 50 Byte overhead and lack   |
|                                      | of proper MTU value setting on       |
|                                      | virtual ethernet devices             |
+--------------------------------------+--------------------------------------+
| JIRA: FUEL-44                        | Centos 6.5 option has not been       |
|                                      | enough verified                      |
+--------------------------------------+--------------------------------------+


Workarounds
-----------
See JIRA: `FUEL-43 <https://jira.opnfv.org/browse/FUEL-43>`


Test Result
===========
Arno SR1 release with the Fuel deployment tool has undergone QA test
runs with the following results:
https://wiki.opnfv.org/arno_sr1_result_page?rev=1443626728

References
==========
For more information on the OPNFV Arno release, please see
http://wiki.opnfv.org/releases/arno.

:Authors: Jonas Bjurel (Ericsson)
:Version: 1.1.3

**Documentation tracking**

Revision: _sha1_

Build date:  _date_
