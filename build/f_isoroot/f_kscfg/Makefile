##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)

.PHONY: all
all:	ks.cfg.iso
	@mkdir -p release
	grep -q OpenStack_Fuel ks.cfg.iso
	sed "s/OpenStack_Fuel/$(PRODNO)_$(REVSTATE)/g" ks.cfg.iso > ks.cfg
	/usr/bin/patch -p0 < ks.cfg.patch
	@cp ks.cfg.iso release/ks.cfg.orig
	@cp ks.cfg release/ks.cfg

ks.cfg.iso:
	7z -so x $(ISOCACHE) ks.cfg > ks.cfg.iso

.PHONY: clean
clean:
	@rm -rf release ks.cfg.iso ks.cfg

.PHONY: release
release: all
	@cp -Rvp release/* ../release

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	@echo "clean-cache not implemented"

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache:
	@echo "get-cache not implemented"

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache:
	@echo "put-cache not implemented"
