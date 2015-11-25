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
	@rm -rf package
	@rm -rf *.deb
	@rm -rf patch-replacements
	@rm -rf .package

.PHONY: release
release:
	../tools/deb_unpack python-oslo.messaging_1.3.0-fuel5.1~mira4_all.deb $(ORIGISO)
	@mkdir -p package/etc
	@echo "Hello, world" > package/etc/hello.txt
	../tools/deb_pack $(REVSTATE)
	@cp *.deb ../release/packages
	@cat patch-replacements >> ../release/patch-replacements
