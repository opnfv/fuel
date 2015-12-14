##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# REPO Information for fuel and build system
#
FUEL_MAIN_REPO := https://github.com/openstack/fuel-main
FUEL_MAIN_TAG = stable/7.0

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

# Target kernel version, needed for some of the build steps
# NOTE! The defined versions must match the kernel version of
# Ubunto and CentOS running on the compute- and controller
# nodes deployed by Fuel!
#
export TARGET_UBUNTU_KERNEL := 3.13.0-66-generic
export TARGET_CENTOS_KERNEL := 3.13.0-66-generic

# Extended build targets
#
.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

