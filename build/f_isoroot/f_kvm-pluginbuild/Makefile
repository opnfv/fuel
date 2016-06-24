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
all: .kvmbuild

.PHONY: clean
clean:
	@rm -f .kvmbuild ../release/opnfv/fuel-plugin-kvm*.rpm fuel-plugin-kvm*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_kvm-plugin.txt gitinfo_kvm-plugin.txt

.PHONY: release
release:.kvmbuild
	@rm -f ../release/opnfv/fuel-plugin-kvm*.rpm
	@mkdir -p ../release/opnfv
	@cp fuel-plugin-kvm*.rpm ../release/opnfv/
	cp gitinfo_kvm-plugin.txt $(BUILD_BASE)

.kvmbuild:
	# fix me
	@sudo rm -rf kvmfornfv
	sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	sudo pip install fuel-plugin-builder
	../../docker/ubuntu-builder/install_docker.sh
	git clone $(KVMFORNFV_REPO)
	cd kvmfornfv; \
	git checkout $(KVMFORNFV_BRANCH); \
	if [ ! -z $(KVMFORNFV_CHANGE) ]; then \
	   git fetch $(KVMFORNFV_REPO) $(KVMFORNFV_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	cd kvmfornfv/fuel-plugin; \
	INCLUDE_DEPENDENCIES=true fpb --debug --build ./
	@mv kvmfornfv/fuel-plugin/fuel-plugin-kvm*.rpm .
	$(REPOINFO) -r . > gitinfo_kvm-plugin.txt
	# fix me
	@sudo rm -rf kvmfornfv
	@touch .kvmbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(KVMFORNFV_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(KVMFORNFV_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(KVMFORNFV_REPO) $(KVMFORNFV_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(KVMFORNFV_REPO) $(KVMFORNFV_BRANCH) > .cachedata; \
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
	@tar cf - .kvmbuild fuel-plugin-kvm*.rpm gitinfo_kvm-plugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
