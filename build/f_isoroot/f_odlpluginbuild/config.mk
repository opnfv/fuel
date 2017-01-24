##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FUEL_PLUGIN_ODL_BRANCH ?= master
FUEL_PLUGIN_ODL_CHANGE ?= 581fcf5c41ec1a584057b31a1af740351fb5faef
FUEL_PLUGIN_ODL_REPO ?= https://github.com/openstack/fuel-plugin-opendaylight.git

export ODL_TARBALL_LOCATION?=https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.5.0-Boron/distribution-karaf-0.5.0-Boron.tar.gz
export ODL_VERSION_NUMBER?=0.5.0
