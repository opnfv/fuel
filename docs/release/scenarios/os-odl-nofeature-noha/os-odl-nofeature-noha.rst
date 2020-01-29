.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Mirantis Inc., Enea Software AB and others

This document provides scenario level details for Iruya 9.0 of
deployment with OpenDaylight controller.

Introduction
============

This scenario is used primarily to validate and deploy a Stein OpenStack
with OpenDaylight Neon controller enabled.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon. It also installs
OpenDaylight as a SDN controller on the dedicated node.


Scenario usage overview
=======================

Simply deploy this scenario by setting up os-odl-nofeature-noha as scenario
deploy parameter.


Limitations, Issues and Workarounds
===================================

Tested on virtual deploy only.

References
==========

For more information on the OPNFV Iruya release, please visit
https://www.opnfv.org/software
