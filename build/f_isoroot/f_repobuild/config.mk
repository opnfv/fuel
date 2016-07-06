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
# FIXME(armband): Update upstream commit ref once [1, 2] are merged
# [1] https://review.openstack.org/#/c/392937/
# [2] https://review.openstack.org/#/c/392936/
export PACKETARY_REPO?=https://github.com/openstack/packetary
export PACKETARY_COMMIT?=c46465c3255a9f5e59a05b8701e06054df39f32f

# arm64 Ubuntu mirror is separated from archive.ubuntu.com
export MIRROR_UBUNTU_URL_arm64=http://ports.ubuntu.com/ubuntu-ports/
export MIRROR_UBUNTU_ROOT_arm64=ubuntu-ports
