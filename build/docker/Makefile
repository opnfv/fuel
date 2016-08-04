##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL = /bin/bash
FILES = $(wildcard ubuntu-builder/*) runcontext

.PHONY: all
all:	.docker

.docker: $(FILES)
	cp Dockerfile ubuntu-builder/Dockerfile
	# Only add proxy ENVs where set in host - needed to pull the base Ubuntu image
	test -n "${http_proxy}" && sed -i "s;INSERT_HTTP_PROXY;${http_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${https_proxy}" && sed -i "s;INSERT_HTTPS_PROXY;${https_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${no_proxy}" && sed -i "s;INSERT_NO_PROXY;${no_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${HTTP_PROXY}" && sed -i "s;INSERT_HTTP_PROXY;${HTTP_PROXY};" ubuntu-builder/Dockerfile || exit 0
	test -n "${HTTPS_PROXY}" && sed -i "s;INSERT_HTTPS_PROXY;${HTTPS_PROXY};" ubuntu-builder/Dockerfile || exit 0
	test -n "${NO_PROXY}" && sed -i "s;INSERT_NO_PROXY;${NO_PROXY};" ubuntu-builder/Dockerfile || exit 0
	sed -i '/INSERT_/d' ubuntu-builder/Dockerfile
	/usr/bin/docker build --rm=true --no-cache=true -t opnfv.org/ubuntu-builder:14.04 ubuntu-builder
	/usr/bin/docker tag opnfv.org/ubuntu-builder:14.04 opnfv.org/ubuntu-builder
	touch .docker

.PHONY:	clean
clean:
	rm -f .docker ubuntu-builder/Dockerfile
