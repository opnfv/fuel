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
DOCKNAME = fuelrepo
DOCKVERSION = 1.0

RSYNC_HOST := $(shell ./select_ubuntu_repo.sh)

.PHONY: all
all: nailgun

nailgun:
	sudo apt-get install -y rsync python python-yaml dpkg-dev openssl
	rm -rf tmpiso tmpdir
	mkdir tmpiso
	fuseiso ${ISOCACHE} tmpiso
	cp tmpiso/ubuntu/pool/main/f/fuel-createmirror/fuel-createmirror_6.1*.deb .
	fusermount -u tmpiso
	rm -rf tmpiso
	sudo dpkg -i fuel-createmirror_6.1*.deb
	sudo sed -i 's/DOCKER_MODE=true/DOCKER_MODE=false/' /etc/fuel-createmirror/common.cfg
	sudo sed -i 's/DEBUG="no"/DEBUG="yes"/' /etc/fuel-createmirror/ubuntu.cfg
	sudo sed -i 's/MIRROR_UBUNTU_HOST="archive.ubuntu.com"/MIRROR_UBUNTU_HOST="${RSYNC_HOST}"/' /etc/fuel-createmirror/common.cfg
	rm -Rf nailgun
	sudo mkdir -p /var/www
	sudo su - -c /opt/fuel-createmirror-6.1/fuel-createmirror
	sudo chmod -R 755 /var/www/nailgun
	cp -Rp /var/www/nailgun .

.PHONY: clean
clean:
	@rm -rf ../release/opnfv/nailgun nailgun fuel-createmirror_6.1*.deb

.PHONY: release
release:nailgun
	@rm -Rf ../release/opnfv/nailgun
	@mkdir -p ../release/opnfv
	@cp -Rp nailgun ../release/opnfv/nailgun

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
