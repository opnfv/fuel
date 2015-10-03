##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

############################################################################
# BEGIN of variables to customize
#
SHELL = /bin/bash


BUILD_DIR := $(shell pwd)
GIT_DIR := /tmp
export CONFIG_SPEC_SCRIPT
export MAVEN_OPTS = -Xmx1024m -XX:MaxPermSize=512m
MAINTAINER = "Main Tainer <main.tainer@example.org>"
ODL_SHORT_NAME = odl
ODL_VERSION = 0.1-1
DEPEND = openjdk-8-jdk
TARGET_BUILD_PATH="/tmp/controller/opendaylight/distribution/opendaylight-karaf/target/"
MAVEN_SPEC = $(BUILD_DIR)/odl_maven/settings.xml

#
# END of variables to customize
#############################################################################

.PHONY: all
all:	odl

############################################################################
# BEGIN of Include definitions
#
include ../config.mk
#
# END Include definitions
#############################################################################

.PHONY: setup
setup:
	rm -f "$(BUILD_BASE)/f_odl"
	ln -s "$(shell readlink -e $(BUILD_DIR))/f_odl" "$(shell readlink -e $(BUILD_BASE))/f_odl"

.PHONY: validate-cache
validate-cache:
	@REMOTE_ID=$(shell git ls-remote $(ODL_MAIN_REPO) $(ODL_MAIN_TAG)^{} | awk '{print $$(NF-1)}'); \
	if [ -z $$REMOTE_ID ] || [ $$REMOTE_ID = " " ]; \
	then \
	   REMOTE_ID=$(shell git ls-remote $(ODL_MAIN_REPO) $(ODL_MAIN_TAG) | awk '{print $$(NF-1)}'); \
	fi; \
	if [ $$REMOTE_ID != $(shell cat $(VERSION_FILE) | grep odl | awk '{print $$NF}') ]; \
	then \
	   echo "Cache does not match upstream OpenDaylight, cache must be rebuilt!"; \
	   exit 1; \
	fi

.PHONY: odl
odl:

ifeq ($(ODL_MAIN_REPO),)
	@echo "No config-spec target for ODL, nothing to build"
else

ifeq ($(shell if [ -e .odl-build.log ];then cat .odl-build.log; fi;),$(ODL_MAIN_TAG))
	@cd /tmp && git clone $(ODL_MAIN_REPO) && cd /tmp/controller && git checkout $(ODL_MAIN_TAG)

	@echo "ODL is up to date"
else
	@if [ ! -d "/tmp/controller" ]; then\
	   cd /tmp && git clone $(ODL_MAIN_REPO);\
	fi;

	@if [ "$(UNIT_TEST)" = "FALSE" ]; then\
	   echo "Building ODL without unit test";\
	   cd /tmp/controller &&\
	   git checkout $(ODL_MAIN_TAG) &&\
	   mvn -D maven.test.skip=true -gs $(MAVEN_SPEC) clean install;\
	else\
	   echo "Building ODL with unit test";\
	   cd /tmp/controller &&\
	   git checkout $(ODL_MAIN_TAG) &&\
	   mvn -gs $(MAVEN_SPEC) clean install;\
	fi;

	@echo "odl" `git -C /tmp/controller show | grep commit | head -1 | cut -d " " -f2` >> $(VERSION_FILE)
	@./make-odl-deb.sh -N $(ODL_SHORT_NAME)_`cd /tmp/controller; git rev-parse --short HEAD` -n $(ODL_SHORT_NAME) -v "$(ODL_VERSION)" -t "$(ODL_MAIN_TAG)" -m $(MAINTAINER) -d $(DEPEND) -p $(TARGET_BUILD_PATH)
	@echo $(ODL_MAIN_TAG) > .odl-build.log
endif
endif

.PHONY: clean $(SUBCLEAN)
clean: $(SUBCLEAN)
	@rm -Rf /tmp/controller
	@rm -f .odl-build.log
	@./make-odl-deb.sh -C

.PHONY: release
release:
