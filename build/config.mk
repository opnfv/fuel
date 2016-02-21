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
FUEL_MAIN_TAG := 9.0
MOS_VERSION = 9.0
OPENSTACK_VERSION = mitaka-9.0

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

