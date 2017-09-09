.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2017 Ericsson AB, Mirantis Inc., Enea Software AB and others.
.. (c) 2017 stefan.k.berg@ericsson.com
.. (c) 2017 jonas.bjurel@ericsson.com

Abstract
========
The fuel/ci directory holds all Fuel@OPNFV programatic abstractions for
the OPNFV community release and continous integration pipeline.
There is now only one Fuel@OPNFV autonomous script for this, complying to the
OPNFV CI pipeline guideline:
 - deploy.sh

USAGE
=====
For usage information of the CI/CD scripts, please run:
./deploy.sh -h

Details on the CI/CD deployment framework
=========================================

Overview and purpose
--------------------
The CI/CD deployment script relies on a configuration structure, providing base
installer configuration (part of fuel repo: mcp/config), per POD specific
configuration (part of a separate classified POD configuration repo: securedlab
and deployment scenario configuration (part of fuel repo: mcp/config/scenario).

- The base installer configuration resembles the least common denominator of all
  HW/POD environment and deployment scenarios. These configurations are
  normally carried by the the installer projects in this case (Fuel@OPNFV).
- Per POD specific configuration specifies POD unique parameters, the POD
  parameter possible to alter is governed by the Fuel@OPNFV project.
- Deployment scenario configuration - provides a high level, POD/HW environment
  independent scenario configuration for a specifiv deployment. It defines what
  features shall be deployed - as well needed overrides of the base
  installer, POD/HW environment configurations. Objects allowed to override
  are governed by the Fuel@OPNFV project.

Executing a deployment
----------------------
deploy.sh must be executed locally at the target lab/pod/jumpserver
A configuration structure must be provided - see the section below.
It is straight forward to execute a deployment task - as an example:
$ sudo deploy.sh -b file:///home/jenkins/config \
  -l lf -p pod2 -s os-nosdn-nofeature-ha

-b and -i arguments should be expressed in URI style (eg: file://...
or http://...). The resources can thus be local or remote.

Configuration repository structure
----------------------------------
The CI deployment engine relies on a configuration directory/file structure
pointed to by the -b option described above.
Normally this points to the secure classified OPNFV securedlab repo to which
only jenkins and andmins have access to, but you may point to any local or
remote strcture fullfilling the diectory/file structure below.
The reason that this configuration structure needs to be secure/hidden
is that there are security sensitive information in the various configuration
files.

FIXME: Below information is out of date and should be refreshed after PDF
support is fully implemented.

A local stripped version of this configuration structure with virtual
deployment configurations also exist under build/config/.
Following configuration directory and file structure should adheare to:

TOP
!
+---- labs
       !
       +---- lab-name-1
       !        !
       !        +---- pod-name-1
       !        !        !
       !        !        +---- fuel
       !        !               !
       !        !               +---- config
       !        !                       !
       !        !                       +---- dea-pod-override.yaml
       !        !                       !
       !        !                       +---- dha.yaml
       !        !
       !        +---- pod-name-2
       !                 !
       !
       +---- lab-name-2
       !        !


Creating a deployment scenario
------------------------------
Please find deploy/scenario/README for instructions on how to create a new
deployment scenario.
