##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Class: opnfv::opncheck
#
# Make sure that /opt/opnfv/pre-deploy.sh has been run by
# verifying there is an "opnfv:" level in the astute.yaml.

class opnfv::opncheck()
{
  unless $::fuel_settings['opnfv'] {
    fail("Error: You have not run /opt/opnfv/pre-deploy.sh on the Fuel master prior to deploying!")
  }
}
