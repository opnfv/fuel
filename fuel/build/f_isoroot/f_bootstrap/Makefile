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
	@cp bootstrap_admin_node.sh release
	@cp bootstrap_admin_node.sh.orig release

.PHONY: clean
clean:
	@rm -rf release

.PHONY: release
release:all
	@cp -Rvp release/* ../release
