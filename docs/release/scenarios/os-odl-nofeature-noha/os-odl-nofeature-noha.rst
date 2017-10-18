.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) <optionally add copywriters name>

This document provides scenario level details for Euphrates 5.0 of
deployment with the OpenDaylight SDN controller and no extra features enabled.

.. contents::
   :depth: 3
   :local:

============
Introduction
============

This scenario is used primarily to validate and deploy a Ocata OpenStack
deployment with OpenDaylight, and without any NFV features enabled.

Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon.

Only a single controller is deployed in this scenario, which also includes
the OpenDaylight service on it.

Scenario usage overview
=======================

Simply deploy this scenario by using the os-odl-nofeature-noha.yaml deploy
settings file.

Limitations, Issues and Workarounds
===================================

Tested on virtual deploy only.

References
==========

For more information on the OPNFV Euphrates release, please visit
http://www.opnfv.org/euphrates
