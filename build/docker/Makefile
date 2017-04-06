##############################################################################
# Copyright (c) 2015,2016 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL = /bin/bash
FILES = $(wildcard ubuntu-builder/*) runcontext
DOCKER_VER := $(shell [[ "$$(docker version --format '{{.Client.Version}}')" =~ ([0-9]+)\.([0-9]+) ]] && echo $$(( $${BASH_REMATCH[1]} * 100 + $${BASH_REMATCH[2]} )))

# Builder tag lifespan, force container rebuild X days after tag creation
DOCKER_KEEP = 1 days
DOCKER_IMG  = opnfv.org/ubuntu-builder
DOCKER_TAG  = ${DOCKER_IMG}:14.04
# Shell contruct for checking our tag object did not expire
DOCKER_EXPIRED = D_TAG_BIRTH=`docker inspect --format="{{.Created}}" \
	${DOCKER_TAG} 2>/dev/null`; test -z "$$D_TAG_BIRTH" -o `date +%s` -gt \
	`date -d "$$D_TAG_BIRTH +${DOCKER_KEEP}" +%s`; echo $$?

# Don't use -f flag when docker is newer than 1.9
# https://docs.docker.com/engine/deprecated/#/f-flag-on-docker-tag
ifeq ($(shell echo "$(DOCKER_VER)>109" | bc), 1)
	tag_flags :=
else
	tag_flags := -f
endif

.PHONY: all
all:	.docker

.dockercfg: $(FILES)
	cp Dockerfile ubuntu-builder/Dockerfile
	# Only add proxy ENVs where set in host - needed to pull the base Ubuntu image
	test -n "${http_proxy}" && sed -i "s;INSERT_HTTP_PROXY;${http_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${https_proxy}" && sed -i "s;INSERT_HTTPS_PROXY;${https_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${no_proxy}" && sed -i "s;INSERT_NO_PROXY;${no_proxy};" ubuntu-builder/Dockerfile || exit 0
	test -n "${HTTP_PROXY}" && sed -i "s;INSERT_HTTP_PROXY;${HTTP_PROXY};" ubuntu-builder/Dockerfile || exit 0
	test -n "${HTTPS_PROXY}" && sed -i "s;INSERT_HTTPS_PROXY;${HTTPS_PROXY};" ubuntu-builder/Dockerfile || exit 0
	test -n "${NO_PROXY}" && sed -i "s;INSERT_NO_PROXY;${NO_PROXY};" ubuntu-builder/Dockerfile || exit 0
	sed -i '/INSERT_/d' ubuntu-builder/Dockerfile
	touch $@

.docker: .dockercfg
	@if test -f .cacheid -o "$(shell ${DOCKER_EXPIRED})" -eq "0"; then \
		/usr/bin/docker build --rm=true --no-cache=true \
			-t ${DOCKER_TAG} ubuntu-builder && \
		/usr/bin/docker tag ${tag_flags} ${DOCKER_TAG} ${DOCKER_IMG}; \
	else \
		echo "Docker: Tag '${DOCKER_TAG}' was created less than" \
			"${DOCKER_KEEP} ago, skipping re-build."; \
	fi
	touch $@
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

.PHONY:	clean
clean:
	rm -f .docker* ubuntu-builder/Dockerfile

.PHONY: deepclean
deepclean: clean clean-cache

##############################################################################
# Cache operations - only used when building through ci/build.sh
##############################################################################

# NOTE: For docker, we only get/put cache to fingerprint build scripts and
# env vars, its cached data holds only an empty .docker file.

# Create a unique hash to be used for getting and putting cache, based on:
#   - ubuntu-builder Dockerfile (includes eventual proxy env vars), runcontext;
#   - The contents of this Makefile
.cacheid: .dockercfg
	sha1sum Makefile runcontext ubuntu-builder/* > .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache:
	rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		if test "$(shell ${DOCKER_EXPIRED})" -eq "0"; then \
			echo "Docker: Tag '${DOCKER_TAG}' missing" \
				"or older than ${DOCKER_KEEP}, not using it."; \
		else \
			touch .docker; \
		fi; \
	else \
		echo "No cache item found for $(shell cat .cacheid)" ;\
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - .docker | $(CACHETOOL) put $(shell cat .cacheid)
