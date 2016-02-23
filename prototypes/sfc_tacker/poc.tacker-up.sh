#!/bin/bash

#
# POC Script to build/install/deploy/orchestrate Tacker on an OPNFV Brhamaputra Fuel cluster
#         Script assuming it runs on the openstack primary controller (where is opendaylight
#         present) and there is a fuel master on 10.20.0.2 and can be reached with default
#         credentials.
#
# author: Ferenc Cserepkei <ferenc.cserepkei@ericsson.com>
#
#         (c) 2016 Telefonaktiebolaget L. M. ERICSSON
#
#         All rights reserved. This program and the accompanying materials are made available
#         under the terms of the Apache License, Version 2.0 which accompanies this distribution,
#         and is available at http://www.apache.org/licenses/LICENSE-2.0
#


SSH_OPTIONS=(-o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null -o LogLevel=error)

MYDIR=$(dirname $(readlink -f "$0"))
MYREPO="tacker-server"
CLIREPO="tacker-client"
DEPREPO="jsonrpclib"

CLIENT="python-python-tackerclient_0.0.1~dev48-1_all.deb"
JSONRPC="python-jsonrpclib_0.1.7-1_all.deb"
SERVER="python-tacker_2014.2.0~dev176-1_all.deb"

# Function checks whether crudini is available, if not - installs
function chkCrudini () {
    if [[ ! -f '/usr/bin/crudini' ]]; then
        wget -N http://mirrors.kernel.org/ubuntu/pool/universe/p/python-iniparse/python-iniparse_0.4-2.1build1_all.deb
        wget -N http://archive.ubuntu.com/ubuntu/pool/universe/c/crudini/crudini_0.3-1_amd64.deb
        dpkg -i python-iniparse_0.4-2.1build1_all.deb crudini_0.3-1_amd64.deb
    fi
}

# Function checks whether a python egg is available, if not, installs
function chkPPkg () {
    PKG="$1"
    IPPACK=$(python - <<'____EOF'
import pip
from os.path import join
for package in pip.get_installed_distributions():
    print(package.location)
    print(join(package.location, *package._get_metadata("top_level.txt")))
____EOF
)
    echo "$IPPACK" | grep -q "$PKG"
    if [ $? -ne 0 ];then
        pip install "$PKG"
    fi
}

# Function setting up the build/deploy environment
function envSetup () {
    apt-get update
    apt-get install -y git python-pip python-all debhelper
    chkPPkg stdeb
    chkCrudini
}

# Function installs jsonrpclib from github
function deployJsonrpclib () {
    if [[ -e "${MYDIR}/${JSONRPC}" ]]; then
        echo "$JSONRPC exists."
        return 1
    fi
    cd $MYDIR
    rm -rf $DEPREPO
    git clone https://github.com/joshmarshall/jsonrpclib.git $DEPREPO
    cd $DEPREPO
    dpkg --purge python-jsonrpclib
    python setup.py --command-packages=stdeb.command bdist_deb
    cd "deb_dist"
    cp $JSONRPC $MYDIR
    dpkg -i $JSONRPC
}

# Function builds Tacker server from github
function buildTackerServer () {
    if [[ -e "${MYDIR}/${SERVER}" ]]; then
        echo "$SERVER exists."
        return 1
    fi
    cd $MYDIR
    rm -rf $MYREPO
    git clone  -b 'SFC_brahmaputra' https://github.com/trozet/tacker.git $MYREPO
    cd $MYREPO
    patch -p  1 <<EOFSCP
diff -ruN a/setup.cfg b/setup.cfg
--- a/setup.cfg	2016-02-08 10:54:37.416525934 +0100
+++ b/setup.cfg	2016-02-08 10:55:29.293428896 +0100
@@ -22,14 +22,14 @@
 packages =
     tacker
 data_files =
-    etc/tacker =
+    /etc/tacker =
         etc/tacker/api-paste.ini
         etc/tacker/policy.json
         etc/tacker/tacker.conf
         etc/tacker/rootwrap.conf
-    etc/rootwrap.d =
+    /etc/rootwrap.d =
         etc/tacker/rootwrap.d/servicevm.filters
-    etc/init.d = etc/init.d/tacker-server
+    /etc/init.d = etc/init.d/tacker-server

 [global]
 setup-hooks =
EOFSCP
    dpkg --purge python-tacker
    python setup.py --command-packages=stdeb.command bdist_deb
}

# Function corrects and installs the Tacker-server debian package
function blessPackage () {
    DEBFILE="${MYDIR}/${MYREPO}/deb_dist/${SERVER}"
    TMPDIR=$(mktemp -d /tmp/deb.XXXXXX) || exit 1
    OUTPUT=$(basename "$DEBFILE")
    if [[ -e "${MYDIR}/${OUTPUT}" ]]; then
	echo "$OUTPUT exists."
	rm -r "$TMPDIR"
	return 1
    fi
    dpkg-deb -x "$DEBFILE" "$TMPDIR"
    dpkg-deb --control "$DEBFILE" "${TMPDIR}/DEBIAN"
    cd "$TMPDIR"
    patch -p 1 <<EOFDC
diff -ruN a/DEBIAN/control b/DEBIAN/control
--- a/DEBIAN/control	2016-02-08 10:06:18.000000000 +0000
+++ b/DEBIAN/control	2016-02-08 10:45:09.501373675 +0000
@@ -4,7 +4,7 @@
 Architecture: all
 Maintainer: OpenStack <openstack-dev@lists.openstack.org>
 Installed-Size: 1575
-Depends: python (>= 2.7), python (<< 2.8), python:any (>= 2.7.1-0ubuntu2), python-pbr, python-paste, python-pastedeploy, python-routes, python-anyjson, python-babel, python-eventlet, python-greenlet, python-httplib2, python-requests, python-iso8601, python-jsonrpclib, python-jinja2, python-kombu, python-netaddr, python-sqlalchemy (>= 1.0~), python-sqlalchemy (<< 1.1), python-webob, python-heatclient, python-keystoneclient, alembic, python-six, python-stevedore, python-oslo.config, python-oslo.messaging-, python-oslo.rootwrap, python-novaclient
+Depends: python (>= 2.7), python (<< 2.8), python:any (>= 2.7.1-0ubuntu2), python-pbr, python-paste, python-pastedeploy, python-routes, python-anyjson, python-babel, python-eventlet, python-greenlet, python-httplib2, python-requests, python-iso8601, python-jsonrpclib, python-jinja2, python-kombu, python-netaddr, python-sqlalchemy (>= 1.0~), python-sqlalchemy (<< 1.1), python-webob, python-heatclient, python-keystoneclient, alembic, python-six, python-stevedore, python-oslo.config, python-oslo.messaging, python-oslo.rootwrap, python-novaclient
 Section: python
 Priority: optional
 Description: OpenStack servicevm/device manager
EOFDC
    cd "$MYDIR"
    echo "Patching  deb..."
    dpkg -b "$TMPDIR" "${MYDIR}/${OUTPUT}"
    rm -r "$TMPDIR"
    dpkg -i "${MYDIR}/${OUTPUT}"
}

# Function deploys Tacker-server (installs missing mandatory files: upstart, default)
function deployTackerServer () {
    rm -rf /etc/default/tacker-server
    cat > /etc/default/tacker-server <<EOFTD
ENABLED=true
PIDFILE=/var/run/tacker/tacker-server.pid
LOGFILE=/var/log/tacker/tacker-server.log
PATH="\${PATH:+\$PATH:}/usr/sbin:/sbin"
TMPDIR=/var/lib/tacker/tmp
EOFTD
    rm -rf /etc/init/tacker.conf
    cat > /etc/init/tacker.conf <<EOFSC
# tacker-server - Provides the Tacker servicevm/device manager service
description      "Openstack Tacker Server"
author           "Ferenc Cserepkei <ferenc.cserepkei@ericsson.com>"

start on runlevel [2345]
stop on runlevel [!2345]

respawn
respawn limit 20 5
limit nofile 65535 65535

chdir /var/run

pre-start script
  # stop job from continuing if no config file found for daemon
  [ ! -f /etc/default/tacker-server ] && { stop; exit 0; }
  [ ! -f /etc/tacker/tacker.conf ]  && { stop; exit 0; }

  # source the config file
  . /etc/default/tacker-server

  # stop job from continuing if admin has not enabled service in
  # config file.
  [ -z "\$ENABLED" ] && { stop; exit 0; }

  mkdir -p /var/run/tacker
  mkdir -p /var/log/tacker
  echo "Starting tacker server"
end script

pre-stop script
  echo "Stopping tacker server"
end script

exec /usr/bin/python /usr/bin/tacker-server --log-file=/var/log/tacker/tacker-server.log -v -d --config-file=/etc/tacker/tacker.conf
EOFSC
}

# Function installs python-tackerclient from github
function deployTackerClient() {
    if [[ -e "${MYDIR}/${CLIENT}" ]]; then
        echo "$CLIENT exists."
        return 1
    fi
    cd $MYDIR
    rm -rf $CLIREPO
    dpkg --purge python-tackerclient
    git clone -b 'SFC_refactor' https://github.com/trozet/python-tackerclient.git $CLIREPO
    cd $CLIREPO
    python setup.py --command-packages=stdeb.command bdist_deb
    cd "deb_dist"
    cp $CLIENT $MYDIR
    dpkg -i $CLIENT
}

# Function removes the cloned git repositories
function remove_repo () {
    if [[ -d "${MYDIR}/${1}" ]]; then
        rm -r "$1"
    fi
}

# Funcion copies and installs built artifact on all remaining cluster nodes
function populate_client() {
    wget -O deb http://archive.ubuntu.com/ubuntu/pool/universe/s/sshpass/sshpass_1.05-1_amd64.deb &&\
    dpkg -i deb &&\
    rm deb

    clusternodes=$(sshpass -p "r00tme" ssh ${SSH_OPTIONS[@]} root@10.20.0.2 fuel node | cut -d '|' -f 5 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" )
    myaddr=$(ifconfig br-fw-admin | sed -n '/inet addr/s/.*addr.\([^ ]*\) .*/\1/p')
    for anode in $clusternodes ; do
        if [ "$anode" != "$myaddr" ] ; then
            echo "Installing $CLIENT on $anode"
            scp ${SSH_OPTIONS[@]} $CLIENT $anode:$CLIENT
            ssh ${SSH_OPTIONS[@]} $anode dpkg -i $CLIENT
            ssh ${SSH_OPTIONS[@]} $anode rm $CLIENT
        fi
    done
}

# Function orchestrate the Tacker service
function orchestarte () {
    rm -rf /etc/puppet/modules/tacker
    pushd /etc/puppet/modules
    git clone https://github.com/trozet/puppet-tacker.git tacker
    rm -rf /etc/puppet/modules/tacker/.git
    popd

    ### Facts ###

    # Port(s)   Protocol ServiceDetails Source
    # 8805-8872 tcp,udp  Unassigned     IANA
    bind_port='8808'

    auth_uri=$(crudini --get '/etc/heat/heat.conf' 'keystone_authtoken' 'auth_uri')
    identity_uri=$(crudini --get '/etc/heat/heat.conf' 'keystone_authtoken' 'identity_uri')
    mgmt_addr=$(ifconfig br-mgmt | sed -n '/inet addr/s/.*addr.\([^ ]*\) .*/\1/p')
    pub_addr=$(ifconfig br-ex-lnx | sed -n '/inet addr/s/.*addr.\([^ ]*\) .*/\1/p')
    rabbit_host=$(crudini --get '/etc/heat/heat.conf' 'oslo_messaging_rabbit' 'rabbit_hosts'| cut -d ':' -f 1)
    rabbit_password=$(crudini --get '/etc/heat/heat.conf' 'oslo_messaging_rabbit' 'rabbit_password')
    sql_host=$(hiera database_vip)
    database_connection="mysql://tacker:tacker@${sql_host}/tacker"
    admin_url="http://${mgmt_addr}:${bind_port}"
    public_url="http://${pub_addr}:${bind_port}"
    heat_api_vip=$(crudini --get '/etc/heat/heat.conf' 'heat_api' 'bind_host')
    allowed_hosts="[ '${sql_host}', '${HOSTNAME%%.domain.tld}', 'localhost', '127.0.0.1', '%' ]"
    heat_uri="http://${heat_api_vip}:8004/v1"
    odl_port='8282'
    service_tenant='services'
    myRegion='RegionOne'
    myPassword='tacker'

    cat > configure_tacker.pp << EOF
   class mysql::config {}
   include mysql::config
   class mysql::server {}
   include mysql::server

   class { 'tacker':
     package_ensure        => 'absent',
     client_package_ensure => 'absent',
     bind_port             => '${bind_port}',
     keystone_password     => '${myPassword}',
     keystone_tenant       => '${service_tenant}',
     auth_uri              => '${auth_uri}',
     identity_uri          => '${identity_uri}',
     database_connection   => '${database_connection}',
     rabbit_host           => '${rabbit_host}',
     rabbit_password       => '${rabbit_password}',
     heat_uri              => '${heat_uri}',
     opendaylight_host     => '${mgmt_addr}',
     opendaylight_port     => '${odl_port}',
   }

   class { 'tacker::db::mysql':
       password      => '${myPassword}',
       dbname        => 'tacker',
       user          => 'tacker',
       host          => '127.0.0.1',
       charset       => 'utf8',
       collate       => 'utf8_general_ci',
       allowed_hosts => ${allowed_hosts},
   }

   class { 'tacker::keystone::auth':
     password            => '${myPassword}',
     tenant              => '${service_tenant}',
     admin_url           => '${admin_url}',
     internal_url        => '${admin_url}',
     public_url          => '${public_url}',
     region              => '${myRegion}',
   }
EOF

    puppet apply configure_tacker.pp
    rm -f tackerc
    cat > tackerc <<EOFRC
#!/bin/sh
export LC_ALL=C
export OS_NO_CACHE='true'
export OS_TENANT_NAME='${service_tenant}'
export OS_PROJECT_NAME='${service_tenant}'
export OS_USERNAME='tacker'
export OS_PASSWORD='tacker'
export OS_AUTH_URL='${auth_uri}'
export OS_DEFAULT_DOMAIN='default'
export OS_AUTH_STRATEGY='keystone'
export OS_REGION_NAME='RegionOne'
EOFRC
    chmod +x tackerc
}

# Funcion copies and installs built environment settings on all remaining cluster nodes
function populate_rc() {
    wget -O deb http://archive.ubuntu.com/ubuntu/pool/universe/s/sshpass/sshpass_1.05-1_amd64.deb &&\
    dpkg -i deb &&\
    rm deb

    clusternodes=$(sshpass -p "r00tme" ssh ${SSH_OPTIONS[@]} root@10.20.0.2 fuel node | cut -d '|' -f 5 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" )
    myaddr=$(ifconfig br-fw-admin | sed -n '/inet addr/s/.*addr.\([^ ]*\) .*/\1/p')
    for anode in $clusternodes ; do
        if [ "$anode" != "$myaddr" ] ; then
            echo "Populating seetings to $anode"
            scp ${SSH_OPTIONS[@]} tackerc $anode:tackerc
        fi
    done
}

envSetup
deployTackerClient
deployJsonrpclib
buildTackerServer
blessPackage
deployTackerServer
populate_client
orchestarte
populate_rc

remove_repo "$MYREPO"
remove_repo "$DEPREPO"
remove_repo "$CLIREPO"

echo "Built: ${MYDIR}/${OUTPUT}"
echo "Built: ${MYDIR}/${CLIENT}"
echo "Built: ${MYDIR}/${JSONRPC}"
echo "tackerc - mandatory environmental parameters file created"
