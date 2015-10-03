##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# == Class: opnfv
#
# This class is used to perform OPNFV inclusions and settings on top of
# the vanilla Fuel installation.
#
# Currently all logic is self contained, i.e. it is sufficient to
# "include opnfv" from site.pp.

class opnfv {
  # Configure resolv.conf if parameters passed through astute
  include opnfv::resolver
  # Setup OPNFV style NTP config
  include opnfv::ntp
  # Make sure all added packages are installed
  include opnfv::add_packages
  # Setup OpenDaylight
  include opnfv::odl_docker
}
