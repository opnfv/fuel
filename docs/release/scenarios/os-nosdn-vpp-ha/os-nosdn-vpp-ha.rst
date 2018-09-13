.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Mirantis Inc., Enea Software AB and others

This document provides scenario level details for Gambia 7.0 of
deployment with no SDN controller and VPP enabled as virtual switch.

============
Introduction
============

This scenario is used primarily to validate and deploy a Queens OpenStack
deployment with no SDN controller enabled and VPP as virtual switch.

Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon. It also installs
VPP on the compute nodes as virtual switch.

All services are in HA, meaning that there are multiple cloned instances of
each service, and they are balanced by HA Proxy using a Virtual IP Address
per service.


Scenario usage overview
=======================

Simply deploy this scenario by setting os-nosdn-vpp-ha as scenario
deploy parameter.

Limitations, Issues and Workarounds
===================================

None

References
==========

For more information on the OPNFV Gambia release, please visit
https://www.opnfv.org/software
