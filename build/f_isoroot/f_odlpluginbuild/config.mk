##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FUEL_PLUGIN_ODL_BRANCH ?= master
FUEL_PLUGIN_ODL_CHANGE ?= 0ff4ebdbfe5f681f0b44eea14c9c2b3dbb10b1d5
FUEL_PLUGIN_ODL_REPO ?= https://github.com/openstack/fuel-plugin-opendaylight.git

export ODL_TARBALL_LOCATION?=https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/0.4.3-Beryllium-SR3/distribution-karaf-0.4.3-Beryllium-SR3.tar.gz
export ODL_VERSION_NUMBER?=0.4.3
export ODL_BORON_TARBALL_LOCATION?=http://artifacts.opnfv.org/fuel/colorado/distribution-karaf-0.5.0-Boron-RC2.tar.gz
