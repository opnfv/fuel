##############################################################################
# Copyright (c) 2015,2016 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# fuel-main tag checked out from upstream `fuel-main` repo before patching it
FUEL_MAIN_TAG = 9.0.1
MOS_VERSION   = 9.0
OPENSTACK_VERSION = mitaka-9.0

# fuel-main repo location used by main Makefile ISO building, use submodule
FUEL_MAIN_REPO := ${F_SUBMOD_DIR}/fuel-main

# FIXME(alav): Disable remote tracking for now, stick to submodule commits
FUEL_TRACK_REMOTES =

##############################################################################
# Fuel components pinning / remote tracking; use submodules from f_repos
##############################################################################

# git submodule & patch locations for Fuel components
F_GIT_ROOT   := $(shell git rev-parse --show-toplevel)
F_SUBMOD_DIR := ${F_GIT_ROOT}/build/f_repos/sub
F_PATCH_DIR  := ${F_GIT_ROOT}/build/f_repos/patch

export FUELLIB_REPO?=${F_SUBMOD_DIR}/fuel-library
export NAILGUN_REPO?=${F_SUBMOD_DIR}/fuel-web
export PYTHON_FUELCLIENT_REPO?=${F_SUBMOD_DIR}/python-fuelclient
export FUEL_AGENT_REPO?=${F_SUBMOD_DIR}/fuel-agent
export FUEL_NAILGUN_AGENT_REPO?=${F_SUBMOD_DIR}/fuel-nailgun-agent
export ASTUTE_REPO?=${F_SUBMOD_DIR}/fuel-astute
export OSTF_REPO?=${F_SUBMOD_DIR}/fuel-ostf
export FUEL_MIRROR_REPO?=${F_SUBMOD_DIR}/fuel-mirror
export FUELMENU_REPO?=${F_SUBMOD_DIR}/fuel-menu
export SHOTGUN_REPO?=${F_SUBMOD_DIR}/shotgun
export NETWORKCHECKER_REPO?=${F_SUBMOD_DIR}/network-checker
export FUELUPGRADE_REPO?=${F_SUBMOD_DIR}/fuel-upgrade
export FUEL_UI_REPO?=${F_SUBMOD_DIR}/fuel-ui

# OPNFV tags are automatically applied by `make -C f_repos patches-import`
export FUELLIB_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export NAILGUN_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export PYTHON_FUELCLIENT_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUEL_AGENT_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUEL_NAILGUN_AGENT_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export ASTUTE_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export OSTF_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUEL_MIRROR_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUELMENU_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export SHOTGUN_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export NETWORKCHECKER_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUELUPGRADE_COMMIT?=${FUEL_MAIN_TAG}-opnfv
export FUEL_UI_COMMIT?=${FUEL_MAIN_TAG}-opnfv

# for the patches applying purposes (empty git config in docker build container)
export GIT_COMMITTER_NAME?=Fuel OPNFV
export GIT_COMMITTER_EMAIL?=fuel@opnfv.org

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest
