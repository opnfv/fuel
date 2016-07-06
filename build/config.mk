##############################################################################
# Copyright (c) 2015,2016 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# This tag is NOT checked out, it only serves a cosmetic purpose of hinting
# what upstream Fuel components our submodules are bound to (while tracking
# remotes, ALL submodules will point to remote branch HEAD).
# NOTE: Pinning fuel-main or other submodules to a specific commit/tag is
# done ONLY via git submodules.
FUEL_MAIN_TAG = 9.0.1
MOS_VERSION   = 9.0
OPENSTACK_VERSION = mitaka-9.0

# List of space-separated Ubuntu architectures supported with current build
# Format: same as `dpkg-architecture -qDEB_HOST_ARCH1`
# NOTE: Currently only amd64 is supported by Fuel@OPNFV. Armband adds arm64.
export UBUNTU_ARCH ?= "amd64"

# FIXME(alav): Disable remote tracking for now, stick to submodule commits
FUEL_TRACK_REMOTES =

##############################################################################
# Fuel components pinning / remote tracking; use submodules from f_repos
##############################################################################

# git submodule & patch locations for Fuel components
F_GIT_ROOT   := $(shell git rev-parse --show-toplevel)
F_GIT_DIR    := $(shell git rev-parse --git-dir)
F_SUBMOD_DIR := ${F_GIT_ROOT}/build/f_repos/sub
F_PATCH_DIR  := ${F_GIT_ROOT}/build/f_repos/patch
F_OPNFV_TAG  := ${FUEL_MAIN_TAG}-opnfv

# fuel-main repo location used by main Makefile ISO building, use submodule
FUEL_MAIN_REPO := ${F_SUBMOD_DIR}/fuel-main

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
export FUELLIB_COMMIT?=${F_OPNFV_TAG}
export NAILGUN_COMMIT?=${F_OPNFV_TAG}
export PYTHON_FUELCLIENT_COMMIT?=${F_OPNFV_TAG}
export FUEL_AGENT_COMMIT?=${F_OPNFV_TAG}
export FUEL_NAILGUN_AGENT_COMMIT?=${F_OPNFV_TAG}
export ASTUTE_COMMIT?=${F_OPNFV_TAG}
export OSTF_COMMIT?=${F_OPNFV_TAG}
export FUEL_MIRROR_COMMIT?=${F_OPNFV_TAG}
export FUELMENU_COMMIT?=${F_OPNFV_TAG}
export SHOTGUN_COMMIT?=${F_OPNFV_TAG}
export NETWORKCHECKER_COMMIT?=${F_OPNFV_TAG}
export FUELUPGRADE_COMMIT?=${F_OPNFV_TAG}
export FUEL_UI_COMMIT?=${F_OPNFV_TAG}

# for the patches applying purposes (empty git config in docker build container)
export GIT_COMMITTER_NAME?=Fuel OPNFV
export GIT_COMMITTER_EMAIL?=fuel@opnfv.org

DOCKER_REPO := http://get.docker.com/builds/Linux/x86_64
DOCKER_TAG := docker-latest
