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
############################################################################
# BEGIN of variables to customize
#
#Input args
export UNIT_TEST = FALSE
export INTERACTIVE = TRUE
export ISOSRC = file:$(shell pwd)/fuel-6.1.iso
export ISOCACHE = $(shell pwd)/$(shell basename $(ISOSRC))
export PRODNO = "OPNFV_BGS"
export REVSTATE = "P0000"
export NEWISO = $(shell pwd)/release/opnfv-${REVSTATE}.iso

# Note! Invoke with "make REVSTATE=RXXXX all" to make release build!
# Invoke with ICOCACHE=/full/path/to/iso if cached ISO is in non-standard location.

#Build variables
export BUILD_BASE := $(shell pwd)
export DEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/main
export UDEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/debian-installer
export PUPPET_DEST := $(BUILD_BASE)/release/puppet/modules
export CACHE_DIR := $(BUILD_BASE)/cache
export VERSION_FILE := $(BUILD_BASE)/.versions
export DOCKERIMG = opnfv.org/ubuntu-builder:14.04
export TOPDIR := $(shell pwd)

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
	@echo "Versions of cached build results built by" $(shell hostname) "at" $(shell date -u) > $(VERSION_FILE)
	@echo "cache.mk" $(shell md5sum $(BUILD_BASE)/cache.mk | cut -f1 -d " ") >> $(VERSION_FILE)
	@echo "config.mk" $(shell md5sum $(BUILD_BASE)/config.mk | cut -f1 -d " ") >> $(VERSION_FILE)
	@make -C docker
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
	cd /tmp && git clone $(FUEL_MAIN_REPO)
	cd /tmp/fuel-main && git checkout $(FUEL_MAIN_TAG)
	@echo "fuel" `git -C /tmp/fuel-main show | grep commit | head -1 | cut -d " " -f2` >> $(VERSION_FILE)
	# Setup cgroups for docker-in-docker
	sudo /root/enable_dockerx2
	# Temporary patch to accomodate for new Ubuntu trusty devops keys not yet
	# backported to fuel 6.0 or 6.1
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-main_3.patch
	# Patch for adding dosfstools, as Fuel 6.1 is running mkfs.vfat
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-main_5.patch
	# Remove Docker optimizations, otherwise multistrap will fail during
	# Fuel build.
	sudo rm -f /etc/apt/apt.conf.d/docker*
	#
	cd /tmp/fuel-main && ./prepare-build-env.sh
	cd /tmp/fuel-main && make repos
	# Patch for speeding up image creation in virtual environments,
	# https://review.openstack.org/#/c/197943/
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-agent_1.patch
	cd /tmp/fuel-main/build/repos/nailgun && git config --global user.email "build$opnfv.org"
	cd /tmp/fuel-main/build/repos/nailgun && git config --global user.name "OPNFV build"
	cd /tmp/fuel-main/build/repos/nailgun && git add -u .
	cd /tmp/fuel-main/build/repos/nailgun && git commit -m "Added patch"
	#
	cd /tmp/fuel-main && make iso
	mv /tmp/fuel-main/build/artifacts/fuel*.iso .

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

.PHONY: build-clean $(SUBCLEAN)
build-clean: $(SUBCLEAN)
	$(MAKE) -C patch-packages -f Makefile clean
	@rm -Rf release
	@rm -Rf newiso
	@rm -f $(NEWISO)

.PHONY: clean $(SUBCLEAN)
clean:  clean-cache $(SUBCLEAN)
	$(MAKE) -C patch-packages -f Makefile clean
	@rm -f *.iso
	@rm -Rf release
	@rm -Rf newiso
	@rm -f $(NEWISO)
	@rm -f $(BUILD_BASE)/.versions

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean

# Todo: Make things smarter - we shouldn't need to clean everything
# betwen make invocations.
.PHONY: iso
iso:	build-clean $(ISOCACHE) $(SUBDIRS) patch-packages
	install/install.sh iso $(ISOCACHE) $(NEWISO) $(PRODNO) $(REVSTATE)
	@printf "\n\nProduct ISO is $(NEWISO)\n\n"

# Start a bash shell in docker for Makefile debugging
.PHONY: debug
debug:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	docker/runcontext $(DOCKERIMG) bash
