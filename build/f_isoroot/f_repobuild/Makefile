##############################################################################
# Copyright (c) 2015,2016 Ericsson AB, Enea AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# Alexandru.Avadanii@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL := /bin/bash
TOP := $(shell pwd)

include ../../config.mk
include config.mk

export MOS_VERSION
export MIRROR_UBUNTU_OPNFV_PATH:=$(TOP)/nailgun/mirrors/ubuntu

.PHONY: all
all: nailgun

nailgun:
	sudo apt-get install -y createrepo git libxml2-dev libxslt1-dev \
		python-dev zlib1g-dev
	rm -Rf nailgun packetary opnfv_config && mkdir opnfv_config
	# We will analyze fuel-web's fixture files for package lists
	ln -sf ${F_SUBMOD_DIR}/fuel-web fuel-web
	git clone --quiet $(PACKETARY_REPO)
	if [ -n $(PACKETARY_COMMIT) ]; then \
		git -C packetary checkout $(PACKETARY_COMMIT); \
	fi
	sudo pip install -U -r ./packetary/requirements.txt
	sudo pip install ./packetary
	# Handle config and mirror build in one place
	./opnfv_mirror_ubuntu.py
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

.PHONY: clean
clean:
	@rm -rf ../release/opnfv/nailgun nailgun packetary fuel-mirror opnfv_config

.PHONY: release
release:nailgun
	@rm -Rf ../release/opnfv/nailgun
	@mkdir -p ../release/opnfv
	@cp -Rp nailgun ../release/opnfv/nailgun
	@cp fuel_bootstrap_cli.yaml ../release/opnfv/

############################################################################
# Cache operations - only used when building through ci/build.sh
############################################################################

# Create a unique hash to be used for getting and putting cache, based on:
#   - Year and week (causing the cache to be rebuilt weekly)
#   - The contents of this Makefile + all sh,mk,py,yaml files in CWD
#   - repo packages fingerprint
#   - repo arch list
.cacheid:
	date +"Repocache %G%V" > .cachedata
	sha1sum Makefile *.{sh,mk,py,yaml} >> .cachedata
	$(CACHETOOL) packages >> .cachedata
	echo -n $(UBUNTU_ARCH) | sha1sum | awk {'print $$1'} >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		 $(CACHETOOL) get $(shell cat .cacheid) | tar xf -;\
	else \
		echo "No cache item found for $(shell cat .cacheid)" ;\
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - nailgun | $(CACHETOOL) put $(shell cat .cacheid)
