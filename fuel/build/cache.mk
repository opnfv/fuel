#############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL = /bin/bash
CACHEVALIDATE := $(addsuffix .validate,$(SUBDIRS))
CACHECLEAN := $(addsuffix .clean,$(CACHEFILES) $(CACHEDIRS))

############################################################################
# BEGIN of variables to customize
#
#CACHEDIRS := foo/bar

CACHEFILES += .versions
CACHEFILES += $(shell basename $(ISOSRC))
#
# END of variables to customize
############################################################################

.PHONY: prepare-cache
prepare-cache: make-cache-dir $(CACHEDIRS) $(CACHEFILES)

.PHONY: make-cache-dir
make-cache-dir:
	@rm -rf ${CACHE_DIR}
	@mkdir ${CACHE_DIR}

.PHONY: clean-cache
clean-cache: $(CACHECLEAN)
	@rm -rf ${CACHE_DIR}

.PHONY: $(CACHEDIRS)
$(CACHEDIRS):
	@mkdir -p $(dir $(CACHE_DIR)/$@)
	@if [ ! -d $(BUILD_BASE)/$@ ]; then\
	   mkdir -p $(BUILD_BASE)/$@;\
	fi
	@ln -s $(BUILD_BASE)/$@ $(CACHE_DIR)/$@

.PHONY: $(CACHEFILES)
$(CACHEFILES):
	@mkdir -p $(dir $(CACHE_DIR)/$@)
	@if [ ! -d $(dir $(BUILD_BASE)/$@) ]; then\
	   mkdir -p $(dir $(BUILD_BASE)/$@);\
	fi

	@if [ ! -f $(BUILD_BASE)/$@ ]; then\
	   echo " " > $(BUILD_BASE)/$@;\
	   ln -s $(BUILD_BASE)/$@ $(CACHE_DIR)/$@;\
	   rm -f $(BUILD_BASE)/$@;\
	else\
	   ln -s $(BUILD_BASE)/$@ $(CACHE_DIR)/$@;\
	fi

.PHONY: validate-cache
validate-cache: $(CACHEVALIDATE)
	@if [ "$(shell md5sum $(BUILD_BASE)/config.mk | cut -f1 -d " ")" != "$(shell cat $(VERSION_FILE) | grep config.mk | awk '{print $$NF}')" ]; then\
	   echo "Cache does not match current config.mk definition, cache must be rebuilt";\
	   exit 1;\
	fi;

	@if [ "$(shell md5sum $(BUILD_BASE)/cache.mk | cut -f1 -d " ")" != "$(shell cat $(VERSION_FILE) | grep cache.mk | awk '{print $$NF}')" ]; then\
	   echo "Cache does not match current cache.mk definition, cache must be rebuilt";\
	   exit 1;\
	fi;

# Once the Make structure is refactored, this should go in as a validate-cache
# taget in the fuel Makefile

	@REMOTE_ID=$(shell git ls-remote $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG)^{} | awk '{print $$(NF-1)}'); \
	if [ -z $$REMOTE_ID ] || [ $$REMOTE_ID = " " ]; \
	then \
	   REMOTE_ID=$(shell git ls-remote $(FUEL_MAIN_REPO) $(FUEL_MAIN_TAG) | awk '{print $$(NF-1)}'); \
	fi; \
	if [[ $$REMOTE_ID != $(shell cat $(VERSION_FILE) | grep fuel | awk '{print $$NF}') ]]; \
	then \
	   echo "Cache does not match upstream Fuel, cache must be rebuilt!"; \
	   exit 1; \
	fi

.PHONY: $(CACHEVALIDATE)
$(CACHEVALIDATE): %.validate:
	@echo VALIDATE $(CACHEVALIDATE)
	$(MAKE) -C $* -f Makefile validate-cache

.PHONY: $(CACHECLEAN)
$(CACHECLEAN): %.clean:
	rm -rf ${CACHE_DIR}/$*
