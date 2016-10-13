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
FUEL_MAIN_TAG := 9.1
MOS_VERSION = 9.0
OPENSTACK_VERSION = mitaka-9.0

# Pinning down exact Fuel repo versions for Fuel 9.1
export FUELLIB_COMMIT?=c6103ad39257e89fa5fae59bf4bfb54ffae07c2b
export NAILGUN_COMMIT?=78fbccc9ac1fad1f05bfc9e68677d4ef24b1a0aa
# Top of stable/mitaka
export PYTHON_FUELCLIENT_COMMIT?=81d1905c00d3c4522f08849a39b2c5a730bb1093

export FUEL_AGENT_COMMIT?=898bcca75224ad82fa98a85b77651faaf554e2b6
export FUEL_NAILGUN_AGENT_COMMIT?=e7bd486ec6d8c65ce5611dad69059e0b7c22f394
export ASTUTE_COMMIT?=2158ea9a60c3f750ec32fd3911213683dadad21f
export OSTF_COMMIT?=ff066dd2900dbc3ec50764b4aa86136098f5c0f3
export FUEL_MIRROR_COMMIT?=d1ef06b530ce2149230953bb3810a88ecaff870c
export FUELMENU_COMMIT?=c4ff3eebde75daab40fb7c7aba175543024e9fb6
export SHOTGUN_COMMIT?=781a8cfa0b6eb290e730429fe2792f2b6f5e0c11
# Top of stable/mitaka
export NETWORKCHECKER_COMMIT?=2dc38414ab9bc32e9dc5b1ab71bea4e4d8eb1bb3

export FUELUPGRADE_COMMIT?=c1c4bac6a467145ac4fac73e4a7dd2b00380ecfb
export FUEL_UI_COMMIT?=b0dc8f854141ba562f2e24374cb3f1db2edbb78b

# for the patches applying purposes
export GIT_COMMITTER_NAME?=Fuel OPNFV
export GIT_COMMITTER_EMAIL?=fuel@opnfv.org

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

