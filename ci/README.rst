.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. SPDX-License-Identifier: CC-BY-4.0
.. (c) 2017 Ericsson AB, Mirantis Inc., Enea Software AB and others.

Abstract
========

The ``ci`` directory holds all OPNFV Fuel programatic abstractions for
the OPNFV community release and continuous integration pipeline.
There are now two OPNFV Fuel autonomous scripts for this, complying to the
OPNFV CI pipeline guideline:

- ``build.sh``
- ``deploy.sh``

Usage
=====

For usage information of the CI/CD deploy script, please run:

.. code-block:: console

    jenkins@jumpserver:~/fuel/ci$ ./deploy.sh -h

Details on the CI/CD Deployment Framework
=========================================

Overview and Purpose
--------------------

The CI/CD deployment script relies on a configuration structure, providing:

- per POD specific configuration (defaults to using Pharos OPNFV project
  ``PDF``/``IDF`` files for all OPNFV CI PODs).
  Pharos OPNFV git repository is included as a git submodule at
  ``mcp/scripts/pharos``.
  Optionally, a custom configuration structure can be used via the ``-b``
  deploy argument.
  The POD specific parameters follow the ``PDF``/``IDF`` formats defined by
  the Pharos OPNFV project.
- deployment scenario configuration, part of fuel repo: ``mcp/config/scenario``.
  Provides a high level, POD/HW environment independent scenario configuration
  for a specific deployment. It defines what features shall be deployed - as
  well as needed overrides of the base installer, POD/HW environment
  configurations. Objects allowed to override are governed by the OPNFV Fuel
  project.
- base installer configuration, part of fuel repo: ``mcp/config/states``,
  ``mcp/reclass``.
  The base installer configuration resembles the least common denominator of all
  HW/POD environment and deployment scenarios. These configurations are
  normally carried by the the installer projects in this case (OPNFV Fuel).

Executing a Deployment
----------------------

``deploy.sh`` must be executed locally on the target lab/pod/jumpserver.
A configuration structure must be provided - see the section below.
It is straight forward to execute a deployment task - as an example:

.. code-block:: console

    jenkins@jumpserver:~/fuel/ci$ ./deploy.sh -b file:///home/jenkins/config \
                                              -l lf \
                                              -p pod2 \
                                              -s os-nosdn-nofeature-ha

``-b`` argument should be expressed in URI style (eg: ``file://...`` or
``http://...``). The resources can thus be local or remote.

If ``-b`` is not used, the Pharos OPNFV project git submodule local path URI
is used for the default configuration structure.

Configuration Repository Structure
----------------------------------

The CI deployment engine relies on a configuration directory/file structure
pointed to by the ``-b`` option described above.
Normally this points to the ``mcp/scripts/pharos`` git repo submodule, but you
may point to any local or remote strcture fullfilling the diectory/file
structure below.
This configuration structure supports optional encryption of certain security
sensitive data, mechanism described in the Pharos documentation.

Following configuration directory and file structure should adheare to:

.. code-block:: console

    TOP
    !
    +---- labs
           !
           +---- lab-name-1
           !        !
           !        +---- pod1.yaml
           !        !
           !        +---- idf-pod1.yaml
           !        !
           !        +---- pod2.yaml
           !        !
           !        +---- idf-pod2.yaml
           !
           +---- lab-name-2
           !        !
