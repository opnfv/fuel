..ThisworkislicensedunderaCreativeCommonsAttribution4.0InternationalLicense.
..http://creativecommons.org/licenses/by/4.0
..(c)OpenPlatformforNFVProject,Inc.anditscontributors

========
Abstract
========

ThisdocumentcontainsdetailsabouthowtouseOPNFVFuel-Euphrates
release-afteritwasdeployed.Fordetailsonhowtodeploycheckthe
installationinstructionsinthe:ref:`references`section.

Thisisanunifieddocumentationforbothx86_64andaarch64
architectures.Allinformationiscommonforbotharchitectures
exceptwhenexplicitlystated.



================
NetworkOverview
================

Fuelusesseveralnetworkstodeployandadministerthecloud:

+------------------+-------------------+---------------------------------------------------------+
|Networkname|DeployType|Description|
||||
+==================+===================+=========================================================+
|**PXE/ADMIN**|baremetalonly|UsedforbootingthenodesviaPXE|
+------------------+-------------------+---------------------------------------------------------+
|**MCPCONTROL**|baremetal&|UsedtoprovisiontheinfrastructureVMs(Salt&MaaS).|
||virtual|Onvirtualdeploys,itisusedforAdmintoo(ontarget|
|||VMs)leavingthePXE/Adminbridgeunused|
+------------------+-------------------+---------------------------------------------------------+
|**Mgmt**|baremetal&|Usedforinternalcommunicationbetween|
||virtual|OpenStackcomponents|
+------------------+-------------------+---------------------------------------------------------+
|**Internal**|baremetal&|UsedforVMdatacommunicationwithinthe|
||virtual|clouddeployment|
+------------------+-------------------+---------------------------------------------------------+
|**Public**|baremetal&|UsedtoprovideVirtualIPsforpublicendpoints|
||virtual|thatareusedtoconnecttoOpenStackservicesAPIs.|
|||UsedbyVirtualmachinestoaccesstheInternet|
+------------------+-------------------+---------------------------------------------------------+


Thesenetworks-exceptmcpcontrol-canbelinuxbridgesconfiguredbeforethedeployonthe
Jumpserver.Iftheydon'texistsatdeploytime,theywillbecreatedbythescriptsasvirsh
networks.

McpcontrolexistsonlyontheJumpserverandneedstobevirtualbecauseaDHCPserverruns
onthisnetworkandassociatesstatichostentryIPsforSaltandMaasVMs.



===================
AccessingtheCloud
===================

AccesstoanycomponentofthedeployedcloudisdonefromJumpservertouser*ubuntu*with
sshkey*/var/lib/opnfv/mcp.rsa*.TheexamplebelowisaconnectiontoSaltmaster.

..code-block::bash

$ssh-oStrictHostKeyChecking=no-i/var/lib/opnfv/mcp.rsa-lubuntu10.20.0.2

**Note**:TheSaltmasterIPisnothardset,itisconfigurableviaINSTALLER_IPduringdeployment


TheFuelbaremetaldeployhasaVirtualizedControlPlane(VCP)whichmeansthatthecontroller
servicesareinstalledinVMsonthebaremetaltargets(kvmservers).TheseVMscanalsobe
accessedwithvirshconsole:user*opnfv*,password*opnfv_secret*.Thismethoddoesnotapply
toinfrastructureVMs(SaltmasterandMaaS).

TheexamplebelowisaconnectiontoacontrollerVM.Theconnectionismadefromthebaremetal
serverkvm01.

..code-block::bash

$ssh-oStrictHostKeyChecking=no-i/var/lib/opnfv/mcp.rsa-lubuntux.y.z.141
ubuntu@kvm01:~$virshconsolectl01

User*ubuntu*hassudorights.User*opnfv*hassudorightsonlyonaarch64deploys.


=============================
ExploringtheCloudwithSalt
=============================

Togatherinformationaboutthecloud,thesaltcommandscanbeused.Itisbased
aroundamaster-minionideawherethesalt-masterpushesconfigtotheminionsto
executeactions.

Forexampletellsalttoexecuteapingto8.8.8.8onallthenodes.

..figure::img/saltstack.png

Complexfilterscanbedonetothetargetlikecompoundqueriesornoderoles.
FormoreinformationaboutSaltseethe:ref:`references`section.

Someexamplesarelistedbelow.NotethatthesecommandsareissuedfromSaltmaster
with*root*user.


#.ViewtheIPsofallthecomponents

..code-block::bash

root@cfg01:~$salt"*"network.ip_addrs
cfg01.baremetal-mcp-ocata-odl-ha.local:
-10.20.0.2
-172.16.10.100
mas01.baremetal-mcp-ocata-odl-ha.local:
-10.20.0.3
-172.16.10.3
-192.168.11.3
.........................


#.Viewtheinterfacesofallthecomponentsandputtheoutputinafilewithyamlformat

..code-block::bash

root@cfg01:~$salt"*"network.interfaces--outyaml--output-fileinterfaces.yaml
root@cfg01:~#catinterfaces.yaml
cfg01.baremetal-mcp-ocata-odl-ha.local:
enp1s0:
hwaddr:52:54:00:72:77:12
inet:
-address:10.20.0.2
broadcast:10.20.0.255
label:enp1s0
netmask:255.255.255.0
inet6:
-address:fe80::5054:ff:fe72:7712
prefixlen:'64'
scope:link
up:true
.........................


#.ViewinstalledpackagesinMaaSnode

..code-block::bash

root@cfg01:~#salt"mas*"pkg.list_pkgs
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


#.Executeanylinuxcommandonallnodes(listthecontentof*/var/log*inthisexample)

..code-block::bash

root@cfg01:~#salt"*"cmd.run'ls/var/log'
cfg01.baremetal-mcp-ocata-odl-ha.local:
alternatives.log
apt
auth.log
boot.log
btmp
cloud-init-output.log
cloud-init.log
.........................


#.Executeanylinuxcommandonnodesusingcompoundqueriesfilter

..code-block::bash

root@cfg01:~#salt-C'*andcfg01*'cmd.run'ls/var/log'
cfg01.baremetal-mcp-ocata-odl-ha.local:
alternatives.log
apt
auth.log
boot.log
btmp
cloud-init-output.log
cloud-init.log
.........................


#.Executeanylinuxcommandonnodesusingrolefilter

..code-block::bash

root@cfg01:~#salt-I'nova:compute'cmd.run'ls/var/log'
cmp001.baremetal-mcp-ocata-odl-ha.local:
alternatives.log
apache2
apt
auth.log
btmp
ceilometer
cinder
cloud-init-output.log
cloud-init.log
.........................



===================
AccessingOpenstack
===================

Oncethedeploymentiscomplete,OpenstackCLIisaccessiblefromcontrollerVMs(ctl01..03).
Openstackcredentialsareat*/root/keystonercv3*.

..code-block::bash

root@ctl01:~#sourcekeystonercv3
root@ctl01:~#openstackimagelist
+--------------------------------------+-----------------------------------------------+--------+
|ID|Name|Status|
+======================================+===============================================+========+
|152930bf-5fd5-49c2-b3a1-cae14973f35f|CirrosImage|active|
|7b99a779-78e4-45f3-9905-64ae453e3dcb|Ubuntu16.04|active|
+--------------------------------------+-----------------------------------------------+--------+


TheOpenStackDashboard,Horizonisavailableathttp://<controllerVIP>:8078,e.g.http://10.16.0.101:8078.
Theadministratorcredentialsare*admin*/*opnfv_secret*.

..figure::img/horizon_login.png


AfulllistofIPs/servicesisavailableat<proxypublicVIP>:8090forbaremetaldeploys.

..figure::img/salt_services_ip.png

ForVirtualdeploys,themostcommonlyusedIPsareinthetablebelow.

+-----------+--------------+---------------+
|Component|IP|Defaultvalue|
+===========+==============+===============+
|gtw01|x.y.z.110|172.16.10.110|
+-----------+--------------+---------------+
|ctl01|x.y.z.100|172.16.10.100|
+-----------+--------------+---------------+
|cmp001|x.y.z.105|172.16.10.105|
+-----------+--------------+---------------+
|cmp002|x.y.z.106|172.16.10.106|
+-----------+--------------+---------------+

=============================
Reclassmodelviewertutorial
=============================


Tovisualizethereclassstructureonemightuse`reclass-doc
<https://github.com/jirihybek/reclass-doc>`_whichcanbe
usedtovisualizethereclassstructure.Inordertosimplifytheinstallationandtoavoid
installingpackagesonthehostwhichmightcollidewithotherpackages,inthistutorial,wewill
installeverythinginadockerubuntucontainerandthenjustuseawebbrowseronthehosttoview
theresults.

*Instructions

#Wewillbeginwithacleanfuelrepoinadedicateddirectory.Ofcoursethelocationdoes
notmatter.onecanchangethelocation.

..code-block::bash

$mkdir-p/home/fuel/modeler

.........................

#Placearmbandintheabovedirectory

..code-block::bash

$cd/home/fuel/modeler

$gitclonegitclonehttps://gerrit.opnfv.org/gerrit/fuel&&cdfuel

.........................

#Createacontainerandmounttheabovehostdirectory

..code-block::bash

$dockerrun--privileged-it-v/home/fuel/modeler:/hostubuntubash

.........................

#Installalltherequiredpackagesinsidethecontainer.

	..code-block::bash

$apt-getupdate

$apt-getinstall-ynpmnodejs

$npminstall-greclass-doc

$cd/host/armband/upstream/fuel/mcp/reclass

$ln-s/usr/bin/nodejs/usr/bin/node

$reclass-doc--output/host/host/fuel/mcp/reclass

.........................

#Viewtheresultsfromthehostbyusingabrowser.Thefiletoopenshouldbenowinthe
directory/home/fuel/modeler/index.html


.._references:

==========
References
==========

1)`Installationinstructions<http://docs.opnfv.org/en/stable-euphrates/submodules/fuel/docs/release/installation/installation.instruction.html>`_
2)`SaltstackDocumentation<https://docs.saltstack.com/en/latest/topics>`_
3)`SaltstackFormulas<http://salt-formulas.readthedocs.io/en/latest/develop/overview-reclass.html>`_


