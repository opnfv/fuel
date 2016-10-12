##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL = /bin/bash

# This file will be created if needed by runcontext to contain proxy
# settings.
-include environment.mk

############################################################################
# BEGIN of variables to customize
#
#Input args
export MOSVERSION = 10.0
export ISOSRC = file:$(shell pwd)/fuel-$(MOSVERSION).iso
export ISOCACHE = $(shell pwd)/$(shell basename $(ISOSRC))
export PRODNO ?= "OPNFV_FUEL"
export REVSTATE = "P0000"
export USER ?= $(shell whoami)
export BUILD_DATE = $(shell date --utc +%Y-%m-%d:%H:%M)
export OPNFV_GIT_SHA ?= $(shell git rev-parse HEAD)
# Store in /etc/fuel_build_id on fuel master
export BUILD_ID := $(PRODNO)_$(BUILD_DATE)_$(OPNFV_GIT_SHA)

ifdef BUILD_FUEL_PLUGINS
$(warning Overriding plugin build selection to $(BUILD_FUEL_PLUGINS))
export NEWISO = $(shell pwd)/release/unofficial-opnfv-${REVSTATE}.iso
else
export NEWISO = $(shell pwd)/release/opnfv-${REVSTATE}.iso
endif

# Note! Invoke with "make REVSTATE=RXXXX all" to make release build!
# Invoke with ICOCACHE=/full/path/to/iso if cached ISO is in non-standard location.

# Build variables
export BUILD_BASE := $(shell pwd)
export DEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/main
export UDEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/debian-installer
export PUPPET_DEST := $(BUILD_BASE)/release/puppet/modules
export VERSION_FILE := $(BUILD_BASE)/.versions
export DOCKERIMG = opnfv.org/ubuntu-builder:14.04
export TOPDIR := $(shell pwd)
export REPOINFO  := $(BUILD_BASE)/repo_info.sh

# Use snapshots
# Use nearby repositories
export MIRROR_UBUNTU_URL := $(shell ./f_isoroot/f_repobuild/select_ubuntu_repo.sh --url)
export MIRROR_UBUNTU := $(shell echo "$(MIRROR_UBUNTU_URL)" | cut -d'/' -f3 )
export MIRROR_UBUNTU_ROOT := $(shell echo -n '/' ; echo "$(MIRROR_UBUNTU_URL)" | cut -d'/' -f4-)

export LATEST_MIRROR_ID_URL := http://$(shell ./select_closest_fuel_mirror.py)

export MIRROR_MOS_UBUNTU ?= $(shell echo "$(LATEST_MIRROR_ID_URL)" | cut -d'/' -f3)
#export LATEST_TARGET_UBUNTU := $(shell curl -sSf "$(MIRROR_MOS_UBUNTU)/mos-repos/ubuntu/$(MOSVERSION).target.txt" | head -1)
# Fuel 9.0
export LATEST_TARGET_UBUNTU := snapshots/9.0-2016-06-23-164100-copy
export MIRROR_MOS_UBUNTU_ROOT := /mos-repos/ubuntu/$(LATEST_TARGET_UBUNTU)

export LATEST_TARGET_CENTOS := $(shell curl -sSf "$(LATEST_MIRROR_ID_URL)/mos-repos/centos/mos$(MOSVERSION)-centos7/os.target.txt" | head -1)
export MIRROR_FUEL := "$(LATEST_MIRROR_ID_URL)/mos-repos/centos/mos$(MOSVERSION)-centos7/$(LATEST_TARGET_CENTOS)/x86_64"

# uncomment and use: make print-VARIABLE
#print-%  : ; @echo $* = $($*)

#Build subclasses

SUBDIRS := f_isoroot

# f_example is only an example of how to generate a .deb package and
# should not be enabled in official builds.
#SUBDIRS += f_example

ORIGDIR := $(TOPDIR)/origiso
#
# END of variables to customize
#############################################################################

FUEL_MAIN_DIR := /tmp/fuel-main

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker
	@lsb_release -a | grep Ubuntu > /dev/null 2>&1 || (echo 'Ubuntu is the only supported Linux distribution for this build system'; exit 1)
	@KERNEL_VER=$$(uname -r); \
	KERNEL_ARRAY=($${KERNEL_VER//./ }); \
	if [ $${KERNEL_ARRAY[0]} -lt 3  ] || [[ $${KERNEL_ARRAY[0]} -eq 3 && $${KERNEL_ARRAY[1]} -lt 19  ]] ; then (echo 'Kernel version must be 3.19 or newer'; exit 1) ; fi
	@docker/runcontext $(DOCKERIMG) wget -q www.google.com -O /dev/null || (echo 'No docker network connectivity or name server - check your network- and docker settings'; exit 1)
	@docker/runcontext $(DOCKERIMG) $(MAKE) $(MAKEFLAGS) iso


############################################################################
# BEGIN of Include definitions
#
include config.mk
include cache.mk
#
# END Include definitions
#############################################################################

$(ISOCACHE):
	# Clone Fuel to non-persistent location and build
	sudo rm -rf $(FUEL_MAIN_DIR)
	$(MAKE) -C f_repos -f Makefile release
	git clone $(FUEL_MAIN_REPO) $(FUEL_MAIN_DIR)
	# Save upstream ref, checkout OPNFV tag (upstream ref + patches)
	@echo "fuel" `git -C $(FUEL_MAIN_DIR) \
		rev-parse $(F_OPNFV_TAG)-root` >> $(VERSION_FILE)
	git -C $(FUEL_MAIN_DIR) checkout $(F_OPNFV_TAG)
	# Remove Docker optimizations, otherwise multistrap will fail during
	# Fuel build.
	sudo rm -f /etc/apt/apt.conf.d/docker*
	#
	# Need to replace the old Docker v. 1.5.0 with a later version to be
	# able to access the Docker remote repository!
	sudo apt-get install apt-transport-https ca-certificates -y
	sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
	sudo apt-get update -y
	sudo apt-get install docker-engine -y
	sudo sh -c 'echo DOCKER_OPTS=\"--bip 172.45.0.1/24\" > /etc/default/docker'
	sudo service docker stop || exit 0
	sudo service docker start

	cd $(FUEL_MAIN_DIR) && ./prepare-build-env.sh
	# Verify that Docker is alive
	sudo docker info
	# fuel-main Makefiles do not like `make -C`
	cd $(FUEL_MAIN_DIR) && make repos
	cp f_repos/.cachefuelinfo gitinfo_fuel.txt

	# Repeat build up to three times
	sudo -E ./fuel_build_loop
	cp $(FUEL_MAIN_DIR)/build/artifacts/fuel*.iso .
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

.PHONY: mount-origiso umount-origiso
mount-origiso: $(ISOCACHE)
	@echo "Mounting original ISO in $(ORIGDIR)"
	@mkdir -p $(ORIGDIR)
	@fuseiso $(ISOCACHE) $(ORIGDIR)

umount-origiso:
	@echo "Unmounting original ISO from $(ORIGDIR)"
	@fusermount -u $(ORIGDIR)
	@rmdir $(ORIGDIR)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	@mkdir -p release/packages/ubuntu/pool/main release/packages/ubuntu/pool/debian-installer release/puppet/modules release/isoroot
	$(MAKE) -C $@ -f Makefile release

.PHONY: patch-packages
patch-packages:
	ORIGISO=$(ISOCACHE) REVSTATE=$(REVSTATE) $(MAKE) -C $@ -f Makefile release

.PHONY: clean $(SUBCLEAN)
clean:  $(SUBCLEAN)
	$(MAKE) -C f_repos -f Makefile clean
	$(MAKE) -C patch-packages -f Makefile clean
	@rm -f *.iso
	@rm -Rf release
	@rm -Rf newiso
	@rm -Rf .versions
	@rm -f $(NEWISO)
	@rm -f $(BUILD_BASE)/gitinfo_*.txt

.PHONY: deepclean
deepclean: clean clean-cache
	$(MAKE) -C f_repos -f Makefile deepclean
	$(MAKE) -C docker clean
	docker rmi opnfv.org/ubuntu-builder:14.04 &>/dev/null || exit 0
	docker rmi opnfv.org/ubuntu-builder:latest &>/dev/null || exit 0
	docker rmi ubuntu:14.04 &>/dev/null || exit 0
	@if docker images | grep -q "ubuntu *14.04"; then \
		echo "Error: ubuntu:14.04 still present!"; \
		exit 1; \
	fi
	@if docker images | grep -q "opnfv.org/ubuntu-builder"; then \
		echo "Error: opnfv.org/ubuntu-builder still present!"; \
		exit 1; \
	fi

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean

.PHONY: setup-env
setup-env:
	@if [ -f environment.mk ]; then \
		sudo bash -c "cat environment.mk >> /etc/environment"; \
	fi

# Todo: Make things smarter - we shouldn't need to clean everything
# betwen make invocations.
.PHONY: iso
iso:	setup-env $(ISOCACHE) $(SUBDIRS) patch-packages
	$(REPOINFO) . > gitinfo_main.txt
	install/install.sh iso $(ISOCACHE) $(NEWISO) $(PRODNO) $(REVSTATE)
	@printf "\n\nProduct ISO is $(NEWISO)\n\n"

# Start a bash shell in docker for Makefile debugging
.PHONY: debug
debug:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker
	docker/runcontext $(DOCKERIMG) debug

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################

# Create a unique hash to be used for getting and putting cache, based on:
#   - The commit ID of the full Fuel repo structure
#   - The contents of all local Fuel patches
#   - Makefile, config and sensitive build scripts fingerprints
# NOTE: Patching is deterministic, so we can fingerprint (submodule root commit
#       info + OPNFV patches) at once, after patches-import.
# NOTE: When git submodule remote tracking is active, `git submodule status`
#       will point to the latest commits (remote/branch/HEAD) + OPNFV patches.
.cacheid:
	$(MAKE) -C f_repos -f Makefile get-cache release
	git submodule status | cut -c2-41 > .cachedata
	sha1sum fuel_build_loop >> .cachedata
	sha1sum config.mk >> .cachedata
	sha1sum Makefile >> .cachedata
	$(CACHETOOL) getbiweek >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: $(SUBCLEANCACHE)
	$(MAKE) -C f_repos -f Makefile clean-cache
	rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		 $(CACHETOOL) get $(shell cat .cacheid) | tar xf -;\
	else \
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - fuel*.iso gitinfo_fuel.txt | $(CACHETOOL) put $(shell cat .cacheid)
