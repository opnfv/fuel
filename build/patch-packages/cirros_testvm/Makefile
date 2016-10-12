##############################################################################
# Copyright (c) 2015,2016 Ericsson AB, Mirantis Inc. and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# mpolenchuk@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)

.PHONY: all
all:

.PHONY: clean
clean:
	@rm -rf package
	@rm -rf *.deb
	@rm -rf patch-replacements
	@rm -rf .package

.PHONY: release
release:
	../tools/deb_unpack c/cirros-testvm/cirros-testvm_0.3.4-2~u16.04+mos5_amd64.deb $(ORIGISO)
	@rm -rf package/usr/share/cirros-testvm/*
	wget -O package/usr/share/cirros-testvm/cirros-x86_64-disk.img http://download.cirros-cloud.net/daily/20160722/cirros-d160722-x86_64-disk.img
	../tools/deb_pack $(REVSTATE)
	@cp *.deb ../release/packages
	@cat patch-replacements >> ../release/patch-replacements
