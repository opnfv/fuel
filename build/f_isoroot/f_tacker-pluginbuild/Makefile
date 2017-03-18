##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# geopar@intracom-telecom.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)

##############################################################################
# BEGIN of Include definitions
#
include config.mk
#
# END Include definitions
##############################################################################


.PHONY: all
all: .tackerbuild

.PHONY: clean
clean:
	@rm -f .tackerbuild ../release/opnfv/tacker*.rpm tacker*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_tackerplugin.txt gitinfo_tackerplugin.txt

.PHONY: release
release:.tackerbuild
	@rm -f ../release/opnfv/tacker*.rpm
	@mkdir -p ../release/tacker
	@cp tacker*.rpm ../release/opnfv/
	cp gitinfo_tackerplugin.txt $(BUILD_BASE)

.tackerbuild:
	rm -rf fuel-plugin-tacker
	git clone $(TACKER_REPO)
	cd fuel-plugin-tacker; \
	git checkout $(TACKER_BRANCH); \
	if [ ! -z $(TACKER_CHANGE) ]; then \
	   git fetch $(TACKER_REPO) $(TACKER_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	fpb --debug --build fuel-plugin-tacker/
	@mv fuel-plugin-tacker/tacker*.rpm .
	$(REPOINFO) -r . > gitinfo_tackerplugin.txt
	@rm -rf fuel-plugin-tacker
	@touch .tackerbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

##############################################################################
# Cache operations - only used when building through ci/build.sh
##############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(TACKER_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(TACKER_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(TACKER_REPO) $(TACKER_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(TACKER_REPO) $(TACKER_BRANCH) > .cachedata; \
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
	@tar cf - .tackerbuild tacker*.rpm gitinfo_tackerplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
