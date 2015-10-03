#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# Default variable declarations

COMMAND=
PACKAGE_NAME=
PACKAGE_SHORT_NAME=
PACKAGE_VERSION=
TARGET_BUILD_PATH=
DEPENDENCIES=
MAINTAINER=
ARCH="amd64"
BUILD_HISTORY=".odl-build-history"

##############################################################################
# subroutine: usage
# Description: Prints out usage of this script

usage ()
{
cat <<EOF
usage: $0 options

$0 creates a ${PACKAGE_NAME} Debian package

OPTIONS:
  -n Package shoer name
  -N Package name
  -v Version
  -t Tag
  -p Target build path, the path where the built tar ball is to be fetched
  -m Maintainer
  -d Package dependencies
  -h Prints this message
  -C Clean

E.g.: $0 -n my/deb/src/dest/path -N my-package -v 1.0-1 -t myTag -p path/to/the/source -m "Main Tainer <main.tainer.exampe.org> -d myJavaDependence
EOF
}

##############################################################################
# subroutine: clean
# Description: Cleans up all artifacts from earlier builds

clean ()
{
if [ -e $BUILD_HISTORY ]; then
    while read line
    do
	rm -rf $line
    done < $BUILD_HISTORY
    rm ${BUILD_HISTORY}
    exit 0
fi
}

##############################################################################
# make-DEBIAN_control
# Description: constructs the Debian pack control file

make-DEBIAN_control ()
{
cat <<EOF
Package: $PACKAGE_SHORT_NAME
Version: $PACKAGE_VERSION
Section: base
Priority: optional
Architecture: $ARCH
Depends: $DEPENDENCIES
Maintainer: $MAINTAINER
Description: OpenDaylight deamon
 This is a daemon for the opendaylight/odl controller service.
EOF
}

##############################################################################
# subroutine: make-DEBIAN_conffiles
# Description: Constructs the Debian package config files assignment

make-DEBIAN_conffiles ()
{
cat <<EOF
/etc/odl/etc/all.policy
/etc/odl/etc/config.properties
/etc/odl/etc/custom.properties
/etc/odl/etc/distribution.info
/etc/odl/etc/equinox-debug.properties
/etc/odl/etc/java.util.logging.properties
/etc/odl/etc/jmx.acl.cfg
/etc/odl/etc/jmx.acl.java.lang.Memory.cfg
/etc/odl/etc/jmx.acl.org.apache.karaf.bundle.cfg
/etc/odl/etc/jmx.acl.org.apache.karaf.config.cfg
/etc/odl/etc/jmx.acl.org.apache.karaf.security.jmx.cfg
/etc/odl/etc/jmx.acl.osgi.compendium.cm.cfg
/etc/odl/etc/jre.properties
/etc/odl/etc/keys.properties
/etc/odl/etc/org.apache.felix.fileinstall-deploy.cfg
/etc/odl/etc/org.apache.karaf.command.acl.bundle.cfg
/etc/odl/etc/org.apache.karaf.command.acl.config.cfg
/etc/odl/etc/org.apache.karaf.command.acl.feature.cfg
/etc/odl/etc/org.apache.karaf.command.acl.jaas.cfg
/etc/odl/etc/org.apache.karaf.command.acl.kar.cfg
/etc/odl/etc/org.apache.karaf.command.acl.shell.cfg
/etc/odl/etc/org.apache.karaf.command.acl.system.cfg
/etc/odl/etc/org.apache.karaf.features.cfg
/etc/odl/etc/org.apache.karaf.features.obr.cfg
/etc/odl/etc/org.apache.karaf.features.repos.cfg
/etc/odl/etc/org.apache.karaf.jaas.cfg
/etc/odl/etc/org.apache.karaf.kar.cfg
/etc/odl/etc/org.apache.karaf.log.cfg
/etc/odl/etc/org.apache.karaf.management.cfg
/etc/odl/etc/org.apache.karaf.shell.cfg
/etc/odl/etc/org.ops4j.pax.logging.cfg
/etc/odl/etc/org.ops4j.pax.url.mvn.cfg
/etc/odl/etc/regions-config.xml
/etc/odl/etc/shell.init.script
/etc/odl/etc/startup.properties
/etc/odl/etc/system.properties
/etc/odl/etc/users.properties
/etc/odl/configuration/context.xml
/etc/odl/configuration/logback.xml
/etc/odl/configuration/tomcat-logging.properties
/etc/odl/configuration/tomcat-server.xml
EOF
}

##############################################################################
# subroutine: make-DEBIAN_postinst
# Description: Constructs the Debian package post installation script

make-DEBIAN_postinst ()
{
cat <<EOF
#!/bin/bash -e
ln -s /etc/${PACKAGE_SHORT_NAME}/* ${TARGET_INSTALL_PATH}
echo "OpenDaylight $TAG version $PACKAGE_VERSION has been installed"
EOF
}

##############################################################################
# subroutine: make-DEBIAN_bin
# Description: Constructs the bin script (normally under /usr/bin)

make-DEBIAN_bin ()
{
cat <<EOF
#!/bin/bash -e
${TARGET_INSTALL_PATH}bin/karaf $@
EOF
}

##############################################################################
# subroutine: make-DEBIAN_copyright
# Description: Constructs the copyright text (normally under /usr/share/doc...)

make-DEBIAN_copyright ()
{
cat <<EOF
OpenDaylight - an open source SDN controller
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF
}

##############################################################################
# subroutine: make-DEBIAN_changelog
# Description: Constructs the changelog text (normally under /usr/share/doc...)

make-DEBIAN_changelog ()
{
cat <<EOF
$PACKAGE_SHORT_NAME ($PACKAGE_VERSION) precise-proposed; urgency=low

  * Derived from $PACKAGE_NAME $PACHAGE_VERSION

 -- $MAINTAINER  $(date)
EOF
}

##############################################################################
# MAIN

while getopts "N:n:v:d:Chm:t:p:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;

        N)
            PACKAGE_NAME=$OPTARG
            COMMAND+="-N ${PACKAGE_NAME} "
            ;;

        n)
            PACKAGE_SHORT_NAME=$OPTARG
            COMMAND+="-n ${PACKAGE_SHORT_NAME} "
            ;;

	v)
            PACKAGE_VERSION=$OPTARG
            COMMAND+="-v ${PACKAGE_VERSION} "
            ;;

	p)
	    TARGET_BUILD_PATH=$OPTARG
	    COMMAND+="-p ${TARGET_BUILD_PATH} "
	    ;;

	t)
            TAG=$OPTARG
            COMMAND+="-t ${TAG} "
            ;;

	m)
	    MAINTAINER=$OPTARG
            COMMAND+="-m ${MAINTAINER} "
            ;;

	d)
	    DEPENDENCIES=$OPTARG
            COMMAND+="-d ${DEPENDENCIES} "
            ;;

        A)
	    ARCH=$OPTARG
	    COMMAND+="-A ${ARCH} "
            ;;

        C)
	    COMMAND+="-C "
	    clean
	    exit 0
            ;;
    esac
done

# Constructing script variables
DEB_PACK_BASE_PATH="f_${PACKAGE_SHORT_NAME}/package/${PACKAGE_NAME}_${PACKAGE_VERSION}"
echo ${DEB_PACK_BASE_PATH} >> "$BUILD_HISTORY"
TARGET_INSTALL_PATH="/usr/share/java/${PACKAGE_SHORT_NAME}/"
DEB_PACK_CONTENT_PATH="${DEB_PACK_BASE_PATH}/usr/share/java/${PACKAGE_SHORT_NAME}/"
DEB_PACK_CONFIG_PATH="${DEB_PACK_BASE_PATH}/etc/${PACKAGE_SHORT_NAME}"
TARGET_TAR=$(ls ${TARGET_BUILD_PATH}*.tar.gz)
TARGET_TAR="${TARGET_TAR##*/}"
TAR_PATH="${TARGET_TAR%.*}"
TAR_PATH="${TAR_PATH%.*}"
if [ -e $DEB_PACK_BASE_PATH ]; then
    rm -R $DEB_PACK_BASE_PATH
fi

# Create Deb pack content and configuration
mkdir -p ${DEB_PACK_CONTENT_PATH}
cp ${TARGET_BUILD_PATH}${TARGET_TAR} ${DEB_PACK_CONTENT_PATH}
tar -xzf ${DEB_PACK_CONTENT_PATH}${TARGET_TAR} -C ${DEB_PACK_CONTENT_PATH}
rm ${DEB_PACK_CONTENT_PATH}${TARGET_TAR}
mv ${DEB_PACK_CONTENT_PATH}${TAR_PATH}/* ${DEB_PACK_CONTENT_PATH}.
rm -R ${DEB_PACK_CONTENT_PATH}${TAR_PATH}

# Crate and populate Deb pack config target
mkdir -p ${DEB_PACK_CONFIG_PATH}/etc
mv ${DEB_PACK_CONTENT_PATH}etc/* ${DEB_PACK_CONFIG_PATH}/etc/
rm -R ${DEB_PACK_CONTENT_PATH}etc
mkdir -p ${DEB_PACK_CONFIG_PATH}/configuration
mv ${DEB_PACK_CONTENT_PATH}configuration/* ${DEB_PACK_CONFIG_PATH}/configuration/
rm -R ${DEB_PACK_CONTENT_PATH}configuration

# Set package permisions
find ${DEB_PACK_CONTENT_PATH} -type d -print -exec chmod 755 {} \;
find ${DEB_PACK_CONFIG_PATH}/etc/ -type f -print -exec chmod 644 {} \;
find ${DEB_PACK_CONFIG_PATH}/etc/ -type d -print -exec chmod 755 {} \;

# Create package usr/bin odl script
mkdir  "${DEB_PACK_BASE_PATH}/usr/bin"
chmod 755 "${DEB_PACK_BASE_PATH}/usr/bin"
make-DEBIAN_bin > "${DEB_PACK_BASE_PATH}/usr/bin/odl"
chmod 755 "${DEB_PACK_BASE_PATH}/usr/bin/odl"

# Create Deb pack install meta-data
mkdir "${DEB_PACK_BASE_PATH}/DEBIAN"
make-DEBIAN_control > "${DEB_PACK_BASE_PATH}/DEBIAN/control"
make-DEBIAN_conffiles > "${DEB_PACK_BASE_PATH}/DEBIAN/conffiles"
mkdir -p "${DEB_PACK_BASE_PATH}/usr/share/doc/${PACKAGE_SHORT_NAME}"
make-DEBIAN_copyright > "${DEB_PACK_BASE_PATH}/usr/share/doc/${PACKAGE_SHORT_NAME}/copyright"
make-DEBIAN_changelog > "${DEB_PACK_BASE_PATH}/usr/share/doc/${PACKAGE_SHORT_NAME}/changelog.Debian"

# Create Deb pack post install symlinks and usr/bin scripts
make-DEBIAN_postinst > "${DEB_PACK_BASE_PATH}/DEBIAN/postinst"
chmod 755  "${DEB_PACK_BASE_PATH}/DEBIAN/postinst"
mkdir -p "${DEB_PACK_BASE_PATH}/usr/bin"
