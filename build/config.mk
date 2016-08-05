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
FUEL_MAIN_TAG := 9.0.1
MOS_VERSION = 9.0
OPENSTACK_VERSION = mitaka-9.0

# Pinning down exact Fuel repo versions for Fuel 9.0.1
export FUELLIB_COMMIT?=e283b62750d9e26355981b3ad3be7c880944ae0f
export NAILGUN_COMMIT?=e2b85bafb68c348f25cb7cceda81edc668ba2e64
export PYTHON_FUELCLIENT_COMMIT?=67d8c693a670d27c239d5d175f3ea2a0512c498c
export FUEL_AGENT_COMMIT?=7ffbf39caf5845bd82b8ce20a7766cf24aa803fb
export FUEL_NAILGUN_AGENT_COMMIT?=46fa0db0f8944f9e67699d281d462678aaf4db26
export ASTUTE_COMMIT?=390b257240d49cc5e94ed5c4fcd940b5f2f6ec64
export OSTF_COMMIT?=f09c98ff7cc71ee612b2450f68a19f2f9c64345a
export FUEL_MIRROR_COMMIT?=d1ef06b530ce2149230953bb3810a88ecaff870c
export FUELMENU_COMMIT?=0ed9e206ed1c6271121d3acf52a6bf757411286b
export SHOTGUN_COMMIT?=781a8cfa0b6eb290e730429fe2792f2b6f5e0c11
export NETWORKCHECKER_COMMIT?=fcb47dd095a76288aacf924de574e39709e1f3ca
export FUELUPGRADE_COMMIT?=c1c4bac6a467145ac4fac73e4a7dd2b00380ecfb
export FUEL_UI_COMMIT?=90de7ef4477230cb7335453ed26ed4306ca6f04f

# for the patches applying purposes
export GIT_COMMITTER_NAME?=Fuel OPNFV
export GIT_COMMITTER_EMAIL?=fuel@opnfv.org

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest

.PHONY: get-fuel-repo
get-fuel-repo:
	@echo $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)

