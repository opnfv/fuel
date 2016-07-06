##############################################################################
# Copyright (c) 2016 Ericsson AB, Enea AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# Alexandru.Avadanii@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Use a recent master commit, since tags/branches are not yet mature
export PACKETARY_REPO?=https://github.com/openstack/packetary
export PACKETARY_COMMIT?=3021c001561b4baef352bf0b881d064ac687cc20

# arm64 Ubuntu mirror is separated from archive.ubuntu.com
export MIRROR_UBUNTU_URL_arm64=http://ports.ubuntu.com/ubuntu-ports/
export MIRROR_UBUNTU_ROOT_arm64=ubuntu-ports

# Merge all local mirror repo components/section into single "main"
# NOTE: When changing this, make sure to also update all consumer config, like:
# - fuel_bootstrap_cli.yaml
export MIRROR_UBUNTU_MERGE=true
