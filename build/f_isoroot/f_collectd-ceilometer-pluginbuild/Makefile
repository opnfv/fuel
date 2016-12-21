##############################################################################
# Copyright (c) 2016 Ericsson AB and others.
# jonas.bjurel@eicsson.com
# ruijing.guo@intel.com
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
all: .barometer

.PHONY: clean
clean:
	@rm -f .barometer ../release/opnfv/fuel-plugin-collectd-ceilometer-*.rpm fuel-plugin-collectd-ceilometer-*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_collectd-ceilometer-plugin.txt gitinfo_collectd-ceilometer-plugin.txt

.PHONY: release
release:.barometer
	@rm -f ../release/opnfv/fuel-plugin-collectd-ceilometer-*.rpm
	@mkdir -p ../release/opnfv
	@cp fuel-plugin-collectd-ceilometer*.rpm ../release/opnfv/
	cp gitinfo_collectd-ceilometer-plugin.txt $(BUILD_BASE)

.barometer:
	@rm -rf barometer
	../../docker/ubuntu-builder/install_docker.sh
	git clone $(COLLECTD_CEILOMETER_REPO)
	cd barometer; \
	git checkout $(COLLECTD_CEILOMETER_BRANCH); \
	if [ ! -z $(COLLECTD_CEILOMETER_CHANGE) ]; then \
	   git fetch $(COLLECTD_CEILOMETER_REPO) $(COLLECTD_CEILOMETER_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	#will fix it soon
	sed -i "s/sudo docker run -v/sudo docker run -v /" src/fuel-plugin/pre_build_hook
	patch -p1 <../fix_docker_build.diff
	fpb --debug --build barometer/src/fuel-plugin
	@mv barometer/src/fuel-plugin/fuel-plugin-collectd-ceilometer*.rpm .
	$(REPOINFO) -r . > gitinfo_collectd-ceilometer-plugin.txt
	@rm -rf barometer
	@touch .barometer
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(COLLECTD_CEILOMETER_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(COLLECTD_CEILOMETER_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(COLLECTD_CEILOMETER_REPO) $(COLLECTD_CEILOMETER_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(COLLECTD_CEILOMETER_REPO) $(COLLECTD_CEILOMETER_BRANCH) > .cachedata; \
	fi
	@sha1sum Makefile | awk {'print $$1'} >> .cachedata
	@sha1sum config.mk | awk {'print $$1'} >> .cachedata
	@echo -n $(UBUNTU_ARCH) | sha1sum | awk {'print $$1'} >> .cachedata
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
	@tar cf - .barometer fuel-plugin-collectd-ceilometer*.rpm gitinfo_collectd-ceilometer-plugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
