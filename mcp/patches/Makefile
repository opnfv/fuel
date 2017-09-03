##############################################################################
# Copyright (c) 2015,2016,2017 Ericsson AB, Enea AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# Alexandru.Avadanii@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

include config.mk

SHELL = /bin/sh
FPATCHES = $(shell find ${F_PATCH_DIR} -name '*.patch')

# NOTE: Mechanism overview is presented in ./README.md.

# Submodule consistent states:
#   - NOT initialized (submodule trees are not populated at all);
#   - initialized, bound to saved commits;
#   - initialized, tracking remote origin (only for FUEL_TRACK_REMOTES);
#   - patched (local patches are applied);

# In order to keep things sort of separate, we should only pass up (to main
# Makefile) the fully-patched repos, and gather any fingerprinting info here.

# Fuel@OPNFV relies on upstream git repos (one per component) in 1 of 2 ways:
#   - pinned down to tag objects (e.g. "9.0.1")
#   - tracking upstream remote HEAD on a stable or master branch
# FIXME(alav): Should we support mixed cases? (e.g. pin down only fuel-main)

# To enable remote tracking, set the following var to any non-empty string.
# Leaving this var empty will bind each git submodule to its saved commit.
FUEL_TRACK_REMOTES ?=

.PHONY: all
all: release

##############################################################################
# git submodule operations - to be used stand-alone or from parent Makefile
##############################################################################

# Fetch & update git submodules, checkout remote HEAD or saved commit
# Also gather fingerprints for parent gitinfo_fuel.txt.
.PHONY: sub
sub: .cachefuelinfo

.cachefuelinfo:
	@if [ -n "${FUEL_TRACK_REMOTES}" ]; then \
		cd ${F_GIT_ROOT} && git submodule update --init --remote 2>/dev/null; \
	else \
		git submodule update --init 2>/dev/null; \
	fi
	@touch $@

# Generate patches from submodules
.PHONY: patches-export
patches-export: sub
	@git submodule -q foreach ' \
		SUB_DIR=${F_PATCH_DIR}/$$name; \
		git tag | awk "!/root/ && /${F_OPNFV_TAG}-fuel/" | while read F_TAG; do \
			SUB_FEATURE=`dirname $${F_TAG#${F_OPNFV_TAG}-fuel/}`; \
			echo "`tput setaf 2`-- exporting $$name ($$F_TAG)`tput sgr0`"; \
			mkdir -p $$SUB_DIR/$${SUB_FEATURE} && \
			git format-patch --no-signature --ignore-space-at-eol \
				-o $$SUB_DIR/$$SUB_FEATURE -N $$F_TAG-root..$$F_TAG; \
			sed -i -e "1{/From: /!d}" -e "s/[[:space:]]*$$//" \
				$$SUB_DIR/$$SUB_FEATURE/*.patch; \
		done'

# Apply patches from patch/* to respective submodules
# We rely on `make sub` and/or `make clean` to checkout correct base
.PHONY: patches-import
patches-import: sub .cachepatched

.cachepatched: ${FPATCHES}
	@$(MAKE) clean
	@cd ${F_GIT_ROOT} && git submodule -q foreach ' \
		SUB_DIR=${F_PATCH_DIR}/$$name; mkdir -p $$SUB_DIR && \
		git tag ${F_OPNFV_TAG}-root && \
		git checkout -q -b opnfv-fuel && \
		find $$SUB_DIR -type d | sort | while read p_dir; do \
			SUB_PATCHES=$$(ls $$p_dir/*.patch 2>/dev/null); \
			if [ -n "$$SUB_PATCHES" ]; then \
				SUB_FEATURE=$${p_dir#$$SUB_DIR}; \
				SUB_TAG=${F_OPNFV_TAG}-fuel$$SUB_FEATURE/patch; \
				echo "`tput setaf 2`-- patching $$name ($$SUB_TAG)`tput sgr0`";\
				git tag $$SUB_TAG-root && \
				git am -3 --whitespace=nowarn --patch-format=mbox \
					--committer-date-is-author-date $$SUB_PATCHES && \
				git tag $$SUB_TAG || exit 1; \
			fi \
		done && \
		git tag ${F_OPNFV_TAG}'
	@touch $@

# Clean any changes made to submodules, checkout upstream Fuel root commit
.PHONY: clean
clean:
	@cd ${F_GIT_ROOT} && git submodule -q foreach ' \
		git am -q --abort > /dev/null 2>&1; \
		git checkout -q -f ${F_OPNFV_TAG}-root > /dev/null 2>&1; \
		git branch -q -D opnfv-fuel > /dev/null 2>&1; \
		git tag | grep ${F_OPNFV_TAG} | xargs git tag -d > /dev/null 2>&1; \
		git reset -q --hard HEAD; \
		git clean -xdff'
	@rm -f .cachepatched

.PHONY: deepclean
deepclean: clean
	@git submodule deinit -f ${F_GIT_ROOT}
	@rm -f .cache*

.PHONY: release
release: sub
	$(MAKE) -f Makefile patches-import
