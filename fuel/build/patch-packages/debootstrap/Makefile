##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
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
	@rm -rf udebPackage
	@rm -rf *.udeb
	@rm -rf patch-replacements
	@rm -rf .udebpackage

.PHONY: release
release:
	../tools/udeb_unpack debootstrap-udeb_1.0.4*.udeb $(ORIGISO)
	patch -s -p0 < debootstrap.patch
	../tools/udeb_pack $(REVSTATE)
	@cp *.udeb $(UDEB_DEST)
