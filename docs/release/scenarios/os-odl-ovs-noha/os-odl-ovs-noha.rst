.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Mirantis Inc., Enea Software AB and others

This document provides scenario level details for Hunter 8.1 of
deployment with OpenDaylight controller and DPDK feature enabled.

Introduction
============

This scenario is used primarily to validate and deploy a Queens OpenStack
deployment with DPDK feature and OpenDaylight Fluorine controller enabled.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon. It also installs
the DPDK-enabled Open vSwitch component along with OpenDaylight as a SDN
controller on the dedicated node.


Scenario usage overview
=======================

Simply deploy this scenario by setting up os-odl-ovs-noha as scenario
deploy parameter.


Limitations, Issues and Workarounds
===================================

Tested on virtual deploy only.

References
==========

For more information on the OPNFV Hunter release, please visit
https://www.opnfv.org/software
