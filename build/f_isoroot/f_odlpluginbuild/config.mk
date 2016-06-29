##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

ODL_BRANCH ?= master
ODL_CHANGE ?= c539dc87d905e9c9992d6624c11814c4eda4c5ca
ODL_REPO ?= https://github.com/openstack/fuel-plugin-opendaylight.git

FPB_BRANCH ?= master
FPB_CHANGE ?= 82191ca16b40021e445e854fad37c65cd8e70b0c
FPB_REPO ?= https://github.com/openstack/fuel-plugins

export ODL_TARBALL_LOCATION?=https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.4.2-Beryllium-SR2/distribution-karaf-0.4.2-Beryllium-SR2.tar.gz
export ODL_VERSION_NUMBER?=0.4.2
export ODL_BORON_TARBALL_LOCATION?=https://nexus.opendaylight.org/content/repositories/staging/org/opendaylight/integration/distribution-karaf/0.5.0-Boron/distribution-karaf-0.5.0-Boron.tar.gz
