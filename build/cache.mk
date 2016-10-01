##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

#############################################################################
# Cache operations - only used when building through ci/build.sh
#
# This is the global cache implementation, providing the main target "cache"
# which is called from ci/build.sh, and recursively calling the cache
# operations clean-cache, get-cache and put-cache on all $(SUBDIRS).
#############################################################################


export CACHETOOL := $(BUILD_BASE)/cache.sh

# Call sub caches
SUBGETCACHE = $(addsuffix .getcache,$(SUBDIRS))
$(SUBGETCACHE): %.getcache:
	$(MAKE) -C $* -f Makefile get-cache

SUBPUTCACHE = $(addsuffix .putcache,$(SUBDIRS))
$(SUBPUTCACHE): %.putcache:
	$(MAKE) -C $* -f Makefile put-cache

SUBCLEANCACHE = $(addsuffix .cleancache,$(SUBDIRS))
$(SUBCLEANCACHE): %.cleancache:
	$(MAKE) -C $* -f Makefile clean-cache

# Overlay implementation:
#   - clean
#   - clean cache identities
#   - get caches
#   - build iso
#   - store caches
.PHONY: cached-all
cached-all: clean clean-cache $(SUBCLEANCACHE) get-cache $(SUBGETCACHE) iso put-cache $(SUBPUTCACHE)
	@echo "Cached build is complete"


# cache: The target for ci/build.sh
.PHONY: cache
cache:
	@if [ -z "${CACHEBASE}" ]; then \
		echo "CACHEBASE not set, are you really building through build.sh?"; \
		exit 1; \
	fi
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker get-cache all
	docker/runcontext $(DOCKERIMG) $(MAKE) $(MAKEFLAGS) cached-all
