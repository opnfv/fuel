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
all: .oclbuild

.PHONY: clean
clean:
	@rm -f .oclbuild ../release/opnfv/contrail*.rpm contrail*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_oclplugin.txt
	@rm -rf fuel-plugin-contrail
	@./build_packages.sh clean

.PHONY: release
release:.oclbuild
	@rm -f ../release/opnfv/contrail*.rpm
	@mkdir -p ../release/opnfv
	@cp contrail*.rpm ../release/opnfv/
	cp gitinfo_oclplugin.txt $(BUILD_BASE)

.oclbuild:
	@echo "============================================================"
	@echo "============ STARTING OpenContrail Plugin build ============"
	@echo "============================================================"
	@./build_packages.sh install_deps
	@./build_packages.sh install_repos
	@rm -rf fuel-plugin-contrail
	@sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	@sudo gem install fpm
	@sudo pip install fuel-plugin-builder
	@git clone -b $(OCL_BRANCH) $(OCL_REPO)
	@./patch.sh
	@./build_packages.sh build_deb
	#./build_packages.sh build_rpm
	@INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-contrail/
	mv fuel-plugin-contrail/contrail*.rpm .
	@$(REPOINFO) -r . > gitinfo_oclplugin.txt
	@rm -rf fuel-plugin-contrail
	@touch .oclbuild

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(ODL_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@echo "Generating contrail cache-id ..."
	@git ls-remote --heads $(OCL_REPO) | grep $(OCL_BRANCH) | awk {'print $$1'} > .cachedata
	@./build_packages.sh generate_cache_id .cachedata
	@./patch.sh generate_cache_id .cachedata
	@sha1sum Makefile  | awk {'print $$1'} >> .cachedata
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
	@tar cf - .oclbuild contrail*.rpm gitinfo_oclplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
