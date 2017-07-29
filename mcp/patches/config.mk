##############################################################################
# Copyright (c) 2015,2016,2017 Ericsson AB, Enea AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# Components pinning / remote tracking
##############################################################################

# git submodule & patch locations for Fuel components
F_GIT_ROOT   := $(shell git rev-parse --show-toplevel)
F_GIT_DIR    := $(shell git rev-parse --git-dir)
F_PATCH_DIR  := $(shell pwd)
F_OPNFV_TAG  := master-opnfv

# for the patches applying purposes (empty git config in docker build container)
export GIT_COMMITTER_NAME?=Fuel OPNFV
export GIT_COMMITTER_EMAIL?=fuel@opnfv.org
