##############################################################################
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
# This file is only meant for a top Makefile which is only calling its
# own SUBDIRS, without building any cachable artifact by itself.
#############################################################################

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

.PHONY: get-cache
get-cache: $(SUBGETCACHE)

.PHONY: put-cache
put-cache: $(SUBPUTCACHE)

.PHONY: clean-cache
clean-cache: $(SUBCLEANCACHE)
