.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2016 Telefonaktiebolaget L. M. ERICSSON
.. (c) Ferenc Cserepkei <ferenc.cserepkei@ericsson.com>

README SFC + Tacker
===================

     The Enclosed shell script builds, deploys, orchestrates Tacker,
an Open NFV Orchestrator with in-built general purpose VNF Manager
to deploy and operate Virtual Network Functions (VNFs).
      The provided deployment tool is experimental, not fault
tolerant but as idempotent as possible. To use the provided shell
script for provision/deployment, transfer the script to the Openstack
primary controller node,  where Your deployed OpenDaylight SDN
controller runs. The deployment tool (poc.tacker-up.sh), expects that
Your primary controller reaches all your OPNFV/Fuel cluster nodes and
has internet connection either directly or via an http proxy, note
that a working and consistent DNS name resolution is a must.
        Theory of operation: the deployment tool downloads the source
python packages from GitHub and a json rpc library developed by Josh
Marshall. Besides these sources, downloads software for python/debian
software release. When building succeeds the script deploys the software
components to the OPNFV Cluster nodes. Finally orchestrates the deployed
tacker binaries as an infrastucture/service. The Tacker has two
components:
o Tacker server - what interacts with Openstack and OpenDayLight.
o Tacker client - a command line software talks with the server,
                  available on all cluster nodes and the access point
                  to the Tacker service. Note that the tacker
                  distribution provides a a plugin to the Horizon
                  OpenStack Gui, but thus Horizon plugin is out of the
                  scope of this Proof of Concept setup/deployment.
As mentioned, this compilation contains an OpenDayLight SDN controller
with Service Function Chaining and Group based Policy features enabled.

To acces for your cluster information ssh to the fuel master (10.20.0.2)
and issue command: fuel node.
Here is an output of an example deployment:

id | status | name             | cluster | ip        | mac               | roles                            | pending_roles | online | group_id
---|--------|------------------|---------|-----------|-------------------|----------------------------------|---------------|--------|---------
3  | ready  | Untitled (a2:4c) | 1       | 10.20.0.5 | 52:54:00:d3:a2:4c | compute                          |               | True   | 1
4  | ready  | Untitled (c7:d8) | 1       | 10.20.0.3 | 52:54:00:00:c7:d8 | cinder, controller, opendaylight |               | True   | 1
1  | ready  | Untitled (cc:51) | 1       | 10.20.0.6 | 52:54:00:1e:cc:51 | compute                          |               | True   | 1
2  | ready  | Untitled (e6:3e) | 1       | 10.20.0.4 | 52:54:00:0c:e6:3e | compute                          |               | True   | 1
[root@fuel-sfc-virt ~]#

As You can see in this case the poc.tacker-up.sh script should be
transferred and run on node having IP address 10.20.0.3
