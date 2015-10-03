=============================================================================================
OPNFV Release Notes for the Arno SR1 release of OPNFV when using Foreman as a deployment tool
=============================================================================================


.. contents:: Table of Contents
   :backlinks: none


Abstract
========

This document provides the release notes for Arno SR1 release with the Foreman/QuickStack deployment
toolchain.

License
=======

All Foreman/QuickStack and "common" entities are protected by the Apache License
( http://www.apache.org/licenses/ )


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
| 2015-09-10         | 0.2.0              | Tim Rozet          | Updated for SR1    |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-09-25         | 0.2.1              | Randy Levensalor   | Added Workaround   |
|                    |                    |                    | for DHCP issue     |
+--------------------+--------------------+--------------------+--------------------+


Important notes
===============

This is the OPNFV Arno SR1 release that implements the deploy stage of the OPNFV CI pipeline.

Carefully follow the installation-instructions which guide a user on how to deploy OPNFV using
Foreman/QuickStack installer.

Summary
=======

Arno release with the Foreman/QuickStack deployment toolchain will establish an OPNFV target system on
a Pharos compliant lab infrastructure.  The current definition of an OPNFV target system is and
OpenStack Juno version combined with OpenDaylight version: Helium.  The system is deployed with
OpenStack High Availability (HA) for most OpenStack services.  OpenDaylight is deployed in non-HA form
as HA is not availble for Arno SR1 release.  Ceph storage is used as Cinder backend, and is the only
supported storage for Arno.  Ceph is setup as 3 OSDs and 3 Monitors, one OSD+Mon per Controller node.

- Documentation is built by Jenkins
- .iso image is built by Jenkins
- Jenkins deploys an Arno release with the Foreman/QuickStack deployment toolchain baremetal, which includes 3 control+network nodes, and 2 compute nodes.

Release Data
============

+--------------------------------------+--------------------------------------+
| **Project**                          | genesis                              |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Repo/tag**                         | genesis/arno.2015.2.0                |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release designation**              | arno.2015.2.0                        |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Release date**                     | 2015-09-23                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| **Purpose of the delivery**          | OPNFV Arno SR1 release               |
|                                      |                                      |
+--------------------------------------+--------------------------------------+

Version change
--------------

Module version changes
~~~~~~~~~~~~~~~~~~~~~~
This is the Service Release 1 version of the Arno release with the Foreman/QuickStack deployment
toolchain. It is based on following upstream versions:

- OpenStack (Juno release)

- OpenDaylight Helium-SR3

- CentOS 7

Document version changes
~~~~~~~~~~~~~~~~~~~~~~~~

This is the SR1 version of Arno release with the Foreman/QuickStack deployment toolchain. The following
documentation is provided with this release:

- OPNFV Installation instructions for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 0.2.0
- OPNFV Release Notes for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 0.2.0 (this document)

Feature additions
~~~~~~~~~~~~~~~~~

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-73                         | Changes Virtual deployments to       |
|                                      | only require 1 interface, and adds   |
|                                      | accesbility in China                 |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-75                         | Adds ability to specify number of    |
|                                      | floating IPs                         |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-3                         | clean now removes all VMs            |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-4                         | Adds ability to specify NICs to      |
|                                      | bridge to on the jumphost            |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-86                         | Adds ability to specify domain name  |
|                                      | for deployment                       |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-1                         | Adds ability to specify VM resources |
|                                      | such as disk size, memory, vcpus     |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-33                        | Adds ability to use single interface |
|                                      | for baremetal installs               |
+--------------------------------------+--------------------------------------+

Bug corrections
~~~~~~~~~~~~~~~

**JIRA TICKETS:**

+--------------------------------------+--------------------------------------+
| **JIRA REFERENCE**                   | **SLOGAN**                           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-65                         | Fixes external network bridge and    |
|                                      | increases neutron quota limits       |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-74                         | Fixes verification of vbox drivers   |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-59                         | Adds ODL Deployment stack docs to    |
|                                      | Foreman Guide                        |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-60                         | Migrates github bgs_vagrant project  |
|                                      | into Genesis                         |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-89                         | Fixes public allocation IP           |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-71                         | Adds check to ensure subnets are the |
|                                      | minimum size required                |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-78                         | Fixes Foreman clean to not hang and  |
|                                      | now also removes libvirt             |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-7                         | Adds check to make sure 3 control    |
|                                      | nodes are set when HA is enabled     |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-68                         | Adds check to make sure baremetal    |
|                                      | nodes are powered off when deploying |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-14                        | Fixes Vagrant base box to be opnfv   |
|                                      |                                      |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-8                         | Fixes puppet modules to come from    |
|                                      | the Genesis repo                     |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-17                        | Fixes clean to kill vagrant processes|
|                                      | correctly                            |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-2                         | Removes default vagrant route from   |
|                                      | virtual nodes                        |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-9                         | Fixes external network to be created |
|                                      | by the services tenant               |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-10                        | Disables DHCP on external neutron    |
|                                      | network                              |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-19                        | Adds check to ensure provided arg    |
|                                      | static_ip_range is correct           |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-12                        | Fixes horizon IP URL for non-HA      |
|                                      | deployments                          |
+--------------------------------------+--------------------------------------+
| JIRA: BGS-84                         | Set default route to public          |
|                                      | gateway                              |
+--------------------------------------+--------------------------------------+

Deliverables
------------

Software deliverables
~~~~~~~~~~~~~~~~~~~~~
Foreman/QuickStack@OPNFV .iso file
deploy.sh - Automatically deploys Target OPNFV System to Bare Metal or VMs

Documentation deliverables
~~~~~~~~~~~~~~~~~~~~~~~~~~
- OPNFV Installation instructions for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.2.0
- OPNFV Release Notes for the Arno release with the Foreman/QuickStack deployment toolchain - ver. 1.2.0 (this document)

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
| JIRA: APEX-13                        | Keystone Config: bind host is wrong  |
|                                      | for admin user                       |
+--------------------------------------+--------------------------------------+
| JIRA: APEX-38                        | Neutron fails to provide DHCP address|
|                                      | to instance                          |
+--------------------------------------+--------------------------------------+

Workarounds
-----------
**-**
JIRA: APEX-38 - Neutron fails to provide DHCP address to instance

1. Find the controller that is running the DHCP service.  ssh to oscontroller[1-3] and
   run the command below until the command returns a namespace that start with with "qdhcp".

  ``ip netns | grep qdhcp``

2. Restart the neturon server and the neutron DHCP service.

  ``systemctl restart neutron-server``

  ``systemctl restart neutron-dhcp-agent``

3. Restart the interface on the VM or restart the VM.


Test Result
===========

The Arno release with the Foreman/QuickStack deployment toolchain has undergone QA test runs with the
following results:

https://wiki.opnfv.org/arno_sr1_result_page?rev=1443626728

References
==========

For more information on the OPNFV Arno release, please see:

http://wiki.opnfv.org/release/arno

:Authors: Tim Rozet (trozet@redhat.com)
:Version: 0.2

**Documentation tracking**

Revision: _sha1_

Build date:  _date_

