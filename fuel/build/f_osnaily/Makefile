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

.PHONY: clean
clean:
	@rm -rf tmp
	@rm -rf release

.PHONY: validate-cache
validate-cache:
	@echo "No cache validation schema available for $(shell pwd)"
	@echo "Continuing ..."

.PHONY: release
release:
	@cp -Rvp puppet/modules/* $(PUPPET_DEST)
