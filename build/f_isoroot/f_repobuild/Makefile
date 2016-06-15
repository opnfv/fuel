##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL := /bin/bash
TOP := $(shell pwd)
TMP_ROOT_DIR := $(shell echo "$(MIRROR_UBUNTU_ROOT)" | cut -d "/" -f2)
# Enable use of exact repo commit if defined, else use Fuel main branch
FUEL_MIRROR_REPO?=https://github.com/openstack/fuel-mirror
FUEL_MIRROR_COMMIT?=$(FUEL_MAIN_TAG)

include ../../config.mk

export MOS_VERSION
export OPENSTACK_VERSION

.PHONY: all
all: nailgun

nailgun:
	sudo apt-get install -y git libxml2-dev libxslt-dev python-dev  python-pip libz-dev libyaml-dev createrepo python-yaml
	rm -Rf nailgun
	sudo mkdir -p /var/www/nailgun
	git clone $(FUEL_MIRROR_REPO)
	cd fuel-mirror && git checkout -q $(FUEL_MIRROR_COMMIT)
	sudo pip install -U -r ./fuel-mirror/requirements.txt
	sudo pip install ./fuel-mirror
	sudo pip install ./fuel-mirror/contrib/fuel_mirror
	./opnfv_mirror_conf.py
	sudo fuel-mirror --debug --config ./opnfv-config.yaml create --group ubuntu --pattern=ubuntu
	sudo chmod -R 755 /var/www/nailgun
	cp -Rp /var/www/nailgun .
	# On the end we want to have ubuntu repository in mirrors/ubuntu directory
	-if [ "$(MIRROR_UBUNTU_ROOT)" != "/ubuntu/" ]; then \
	  mkdir -p nailgun/mirrors/ubuntu;\
	  mv nailgun/mirrors$(MIRROR_UBUNTU_ROOT)* nailgun/mirrors/ubuntu;\
	  [ "$(MIRROR_UBUNTU_ROOT)" != "/" ] && rm -rf nailgun/mirrors/$(TMP_ROOT_DIR);\
	fi
	# Store artifact in cache straight away if caching is enabled
	# (no .cacheid will be present unless this is a cached build)
	test -f .cacheid && $(MAKE) -f Makefile put-cache || exit 0

.PHONY: clean
clean:
	@rm -rf ../release/opnfv/nailgun nailgun fuel-mirror opnfv-config.yaml ubuntu.yaml

.PHONY: release
release:nailgun
	@rm -Rf ../release/opnfv/nailgun
	@mkdir -p ../release/opnfv
	@cp -Rp nailgun ../release/opnfv/nailgun
	@cp fuel_bootstrap_cli.yaml ../release/opnfv/

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################

# Create a unique hash to be used for getting and putting cache, based on:
#   - Year and week (causing the cache to be rebuilt weekly)
#   - The contents of this Makefile
.cacheid:
	date +"Repocache %G%V" > .cachedata
	sha1sum Makefile >> .cachedata
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
