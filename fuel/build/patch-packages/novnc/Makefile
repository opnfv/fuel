# This is a temporary patch which add missing files
# inside novnc ubuntu package.
# Related bug: https://bugs.launchpad.net/fuel/+bug/1433894
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
	../tools/deb_unpack novnc_0.5.1*.deb $(ORIGISO)
	./fix-missing.sh
	../tools/deb_pack $(REVSTATE)
	@cp *.deb ../release/packages
	@cat patch-replacements >> ../release/patch-replacements
