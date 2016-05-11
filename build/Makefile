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
export ISOSRC = file:$(shell pwd)/fuel-9.0.iso
export ISOCACHE = $(shell pwd)/$(shell basename $(ISOSRC))
export PRODNO = "OPNFV_FUEL"
export REVSTATE = "P0000"
export USER ?= $(shell whoami)

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

export MIRROR_MOS_UBUNTU := $(shell echo "$(LATEST_MIRROR_ID_URL)" | cut -d'/' -f3)
export LATEST_TARGET_UBUNTU := $(shell curl -sSf "$(MIRROR_MOS_UBUNTU)/mos-repos/ubuntu/9.0.target.txt" | head -1)
export MIRROR_MOS_UBUNTU_ROOT := /mos-repos/ubuntu/$(LATEST_TARGET_UBUNTU)

export LATEST_TARGET_CENTOS := $(shell curl -sSf "$(LATEST_MIRROR_ID_URL)/mos-repos/centos/mos9.0-centos7/os.target.txt" | head -1)
export MIRROR_FUEL := "$(LATEST_MIRROR_ID_URL)/mos-repos/centos/mos9.0-centos7/$(LATEST_TARGET_CENTOS)/x86_64"

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

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker
	@lsb_release -a | grep Ubuntu > /dev/null 2>&1 || (echo 'Ubuntu is the only supported Linux distribution for this build system'; exit 1)
	@KERNEL_VER=$$(uname -r); \
	KERNEL_VER="$${KERNEL_VER%.*-*}"; \
	KERNEL_VER="$${KERNEL_VER//.}"; \
        [ $$KERNEL_VER -ge 319 ] || (echo 'Kernel version must be 3.19 or newer'; exit 1)
	@docker/runcontext $(DOCKERIMG) wget -q www.google.com > /dev/null 2>&1 || (echo 'No docker network connectivity or name server - check your network- and docker settings'; exit 1)
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
	if [ ! -d /tmp/fuel-main ]; then \
		cd /tmp && git clone $(FUEL_MAIN_REPO); \
	fi
	cd /tmp/fuel-main && git checkout $(FUEL_MAIN_TAG)
	@echo "fuel" `git -C /tmp/fuel-main show | grep commit | head -1 | cut -d " " -f2` >> $(VERSION_FILE)
	# Patch for using the Czech Fuel mirror
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/repo-mirror-cz.patch
	# Remove Docker optimizations, otherwise multistrap will fail during
	# Fuel build.
	sudo rm -f /etc/apt/apt.conf.d/docker*
	#
	# Need to replace the old Docker v. 1.5.0 with a later version to be
	# able to access the Docker remote repository!
	sudo apt-get install apt-transport-https ca-certificates -y
	sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
	sudo apt-get update
	sudo apt-get install docker-engine -y
	sudo sh -c 'echo DOCKER_OPTS=\"--bip 172.45.0.1/24\" > /etc/default/docker'
	sudo /etc/init.d/docker stop || exit 0
	sudo /etc/init.d/docker start

	cd /tmp/fuel-main && ./prepare-build-env.sh
	# Verify that Docker is alive
	sudo docker info
	cd /tmp/fuel-main && make repos
	$(REPOINFO) -r /tmp/fuel-main > gitinfo_fuel.txt
	# OPNFV patches at Fuel build time
	cd /tmp/fuel-main/iso && git config user.name "Fuel OPNFV"
	cd /tmp/fuel-main/iso && git config user.email "fuel@opnfv.org"
	cd /tmp/fuel-main/iso && patch -p0 < $(TOPDIR)/bootstrap_admin_node.sh.patch
	cd /tmp/fuel-main/iso && git add -u bootstrap_admin_node.sh
	cd /tmp/fuel-main/iso/isolinux && patch -p0 <  $(TOPDIR)/isolinux.cfg.patch
	cd /tmp/fuel-main/iso/isolinux && git add -u isolinux.cfg
	cd /tmp/fuel-main/iso && git commit -m "Added OPNFV patches"
	# Repeat build up to three times
	sudo -E ./fuel_build_loop
	cp /tmp/fuel-main/build/artifacts/fuel*.iso .
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
	$(MAKE) -C patch-packages -f Makefile clean
	@rm -f *.iso
	@rm -Rf release
	@rm -Rf newiso
	@rm -Rf .versions
	@rm -f $(NEWISO)
	@rm -f $(BUILD_BASE)/gitinfo_*.txt

.PHONY: deepclean
deepclean: clean clean-cache
	make -C docker clean
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
#   - The commit ID of the full Fuel repo structre
#   - The contents of all local Fuel patches
.cacheid:
	cd /tmp && git clone $(FUEL_MAIN_REPO)
	cd /tmp/fuel-main && git checkout $(FUEL_MAIN_TAG)
	cd /tmp/fuel-main && make repos
	$(REPOINFO) -r /tmp/fuel-main > .cachedata
	sha1sum *.patch >> .cachedata
	sha1sum fuel_build_loop >> .cachedata
	sha1sum config.mk >> .cachedata
	sha1sum Makefile >> .cachedata
	$(CACHETOOL) getbiweek >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid
	# Not removing fuel-main as it is re-used in build

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: $(SUBCLEANCACHE)
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
