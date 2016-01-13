
Fuel configuration
==================
This section describes providing guidelines on how to install and
configure the Brahmaputra release of OPNFV when using Fuel as a
deployment tool including required software and hardware
configurations.

Although the available installation options gives a high degree of
freedom in how the system is set-up including architecture, services
and features, etc. said permutations may not provide an OPNFV
compliant reference architecture. This section provides a
step-by-step guide that results in an OPNFV Brahmaputra compliant
deployment.

The audience of this section is assumed to have good knowledge in
networking and Unix/Linux administration.

Pre-configuration activities
-----------------------------

Planning the deployment

Before starting the installation of the Brahmaputra WP1 release of
OPNFV when using Fuel as a deployment tool, some planning must be
done.

Next, familiarize yourself with the Fuel 7.0 version by reading the
following documents:

- Fuel planning guide
  <https://docs.mirantis.com/openstack/fuel/fuel-7.0/planning-guide.html>

- Fuel user guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html>

- Fuel operations guide
  <http://docs.mirantis.com/openstack/fuel/fuel-7.0/operations.html>


A number of deployment specific parameters must be collected, those are:

#.     Provider sub-net and gateway information

#.     Provider VLAN information

#.     Provider DNS addresses

#.     Provider NTP addresses

#.     Network Topology you plan to Deploy (VLAN, GRE(VXLAN), FLAT)

#.     Linux Distro you intend to deploy.

#.     How many nodes and what roles you want to deploy (Controllers,
Storage, Computes)

#.     Monitoring Options you want to deploy (Ceilometer, MongoDB).

#.     Other options not covered in the document are available in the
links above


Retrieving the ISO image
^^^^^^^^^^^^^^^^^^^^^^^^
First of all, the Fuel deployment ISO image needs to be retrieved, the
.iso image of the Brahmaputra release of OPNFV when using Fuel as
a deployment tool can be found at:

NOTE: TO BE UPDATED WITH FINAL B-RELASE ARTIFACT

Alternatively, you may build the .iso from source by cloning the
opnfv/genesis git repository.  To retrieve the repository for the Arno
release use the following command:

- git clone https://<linux foundation uid>@gerrit.opnf.org/gerrit/fuel

Check-out the Brahmaputra release tag to set the branch to the
baseline required to replicate the Brahmaputra release:

- TODO: NEEDS UPDATE TO REFLECT WP1 TAG / NEW REPO - cd genesis; git
  checkout stable/arno2015.2.0

Go to the fuel directory and build the .iso:

- cd fuel/build; make all

For more information on how to build, please see "OPNFV Build
instructions for - Brahmaputra WP1 release of OPNFV when using Fuel as
a deployment tool which you retrieved with the repository at
</fuel/fuel/docs/src/build-instructions.rst>


Hardware configuration
----------------------
The following minimum hardware requirements must be met for the
installation of Brahmaputra WP1 using Fuel:

Hardware requirements
^^^^^^^^^^^^^^^^^^^^^
Following high level hardware requirements must be met:

+--------------------+------------------------------------------------------+
| **HW Aspect**      | **Requirement**                                      |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **# of nodes**     | Minimum 6 (3 for non redundant deployment):          |
|                    |                                                      |
|                    | - 1 Fuel deployment master (may be virtualized)      |
|                    |                                                      |
|                    | - 3(1) Controllers                                   |
|                    |                                                      |
|                    | - 1 Compute                                          |
|                    |                                                      |
|                    | - 1 Ceilometer (VM option)                           |
+--------------------+------------------------------------------------------+
| **CPU**            | Minimum 1 socket x86_AMD64 with Virtualization       |
|                    |   support                                            |
+--------------------+------------------------------------------------------+
| **RAM**            | Minimum 16GB/server (Depending on VNF work load)     |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **Disk**           | Minimum 256GB 10kRPM spinning disks                  |
|                    |                                                      |
+--------------------+------------------------------------------------------+
| **Networks**       | 4 Tagged VLANs (PUBLIC, MGMT, STORAGE, PRIVATE)      |
|                    |                                                      |
|                    | 1 Un-Tagged VLAN for PXE Boot - ADMIN Network        |
|                    |                                                      |
|                    | note: These can be run on single NIC - or spread out |
|                    |  over other nics as your hardware supports           |
+--------------------+------------------------------------------------------+

For a detailed hardware compatibility matrix - please see:
<https://www.mirantis.com/products/openstack-drivers-and-plugins/hardware-compatibility-list/>

Top of the rack (TOR) Configuration requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The switching infrastructure provides connectivity for the OPNFV
infrastructure operations, tenant networks (East/West) and provider
connectivity (North/South bound connectivity); it also provides needed
connectivity for the storage Area Network (SAN). To avoid traffic
congestion, it is strongly suggested that three physically separated
networks are used, that is: 1 physical network for administration and
control, one physical network for tenant private and public networks,
and one physical network for SAN. The switching connectivity can (but
does not need to) be fully redundant, in such case it and comprises a
redundant 10GE switch pair for each of the three physically separated
networks.

The physical TOR switches are **not** automatically configured from
the OPNFV reference platform. All the networks involved in the OPNFV
infrastructure as well as the provider networks and the private tenant
VLANs needs to be manually configured.

Manual configuration of the Brahmaputra hardware platform should
be carried out according to the Pharos specification TODO-<insert link
to Pharos ARNO SR1 Specification>

Jumphost configuration
-----------------------
The Jumphost server requires 2 (4 if redundancy is required) ethernet interfaces - one for external management of the OPNFV installation, and another for jump-host communication with the OPNFV cluster.

Install the Fuel jump-host
^^^^^^^^^^^^^^^^^^^^^^^^^^
#. Mount the Brahmaputra WP1 ISO file as a boot device to the jump host server.

#. Reboot the jump host to establish the Fuel server.

   - The system now boots from the ISO image.

   - Select 'DVD Fuel Install (Static IP)'

   - Press [Enter].

#. Wait until screen Fuel setup is shown (Note: This can take up to 30 minutes).

#. In the 'Fuel User' Section - Confirm/change the default password
   - Enter 'admin' in the Fuel password input

   - Enter 'admin' in the Confim password input

   - Select 'Check' and press [Enter]

#. In 'Network Setup' Section - Configure DHCP/Static IP information
for your FUEL node - For example, ETH0 is 10.20.0.2/24 for FUEL
booting and ETH1 is DHCP in your corporate/lab network.

   - Configure eth1 or other network interfaces here as well (if you
     have them present on your FUEL server).

#. In 'PXE Setup' Section - Change the following fields to appropriate
values (example below):

   - DHCP Pool Start 10.20.0.3

   - DHCP Pool End 10.20.0.254

   - DHCP Pool Gateway  10.20.0.2 (ip of Fuel node)

#. In 'DNS & Hostname' - Change the following fields to appropriate values:

   - Hostname <OPNFV Region name>-fuel

   - Domain <Domain Name>

   - Search Domain <Search Domain Name>

   - External DNS

   - Hostname to test DNS <Hostname to test DNS>

   - Select 'Check' and press [Enter]


#. OPTION TO ENABLE PROXY SUPPORT - In 'Bootstrap Image', edit the
following fields to define a proxy.

        NOTE: cannot be used in tandem with local repo support
        NOTE: not tested with ODL for support (plugin)

   - Navigate to 'HTTP proxy' and input your http proxy address

   - Select 'Check' and press [Enter]


#. In 'Time Sync' Section - Change the following fields to appropriate values:

   - NTP Server 1 <Customer NTP server 1>

   - NTP Server 2 <Customer NTP server 2>

   - NTP Server 3 <Customer NTP server 3>

#. Start the installation.

   - Select Quit Setup and press Save and Quit.

   - Installation starts, wait until a screen with logon credentials is shown.

Platform components configuration
---------------------------------

Fuel-Plugins
^^^^^^^^^^^^
Fuel plugins enable you to install and configure additional capabilities for
your Fuel OPNFV based cloud, such as additional storage types, networking
functionality, or NFV features developed by OPNFV.

Fuel offers an open source framework for creating these plugins, so there’s a wide range of capabilities that you can enable Fuel to add to your OpenStack clouds.

The OPNFV Brahmaputra version of Fuel provides a set of pre-packaged plugins developed by OPNFV:

+--------------------+------------------------------------------------------+
|  **Plugin name**   | **Short description**                                |
|                    |                                                      |
+--------------------+------------------------------------------------------+
|                    |                                                      |
|                    |                                                      |
+--------------------+------------------------------------------------------+
*Additional third-party plugins can be found here:*
*https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/*

The plugins come prepackaged, ready to install. To do so follow the instructions below:

#. SSH to your FUEL node (e.g. ssh root@10.20.0.2  pwd: r00tme)

#. Verify that the plugins you intend to install exists at /opt/opnfv/

#. Install the plugins of your choice with the command

    - "fuel plugins --install /opt/opnfv/<plugin-package-name>.rpm

    - Expected output: "Plugin nn was successfully installed."

**Note: Plugins are not necessarilly compatible with each other, see section XYZ
for compatibility information**

Fuel environment
^^^^^^^^^^^^^^^^
A Fuel environment is an OpenStack instance managed by Fuel, one Fuel instance can manage several OpenStack instances with different configurations.
To create a Fuel instance, follollw the instructions below:

#. Connect to Fuel WEB UI with a browser towards port
http://<fuel-server-ip>:8000 (login admin/admin)

#. Create and name a new OpenStack environment, to be installed.

#. Select <Liberty on Ubuntu 14.04> and press "Next"

#. Select "KVM" compute virtulization method.

#. Select "Tun" as the network segmentation mode.

#. Select "CEPH" Storage Back-end.

#. Select "Ceilometer" and "Heat" aditional services.

#. Create the new environment by clicking the "Create" Button

Aditional features and services
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Although we have already earlier installed the plugins, it doesnt mean those
are enabled for the environment we just created. The plugins of you choice need to be enabled and configured as instructed below:

#. In the FUEL UI of your Enviornment, click the "Settings" Tab

#. On the left hand side, select the name of the plugin you want enable and
click, "enable".

#. Configure the plugins according to the respective feature configuration
sections in this document.

#. Click "Save Settings" at the bottom to Save your changes

**Note: Plugins are not necessarilly compatible with each other, see section XYZ
for compatibility information**

Networking
^^^^^^^^^^
Configure your network settings as instructed below:

#. Open the networks tab.

#. Update the Public network configuration.

    Change the following fields to appropriate values:

    - IP Range Start to <Public IP Address start>

    - IP Range End to <Public IP Address end>

    - CIDR to <CIDR for Public IP Addresses>

    - Check VLAN tagging.

    - Set appropriate VLAN id.

    - Gateway to <Gateway for Public IP Addresses>

    - Set floating ip ranges

#. Update the Storage Network Configuration

    - Set CIDR to appropriate value  (default 192.168.1.0/24)

    - Set vlan to appropriate value  (default 102)

#. Update the Management network configuration.

    - Set CIDR to appropriate value (default 192.168.0.0/24)

    - Check VLAN tagging.

    - Set appropriate VLAN id. (default 101)

#. Update the Private Network Information

    - Set CIDR to appropriate value (default 192.168.2.0/24

    - Check and set VLAN tag appropriately (default 103)

#. Update the Neutron L3 configuration.

    - Set Internal network CIDR to an appropriate value

    - Set Internal network gateway to an appropriate value

    - Set Guest OS DNS Server values appropriately

#. Save Settings

#. Open the "setings tab"

#. On the left hand pane, select DNS-settings and enter the upstream DNS
address(es) and click "save settings" at the bottom.

#. On the left hand pane, select NTP-settings and enter the upstream NTP
address(es) and click "save settings" at the bottom.

Node allocation
^^^^^^^^^^^^^^^
Now, it is time to allocate the nodes in your OPNFV cluster to OpenStack-, SDN-, and other feature/service roles. To do so, follow the instructions below:

#. Enable PXE booting
   - For every controller and compute server: enable PXE Booting as
     the first boot device in the BIOS boot order menu and hard disk
     as the second boot device in the same menu.

#. Power-cycle all controller- servers and compute servers

#. Wait for the availability of nodes showing up in the Fuel GUI.
   - Wait until all nodes are displayed in top right corner of the
     Fuel GUI: <total number of server> TOTAL NODES and <total number
     of servers> UNALLOCATED NODES.

#. Click on the "Nodes" Tab in the FUEL WEB UI.

#. Assign roles.
   - Click on "Add Nodes" button
   - Check "Controller" and the "Storage-Ceph OSD"  in the Assign Roles Section
   - In case you have enabled one of the SDN features/sevices plugins, check
     the controller roles for the respective SDN service.
   - Check the 3 Nodes you want to act as Controllers from the bottom half of the screen
   - Click <Apply Changes>.
   - Click on "Add Nodes" button
   - Check "Compute" in the Assign Roles Section
    - Check the Nodes that you want to act as Computes from the bottom half of the screen
    - Click <Apply Changes>.

#. Configure interfaces.
   - Check Select <All> to select all nodes
   - Click <Configure Interfaces>
   - Screen Configure interfaces on number of <number of nodes> nodes is shown.
   - Assign interfaces (bonded) for mgmt-, admin-, private-, public-
     and storage networks
   - Note: Set MTU level to at least MTU=1458 (recommended
           MTU=1450 for SDN over VXLAN Usage)
   - Click Apply

Off-line deployment
^^^^^^^^^^^^^^^^^^^
The OPNFV Brahmaputra version of Fuel can be deployed uing on-line upstream
repositories (default) or off-line using built-in local repositories on the
Fuel jump-start server.

If you do not have Internet connectivitey, or for other reasons want to perform an off-line deployment - follow the instructions below:

#.  In the Fuel UI of your Environment, click the Settings Tab and
 on the left hand pane - select the Repositories tab.
    - Replace the URI values for the "Name" values outlined below:
    - "ubuntu" URI="deb http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
    - "ubuntu-security" URI="deb
      http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
    - "ubuntu-updates" URI="deb
      http://<ip-of-fuel-server>:8080/ubuntu-part trusty main"
    - "mos-updates"  URI="deb
      http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-updates main
      restricted"
    - "mos-security" URI="deb
      http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-security main
      restricted"
    - "mos-holdback" URI="deb
      http://<ip-of-fuel-server>:8080/mos-ubuntu mos6.1-holdback main
      restricted"
    - Click "Save Settings" at the bottom to Save your changes

Deployment
^^^^^^^^^^
You should now be ready to deploy your OPNFV Brahmaputra environment - but before doing so you may want to verify your network settings. Follow the instructions below to verify your settings and start the deployment:

#.  From the FUEL UI in your Environment, Select the Networks Tab
    - At the bottom of the page, Select "Verify Networks"
    - Continue to fix your topology (physical switch, etc) until the
      "Verification Succeeded - Your network is configured correctly"
      message is shown.

#. Deploy the environment.
   - In the Fuel GUI, click on the Dashboard Tab.
   - Click on 'Deploy Changes' in the 'Ready to Deploy?' Section
   - Examine any information notice that pops up and click 'Deploy'
   - Wait for your deployment to complete, you can view the 'Dashboard'
     Tag to see the progress and status of your deployment.

Post-installation checks
^^^^^^^^^^^^^^^^^^^^^^^^
#. Perform system health-check
   - Click the "Health Check" tab inside your Environment in the FUEL Web UI
   - Check "Select All" and Click "Run Tests"
   - Allow tests to run and investigate results where appropriate

#. Consult the feature sections in this document for any post-install
   configurations or health-checks

Feature/Service/Plugin compatibility
------------------------------------

Platform anf feature/services roles
-----------------------------------
