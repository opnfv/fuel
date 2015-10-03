===========================================================================================
OPNFV Release Note for  the Arno release of OPNFV when using Foreman as a deployment tool
===========================================================================================


.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document provides the release notes for Arno release with the Foreman/QuickStack deployment toolchain.

License
=======

All Foreman/QuickStack and "common" entities are protected by the Apache License ( http://www.apache.org/licenses/ )


Version history
===============

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-04-16         | 0.1.0              | Tim Rozet          | First draft        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-02         | 0.1.1              | Chris Price        | Minor Edits        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-03         | 0.1.2              | Tim Rozet          | Minor Edits        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+

Important notes
===============

This is the initial OPNFV Arno release that implements the deploy stage of the OPNFV CI pipeline.

Carefully follow the installation-instructions which guide a user on how to deploy OPNFV using Foreman/QuickStack installer.

Summary
=======

Arno release with the Foreman/QuickStack deployment toolchain will establish an OPNFV target system on a Pharos compliant lab infrastructure.  The current definition of an OPNFV target system is and OpenStack Juno version combined with OpenDaylight version: Helium.  The system is deployed with OpenStack High Availability (HA) for most OpenStack services.  OpenDaylight is deployed in non-HA form as HA is not availble for Arno release.  Ceph storage is used as Cinder backend, and is the only supported storage for Arno.  Ceph is setup as 3 OSDs and 3 Monitors, one OSD+Mon per Controller node.

- Documentation is built by Jenkins
- .iso image is built by Jenkins
- Jenkins deploys an Arno release with the Foreman/QuickStack deployment toolchain baremetal, which includes 3 control+network nodes, and 2 compute nodes.

Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | genesis                              |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | genesis/arno.2015.1.0                |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | arno.2015.1.0                        |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | 2015-06-04                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Arno release                   |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Version change
--------------

Module version changes
~~~~~~~~~~~~~~~~~~~~~~
This is the first tracked version of the Arno release with the Foreman/QuickStack deployment toolchain. It is based on following upstream versions:

- OpenStack (Juno release)

- OpenDaylight Helium-SR3

- CentOS 7

Document version changes
~~~~~~~~~~~~~~~~~~~~~~~~

This is the first tracked version of Arno release with the Foreman/QuickStack deployment toolchain. The following documentation is provided with this release:

- OPNFV Installation instructions for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.0.0
- OPNFV Release Notes for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.0.0 (this document)

Feature additions
~~~~~~~~~~~~~~~~~

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-4                          | OPNFV base system install            |
|                                      | using Foreman/Quickstack.            |
+--------------------------------------+--------------------------------------+

Bug corrections
~~~~~~~~~~~~~~~

**JIRA TICKETS:**

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
|                                      |                                      |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Deliverables
------------

Software deliverables
~~~~~~~~~~~~~~~~~~~~~
Foreman/QuickStack@OPNFV .iso file
deploy.sh - Automatically deploys Target OPNFV System to Bare Metal

Documentation deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~
- OPNFV Installation instructions for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.0.0
- OPNFV Release Notes for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.0.0 (this document)

Known Limitations, Issues and Workarounds
=========================================

System Limitations
------------------

**Max number of blades:**   1 Foreman/QuickStack master, 3 Controllers, 20 Compute blades

**Min number of blades:**   1 Foreman/QuickStack master, 1 Controller, 1 Compute blade

**Storage:**    Ceph is the only supported storage configuration.

**Min master requirements:** At least 2048 MB of RAM


Known issues
------------

**JIRA TICKETS:**

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-13                         | bridge br-ex is not auto configured  |
|                                      | by puppet                            |
+--------------------------------------+--------------------------------------+

Workarounds
-----------
**-**


Test Result
===========

The Arno release with the Foreman/QuickStack deployment toolchain has undergone QA test runs with the following results:

+--------------------------------------+--------------------------------------+
| **TEST-SUITE**                       | **Results:**                         |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **-**                                | **-**                                |
+--------------------------------------+--------------------------------------+


References
==========

For more information on the OPNFV Arno release, please see:

http://wiki.opnfv.org/release/arno

:Authors: Tim Rozet (trozet@redhat.com)
:Version: 0.2

**Documentation tracking**

Revision: _sha1_

Build date:  _date_

