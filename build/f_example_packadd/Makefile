##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)
PACKAGE := foobar
VERSION := 1.0-1
DEB_NAME := $(PACKAGE)_$(VERSION).deb

.PHONY: all
all:	release/pool/main/$(DEB_NAME)

release/pool/main/$(DEB_NAME):
	@mkdir -p tmp/src
	@mkdir -p release/pool/main
	@cp -r $(DEB_NAME) tmp/src
	@gzip -9 tmp/src/$(DEB_NAME)/usr/share/doc/$(PACKAGE)/changelog.Debian
	@fakeroot dpkg-deb --build tmp/src/$(DEB_NAME)
	@lintian tmp/src/$(DEB_NAME)
	@cp tmp/src/$(DEB_NAME) release/pool/main

.PHONY: clean
clean:
	@rm -rf tmp
	@rm -rf release
	@rm -f ../release/packages/ubuntu/pool/main/$(DEB_NAME)

.PHONY: validate-cache
validate-cache:
	@echo "No cache validation schema available for $(shell pwd)"
	@echo "Continuing ..."

.PHONY: release
release:release/pool/main/$(DEB_NAME)
	@cp release/pool/main/$(DEB_NAME) $(DEB_DEST)
	@cp -Rvp puppet/modules/* $(PUPPET_DEST)
