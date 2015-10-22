##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Fuel Plugin repo/branch
#
export OCL_PLUGIN_BRANCH="stable/2.1"
export OCL_PLUGIN_REPO="https://github.com/openstack/fuel-plugin-contrail"
export OPENSTACK_RELEASE='juno'
export UBUNTU_RELEASE=$(lsb_release -cs)
CONTRAIL_BUILD="22mira1${OPENSTACK_RELEASE}1~${UBUNTU_RELEASE}1"
#export CONTRAIL_BUILD=opnfv-$(OPENSTACK_RELEASE)-$(UBUNTU_RELEASE)

# Build options
#
# Uncomment The line below to in order to build a DPDK accellerated vRouter -
# Not yet supported
# CONTRAIL_DPDK=1

# OpenContrail repos
#
# NOTE THE OPEN CONTRAIL REPO SPECIFICATION IS FOUND AT:
# ===== ./manifest.xml =====
