##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SUBDIRS = f_kscfg f_bootstrap f_isolinux f_repobuild
SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all:	$(SUBDIRS) plugins

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	@mkdir -p release
	$(MAKE) -C $@ -f Makefile release

.PHONY: plugins
plugins:
#	TODO default no plugin-build if promotions- or build-spec aren't defined......
#	TODO rather than operating on files in the make script, we should have BUILD_SPEC_YAML
#	and PROMOTIONS_YAML representing JSON objects - expanded by ci/build.sh
	@mkdir -p release/opt/plugins
	PLUGINS=`echo "$(BUILD_SPEC)" | shyaml get-value Plugins | shyaml keys`; \
	pushd release/opt/plugins &> /dev/null; \
	for plugin in $${PLUGINS}; do \
	   ARTIFACT_URI=`echo "$(BUILD_SPEC)" | shyaml get-value Plugins.$${plugin).Un-promoted 2> /dev/null`; \
	   if [ $$? -ne 0 ]; then \
	      plugin_branch=`echo "$(BUILD_SPEC)" | shyaml get-value Plugins.$${plugin).Branch 2> /dev/null`; \
	      if [ $$? -ne 0 ]; then \
	         echo "ERROR: Syntax error in build-spec for Plugin: $${plugin}, aborting build with errors..."; \
                 exit 1;
	      fi; \
	      plugin_promotion=`echo "$(BUILD_SPEC)" | shyaml get-value Plugins.$${plugin).Promotion-level 2> /dev/null`; \
	      if [ $$? -ne 0 ]; then \
	         echo "ERROR: Syntax error in build-spec for Plugin: $${plugin}, aborting build with errors..."; \
	         exit 1;
	      fi; \
	      ARTIFACT_URI=`echo "$(PROMOTIONS)" | shyaml get-value Plugins.$${plugin).Branch.$${plugin_branch}.Promotion-level.$${plugin-promotion} 2> /dev/null`; \
	      if [ $$? -ne 0 ]; then \
	         echo "ERROR: There is no plugin: $${plugin} promoted to: $${plugin-promotion} as defined by the build-spec, aborting build with errors..."; \
	         exit 1;
	      fi; \
	   fi; \
	   wget $${ARTIFACT_URI}; \
	   tar -xf basename $${plugin}; \
	done; \
	popd &> /dev/null

.PHONY: clean $(SUBCLEAN)
clean: $(SUBCLEAN)
	@rm -Rf release

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean

.PHONY: release
release: $(SUBDIRS)
	@cp -Rvp release/* ../release/isoroot

include cache.mk
