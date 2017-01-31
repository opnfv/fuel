##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
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
all: .bgpvpnbuild

.PHONY: clean
clean:
	@rm -f .bgpvpnbuild ../release/opnfv/bgpvpn*.rpm bgpvpn*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_bgpvpnplugin.txt gitinfo_bgpvpnplugin.txt

.PHONY: release
release:.bgpvpnbuild
	@rm -f ../release/opnfv/bgpvpn*.rpm
	@mkdir -p ../release/bgpvpn
	@cp bgpvpn*.rpm ../release/opnfv/
	cp gitinfo_bgpvpnplugin.txt $(BUILD_BASE)

.bgpvpnbuild:
	# The python packages build into deb by this plugin require a newer
	# setuptools install a newer setuptools version until the container
	# where this is run is bumped to ubuntu 16.04.
	# --user is used because there is already a setuptools installation
	#  managed by apt.
	pip install setuptools --upgrade --user
	rm -rf fuel-plugin-bgpvpn
	git clone $(BGPVPN_REPO)
	cd fuel-plugin-bgpvpn; \
	git checkout $(BGPVPN_BRANCH); \
	if [ ! -z $(BGPVPN_CHANGE) ]; then \
	   git fetch $(BGPVPN_REPO) $(BGPVPN_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	fpb --debug --build fuel-plugin-bgpvpn/
	mv fuel-plugin-bgpvpn/bgpvpn*.rpm .
	$(REPOINFO) -r . > gitinfo_bgpvpnplugin.txt
	rm -rf fuel-plugin-bgpvpn
	touch .bgpvpnbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(BGPVPN_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(BGPVPN_CHANGE) ]; then \
	  $(CACHETOOL) getcommitid $(BGPVPN_REPO) $(BGPVPN_CHANGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(BGPVPN_REPO) $(BGPVPN_BRANCH) > .cachedata; \
	fi
	sha1sum Makefile >> .cachedata
	sha1sum config.mk >> .cachedata
	echo -n $(UBUNTU_ARCH) | sha1sum | awk {'print $$1'} >> .cachedata
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
	@tar cf - .bgpvpnbuild bgpvpn*.rpm gitinfo_bgpvpnplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
