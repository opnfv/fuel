.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

========
Abstract
========

This document contains details about how to use OPNFV Fuel - Euphrates
release - after it was deployed. For details on how to deploy check the
installation instructions in the :ref:`references` section.

This is an unified documentation for both x86_64 and aarch64
architectures. All information is common for both architectures
except when explicitly stated.



================
Network Overview
================

Fuel uses several networks to deploy and administer the cloud:

+------------------+-------------------+---------------------------------------------------------+
| Network name     | Deploy Type       | Description                                             |
|                  |                   |                                                         |
+==================+===================+=========================================================+
| **PXE/ADMIN**    | baremetal only    | Used for booting the nodes via PXE                      |
+------------------+-------------------+---------------------------------------------------------+
| **MCPCONTROL**   | baremetal &       | Used to provision the infrastructure VMs (Salt & MaaS). |
|                  | virtual           | On virtual deploys, it is used for PXE too (on target   |
|                  |                   | VMs) leaving the PXE bridge unused                      |
+------------------+-------------------+---------------------------------------------------------+
| **Mgmt**         | baremetal &       | Used for internal communication between                 |
|                  | virtual           | OpenStack components                                    |
+------------------+-------------------+---------------------------------------------------------+
| **Internal**     | baremetal &       | Used for VM data communication within the               |
|                  | virtual           | cloud deployment                                        |
+------------------+-------------------+---------------------------------------------------------+
| **Public**       | baremetal &       | Used to provide Virtual IPs for public endpoints        |
|                  | virtual           | that are used to connect to OpenStack services APIs.    |
|                  |                   | Used by Virtual machines to access the Internet         |
+------------------+-------------------+---------------------------------------------------------+


These networks - except mcpcontrol - can be linux bridges configured before the deploy on the
Jumpserver. If they don't exists at deploy time, they will be created by the scripts as virsh
networks.

Mcpcontrol exists only on the Jumpserver and needs to be virtual because a DHCP server runs
on this network and associates static host entry IPs for Salt and Maas VMs.



===================
Accessing the cloud
===================

Access to any component of the deployed cloud is done from Jumpserver to user *ubuntu* with
ssh key */var/lib/opnfv/mcp.rsa*. The example below is a connection to Salt master.

   .. code-block:: bash

       $ ssh -o StrictHostKeyChecking=no -i  /var/lib/opnfv/mcp.rsa  -l ubuntu 10.20.0.2

The Fuel baremetal deploy has a Virtualized Control Plane (VCP) which means that the controller
services are installed in VMs on the baremetal targets (kvm servers). These VMs can also be
accessed with virsh console: user *opnfv*, password *opnfv_secret*. This method does not apply
to infrastructure VMs (Salt master and MaaS).

The example below is a connection to a controller VM. The connection is made from the baremetal
server kvm01.

   .. code-block:: bash

       $ ssh -o StrictHostKeyChecking=no -i  /var/lib/opnfv/mcp.rsa  -l ubuntu 10.167.4.141
       ubuntu@kvm01:~$ virsh console ctl01
       Connected to domain cfg01
       Escape character is ^]
       Ubuntu 16.04.3 LTS cfg01 ttyAMA0
       ctl01 login: opnfv
       Password:
       ubuntu@ctl01:~$

Both *opnfv* and *ubuntu* users have sudo rights.



=============================
Exploring the cloud with Salt
=============================

To gather information about the cloud, the salt commands can be used. It is based
around a master-minion idea where the salt-master, pushes config to the minions to
execute actions.

For example tell salt to execute in all the nodes, rand_sleep action with 120 as an argument.

.. figure:: img/saltstack.png

Some examples are listed below. Note that these commands are issued from Salt master
with *root* user.

#. View the IPs of all the components

   .. code-block:: bash

       root@cfg01:~$ salt "*" network.ip_addrs
       cfg01.baremetal-mcp-ocata-odl-ha.local:
           - 10.20.0.2
           - 172.16.10.100
       mas01.baremetal-mcp-ocata-odl-ha.local:
           - 10.20.0.3
           - 172.16.10.3
           - 192.168.11.3
        .........................


#. View the interfaces of all the components and put the output in a file with yaml format

   .. code-block:: bash

       root@cfg01:~$ salt "*" network.interfaces --out yaml --output-file interfaces.yaml
       root@cfg01:~# cat interfaces.yaml
       cfg01.baremetal-mcp-ocata-odl-ha.local:
         enp1s0:
           hwaddr: 52:54:00:72:77:12
           inet:
           - address: 10.20.0.2
             broadcast: 10.20.0.255
             label: enp1s0
             netmask: 255.255.255.0
           inet6:
           - address: fe80::5054:ff:fe72:7712
             prefixlen: '64'
             scope: link
           up: true
        .........................

#. View installed packages in MaaS node

  .. code-block:: bash

      root@cfg01:~# salt "mas*" pkg.list_pkgs
      mas01.baremetal-mcp-ocata-odl-ha.local:
          ----------
          accountsservice:
              0.6.40-2ubuntu11.3
          acl:
              2.2.52-3
          acpid:
              1:2.0.26-1ubuntu2
          adduser:
              3.113+nmu3ubuntu4
          anerd:
              1
        .........................

#. Execute any linux command on all nodes (list the content of */var/log* in this example)

  .. code-block:: bash

     root@cfg01:~# salt "*" cmd.run 'ls /var/log'
     cfg01.baremetal-mcp-ocata-odl-ha.local:
         alternatives.log
         apt
         auth.log
         boot.log
         btmp
         cloud-init-output.log
         cloud-init.log
        .........................


For more information about Salt see the :ref:`references` section.



===================
Accessing openstack
===================

Once the deployment is complete, Openstack CLI is accessible from controller VMs (ctl01..03).
Openstack credentials are at */root/keystonercv3*.

 .. code-block:: bash

    root@ctl01:~# source keystonercv3
    root@ctl01:~# openstack image list
    +--------------------------------------+-----------------------------------------------+--------+
    | ID                                   | Name                                          | Status |
    +--------------------------------------+-----------------------------------------------+--------+
    | 152930bf-5fd5-49c2-b3a1-cae14973f35f | CirrosImage                                   | active |
    | 7b99a779-78e4-45f3-9905-64ae453e3dcb | Ubuntu16.04                                   | active |
    +--------------------------------------+-----------------------------------------------+--------+


The OpenStack Dashboard, Horizon is available at http://<controller VIP>:8078, e.g. http://10.16.0.101:8078.
The administrator credentials are *admin*/*opnfv_secret*.

.. figure:: img/horizon_login.png


.. _references:

==========
References
==========

1) `Installation instructions <http://docs.opnfv.org/en/stable-euphrates/submodules/fuel/docs/release/installation/installation.instruction.html>`_
2) `Saltstack Documentation <https://docs.saltstack.com/en/latest/topics>`_
3) `Saltstack Formulas <http://salt-formulas.readthedocs.io/en/latest/develop/overview-reclass.html>`_


