.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2018 Mirantis Inc., Enea Software AB, Tieto and others

This document provides scenario level details for Hunter
deployment, with no SDN controller, with ONAP deployed on top of OPNFV.


Introduction
============

This scenario is used primarily to deploy a Queens OpenStack deployment,
without any NFV features or SDN controller enabled, with an ONAP deployment
managed by the OPNFV Auto project. This scenario is a "specific" scenario
created from the "generic" scenario os-nosdn-nofeature-ha.


Scenario components and composition
===================================

This scenario is composed of common OpenStack services enabled by default,
including Nova, Neutron, Glance, Cinder, Keystone, Horizon. It also installs
an ONAP deployment, managed by the OPNFV Auto project.

All services are in HA, meaning that there are multiple cloned instances of
each service, and they are balanced by HA Proxy using a Virtual IP Address
per service.


Scenario usage overview
=======================

Simply deploy this scenario by setting os-nosdn-onap-ha as scenario
deploy parameter and refer to the Auto Project documentation for further
setup instructions at https://wiki.opnfv.org/display/AUTO/Auto+Documentation .

Limitations, Issues and Workarounds
===================================

None

References
==========

For more information on the OPNFV Hunter release, please visit
https://www.opnfv.org/software
For setup instructions visit the Auto Project at,
https://wiki.opnfv.org/display/AUTO/Auto+Documentation
