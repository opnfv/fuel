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
	# Deliberately not cleaning nailgun directory to speed up multiple builds
	@rm -f ../release/opnfv/opendaylight*.rpm

.PHONY: release
release:.odlbuild
	@rm -f ../release/opnfv/opendaylight*.rpm
	@mkdir -p ../release/opnfv
	@cp  opendaylight*.rpm ../release/opnfv/

.odlbuild:
	rm -rf fuel-plugin-opendaylight
	sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	sudo gem install fpm
	sudo pip install fuel-plugin-builder
	git clone -b ${ODL_BRANCH} ${ODL_REPO}
	INCLUDE_DEPENDENCIES=true fpb --debug --build fuel-plugin-opendaylight/
	mv fuel-plugin-opendaylight/opendaylight*.rpm .
	rm -rf fuel-plugin-opendaylight
