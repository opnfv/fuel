.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2017 Mirantis Inc., Enea AB and others.

Fuel@OPNFV Cluster Reclass Models
=================================

Overview
--------

#. Common classes (baremetal + virtual)

   - all-mcp-arch-common

#. Common classes (specific to either baremetal or virtual deploys)

   - baremetal-mcp-<release>-common-ha
   - virtual-mcp-<release>-common-noha

#. Cluster specific classes

   - baremetal-mcp-<release>-*-{ha,noha}
   - virtual-mcp-<release>-*-{ha,noha}
