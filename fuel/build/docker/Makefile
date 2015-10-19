##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FILES = $(wildcard ubuntu-builder/*) runcontext

.PHONY: all
all:	.docker

.docker: $(FILES)
	cp Dockerfile ubuntu-builder/Dockerfile
	sed -i "s;INSERT_HTTP_PROXY;${http_proxy};" ubuntu-builder/Dockerfile
	sed -i "s;INSERT_HTTPS_PROXY;${https_proxy};" ubuntu-builder/Dockerfile
	sed -i "s;INSERT_NO_PROXY;${no_proxy};" ubuntu-builder/Dockerfile
	/usr/bin/docker build --rm=true --no-cache=true -t opnfv.org/ubuntu-builder:14.04 ubuntu-builder
	/usr/bin/docker tag -f opnfv.org/ubuntu-builder:14.04 opnfv.org/ubuntu-builder
	touch .docker

.PHONY:	clean
clean:
	rm -f .docker ubuntu-builder/Dockerfile
