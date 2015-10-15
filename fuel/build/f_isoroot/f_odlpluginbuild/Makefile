##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)
DOCKNAME = fuelrepo
DOCKVERSION = 1.0
ODL_BRANCH="juno/lithium-sr1"
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
	git clone -b ${ODL_BRANCH} ${ODL_REPO}
	INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-opendaylight/
	mv fuel-plugin-opendaylight/opendaylight*.rpm .
	$(REPOINFO) -r . > $(BUILD_BASE)/gitinfo_odlplugin.txt
	rm -rf fuel-plugin-opendaylight

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	@echo "clean-cache not implemented"

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache:
	@echo "get-cache not implemented"

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache:
	@echo "put-cache not implemented"

