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
	../tools/deb_unpack neutron-common_*.deb $(ORIGISO)
	patch -s -p0 < quota.patch
	../tools/deb_pack $(REVSTATE)
	@cp *.deb ../release/packages
	@cat patch-replacements >> ../release/patch-replacements
