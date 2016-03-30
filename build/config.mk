##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FUEL_MAIN_REPO := https://github.com/openstack/fuel-main
FUEL_MAIN_TAG = a365f05b903368225da3fea9aa42afc1d50dc9b4
MOS_VERSION = 8.0
OPENSTACK_VERSION = liberty-8.0

# Pinning down exact Fuel repo versions
export FUELLIB_COMMIT=c2a335b5b725f1b994f78d4c78723d29fa44685a
export NAILGUN_COMMIT=feff938157ce26d09409219350f126214dfeae4c
export PYTHON_FUELCLIENT_COMMIT=4f234669cfe88a9406f4e438b1e1f74f1ef484a5
export FUEL_AGENT_COMMIT=658be72c4b42d3e1436b86ac4567ab914bfb451b
export FUEL_NAILGUN_AGENT_COMMIT=b2bb466fd5bd92da614cdbd819d6999c510ebfb1
export ASTUTE_COMMIT=b81577a5b7857c4be8748492bae1dec2fa89b446
export OSTF_COMMIT=3bc76a63a9e7d195ff34eadc29552f4235fa6c52
export FUEL_MIRROR_COMMIT=fb45b80d7bee5899d931f926e5c9512e2b442749
export FUELMENU_COMMIT=78ffc73065a9674b707c081d128cb7eea611474f
export SHOTGUN_COMMIT=63645dea384a37dde5c01d4f8905566978e5d906
export NETWORKCHECKER_COMMIT=a43cf96cd9532f10794dce736350bf5bed350e9d
export FUELUPGRADE_COMMIT=616a7490ec7199f69759e97e42f9b97dfc87e85b

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

