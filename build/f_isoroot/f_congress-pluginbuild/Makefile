##############################################################################
# Copyright (c) 2016 Mirantis Inc and others.
# fzhadaev@mirantis.com
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
all: .congressbuild

.PHONY: clean
clean:
	@rm -f .congressbuild ../release/opnfv/congress*.rpm congress*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_congressplugin.txt gitinfo_congressplugin.txt

.PHONY: release
release:.congressbuild
	@rm -f ../release/opnfv/congress*.rpm
	@mkdir -p ../release/congress
	@cp congress*.rpm ../release/opnfv/
	cp gitinfo_congressplugin.txt $(BUILD_BASE)

.congressbuild:
	rm -rf fuel-plugin-congress
	git clone $(CONGRESS_REPO)
	cd fuel-plugin-congress; \
	git checkout $(CONGRESS_BRANCH); \
	if [ ! -z $(CONGRESS_CHANGE) ]; then \
	   git fetch $(CONGRESS_REPO) $(CONGRESS_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	fpb --debug --build fuel-plugin-congress/
	@mv fuel-plugin-congress/congress*.rpm .
	$(REPOINFO) -r . > gitinfo_congressplugin.txt
	@rm -rf fuel-plugin-congress
	@touch .congressbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(CONGRESS_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(CONGRESS_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(CONGRESS_REPO) $(CONGRESS_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(CONGRESS_REPO) $(CONGRESS_BRANCH) > .cachedata; \
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
	@tar cf - .congressbuild congress*.rpm gitinfo_congressplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
