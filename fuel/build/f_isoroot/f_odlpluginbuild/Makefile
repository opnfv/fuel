##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)
ODL_BRANCH=juno/lithium-sr1
ODL_REPO="https://github.com/stackforge/fuel-plugin-opendaylight.git"

.PHONY: all
all: .odlbuild

.PHONY: clean
clean:
	@rm -f .odlbuild ../release/opnfv/opendaylight*.rpm opendaylight*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_odlplugin.txt

.PHONY: release
release:.odlbuild
	@rm -f ../release/opnfv/opendaylight*.rpm
	@mkdir -p ../release/opnfv
	@cp opendaylight*.rpm ../release/opnfv/

.odlbuild:
	rm -rf fuel-plugin-opendaylight
	sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	sudo gem install fpm
	sudo pip install fuel-plugin-builder
	git clone -b $(ODL_BRANCH) $(ODL_REPO)
	INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-opendaylight/
	mv fuel-plugin-opendaylight/opendaylight*.rpm .
	$(REPOINFO) -r . > $(BUILD_BASE)/gitinfo_odlplugin.txt
	rm -rf fuel-plugin-opendaylight

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(ODL_BRANCH)
#   - The contents of this Makefile
.cacheid:
	git ls-remote --heads $(ODL_REPO) | grep $(ODL_BRANCH) > .cachedata
	sha1sum Makefile >> .cachedata
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
	@tar cf - .odlbuild opendaylight*.rpm | $(CACHETOOL) put $(shell cat .cacheid)
