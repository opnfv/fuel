.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) <optionally add copywriters name>

This document provides scenario level details for Euphrates 5.0 of
deployment with no SDN controller and no extra features enabled.

.. contents::
   :depth: 3
   :local:

============
Introduction
============

This scenario is used primarily to validate and deploy a Ocata OpenStack
deployment without any NFV features or SDN controller enabled. This is an
unified documentation for both x86_64 and aarch64 architectures. All
information is common for both architectures except when explicitly stated.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon.

All services are in HA, meaning that there are multiple cloned instances of
each service, and they are balanced by HA Proxy using a Virtual IP Address
per service.


Scenario usage overview
=======================

Simply deploy this scenario by using the os-nosdn-nofeature-ha.yaml deploy
settings file.

Limitations, Issues and Workarounds
===================================

None

References
==========

For more information on the OPNFV Euphrates release, please visit
http://www.opnfv.org/euphrates
