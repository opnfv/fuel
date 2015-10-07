##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Change the below value with "uuidgen" to force a full cache rebuild - a
# temporary as we work with improving the caching functionality for the next
# release.
CACHE_RND := 73b88a88-9714-4010-888e-e7cd4b26d5e4

FUEL_MAIN_REPO := https://github.com/stackforge/fuel-main
FUEL_MAIN_TAG = stable/6.1

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

