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

# try to choose close ubuntu mirror which support rsync protocol
# https://bugs.launchpad.net/fuel/+bug/1459252
MIRROR_URLS := $(shell curl -s http://mirrors.ubuntu.com/mirrors.txt)
MIRROR_HOSTS := $(shell for url in ${MIRROR_URLS}; do echo $$url | cut -d'/' -f3; done)
RSYNC_HOST := $(shell for host in ${MIRROR_HOSTS}; do rsync -4 --contimeout 5 --no-motd --list-only "$${host}::ubuntu/." &> /dev/null && echo $$host && break; done)

.PHONY: all
all: .nailgun

.nailgun:
	sudo apt-get update
	sudo apt-get upgrade -y
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
	touch .nailgun

.PHONY: clean
clean:
	# Deliberately not cleaning nailgun directory to speed up multiple builds
	@rm -rf ../release/opnfv/nailgun fuel-createmirror_6.1*.deb

.PHONY: release
release:.nailgun
	@rm -Rf ../release/opnfv/nailgun
	@mkdir -p ../release/opnfv
	@cp -Rp nailgun ../release/opnfv/nailgun

