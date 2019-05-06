.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Mirantis Inc., Enea Software AB and others

This document provides scenario level details for Hunter 8.0 of deployment
with Open Virtual Network (OVN) providing Layers 2 and 3 networking and no
extra features enabled.

Introduction
============

This scenario is used primarily to validate and deploy a Queens OpenStack
deployment with OVN enabled and without any NFV features.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon, plus OVN.


Scenario usage overview
=======================

Simply deploy this scenario by setting os-ovn-nofeature-noha as scenario
deploy parameter.


Limitations, Issues and Workarounds
===================================

Tested on virtual deploy only.

References
==========

For more information on the OPNFV Hunter release, please visit
https://www.opnfv.org/software
