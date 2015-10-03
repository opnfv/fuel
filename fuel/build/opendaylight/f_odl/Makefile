##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

include $(BUILD_BASE)/config.mk
ODL_NAME_SHORT := odl
PACKAGE := odl_$(shell cd /tmp/controller; git rev-parse --short HEAD)
VERSION := 0.1-1
DEB_NAME := $(PACKAGE)_$(VERSION)

.PHONY: all
all:	release/pool/main/$(DEB_NAME).deb

release/pool/main/$(DEB_NAME).deb:
ifeq ($(ODL_MAIN_REPO),)
	@echo "No config-spec target for ODL, nothing to build"
else
	@mkdir -p tmp/src
	@mkdir -p release/pool/main
	@cp -rp package/$(DEB_NAME) tmp/src
	@gzip -f9 tmp/src/$(DEB_NAME)/usr/share/doc/$(ODL_NAME_SHORT)/changelog.Debian
	@fakeroot dpkg-deb --build tmp/src/$(DEB_NAME)
	@lintian tmp/src/$(DEB_NAME).deb
	@cp tmp/src/$(DEB_NAME).deb release/pool/main
endif

.PHONY: clean
clean:
	@rm -rf tmp
	@rm -rf release
	@rm -f $(DEB_DEST)/$(DEB_NAME).deb

.PHONY: validate-cache
validate-cache:
	@echo "No cache validation schema available for $(shell pwd)"
	@echo "Continuing ..."

.PHONY: release
release:release/pool/main/$(DEB_NAME).deb
ifneq ($(ODL_MAIN_REPO),)
	@cp release/pool/main/$(DEB_NAME).deb $(DEB_DEST)
	@cp -Rvp puppet/modules/* $(PUPPET_DEST)
endif
