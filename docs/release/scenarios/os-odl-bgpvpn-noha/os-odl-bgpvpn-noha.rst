.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Intracom Telecom and others

This document provides scenario level details for Gambia 7.1 of
deployment with OpenDaylight controller and Neutron BGP VPN plugin enabled.

Introduction
============

This scenario is used primarily to validate and deploy a Queens OpenStack
deployment with Neutron BGP VPN plugin and OpenDaylight Fluorine controller
enabled.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon. It also installs
the Neutron BGP VPN plugin along with OpenDaylight as a SDN controller on the
dedicated node. Finally, it deploys Quagga on the same node with Opendaylight.


Scenario usage overview
=======================

Simply deploy this scenario by setting up os-odl-bgpvpn-noha as scenario
deploy parameter.


Limitations, Issues and Workarounds
===================================

Tested on virtual deployment only.

References
==========

For more information on the OPNFV Gambia release, please visit
https://www.opnfv.org/software
