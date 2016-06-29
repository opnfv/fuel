##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)

############################################################################
# BEGIN of Include definitions
#
include config.mk
#
# END Include definitions
#############################################################################

.PHONY: all
all: .ovsbuild

.PHONY: clean
clean:
	@rm -f .ovsbuild ../release/opnfv/fuel-plugin-ovs-*.rpm fuel-plugin-ovs-*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_ovs-nsh-dpdk-plugin.txt gitinfo_ovs-nsh-dpdk-plugin.txt

.PHONY: release
release:.ovsbuild
	@rm -f ../release/opnfv/fuel-plugin-ovs-*.rpm
	@mkdir -p ../release/opnfv
	@cp fuel-plugin-ovs*.rpm ../release/opnfv/
	cp gitinfo_ovs-nsh-dpdk-plugin.txt $(BUILD_BASE)

.ovsbuild:
	@rm -rf fuel-plugin-ovs
	../../docker/ubuntu-builder/install_docker.sh
	git clone $(OVS_NSH_DPDK_REPO)
	cd fuel-plugin-ovs; \
	git checkout $(OVS_NSH_DPDK_BRANCH); \
	if [ ! -z $(OVS_NSH_DPDK_CHANGE) ]; then \
	   git fetch $(OVS_NSH_DPDK_REPO) $(OVS_NSH_DPDK_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-ovs/
	@mv fuel-plugin-ovs/fuel-plugin-ovs*.rpm .
	$(REPOINFO) -r . > gitinfo_ovs-nsh-dpdk-plugin.txt
	@rm -rf fuel-plugin-ovs
	@touch .ovsbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(OVS_NSH_DPDK_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(OVS_NSH_DPDK_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(OVS_NSH_DPDK_REPO) $(OVS_NSH_DPDK_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(OVS_NSH_DPDK_REPO) $(OVS_NSH_DPDK_BRANCH) > .cachedata; \
	fi
	@sha1sum Makefile | awk {'print $$1'} >> .cachedata
	@sha1sum config.mk | awk {'print $$1'} >> .cachedata
	@cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	@rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		 $(CACHETOOL) get $(shell cat .cacheid) | tar xf -;\
	else \
		echo "No cache item found for $(shell cat .cacheid)" ;\
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - .ovsbuild fuel-plugin-ovs*.rpm gitinfo_ovs-nsh-dpdk-plugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
