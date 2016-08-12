##############################################################################
# Copyright (c) 2016 ZTE and others.
# dong.wenjuan@zte.com.cn
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
all: .doctorbuild

.PHONY: clean
clean:
	@rm -f .doctorbuild ../release/opnfv/fuel-plugin-doctor*.rpm fuel-plugin-doctor*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_doctor-plugin.txt gitinfo_doctor-plugin.txt

.PHONY: release
release:.doctorbuild
	@rm -f ../release/opnfv/fuel-plugin-doctor*.rpm
	@mkdir -p ../release/opnfv
	@cp fuel-plugin-doctor*.rpm ../release/opnfv/
	cp gitinfo_doctor-plugin.txt $(BUILD_BASE)

.doctorbuild:
	@rm -rf doctor
	git clone $(DOCTOR_PLUGIN_REPO) fuel-plugin-doctor
	cd fuel-plugin-doctor; \
	git checkout $(DOCTOR_PLUGIN_BRANCH); \
	if [ ! -z $(DOCTOR_PLUGIN_CHENGE) ]; then \
	   git fetch $(DOCTOR_PLUGIN_REPO) $(DOCTOR_PLUGIN_CHENGE); \
	   git checkout FETCH_HEAD; \
	fi
	fpb --debug --build fuel-plugin-doctor
	@mv fuel-plugin-doctor/fuel-plugin-doctor*.rpm .
	$(REPOINFO) -r . > gitinfo_doctor-plugin.txt
	@rm -rf fuel-plugin-doctor
	@touch .doctorbuild
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(DOCTOR_PLUGIN_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@if [ ! -z $(DOCTOR_PLUGIN_CHENGE) ]; then \
	  $(CACHETOOL) getcommitid $(DOCTOR_PLUGIN_REPO) $(DOCTOR_PLUGIN_CHENGE) > .cachedata; \
	else \
	  $(CACHETOOL) getcommitid $(DOCTOR_PLUGIN_REPO) $(DOCTOR_PLUGIN_BRANCH) > .cachedata; \
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
	@tar cf - .doctorbuild fuel-plugin-doctor*.rpm gitinfo_doctor-plugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
