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
	@mkdir -p release/opnfv
	@cp pre-deploy.sh release/opnfv
	@cp sysinfo.sh release/opnfv
	@cp transform_yaml.py release/opnfv
	@chmod 755 release/opnfv/*

.PHONY: clean
clean:
	@rm -rf release


.PHONY: release
release:clean all
	@cp -Rvp release/* ../release
