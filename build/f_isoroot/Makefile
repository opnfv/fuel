##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Add Fuel plugin build targets here
# Plugins disabled for the Fuel Newton uplift. Please re-enable your plugin as you have
# verified it!
PLUGINS = f_ovs-nsh-dpdk-pluginbuild f_vsperfpluginbuild
export PLUGINS
NON_10-0_REBASED_PLUGINS = f_odlpluginbuild f_onosfwpluginbuild f_ovsnfv-dpdk-pluginbuild f_vsperfpluginbuild f_bgpvpn-pluginbuild

# If the BUILD_FUEL_PLUGINS environment variable is set, only build the plugins
# indicated therein.
# Temporarilu disabling f_repobuild that currently have some issues on
# Fuel Newton.
ifdef BUILD_FUEL_PLUGINS
export BUILD_FUEL_PLUGINS
#SUBDIRS = f_kscfg f_bootstrap f_isolinux f_repobuild $(BUILD_FUEL_PLUGINS)
SUBDIRS = f_kscfg f_bootstrap f_isolinux $(BUILD_FUEL_PLUGINS)
$(warning Overriding plugin build selection to $(BUILD_FUEL_PLUGINS))
else
#SUBDIRS = f_kscfg f_bootstrap f_isolinux f_repobuild $(PLUGINS)
SUBDIRS = f_kscfg f_bootstrap f_isolinux $(PLUGINS)
endif
SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all:	$(SUBDIRS)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	@mkdir -p release
	$(MAKE) -C $@ -f Makefile release

.PHONY: clean $(SUBCLEAN)
clean: $(SUBCLEAN)
	@rm -Rf release

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean

.PHONY: release
release: $(SUBDIRS)
	@cp -Rvp release/* ../release/isoroot

include cache.mk
