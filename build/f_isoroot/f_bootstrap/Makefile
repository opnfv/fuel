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

.PHONY: all
all:
	@mkdir -p release/opnfv/bootstrap/pre.d
	@mkdir -p release/opnfv/bootstrap/post.d
	@mkdir -p release/usr/local/sbin
	@cp pre-scripts/* release/opnfv/bootstrap/pre.d
	@cp post-scripts/* release/opnfv/bootstrap/post.d

.PHONY: clean
clean:
	@rm -rf release

.PHONY: release
release:all
	@cp -Rvp release/* ../release

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
