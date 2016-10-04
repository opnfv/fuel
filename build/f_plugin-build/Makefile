##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)
SHELL = /bin/bash
export DOCKERIMG = opnfv.org/ubuntu-builder:14.04
export PLUGIN_BUILD_PATH ?= $(TOP)
export GIT_METADATA_FILE ?= $(TOP)/metadata.yaml

############################################################################
# BEGIN of variables to customize
#
# Input args
PLUGIN_REPO ?=
PLUGIN_BRANCH ?=
PLUGIN_CHANGE ?=
CI_META ?= \{\"info\":\"no_info_available\"}
# END Input args
#
# END of variables to customize
#############################################################################



.PHONY: all
all:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C ../docker
	@lsb_release -a | grep Ubuntu > /dev/null 2>&1 || (echo 'Ubuntu is the only supported Linux distribution for this build system'; exit 1)
	@KERNEL_VER=$$(uname -r); \
	KERNEL_ARRAY=($${KERNEL_VER//./ }); \
	if [ $${KERNEL_ARRAY[0]} -lt 3  ] || [[ $${KERNEL_ARRAY[0]} -eq 3 && $${KERNEL_ARRAY[1]} -lt 19  ]] ; then (echo 'Kernel version must be 3.19 or newer'; exit 1) ; fi
	@docker/runcontext $(DOCKERIMG) wget -q www.google.com -O /dev/null || (echo 'No docker network connectivity or name server - check your network- and docker settings'; exit 1)
	@docker/runcontext $(DOCKERIMG) $(MAKE) $(MAKEFLAGS) release


.PHONY: clean
clean:
	@rm -rf plugin-repo release metadata.yaml

.PHONY: release
release:.pluginbuild
	@rm -rf release
	@mkdir -p release
	PLUGIN_RPM=$(shell cd plugin-repo; ls *.rpm)
	mv plugin-repo/${PLUGIN_RPM} release/.

#	Generate Build-info metadata
	BUILD_TIME=$(shell date -u "+%F-%T")
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Build-info\":\{\"Build-time\":\"${BUILD_TIME}\"\}\}
	BUILD_HOST=$(shell hostname)
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Build-info\":\{\"Build-time\":\"${BUILD_HOST}\"\}\}
	FUEL_BRANCH=$(/usr/bin/git branch | grep "*" | cut -d " " -f2)
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Build-info\":\{\"Fuel\":\{\"Branch\":\"${FUEL_BRANCH}\"\}\}\}
	FUEL_COMMIT=$(/usr/bin/git show-ref --head | head -n1 | cut -d " " -f1)
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Build-info\":\{\"Fuel\":\{\"Commit\":\"${FUEL_COMMIT}\"\}\}\}
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Build-info\":\{\"CI-metadata\":\"${CI_META}\"\}\}

#	Generate Plugin metadata
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"
Plug-in\":\{\"Archive-name\":\"${PLUGIN_RPM}\"\}
	BUILD_SHA1=$(shell sha1sum release/*.rpm | cut -d " " -f1)
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Plug-in\":\{\"SHA-1\":\"${BUILD_SHA1}\"\}
	BUILD_SIGN="noop"
	@python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Plug-in\":\{\"Sign\":\"${BUILD_SIGN}\"\}

#	Package plugin and metadata
	mv metadata.yaml release/.
	TAR_ARCHIVE=${PLUGIN_RPM##*.rpm}
	tar -C release -cfz ${TAR_ARCHIVE}.tar.gz *

.pluginbuild:
	@alias git="$(TOP)/git-tracker.sh"
	rm -rf plugin-repo metadata.yaml
	git clone $(PLUGIN_REPO) plugin-repo
	cd plugin-repo; \
	git checkout $(PLUGIN_BRANCH); \
	if [ ! -z $(PLUGIN_CHANGE) ]; then \
	   git fetch $(PLUGIN_REPO) $(PLUGIN_CHANGE); \
	   git checkout FETCH_HEAD; \
	fi
	fpb --debug --build plugin-repo/
