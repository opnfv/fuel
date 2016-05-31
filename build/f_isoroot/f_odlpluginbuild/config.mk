##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

ODL_BRANCH ?= master
ODL_CHANGE ?= 1c8443ffc64af120337740551307378d1c21535d
ODL_REPO ?= https://github.com/openstack/fuel-plugin-opendaylight.git

FPB_BRANCH ?= master
FPB_CHANGE ?= 82191ca16b40021e445e854fad37c65cd8e70b0c
FPB_REPO ?= https://github.com/openstack/fuel-plugins

export USE_JAVA8?=true
export JAVA8_URL?=https://launchpad.net/~openjdk-r/+archive/ubuntu/ppa/+files/openjdk-8-jre-headless_8u72-b15-1~trusty1_amd64.deb
export ODL_TARBALL_LOCATION?=https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.4.2-Beryllium-SR2/distribution-karaf-0.4.2-Beryllium-SR2.tar.gz
export ODL_VERSION_NUMBER?=0.4.2
