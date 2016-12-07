##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)

include config.mk

.PHONY: all
all: .odlbuild

.PHONY: clean
clean:
	@rm -f .odlbuild ../release/opnfv/opendaylight*.rpm opendaylight*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_odlplugin.txt gitinfo_odlplugin.txt
	@rm -rf fuel-plugins

.PHONY: release
release:.odlbuild
	@rm -f ../release/opnfv/opendaylight*.rpm
	@mkdir -p ../release/opnfv
	@cp opendaylight*.rpm ../release/opnfv/
	cp gitinfo_odlplugin.txt $(BUILD_BASE)
.odlbuild:
	rm -rf fuel-plugin-opendaylight
	../../docker/ubuntu-builder/install_docker.sh
	git clone -b $(FUEL_PLUGIN_ODL_BRANCH) $(FUEL_PLUGIN_ODL_REPO)
	cd fuel-plugin-opendaylight; \
	if [ -n $(FUEL_PLUGIN_ODL_CHANGE) ]; then \
	   git checkout $(FUEL_PLUGIN_ODL_CHANGE); \
	fi
	fpb --debug --build fuel-plugin-opendaylight/
	mv fuel-plugin-opendaylight/opendaylight*.rpm .
	$(REPOINFO) -r . > gitinfo_odlplugin.txt
	rm -rf fuel-plugin-opendaylight
	touch .odlbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(FUEL_PLUGIN_ODL_BRANCH)
#   - The contents of this Makefile
.cacheid:
	if [ -n $(FUEL_PLUGIN_ODL_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(FUEL_PLUGIN_ODL_REPO) $(FUEL_PLUGIN_ODL_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(FUEL_PLUGIN_ODL_REPO) $(FUEL_PLUGIN_ODL_BRANCH) > .cachedata; \
	fi
	@sha1sum Makefile | awk {'print $$1'} >> .cachedata
	@sha1sum config.mk | awk {'print $$1'} >> .cachedata
	@echo -n $(UBUNTU_ARCH) | sha1sum | awk {'print $$1'} >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	rm -f .cachedata .cacheid

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
	@tar cf - .odlbuild opendaylight*.rpm gitinfo_odlplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
