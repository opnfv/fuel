##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# dradez@redhat.com
# chigang@huawei.com
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
export ISOSRC = file:$(shell pwd)/ubuntu
export ISOCACHE = $(shell pwd)/$(shell basename $(ISOSRC))
export PRODNO = "OPNFV_BGS"
export REVSTATE = "P0000"
export RELEASE_DIR = $(shell pwd)/release

# Note! Invoke with "make REVSTATE=RXXXX all" to make release build!
# Invoke with ICOCACHE=/full/path/to/iso if cached ISO is in non-standard location.

#Build variables
export BUILD_BASE := $(shell pwd)
export CACHE_DIR := $(BUILD_BASE)/cache
export INSTALL_DIR := $(BUILD_BASE)
export VERSION_FILE := $(BUILD_BASE)/.versions
export TOPDIR := $(shell pwd)

export OLDISO_DIR := $(TOPDIR)/oldiso
export NEWISO_DIR := $(TOPDIR)/newiso
export NEWIMAGE_DIR := $(TOPDIR)/newiso/image
export NEWFILESYSTEM := $(TOPDIR)/newiso/filesystem
export MANIFEST_DIR = $(shell find $(NEWISO_DIR) -name filesystem.manifest)
export SQUASHFS_DIR = $(shell find $(NEWISO_DIR) -name filesystem.squashfs)
export FSSIZE_DIR = $(shell find $(NEWISO_DIR) -name filesystem.size)

#
# END of variables to customize
#############################################################################

.PHONY: all
all: iso
	@echo "Versions of cached build results built by" $(shell hostname) "at" $(shell date -u) > $(VERSION_FILE)
	@echo "cache.mk" $(shell md5sum $(BUILD_BASE)/cache.mk | cut -f1 -d " ") >> $(VERSION_FILE)
	@echo "config.mk" $(shell md5sum $(BUILD_BASE)/config.mk | cut -f1 -d " ") >> $(VERSION_FILE)

############################################################################
# BEGIN of Include definitions
#
include config.mk
include cache.mk
#
# END Include definitions
#############################################################################

.PHONY: prepare-cache
prepare-cache: 
	@echo "prepare-cache to be done"

.PHONY: mount-ubuntuiso
mount-ubuntuiso:
	@echo "===Mounting ubuntu ISO in $(OLDISO_DIR)"
	-mkdir -p $(OLDISO_DIR) $(NEWIMAGE_DIR)
	@fuseiso $(ISOCACHE)/*.iso $(OLDISO_DIR)
	cp $(OLDISO_DIR)/. $(NEWIMAGE_DIR) -rp

.PHONY: umount-ubuntuiso
umount-ubuntuiso:
	@set +e
	@echo "===Unmounting ubuntu ISO from $(OLDISO_DIR)"
	@fusermount -u $(OLDISO_DIR)
	@set -e

.PHONY: install-package
install-package:
	@echo "===uncompress file system to add new files"
	@find $(NEWISO_DIR) -name "filesystem.squashfs" |xargs unsquashfs
	@mv squashfs-root $(NEWFILESYSTEM)
	cp -f /etc/resolv.conf $(NEWFILESYSTEM)/run/resolvconf/
	cp /etc/hosts $(NEWFILESYSTEM)/etc/
	cp $(INSTALL_DIR)/install.sh $(NEWFILESYSTEM)/
	@echo "===install package on filesystem for newiso"
	#@chroot $(NEWFILESYSTEM) sh ./install.sh
	@chmod +w $(MANIFEST_DIR)
	@chroot $(NEWFILESYSTEM) dpkg-query -W --showformat='$${Package} $${Version}\n' | tee ${MANIFEST_DIR}
	@rm $(SQUASHFS_DIR)
	@mksquashfs $(NEWFILESYSTEM) $(SQUASHFS_DIR)
	@chmod +w $(FSSIZE_DIR)
	cd $(NEWISO_DIR); \
	(du -sx --block-size=1 $(NEWFILESYSTEM) | cut -f1 ) | tee ${FSSIZE_DIR}
	cd $(NEWIMAGE_DIR); \
	find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" | tee ./md5sum.txt

.PHONY: make-iso
make-iso:
	@echo "===Building OPNFV iso"
	cd $(NEWIMAGE_DIR); \
	mkisofs -r -V "OPNFV" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-14.04-amd64-opnfv.iso .

.PHONY: build-clean
build-clean:
	-rm -Rf $(OLDISO_DIR)
	-rm -Rf $(NEWISO_DIR)
	-rm -Rf $(RELEASE_DIR)

.PHONY: iso
iso: build-clean mount-ubuntuiso umount-ubuntuiso install-package make-iso
	-mkdir $(RELEASE_DIR)
	@mv $(NEWISO_DIR)/*.iso $(RELEASE_DIR)
	@printf "\n\nISO is built successfully!\n\n"
