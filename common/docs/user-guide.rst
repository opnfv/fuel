=====================================
OPNFV User Guide for the Arno release
=====================================

Abstract
========

This document provides an overview of how to use the Arno release of OPNFV once the system has been successfully deployed to a Pharos compliant infrastructure.

License
=======

OPNFV User Guide for the Arno release (c) by Christopher Price (christopher.price@ericsson.com)

OPNFV User Guide for the Arno release is licensed under a Creative Commons Attribution 4.0 International License. You should have received a copy of the license along with this. If not, see <http://creativecommons.org/licenses/by/4.0/>.

Version history
===================

+--------------------+--------------------+--------------------+--------------------+
| **Date**           | **Ver.**           | **Author**         | **Comment**        |
|                    |                    |                    |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-04         | 1.0.0              | Christopher Price  | Initial revision   |
|                    |                    | (Ericsson AB)      |                    |
+--------------------+--------------------+--------------------+--------------------+
| 2015-06-05         | 1.0.1              | Christopher Price  | Corrected links &  |
|                    |                    | (Ericsson AB)      | e-mail address     |
+--------------------+--------------------+--------------------+--------------------+

.. contents:: Table of Contents
   :backlinks: none


Introduction
============

This document provides a rudimentary user guide for the OPNFV Arno release.  The Arno release is the initial iteration of the OPNFV project and should be used as a developmental platform if you are interested in participating in the community and providing feedback.

The Arno release is not intended to be used in production environments.  It is an initial, experimental, release intended to provide a foundation on which the OPNFV project can evaluate platform capabilities and develop further capabilities.  It is possible that some expected features in the platform may not perform as desired, if you find these types of issue in the platform please report them to support@opnfv.org so that we can resolve them in future releases.

Preface
=======

The Arno release of OPNFV is derived exclusively from open source development activities.  As such the functions, capabilities and user interfaces of the platform derive directly from those upstream sources as well.  The OPNFV project intends to work cooperatively and in conjunction with these projects, awareness of the components and their roles in the platform is important when attempting to use the platform.

 - In the Arno release OpenStack Juno is used as the virtual infrastructure management component.  When operating the Arno release you will most often be interacting with the provided OpenStack interfaces.
 - Application deployment on the stack can be performed directly on the OpenStack interfaces or by using the Heat interfaces provided.
 - If you intend to perform actions on the networking component of the stack the Arno release uses OpenDaylight Helium.  The interfaces for OpenDaylight are available for checking topology and interacting with the OpenDaylight SDN controller.
 - Additional interfaces are provided by the Linux operating systems.  The Arno release supports either Centos 7.1 or Ubuntu 14.4 operating systems.

Details of operating these interfaces are explained later in the document.

Prerequisites
=============

Hardware Requirements
---------------------

The Arno release of OPNFV is intended to be run as a baremetal deployment on a "Pharos compliant" lab infrastructure.  The Pharos project in OPNFV is a community activity to provide guidance and establish requirements on hardware platforms supporting the Arno virtualisation platform.

Prior to deploying the OPNFV platform it is important that the hardware infrastructure be configured according to the Pharos specification: https://www.opnfv.org/sites/opnfv/files/release/pharos-spec.arno.2015.1.0.pdf

Arno Platform Deployment
------------------------

The Arno platform supports installation and deployment using two deployment tools; a Foreman based deployment toolchain and a Fuel based deployment toolchain.

In order to deploy the Arno release on a Pharos compliant lab using the Foreman deployment toolchain you should follow in the Foreman installation guide: https://www.opnfv.org/sites/opnfv/files/release/foreman_install-guide.arno.2015.1.0.pdf

In order to deploy the Arno release on a Pharos compliant lab using the Fuel deployment toolchain you should follow in the Fuel installation guide: https://www.opnfv.org/sites/opnfv/files/release/install-guide.arno.2015.1.0.pdf

Enabling or disabling OpenDaylight and the native Neutron driver
----------------------------------------------------------------

You may find that you wish to adjust the system by enabling or disabling the native OpenStack Neutron driver depending on the tasks you are trying to achieve with the platform.  Each of the deployment tools has the option to deploy with or without OpenDaylight enabled.  Details of the available delpoyment options can be found in the associated installation-instructions, please note the platform validation procedures expect a fully deployed platform and results may vary depending on the options selected.

Deployment Validation
---------------------

Once installed you should validate the deployment completed successfully by executing the automated basic platform validation routines outlined in the Arno testing documentation: https://www.opnfv.org/sites/opnfv/files/release/functest.arno.2015.1.0.pdf

Operating the Arno platform
===========================

The Arno release provides a platform for deploying software on virtual infrastructure.  The majority of operations to be executed on the platform revolve around deploying, managing and removing software (applications) on the platform itself.  Application deployment is covered in the following sections, however some platform operations you may want to perform include setting up a tenant, in OpenStack tenants are also known as projects in this document we will refer to them as tenants, and associated users for that tenant.

OpenStack provides a good overview of how to create your first tenant for deploying your applications.  You should create a tenant for your applications, associate users with the tenant and assign quota's.
 - Open the OpenStack console (Horizon) you should find this by logging into your control node; for example to access the console of POD1 of the OPNFV lab you would browse to <172.30.9.70:80>
 - Create your tenant and users by following the instructions at: http://docs.openstack.org/openstack-ops/content/projects_users.html

Further actions and activities for checking logs and status can be found in other areas of the operations document: http://docs.openstack.org/openstack-ops/content/openstack-ops_preface.html


Deploying your applications on Arno
===================================

Most actions you will want to perform can be executed from the OpenStack dashboard.  When deploying your application on Arno a good reference is the user-guide which describe uploading, managing and deploying your application images.

 - Make sure you have established your tenant, associated users and quota's
 - Follow the guidelines for managing and deploying your images in the following user-guide: http://docs.openstack.org/user-guide/dashboard.html


Frequently Asked Questions
==========================

Does OPNFV provide support for the Arno release?
------------------------------------------------

The Arno release of OPNFV is intended to be a developmental release and is not considered suitable for production deployment or at scale testing activities.  As a developmental release, and in the spirit of collaborative development, we want as much feedback from the community as possible on your experiences with the platform and how the release can be improved.

Support for Arno is provided in two ways:

You can engage with the community to help us improve and further develop the OPNFV platform by raising Jira Bugs or Tasks, and pushing correction patches to our repositories.

 - To access Jira for issue reporting or improvement proposals head to: https://jira.opnfv.org/
 - To get started helping out developing the platform head to: https://wiki.opnfv.org/developer

Alternatively if you are intending to invest your time as a user of the platform you can ask questions and request help from our mailing list at: mailto://opnfv-users@lists.opnfv.org

License
=======

All Arno entities are protected by the `Apache 2.0 License <http://www.apache.org/licenses/>`_.
Arno platform components and their licences are described in their respective Release Notes: http://artifacts.opnfv.org/genesis/foreman/docs/release-notes.html and http://artifacts.opnfv.org/genesis/fuel/docs/release-notes.html

References
==========

OpenStack
---------

`OpenStack Admin User Guide <http://docs.openstack.org/user-guide-admin/>`_

OpenDaylight
------------

`OpenDaylight User Guide <https://www.opendaylight.org/sites/opendaylight/files/User-Guide-Helium-SR2.pdf>`_

Foreman
-------

`Foreman User Manual <http://theforeman.org/manuals/1.7/index.html>`_

Fuel
----

`Fuel User Guide <http://docs.fuel-infra.org/openstack/fuel/fuel-6.0/user-guide.html>`_

:Authors: Christopher Price (christopher.price@ericsson.com)
:Version: 1.0.1

**Documentation tracking**

Revision: _sha1_

Build date:  _date_

