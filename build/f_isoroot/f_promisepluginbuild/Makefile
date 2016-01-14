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
all: .promisebuild

.PHONY: clean
clean:
	@rm -f .promisebuild ../release/opnfv/fuel-plugin-promise*.fp \
        fuel-plugin-promise*.fp \
	@rm -f $(BUILD_BASE)/gitinfo_promise-plugin.txt gitinfo_promise-plugin.txt

.PHONY: release
release:.promisebuild
	@rm -f ../release/opnfv/fuel-plugin-promise*.fp
	@mkdir -p ../release/opnfv
	@cp fuel-plugin-promise*.fp ../release/opnfv/
	cp gitinfo_promise-plugin.txt $(BUILD_BASE)
	cd $(BUILD_BASE) && mkdir -p ../deploy/templates/plugins && cp -rf $(TOP)/config/* ../deploy/templates/plugins

.promisebuild:
	@rm -rf fuel-plugin-promise
	sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	sudo pip install fuel-plugin-builder
	../../docker/ubuntu-builder/install_docker.sh
	git clone $(PROMISE_REPO)
	cd fuel-plugin-promise; \
	git checkout $(PROMISE_BRANCH); \
	if [ ! -z $(PROMISE_CHANGE) ]; then \
	   git fetch $(PROMISE_REPO) $(PROMISE_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-promise/
	@mv fuel-plugin-promise/fuel-plugin-promise*.fp .
	$(REPOINFO) -r . > gitinfo_promise-plugin.txt
	@rm -rf fuel-plugin-promise
	@touch .promisebuild

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(PROMISE_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(PROMISE_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(PROMISE_REPO) $(PROMISE_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(PROMISE_REPO) $(PROMISE_BRANCH) > .cachedata; \
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
	@tar cf - .promisebuild fuel-plugin-promise*.fp gitinfo_promise-plugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
