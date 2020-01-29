.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) Open Platform for NFV Project, Inc. and its contributors

***********************************
OPNFV Fuel Installation Instruction
***********************************

Abstract
========

This document describes how to install the ``Iruya`` release of
OPNFV when using Fuel as a deployment tool, covering its usage,
limitations, dependencies and required system resources.

This is an unified documentation for both ``x86_64`` and ``aarch64``
architectures. All information is common for both architectures
except when explicitly stated.

Introduction
============

This document provides guidelines on how to install and
configure the ``Iruya`` release of OPNFV when using Fuel as a
deployment tool, including required software and hardware configurations.

Although the available installation options provide a high degree of
freedom in how the system is set up, including architecture, services
and features, etc., said permutations may not provide an OPNFV
compliant reference architecture. This document provides a
step-by-step guide that results in an OPNFV ``Iruya`` compliant
deployment.

The audience of this document is assumed to have good knowledge of
networking and Unix/Linux administration.

Before starting the installation of the ``Iruya`` release of
OPNFV, using Fuel as a deployment tool, some planning must be
done.

Preparations
============

Prior to installation, a number of deployment specific parameters must be
collected, those are:

#.     Provider sub-net and gateway information

#.     Provider ``VLAN`` information

#.     Provider ``DNS`` addresses

#.     Provider ``NTP`` addresses

#.     How many nodes and what roles you want to deploy (Controllers, Computes)

This information will be needed for the configuration procedures
provided in this document.

Hardware Requirements
=====================

Mininum hardware requirements depend on the deployment type.

.. WARNING::

    If ``baremetal`` nodes are present in the cluster, the architecture of the
    nodes running the control plane (``kvm01``, ``kvm02``, ``kvm03`` for
    ``HA`` scenarios, respectively ``ctl01``, ``gtw01``, ``odl01`` for
    ``noHA`` scenarios) and the ``jumpserver`` architecture must be the same
    (either ``x86_64`` or ``aarch64``).

.. TIP::

    The compute nodes may have different architectures, but extra
    configuration might be required for scheduling VMs on the appropiate host.
    This use-case is not tested in OPNFV CI, so it is considered experimental.

Hardware Requirements for ``virtual`` Deploys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following minimum hardware requirements must be met for the ``virtual``
installation of ``Iruya`` using Fuel:

+------------------+------------------------------------------------------+
| **HW Aspect**    | **Requirement**                                      |
|                  |                                                      |
+==================+======================================================+
| **1 Jumpserver** | A physical node (also called Foundation Node) that   |
|                  | will host a Salt Master container and each of the VM |
|                  | nodes in the virtual deploy                          |
+------------------+------------------------------------------------------+
| **CPU**          | Minimum 1 socket with Virtualization support         |
+------------------+------------------------------------------------------+
| **RAM**          | Minimum 32GB/server (Depending on VNF work load)     |
+------------------+------------------------------------------------------+
| **Disk**         | Minimum 100GB (SSD or 15krpm SCSI highly recommended)|
+------------------+------------------------------------------------------+

Hardware Requirements for ``baremetal`` Deploys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following minimum hardware requirements must be met for the ``baremetal``
installation of ``Iruya`` using Fuel:

+------------------+------------------------------------------------------+
| **HW Aspect**    | **Requirement**                                      |
|                  |                                                      |
+==================+======================================================+
| **1 Jumpserver** | A physical node (also called Foundation Node) that   |
|                  | hosts the Salt Master and MaaS containers            |
+------------------+------------------------------------------------------+
| **# of nodes**   | Minimum 5                                            |
|                  |                                                      |
|                  | - 3 KVM servers which will run all the controller    |
|                  |   services                                           |
|                  |                                                      |
|                  | - 2 Compute nodes                                    |
|                  |                                                      |
|                  | .. WARNING::                                         |
|                  |                                                      |
|                  |     ``kvm01``, ``kvm02``, ``kvm03`` nodes and the    |
|                  |     ``jumpserver`` must have the same architecture   |
|                  |     (either ``x86_64`` or ``aarch64``).              |
|                  |                                                      |
|                  | .. NOTE::                                            |
|                  |                                                      |
|                  |     ``aarch64`` nodes should run an ``UEFI``         |
|                  |     compatible firmware with PXE support             |
|                  |     (e.g. ``EDK2``).                                 |
+------------------+------------------------------------------------------+
| **CPU**          | Minimum 1 socket with Virtualization support         |
+------------------+------------------------------------------------------+
| **RAM**          | Minimum 16GB/server (Depending on VNF work load)     |
+------------------+------------------------------------------------------+
| **Disk**         | Minimum 256GB 10kRPM spinning disks                  |
+------------------+------------------------------------------------------+
| **Networks**     | Mininum 4                                            |
|                  |                                                      |
|                  | - 3 VLANs (``public``, ``mgmt``, ``private``) -      |
|                  |   can be a mix of tagged/native                      |
|                  |                                                      |
|                  | - 1 Un-Tagged VLAN for PXE Boot -                    |
|                  |   ``PXE/admin`` Network                              |
|                  |                                                      |
|                  | .. NOTE::                                            |
|                  |                                                      |
|                  |     These can be allocated to a single NIC           |
|                  |     or spread out over multiple NICs.                |
|                  |                                                      |
|                  | .. WARNING::                                         |
|                  |                                                      |
|                  |     No external ``DHCP`` server should be present    |
|                  |     in the ``PXE/admin`` network segment, as it      |
|                  |     would interfere with ``MaaS`` ``DHCP`` during    |
|                  |     ``baremetal`` node commissioning/deploying.      |
+------------------+------------------------------------------------------+
| **Power mgmt**   | All targets need to have power management tools that |
|                  | allow rebooting the hardware (e.g. ``IPMI``).        |
+------------------+------------------------------------------------------+

Hardware Requirements for ``hybrid`` (``baremetal`` + ``virtual``) Deploys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following minimum hardware requirements must be met for the ``hybrid``
installation of ``Iruya`` using Fuel:

+------------------+------------------------------------------------------+
| **HW Aspect**    | **Requirement**                                      |
|                  |                                                      |
+==================+======================================================+
| **1 Jumpserver** | A physical node (also called Foundation Node) that   |
|                  | hosts the Salt Master and MaaS containers, and       |
|                  | each of the virtual nodes defined in ``PDF``         |
+------------------+------------------------------------------------------+
| **# of nodes**   | .. NOTE::                                            |
|                  |                                                      |
|                  |     Depends on ``PDF`` configuration.                |
|                  |                                                      |
|                  | If the control plane is virtualized, minimum         |
|                  | baremetal requirements are:                          |
|                  |                                                      |
|                  | - 2 Compute nodes                                    |
|                  |                                                      |
|                  | If the computes are virtualized, minimum             |
|                  | baremetal requirements are:                          |
|                  |                                                      |
|                  | - 3 KVM servers which will run all the controller    |
|                  |   services                                           |
|                  |                                                      |
|                  | .. WARNING::                                         |
|                  |                                                      |
|                  |     ``kvm01``, ``kvm02``, ``kvm03`` nodes and the    |
|                  |     ``jumpserver`` must have the same architecture   |
|                  |     (either ``x86_64`` or ``aarch64``).              |
|                  |                                                      |
|                  | .. NOTE::                                            |
|                  |                                                      |
|                  |     ``aarch64`` nodes should run an ``UEFI``         |
|                  |     compatible firmware with PXE support             |
|                  |     (e.g. ``EDK2``).                                 |
+------------------+------------------------------------------------------+
| **CPU**          | Minimum 1 socket with Virtualization support         |
+------------------+------------------------------------------------------+
| **RAM**          | Minimum 16GB/server (Depending on VNF work load)     |
+------------------+------------------------------------------------------+
| **Disk**         | Minimum 256GB 10kRPM spinning disks                  |
+------------------+------------------------------------------------------+
| **Networks**     | Same as for ``baremetal`` deployments                |
+------------------+------------------------------------------------------+
| **Power mgmt**   | Same as for ``baremetal`` deployments                |
+------------------+------------------------------------------------------+

Help with Hardware Requirements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Calculate hardware requirements:

When choosing the hardware on which you will deploy your OpenStack
environment, you should think about:

- CPU -- Consider the number of virtual machines that you plan to deploy in
  your cloud environment and the CPUs per virtual machine.

- Memory -- Depends on the amount of RAM assigned per virtual machine and the
  controller node.

- Storage -- Depends on the local drive space per virtual machine, remote
  volumes that can be attached to a virtual machine, and object storage.

- Networking -- Depends on the Choose Network Topology, the network bandwidth
  per virtual machine, and network storage.

Top of the Rack (``TOR``) Configuration Requirements
====================================================

The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South); it also provides needed connectivity for
the Storage Area Network (SAN).

To avoid traffic congestion, it is strongly suggested that three
physically separated networks are used, that is: 1 physical network
for administration and control, one physical network for tenant private
and public networks, and one physical network for SAN.

The switching connectivity can (but does not need to) be fully redundant,
in such case it comprises a redundant 10GE switch pair for each of the
three physically separated networks.

.. WARNING::

    The physical ``TOR`` switches are **not** automatically configured from
    the OPNFV Fuel reference platform. All the networks involved in the OPNFV
    infrastructure as well as the provider networks and the private tenant
    VLANs needs to be manually configured.

Manual configuration of the ``Iruya`` hardware platform should
be carried out according to the `OPNFV Pharos Specification`_.

OPNFV Software Prerequisites
============================

.. NOTE::

    All prerequisites described in this chapter apply to the ``jumpserver``
    node.

OS Distribution Support
~~~~~~~~~~~~~~~~~~~~~~~

The Jumpserver node should be pre-provisioned with an operating system,
according to the `OPNFV Pharos specification`_.

OPNFV Fuel has been validated by CI using the following distributions
installed on the Jumpserver:

- ``CentOS 7`` (recommended by Pharos specification);
- ``Ubuntu Xenial 16.04``;

.. TOPIC:: ``aarch64`` notes

    For an ``aarch64`` Jumpserver, the ``libvirt`` minimum required
    version is ``3.x``, ``3.5`` or newer highly recommended.

    .. TIP::

        ``CentOS 7`` (``aarch64``) distro provided packages are already new
        enough.

    .. WARNING::

        ``Ubuntu 16.04`` (``arm64``), distro packages are too old and 3rd party
        repositories should be used.

    For convenience, Armband provides a DEB repository holding all the
    required packages.

    To add and enable the Armband repository on an Ubuntu 16.04 system,
    create a new sources list file ``/apt/sources.list.d/armband.list``
    with the following contents:

    .. code-block:: console

        jenkins@jumpserver:~$ cat /etc/apt/sources.list.d/armband.list
        deb http://linux.enea.com/mcp-repos/rocky/xenial rocky-armband main

        jenkins@jumpserver:~$ sudo apt-key adv --keyserver keys.gnupg.net \
                                               --recv 798AB1D1
        jenkins@jumpserver:~$ sudo apt-get update

OS Distribution Packages
~~~~~~~~~~~~~~~~~~~~~~~~

By default, the ``deploy.sh`` script will automatically install the required
distribution package dependencies on the Jumpserver, so the end user does
not have to manually install them before starting the deployment.

This includes Python, QEMU, libvirt etc.

.. SEEALSO::

    To disable automatic package installation (and/or upgrade) during
    deployment, check out the ``-P`` deploy argument.

.. WARNING::

    The install script expects ``libvirt`` to be already running on the
    Jumpserver.

In case ``libvirt`` packages are missing, the script will install them; but
depending on the OS distribution, the user might have to start the
``libvirt`` daemon service manually, then run the deploy script again.

Therefore, it is recommended to install ``libvirt`` explicitly on the
Jumpserver before the deployment.

While not mandatory, upgrading the kernel on the Jumpserver is also highly
recommended.

.. code-block:: console

    jenkins@jumpserver:~$ sudo apt-get install \
                          linux-image-generic-hwe-16.04-edge libvirt-bin
    jenkins@jumpserver:~$ sudo reboot

User Requirements
~~~~~~~~~~~~~~~~~

The user running the deploy script on the Jumpserver should belong to
``sudo`` and ``libvirt`` groups, and have passwordless sudo access.

.. NOTE::

    Throughout this documentation, we will use the ``jenkins`` username for
    this role.

The following example adds the groups to the user ``jenkins``:

.. code-block:: console

    jenkins@jumpserver:~$ sudo usermod -aG sudo jenkins
    jenkins@jumpserver:~$ sudo usermod -aG libvirt jenkins
    jenkins@jumpserver:~$ sudo reboot
    jenkins@jumpserver:~$ groups
    jenkins sudo libvirt

    jenkins@jumpserver:~$ sudo visudo
    ...
    %jenkins ALL=(ALL) NOPASSWD:ALL

Local Artifact Storage
~~~~~~~~~~~~~~~~~~~~~~

The folder containing the temporary deploy artifacts (``/home/jenkins/tmpdir``
in the examples below) needs to have mask ``777`` in order for ``libvirt`` to
be able to use them.

.. code-block:: console

    jenkins@jumpserver:~$ mkdir -p -m 777 /home/jenkins/tmpdir

Network Configuration
~~~~~~~~~~~~~~~~~~~~~

Relevant Linux bridges should also be pre-configured for certain networks,
depending on the type of the deployment.

+------------+---------------+----------------------------------------------+
| Network    | Linux Bridge  | Linux Bridge necessity based on deploy type  |
|            |               +--------------+---------------+---------------+
|            |               | ``virtual``  | ``baremetal`` | ``hybrid``    |
+============+===============+==============+===============+===============+
| PXE/admin  | ``admin_br``  | absent       | present       | present       |
+------------+---------------+--------------+---------------+---------------+
| management | ``mgmt_br``   | optional     | optional,     | optional,     |
|            |               |              | recommended,  | recommended,  |
|            |               |              | required for  | required for  |
|            |               |              | ``functest``, | ``functest``, |
|            |               |              | ``yardstick`` | ``yardstick`` |
+------------+---------------+--------------+---------------+---------------+
| internal   | ``int_br``    | optional     | optional      | present       |
+------------+---------------+--------------+---------------+---------------+
| public     | ``public_br`` | optional     | optional,     | optional,     |
|            |               |              | recommended,  | recommended,  |
|            |               |              | useful for    | useful for    |
|            |               |              | debugging     | debugging     |
+------------+---------------+--------------+---------------+---------------+

.. TIP::

    IP addresses should be assigned to the created bridge interfaces (not
    to one of its ports).

.. WARNING::

    ``PXE/admin`` bridge (``admin_br``) **must** have an IP address.

Changes ``deploy.sh`` Will Perform to Jumpserver OS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. WARNING::

    The install script will alter Jumpserver sysconf and disable
    ``net.bridge.bridge-nf-call``.

.. WARNING::

    On Jumpservers running Ubuntu with AppArmor enabled, when deploying
    on baremetal nodes (i.e. when MaaS is used), the install script
    will disable certain conflicting AppArmor profiles that interfere with
    MaaS services inside the container, e.g. ``ntpd``, ``named``, ``dhcpd``,
    ``tcpdump``.

.. WARNING::

    The install script will automatically install and/or upgrade the
    required distribution package dependencies on the Jumpserver,
    unless explicitly asked not to (via the ``-P`` deploy arg).

OPNFV Software Configuration (``XDF``)
======================================

.. versionadded:: 5.0.0
.. versionchanged:: 7.0.0

Unlike the old approach based on OpenStack Fuel, OPNFV Fuel no longer has a
graphical user interface for configuring the environment, but instead
switched to OPNFV specific descriptor files that we will call generically
``XDF``:

- ``PDF`` (POD Descriptor File) provides an abstraction of the target POD
  with all its hardware characteristics and required parameters;
- ``IDF`` (Installer Descriptor File) extends the ``PDF`` with POD related
  parameters required by the OPNFV Fuel installer;
- ``SDF`` (Scenario Descriptor File, **not** yet adopted) will later
  replace embedded scenario definitions, describing the roles and layout of
  the cluster enviroment for a given reference architecture;

.. TIP::

    For ``virtual`` deployments, if the ``public`` network will be accessed
    from outside the ``jumpserver`` node, a custom ``PDF``/``IDF`` pair is
    required for customizing ``idf.net_config.public`` and
    ``idf.fuel.jumphost.bridges.public``.

.. NOTE::

    For OPNFV CI PODs, as well as simple (no ``public`` bridge) ``virtual``
    deployments, ``PDF``/``IDF`` files are already available in the
    `pharos git repo`_. They can be used as a reference for user-supplied
    inputs or to kick off a deployment right away.

+----------+------------------------------------------------------------------+
| LAB/POD  | ``PDF``/``IDF`` availability based on deploy type                |
|          +------------------------+--------------------+--------------------+
|          | ``virtual``            | ``baremetal``      | ``hybrid``         |
+==========+========================+====================+====================+
| OPNFV CI | available in           | available in       | N/A, as currently  |
| POD      | `pharos git repo`_     | `pharos git repo`_ | there are 0 hybrid |
|          | (e.g.                  | (e.g. ``lf-pod2``, | PODs in OPNFV CI   |
|          | ``ericsson-virtual1``) | ``arm-pod5``)      |                    |
+----------+------------------------+--------------------+--------------------+
| local or | ``user-supplied``      | ``user-supplied``  | ``user-supplied``  |
| new POD  |                        |                    |                    |
+----------+------------------------+--------------------+--------------------+

.. TIP::

    Both ``PDF`` and ``IDF`` structure are modelled as ``yaml`` schemas in the
    `pharos git repo`_, also included as a git submodule in OPNFV Fuel.

    .. SEEALSO::

        - ``mcp/scripts/pharos/config/pdf/pod1.schema.yaml``
        - ``mcp/scripts/pharos/config/pdf/idf-pod1.schema.yaml``

    Schema files are also used during the initial deployment phase to validate
    the user-supplied input ``PDF``/``IDF`` files.

``PDF``
~~~~~~~

The Pod Descriptor File is a hardware description of the POD
infrastructure. The information is modeled under a ``yaml`` structure.

The hardware description covers the ``jumphost`` node and a set of ``nodes``
for the cluster target boards. For each node the following characteristics
are defined:

- Node parameters including ``CPU`` features and total memory;
- A list of available disks;
- Remote management parameters;
- Network interfaces list including name, ``MAC`` address, link speed,
  advanced features;

.. SEEALSO::

    A reference file with the expected ``yaml`` structure is available at:

    - ``mcp/scripts/pharos/config/pdf/pod1.yaml``

    For more information on ``PDF``, see the `OPNFV PDF Wiki Page`_.

.. WARNING::

    The fixed IPs defined in ``PDF`` are ignored by the OPNFV Fuel installer
    script and it will instead assign addresses based on the network ranges
    defined in ``IDF``.

    For more details on the way IP addresses are assigned, see
    :ref:`OPNFV Fuel User Guide <fuel-userguide>`.

``PDF``/``IDF`` Role (hostname) Mapping
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Upcoming ``SDF`` support will introduce a series of possible node roles.
Until that happens, the role mapping logic is hardcoded, based on node index
in ``PDF``/``IDF`` (which should also be in sync, i.e. the parameters of the
``n``-th cluster node defined in ``PDF`` should be the ``n``-th node in
``IDF`` structures too).

+-------------+------------------+----------------------+
| Node index  | ``HA`` scenario  | ``noHA`` scenario    |
+=============+==================+======================+
| 1st         | ``kvm01``        | ``ctl01``            |
+-------------+------------------+----------------------+
| 2nd         | ``kvm02``        | ``gtw01``            |
+-------------+------------------+----------------------+
| 3rd         | ``kvm03``        | ``odl01``/``unused`` |
+-------------+------------------+----------------------+
| 4th,        | ``cmp001``,      | ``cmp001``,          |
| 5th,        | ``cmp002``,      | ``cmp002``,          |
| ...         | ``...``          | ``...``              |
+-------------+------------------+----------------------+

.. TIP::

    To switch node role(s), simply reorder the node definitions in
    ``PDF``/``IDF`` (make sure to keep them in sync).

``IDF``
~~~~~~~

The Installer Descriptor File extends the ``PDF`` with POD related parameters
required by the installer. This information may differ per each installer type
and it is not considered part of the POD infrastructure.

``idf.*`` Overview
------------------

The ``IDF`` file must be named after the ``PDF`` it attaches to, with the
prefix ``idf-``.

.. SEEALSO::

    A reference file with the expected ``yaml`` structure is available at:

    - ``mcp/scripts/pharos/config/pdf/idf-pod1.yaml``

The file follows a ``yaml`` structure and at least two sections
(``idf.net_config`` and ``idf.fuel``) are expected.

The ``idf.fuel`` section defines several sub-sections required by the OPNFV
Fuel installer:

- ``jumphost``: List of bridge names for each network on the Jumpserver;
- ``network``: List of device name and bus address info of all the target nodes.
  The order must be aligned with the order defined in the ``PDF`` file.
  The OPNFV Fuel installer relies on the ``IDF`` model to setup all node NICs
  by defining the expected device name and bus address;
- ``maas``: Defines the target nodes commission timeout and deploy timeout;
- ``reclass``: Defines compute parameter tuning, including huge pages, ``CPU``
  pinning and other ``DPDK`` settings;

.. code-block:: yaml

    ---
    idf:
      version: 0.1     # fixed, the only supported version (mandatory)
      net_config:      # POD network configuration overview (mandatory)
        oob: ...       # mandatory
        admin: ...     # mandatory
        mgmt: ...      # mandatory
        storage: ...   # mandatory
        private: ...   # mandatory
        public: ...    # mandatory
      fuel:            # OPNFV Fuel specific section (mandatory)
        jumphost:      # OPNFV Fuel jumpserver bridge configuration (mandatory)
          bridges:                          # Bridge name mapping (mandatory)
            admin: 'admin_br'               # <PXE/admin bridge name> or ~
            mgmt: 'mgmt_br'                 # <mgmt bridge name> or ~
            private: ~                      # <private bridge name> or ~
            public: 'public_br'             # <public bridge name> or ~
          trunks: ...                       # Trunked networks (optional)
        maas:                               # MaaS timeouts (optional)
          timeout_comissioning: 10          # commissioning timeout in minutes
          timeout_deploying: 15             # deploy timeout in minutes
        network:                            # Cluster nodes network (mandatory)
          interface_mtu: 1500               # Cluster-level MTU (optional)
          ntp_strata_host1: 1.pool.ntp.org  # NTP1 (optional)
          ntp_strata_host2: 0.pool.ntp.org  # NTP2 (optional)
          node: ...                         # List of per-node cfg (mandatory)
        reclass:                            # Additional params (mandatory)
          node: ...                         # List of per-node cfg (mandatory)

``idf.net_config``
------------------

``idf.net_config`` was introduced as a mechanism to map all the usual cluster
networks (internal and provider networks, e.g. ``mgmt``) to their ``VLAN``
tags, ``CIDR`` and a physical interface index (used to match networks to
interface names, like ``eth0``, on the cluster nodes).


.. WARNING::

    The mapping between one network segment (e.g. ``mgmt``) and its ``CIDR``/
    ``VLAN`` is not configurable on a per-node basis, but instead applies to
    all the nodes in the cluster.

For each network, the following parameters are currently supported:

+--------------------------+--------------------------------------------------+
| ``idf.net_config.*`` key | Details                                          |
+==========================+==================================================+
| ``interface``            | The index of the interface to use for this net.  |
|                          | For each cluster node (if network is present),   |
|                          | OPNFV Fuel will determine the underlying physical|
|                          | interface by picking the element at index        |
|                          | ``interface`` from the list of network interface |
|                          | names defined in                                 |
|                          | ``idf.fuel.network.node.*.interfaces``.          |
|                          | Required for each network.                       |
|                          |                                                  |
|                          | .. NOTE::                                        |
|                          |                                                  |
|                          |     The interface index should be the            |
|                          |     same on all cluster nodes. This can be       |
|                          |     achieved by ordering them accordingly in     |
|                          |     ``PDF``/``IDF``.                             |
+--------------------------+--------------------------------------------------+
| ``vlan``                 | ``VLAN`` tag (integer) or the string ``native``. |
|                          | Required for each network.                       |
+--------------------------+--------------------------------------------------+
| ``ip-range``             | When specified, all cluster IPs dynamically      |
|                          | allocated by OPNFV Fuel for that network will be |
|                          | assigned inside this range.                      |
|                          | Required for ``oob``, optional for others.       |
|                          |                                                  |
|                          | .. NOTE::                                        |
|                          |                                                  |
|                          |     For now, only range start address is used.   |
+--------------------------+--------------------------------------------------+
| ``network``              | Network segment address.                         |
|                          | Required for each network, except ``oob``.       |
+--------------------------+--------------------------------------------------+
| ``mask``                 | Network segment mask.                            |
|                          | Required for each network, except ``oob``.       |
+--------------------------+--------------------------------------------------+
| ``gateway``              | Gateway IP address.                              |
|                          | Required for ``public``, N/A for others.         |
+--------------------------+--------------------------------------------------+
| ``dns``                  | List of DNS IP addresses.                        |
|                          | Required for ``public``, N/A for others.         |
+--------------------------+--------------------------------------------------+

Sample ``public`` network configuration block:

.. code-block:: yaml

    idf:
        net_config:
            public:
              interface: 1
              vlan: native
              network: 10.0.16.0
              ip-range: 10.0.16.100-10.0.16.253
              mask: 24
              gateway: 10.0.16.254
              dns:
                - 8.8.8.8
                - 8.8.4.4

.. TOPIC:: ``hybrid`` POD notes

    Interface indexes must be the same for all nodes, which is problematic
    when mixing ``virtual`` nodes (where all interfaces were untagged
    so far) with ``baremetal`` nodes (where interfaces usually carry
    tagged VLANs).

    .. TIP::

        To achieve this, a special ``jumpserver`` network layout is used:
        ``mgmt``, ``storage``, ``private``, ``public`` are trunked together
        in a single ``trunk`` bridge:

        - without decapsulating them (if they are also tagged on ``baremetal``);
          a ``trunk.<vlan_tag>`` interface should be created on the
          ``jumpserver`` for each tagged VLAN so the kernel won't drop the
          packets;
        - by decapsulating them  first (if they are also untagged on
          ``baremetal`` nodes);

    The ``trunk`` bridge is then used for all bridges OPNFV Fuel
    is aware of in ``idf.fuel.jumphost.bridges``, e.g. for a ``trunk`` where
    only ``mgmt`` network is not decapsulated:

    .. code-block:: yaml

        idf:
            fuel:
              jumphost:
                bridges:
                  admin: 'admin_br'
                  mgmt: 'trunk'
                  private: 'trunk'
                  public: 'trunk'
                trunks:
                  # mgmt network is not decapsulated for jumpserver infra nodes,
                  # to align with the VLAN configuration of baremetal nodes.
                  mgmt: True

.. WARNING::

    The Linux kernel limits the name of network interfaces to 16 characters.
    Extra care is required when choosing bridge names, so appending the
    ``VLAN`` tag won't lead to an interface name length exceeding that limit.

``idf.fuel.network``
--------------------

``idf.fuel.network`` allows mapping the cluster networks (e.g. ``mgmt``) to
their physical interface name (e.g. ``eth0``) and bus address on the cluster
nodes.

``idf.fuel.network.node`` should be a list with the same number (and order) of
elements as the cluster nodes defined in ``PDF``, e.g. the second cluster node
in ``PDF`` will use the interface name and bus address defined in the second
list element.

Below is a sample configuration block for a single node with two interfaces:

.. code-block:: yaml

    idf:
      fuel:
        network:
          node:
            # Ordered-list, index should be in sync with node index in PDF
            - interfaces:
                # Ordered-list, index should be in sync with interface index
                # in PDF
                - 'ens3'
                - 'ens4'
              busaddr:
                # Bus-info reported by `ethtool -i ethX`
                - '0000:00:03.0'
                - '0000:00:04.0'


``idf.fuel.reclass``
--------------------

``idf.fuel.reclass`` provides a way of overriding default values in the
reclass cluster model.

This currently covers strictly compute parameter tuning, including huge
pages, ``CPU`` pinning and other ``DPDK`` settings.

``idf.fuel.reclass.node`` should be a list with the same number (and order) of
elements as the cluster nodes defined in ``PDF``, e.g. the second cluster node
in ``PDF`` will use the parameters defined in the second list element.

The following parameters are currently supported:

+---------------------------------+-------------------------------------------+
| ``idf.fuel.reclass.node.*``     | Details                                   |
| key                             |                                           |
+=================================+===========================================+
| ``nova_cpu_pinning``            | List of CPU cores nova will be pinned to. |
|                                 |                                           |
|                                 | .. NOTE::                                 |
|                                 |                                           |
|                                 |     Currently disabled.                   |
+---------------------------------+-------------------------------------------+
| ``compute_hugepages_size``      | Size of each persistent huge pages.       |
|                                 |                                           |
|                                 | Usual values are ``2M`` and ``1G``.       |
+---------------------------------+-------------------------------------------+
| ``compute_hugepages_count``     | Total number of persistent huge pages.    |
+---------------------------------+-------------------------------------------+
| ``compute_hugepages_mount``     | Mount point to use for huge pages.        |
+---------------------------------+-------------------------------------------+
| ``compute_kernel_isolcpu``      | List of certain CPU cores that are        |
|                                 | isolated from Linux scheduler.            |
+---------------------------------+-------------------------------------------+
| ``compute_dpdk_driver``         | Kernel module to provide userspace I/O    |
|                                 | support.                                  |
+---------------------------------+-------------------------------------------+
| ``compute_ovs_pmd_cpu_mask``    | Hexadecimal mask of CPUs to run ``DPDK``  |
|                                 | Poll-mode drivers.                        |
+---------------------------------+-------------------------------------------+
| ``compute_ovs_dpdk_socket_mem`` | Set of amount huge pages in ``MB`` to be  |
|                                 | used by ``OVS-DPDK`` daemon taken for each|
|                                 | ``NUMA`` node. Set size is equal to       |
|                                 | ``NUMA`` nodes count, elements are        |
|                                 | divided by comma.                         |
+---------------------------------+-------------------------------------------+
| ``compute_ovs_dpdk_lcore_mask`` | Hexadecimal mask of ``DPDK`` lcore        |
|                                 | parameter used to run ``DPDK`` processes. |
+---------------------------------+-------------------------------------------+
| ``compute_ovs_memory_channels`` | Number of memory channels to be used.     |
+---------------------------------+-------------------------------------------+
| ``dpdk0_driver``                | NIC driver to use for physical network    |
|                                 | interface.                                |
+---------------------------------+-------------------------------------------+
| ``dpdk0_n_rxq``                 | Number of ``RX`` queues.                  |
+---------------------------------+-------------------------------------------+

Sample ``compute_params`` configuration block (for a single node):

.. code-block:: yaml

    idf:
      fuel:
        reclass:
          node:
            - compute_params:
                common: &compute_params_common
                  compute_hugepages_size: 2M
                  compute_hugepages_count: 2048
                  compute_hugepages_mount: /mnt/hugepages_2M
                dpdk:
                  <<: *compute_params_common
                  compute_dpdk_driver: uio
                  compute_ovs_pmd_cpu_mask: "0x6"
                  compute_ovs_dpdk_socket_mem: "1024"
                  compute_ovs_dpdk_lcore_mask: "0x8"
                  compute_ovs_memory_channels: "2"
                  dpdk0_driver: igb_uio
                  dpdk0_n_rxq: 2

``SDF``
~~~~~~~

Scenario Descriptor Files are not yet implemented in the OPNFV Fuel ``Iruya``
release.

Instead, embedded OPNFV Fuel scenarios files are locally available in
``mcp/config/scenario``.

OPNFV Software Installation and Deployment
==========================================

This section describes the process of installing all the components needed to
deploy the full OPNFV reference platform stack across a server cluster.

Deployment Types
~~~~~~~~~~~~~~~~

.. WARNING::

    OPNFV releases previous to ``Iruya`` used to rely on the ``virtual``
    keyword being part of the POD name (e.g. ``ericsson-virtual2``) to
    configure the deployment type as ``virtual``. Otherwise ``baremetal``
    was implied.

``Gambia`` and newer releases are more flexbile towards supporting a mix
of ``baremetal`` and ``virtual`` nodes, so the type of deployment is
now automatically determined based on the cluster nodes types in ``PDF``:

+---------------------------------+-------------------------------------------+
| ``PDF`` has nodes of type       | Deployment type                           |
+---------------+-----------------+                                           |
| ``baremetal`` | ``virtual``     |                                           |
+===============+=================+===========================================+
| yes           | no              | ``baremetal``                             |
+---------------+-----------------+-------------------------------------------+
| yes           | yes             | ``hybrid``                                |
+---------------+-----------------+-------------------------------------------+
| no            | yes             | ``virtual``                               |
+---------------+-----------------+-------------------------------------------+

Based on that, the deployment script will later enable/disable certain extra
nodes (e.g. ``mas01``) and/or ``STATE`` files (e.g. ``maas``).

``HA`` vs ``noHA``
~~~~~~~~~~~~~~~~~~

High availability of OpenStack services is determined based on scenario name,
e.g. ``os-nosdn-nofeature-noha`` vs ``os-nosdn-nofeature-ha``.

.. TIP::

    ``HA`` scenarios imply a virtualized control plane (``VCP``) for the
    OpenStack services running on the 3 ``kvm`` nodes.

    .. SEEALSO::

        An experimental feature argument (``-N``) is supported by the deploy
        script for disabling ``VCP``, although it might not be supported by
        all scenarios and is not being continuosly validated by OPNFV CI/CD.

.. WARNING::

    ``virtual`` ``HA`` deployments are not officially supported, due to
    poor performance and various limitations of nested virtualization on
    both ``x86_64`` and ``aarch64`` architectures.

    .. TIP::

        ``virtual`` ``HA`` deployments without ``VCP`` are supported, but
        highly experimental.

+-------------------------------+-------------------------+-------------------+
| Feature                       | ``HA`` scenario         | ``noHA`` scenario |
+===============================+=========================+===================+
| ``VCP``                       | yes,                    | no                |
| (Virtualized Control Plane)   | disabled with ``-N``    |                   |
+-------------------------------+-------------------------+-------------------+
| OpenStack APIs SSL            | yes                     | no                |
+-------------------------------+-------------------------+-------------------+
| Storage                       | ``GlusterFS``           | ``NFS``           |
+-------------------------------+-------------------------+-------------------+

Steps to Start the Automatic Deploy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These steps are common for ``virtual``, ``baremetal`` or ``hybrid`` deploys,
``x86_64``, ``aarch64`` or ``mixed`` (``x86_64`` and ``aarch64``):

- Clone the OPNFV Fuel code from gerrit
- Checkout the ``Iruya`` release tag
- Start the deploy script

.. NOTE::

    The deployment uses the OPNFV Pharos project as input (``PDF`` and
    ``IDF`` files) for hardware and network configuration of all current
    OPNFV PODs.

    When deploying a new POD, one may pass the ``-b`` flag to the deploy
    script to override the path for the labconfig directory structure
    containing the ``PDF`` and ``IDF`` (``<URI to configuration repo ...>`` is
    the absolute path to a local or remote directory structure, populated
    similar to `pharos git repo`_, i.e. ``PDF``/``IDF`` reside in a
    subdirectory called ``labs/<lab_name>``).

.. code-block:: console

    jenkins@jumpserver:~$ git clone https://git.opnfv.org/fuel
    jenkins@jumpserver:~$ cd fuel
    jenkins@jumpserver:~/fuel$ git checkout opnfv-9.0.0
    jenkins@jumpserver:~/fuel$ ci/deploy.sh -l <lab_name> \
                                            -p <pod_name> \
                                            -b <URI to configuration repo containing the PDF/IDF files> \
                                            -s <scenario> \
                                            -D \
                                            -S <Storage directory for deploy artifacts> |& tee deploy.log

.. TIP::

    Besides the basic options,  there are other recommended deploy arguments:

    - use ``-D`` option to enable the debug info
    - use ``-S`` option to point to a tmp dir where the disk images are saved.
      The deploy artifacts will be re-used on subsequent (re)deployments.
    - use ``|& tee`` to save the deploy log to a file

Typical Cluster Examples
~~~~~~~~~~~~~~~~~~~~~~~~

Common cluster layouts usually fall into one of the cases described below,
categorized by deployment type (``baremetal``, ``virtual`` or ``hybrid``) and
high availability (``HA`` or ``noHA``).

A simplified overview of the steps ``deploy.sh`` will automatically perform is:

- create a Salt Master Docker container on the jumpserver, which will drive
  the rest of the installation;
- ``baremetal`` or ``hybrid`` only: create a ``MaaS`` container node,
  which will be leveraged using Salt to handle OS provisioning on the
  ``baremetal`` nodes;
- leverage Salt to install & configure OpenStack;

.. NOTE::

    A Docker network ``mcpcontrol`` is always created for initial connection
    of the infrastructure containers (``cfg01``, ``mas01``) on Jumphost.

.. WARNING::

    A single cluster deployment per ``jumpserver`` node is currently supported,
    indifferent of its type (``virtual``, ``baremetal`` or ``hybrid``).

Once the deployment is complete, the following should be accessible:

+---------------+----------------------------------+---------------------------+
| Resource      | ``HA`` scenario                  | ``noHA`` scenario         |
+===============+==================================+===========================+
| ``Horizon``   | ``https://<prx public VIP>``     | ``http://<ctl VIP>:8078`` |
| (Openstack    |                                  |                           |
| Dashboard)    |                                  |                           |
+---------------+----------------------------------+---------------------------+
| ``SaltStack`` | ``http://<prx public VIP>:8090`` | N/A                       |
| Deployment    |                                  |                           |
| Documentation |                                  |                           |
+---------------+----------------------------------+---------------------------+

.. SEEALSO::

    For more details on locating and importing the generated SSL certificate,
    see :ref:`OPNFV Fuel User Guide <fuel-userguide>`.

``virtual`` ``noHA`` POD
------------------------

In the following figure there are two generic examples of ``virtual`` deploys,
each on a separate Jumphost node, both behind the same ``TOR`` switch:

- Jumphost 1 has only virsh bridges (created by the deploy script);
- Jumphost 2 has a mix of Linux (manually created) and ``libvirt`` managed
  bridges (created by the deploy script);

.. figure:: img/fuel_virtual_noha.png
   :align: center
   :width: 60%
   :alt: OPNFV Fuel Virtual noHA POD Network Layout Examples

   OPNFV Fuel Virtual noHA POD Network Layout Examples

   +-------------+------------------------------------------------------------+
   | ``cfg01``   | Salt Master Docker container                               |
   +-------------+------------------------------------------------------------+
   | ``ctl01``   | Controller VM                                              |
   +-------------+------------------------------------------------------------+
   | ``gtw01``   | Gateway VM with neutron services                           |
   |             | (``DHCP`` agent, ``L3`` agent, ``metadata`` agent etc)     |
   +-------------+------------------------------------------------------------+
   | ``odl01``   | VM on which ``ODL`` runs                                   |
   |             | (for scenarios deployed with ODL)                          |
   +-------------+------------------------------------------------------------+
   | ``cmp001``, | Compute VMs                                                |
   | ``cmp002``  |                                                            |
   +-------------+------------------------------------------------------------+

.. TIP::

    If external access to the ``public`` network is not required, there is
    little to no motivation to create a custom ``PDF``/``IDF`` set for a
    virtual deployment.

    Instead, the existing virtual PODs definitions in `pharos git repo`_ can
    be used as-is:

    - ``ericsson-virtual1`` for ``x86_64``;
    - ``arm-virtual2`` for ``aarch64``;

.. code-block:: console

    # example deploy cmd for an x86_64 virtual cluster
    jenkins@jumpserver:~/fuel$ ci/deploy.sh -l ericsson \
                                            -p virtual1 \
                                            -s os-nosdn-nofeature-noha \
                                            -D \
                                            -S /home/jenkins/tmpdir |& tee deploy.log

``baremetal`` ``noHA`` POD
--------------------------

.. WARNING::

    These scenarios are not tested in OPNFV CI, so they are considered
    experimental.

.. figure:: img/fuel_baremetal_noha.png
   :align: center
   :width: 60%
   :alt: OPNFV Fuel Baremetal noHA POD Network Layout Example

   OPNFV Fuel Baremetal noHA POD Network Layout Example

   +-------------+------------------------------------------------------------+
   | ``cfg01``   | Salt Master Docker container                               |
   +-------------+------------------------------------------------------------+
   | ``mas01``   | MaaS Node Docker container                                 |
   +-------------+------------------------------------------------------------+
   | ``ctl01``   | Baremetal controller node                                  |
   +-------------+------------------------------------------------------------+
   | ``gtw01``   | Baremetal Gateway with neutron services                    |
   |             | (dhcp agent, L3 agent, metadata, etc)                      |
   +-------------+------------------------------------------------------------+
   | ``odl01``   | Baremetal node on which ODL runs                           |
   |             | (for scenarios deployed with ODL, otherwise unused         |
   +-------------+------------------------------------------------------------+
   | ``cmp001``, | Baremetal Computes                                         |
   | ``cmp002``  |                                                            |
   +-------------+------------------------------------------------------------+
   | Tenant VM   | VM running in the cloud                                    |
   +-------------+------------------------------------------------------------+

``baremetal`` ``HA`` POD
------------------------

.. figure:: img/fuel_baremetal_ha.png
   :align: center
   :width: 60%
   :alt: OPNFV Fuel Baremetal HA POD Network Layout Example

   OPNFV Fuel Baremetal HA POD Network Layout Example

   +---------------------------+----------------------------------------------+
   | ``cfg01``                 | Salt Master Docker container                 |
   +---------------------------+----------------------------------------------+
   | ``mas01``                 | MaaS Node Docker container                   |
   +---------------------------+----------------------------------------------+
   | ``kvm01``,                | Baremetals which hold the VMs with           |
   | ``kvm02``,                | controller functions                         |
   | ``kvm03``                 |                                              |
   +---------------------------+----------------------------------------------+
   | ``prx01``,                | Proxy VMs for Nginx                          |
   | ``prx02``                 |                                              |
   +---------------------------+----------------------------------------------+
   | ``msg01``,                | RabbitMQ Service VMs                         |
   | ``msg02``,                |                                              |
   | ``msg03``                 |                                              |
   +---------------------------+----------------------------------------------+
   | ``dbs01``,                | MySQL service VMs                            |
   | ``dbs02``,                |                                              |
   | ``dbs03``                 |                                              |
   +---------------------------+----------------------------------------------+
   | ``mdb01``,                | Telemetry VMs                                |
   | ``mdb02``,                |                                              |
   | ``mdb03``                 |                                              |
   +---------------------------+----------------------------------------------+
   | ``odl01``                 | VM on which ``OpenDaylight`` runs            |
   |                           | (for scenarios deployed with ``ODL``)        |
   +---------------------------+----------------------------------------------+
   | ``cmp001``,               | Baremetal Computes                           |
   | ``cmp002``                |                                              |
   +---------------------------+----------------------------------------------+
   | Tenant VM                 | VM running in the cloud                      |
   +---------------------------+----------------------------------------------+

.. code-block:: console

    # x86_x64 baremetal deploy on pod2 from Linux Foundation lab (lf-pod2)
    jenkins@jumpserver:~/fuel$ ci/deploy.sh -l lf \
                                            -p pod2 \
                                            -s os-nosdn-nofeature-ha \
                                            -D \
                                            -S /home/jenkins/tmpdir |& tee deploy.log

.. code-block:: console

    # aarch64 baremetal deploy on pod5 from Enea ARM lab (arm-pod5)
    jenkins@jumpserver:~/fuel$ ci/deploy.sh -l arm \
                                            -p pod5 \
                                            -s os-nosdn-nofeature-ha \
                                            -D \
                                            -S /home/jenkins/tmpdir |& tee deploy.log

``hybrid`` ``noHA`` POD
-----------------------

.. figure:: img/fuel_hybrid_noha.png
   :align: center
   :width: 60%
   :alt: OPNFV Fuel Hybrid noHA POD Network Layout Examples

   OPNFV Fuel Hybrid noHA POD Network Layout Examples

   +-------------+------------------------------------------------------------+
   | ``cfg01``   | Salt Master Docker container                               |
   +-------------+------------------------------------------------------------+
   | ``mas01``   | MaaS Node Docker container                                 |
   +-------------+------------------------------------------------------------+
   | ``ctl01``   | Controller VM                                              |
   +-------------+------------------------------------------------------------+
   | ``gtw01``   | Gateway VM with neutron services                           |
   |             | (``DHCP`` agent, ``L3`` agent, ``metadata`` agent etc)     |
   +-------------+------------------------------------------------------------+
   | ``odl01``   | VM on which ``ODL`` runs                                   |
   |             | (for scenarios deployed with ODL)                          |
   +-------------+------------------------------------------------------------+
   | ``cmp001``, | Baremetal Computes                                         |
   | ``cmp002``  |                                                            |
   +-------------+------------------------------------------------------------+

Automatic Deploy Breakdown
~~~~~~~~~~~~~~~~~~~~~~~~~~

When an automatic deploy is started, the following operations are performed
sequentially by the deploy script:

+------------------+----------------------------------------------------------+
| **Deploy stage** | **Details**                                              |
+==================+==========================================================+
| Argument         | enviroment variables and command line arguments passed   |
| Parsing          | to ``deploy.sh`` are interpreted                         |
+------------------+----------------------------------------------------------+
| Distribution     | Install and/or configure mandatory requirements on the   |
| Package          | ``jumpserver`` node:                                     |
| Installation     |                                                          |
|                  | - ``Docker`` (from upstream and not distribution repos,  |
|                  |   as the version included in ``Ubuntu`` ``Xenial`` is    |
|                  |   outdated);                                             |
|                  | - ``docker-compose`` (from upstream, as the version      |
|                  |   included in both ``CentOS 7`` and                      |
|                  |   ``Ubuntu Xenial 16.04`` has dependency issues on most  |
|                  |   systems);                                              |
|                  | - ``virt-inst`` (from upstream, as the version included  |
|                  |   in ``Ubuntu Xenial 16.04`` is outdated and lacks       |
|                  |   certain required features);                            |
|                  | - other miscelaneous requirements, depending on          |
|                  |   ``jumpserver`` distribution OS;                        |
|                  |                                                          |
|                  | .. SEEALSO::                                             |
|                  |                                                          |
|                  |     - ``mcp/scripts/requirements_deb.yaml`` (``Ubuntu``) |
|                  |     - ``mcp/scripts/requirements_rpm.yaml`` (``CentOS``) |
|                  |                                                          |
|                  | .. WARNING::                                             |
|                  |                                                          |
|                  |     Mininum required ``Docker`` version is ``17.x``.     |
|                  |                                                          |
|                  | .. WARNING::                                             |
|                  |                                                          |
|                  |     Mininum required ``virt-inst`` version is ``1.4``.   |
+------------------+----------------------------------------------------------+
| Patch            | For each ``git`` submodule in OPNFV Fuel repository,     |
| Apply            | if a subdirectory with the same name exists under        |
|                  | ``mcp/patches``, all patches in that subdirectory are    |
|                  | applied using ``git-am`` to the respective ``git``       |
|                  | submodule.                                               |
|                  |                                                          |
|                  | This allows OPNFV Fuel to alter upstream repositories    |
|                  | contents before consuming them, including:               |
|                  |                                                          |
|                  | - ``Docker`` container build process customization;      |
|                  | - ``salt-formulas`` customization;                       |
|                  | - ``reclass.system`` customization;                      |
|                  |                                                          |
|                  | .. SEEALSO::                                             |
|                  |                                                          |
|                  |     - ``mcp/patches/README.rst``                         |
+------------------+----------------------------------------------------------+
| SSH RSA Keypair  | If not already present, a RSA keypair is generated on    |
| Generation       | the ``jumpserver`` node at:                              |
|                  |                                                          |
|                  | - ``/var/lib/opnfv/mcp.rsa{,.pub}``                      |
|                  |                                                          |
|                  | The public key will be added to the ``authorized_keys``  |
|                  | list for ``ubuntu`` user, so the private key can be used |
|                  | for key-based logins on:                                 |
|                  |                                                          |
|                  | - ``cfg01``, ``mas01`` infrastructure nodes;             |
|                  | - all cluster nodes (``baremetal`` and/or ``virtual``),  |
|                  |   including ``VCP`` VMs;                                 |
+------------------+----------------------------------------------------------+
| ``j2``           | Based on ``XDF`` (``PDF``, ``IDF``, ``SDF``) and         |
| Expansion        | additional deployment configuration determined during    |
|                  | ``argument parsing`` stage described above, all jinja2   |
|                  | templates are expanded, including:                       |
|                  |                                                          |
|                  | - various classes in ``reclass.cluster``;                |
|                  | - docker-compose ``yaml`` for Salt Master bring-up;      |
|                  | - ``libvirt`` network definitions (``xml``);             |
+------------------+----------------------------------------------------------+
| Jumpserver       | Basic validation that common ``jumpserver`` requirements |
| Requirements     | are satisfied, e.g. ``PXE/admin`` is Linux bridge if     |
| Check            | ``baremetal`` nodes are defined in the ``PDF``.          |
+------------------+----------------------------------------------------------+
| Infrastucture    | .. NOTE::                                                |
| Setup            |                                                          |
|                  |     All steps apply to and only to the ``jumpserver``.   |
|                  |                                                          |
|                  | - prepare virtual machines;                              |
|                  | - (re)create ``libvirt`` managed networks;               |
|                  | - apply ``sysctl`` configuration;                        |
|                  | - apply ``udev`` configuration;                          |
|                  | - create & start virtual machines prepared earlier;      |
|                  | - create & start Salt Master (``cfg01``) Docker          |
|                  |   container;                                             |
+------------------+----------------------------------------------------------+
| ``STATE``        | Based on deployment type, scenario and other parameters, |
| Files            | a ``STATE`` file list is constructed, then executed      |
|                  | sequentially.                                            |
|                  |                                                          |
|                  | .. TIP::                                                 |
|                  |                                                          |
|                  |     The table below lists all current ``STATE`` files    |
|                  |     and their intended action.                           |
|                  |                                                          |
|                  | .. SEEALSO::                                             |
|                  |                                                          |
|                  |     For more information on how the list of ``STATE``    |
|                  |     files is constructed, see                            |
|                  |     :ref:`OPNFV Fuel User Guide <fuel-userguide>`.       |
+------------------+----------------------------------------------------------+
| Log              | Contents of ``/var/log`` are recursively gathered from   |
| Collection       | all the nodes, then archived together for later          |
|                  | inspection.                                              |
+------------------+----------------------------------------------------------+

``STATE`` Files Overview
------------------------

+---------------------------+-------------------------------------------------+
| ``STATE`` file            | Targets involved and main intended action       |
+===========================+=================================================+
| ``virtual_init``          | ``cfg01``: reclass node generation              |
|                           |                                                 |
|                           | ``jumpserver`` VMs (if present): basic OS       |
|                           | config                                          |
+---------------------------+-------------------------------------------------+
| ``maas``                  | ``mas01``: OS, MaaS configuration               |
|                           | ``baremetal`` node commissioning and deploy     |
|                           |                                                 |
|                           | .. NOTE::                                       |
|                           |                                                 |
|                           |     Skipped if no ``baremetal`` nodes are       |
|                           |     defined in ``PDF`` (``virtual`` deploy).    |
+---------------------------+-------------------------------------------------+
| ``baremetal_init``        | ``kvm``, ``cmp``: OS install, config            |
+---------------------------+-------------------------------------------------+
| ``dpdk``                  | ``cmp``: configure OVS-DPDK                     |
+---------------------------+-------------------------------------------------+
| ``networks``              | ``ctl``: create OpenStack networks              |
+---------------------------+-------------------------------------------------+
| ``neutron_gateway``       | ``gtw01``: configure Neutron gateway            |
+---------------------------+-------------------------------------------------+
| ``opendaylight``          | ``odl01``: install & configure ``ODL``          |
+---------------------------+-------------------------------------------------+
| ``openstack_noha``        | cluster nodes: install OpenStack without ``HA`` |
+---------------------------+-------------------------------------------------+
| ``openstack_ha``          | cluster nodes: install OpenStack with ``HA``    |
+---------------------------+-------------------------------------------------+
| ``virtual_control_plane`` | ``kvm``: create ``VCP`` VMs                     |
|                           |                                                 |
|                           | ``VCP`` VMs: basic OS config                    |
|                           |                                                 |
|                           | .. NOTE::                                       |
|                           |                                                 |
|                           |     Skipped if ``-N`` deploy argument is used.  |
+---------------------------+-------------------------------------------------+
| ``tacker``                | ``ctl``: install & configure Tacker             |
+---------------------------+-------------------------------------------------+

Release Notes
=============

Please refer to the :ref:`OPNFV Fuel Release Notes <fuel-releasenotes>`
article.

References
==========

For more information on the OPNFV ``Iruya`` 9.0 release, please see:

#. `OPNFV Home Page`_
#. `OPNFV Documentation`_
#. `OPNFV Software Downloads`_
#. `OPNFV Iruya Wiki Page`_
#. `OpenStack Rocky Release Artifacts`_
#. `OpenStack Documentation`_
#. `OpenDaylight Artifacts`_
#. `Mirantis Cloud Platform Documentation`_
#. `Saltstack Documentation`_
#. `Saltstack Formulas`_
#. `Reclass`_

.. FIXME: cleanup unused refs, extend above list
.. _`OpenDaylight`: https://www.opendaylight.org
.. _`OpenDaylight Artifacts`: https://www.opendaylight.org/software/downloads
.. _`MCP`: https://www.mirantis.com/software/mcp/
.. _`Mirantis Cloud Platform Documentation`: https://docs.mirantis.com/mcp/latest/
.. _`fuel git repository`: https://git.opnfv.org/fuel
.. _`pharos git repo`: https://git.opnfv.org/pharos
.. _`OpenStack Documentation`: https://docs.openstack.org/rocky
.. _`OpenStack Rocky Release Artifacts`: https://www.openstack.org/software/rocky
.. _`OPNFV Home Page`: https://www.opnfv.org
.. _`OPNFV Iruya Wiki Page`: https://wiki.opnfv.org/display/SWREL/Iruya
.. _`OPNFV Documentation`: https://docs.opnfv.org
.. _`OPNFV Software Downloads`: https://www.opnfv.org/software/downloads
.. _`Apache License 2.0`: https://www.apache.org/licenses/LICENSE-2.0
.. _`Saltstack Documentation`: https://docs.saltstack.com/en/latest/topics/
.. _`Saltstack Formulas`: https://salt-formulas.readthedocs.io/en/latest/
.. _`Reclass`: https://reclass.pantsfullofunix.net
.. _`OPNFV Pharos Specification`: https://wiki.opnfv.org/display/pharos/Pharos+Specification
.. _`OPNFV PDF Wiki Page`: https://wiki.opnfv.org/display/INF/POD+Descriptor
