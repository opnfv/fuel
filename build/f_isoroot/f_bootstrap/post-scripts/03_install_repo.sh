#/bin/sh
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

echo "Installing pre-build repo"
if [ ! -d /opt/opnfv/nailgun ]; then
  echo "Error - found no repo!"
  exit 1
fi

mkdir -p /var/www/nailgun
mv /opt/opnfv/nailgun/* /var/www/nailgun
if [ $? -ne 0 ]; then
  echo "Error moving repos to their correct location!"
  exit 1
fi
rmdir /opt/opnfv/nailgun
if [ $? -ne 0 ]; then
  echo "Error removing /opt/opnfv/nailgun directory!"
  exit 1
fi
echo "Done installing pre-build repo"
