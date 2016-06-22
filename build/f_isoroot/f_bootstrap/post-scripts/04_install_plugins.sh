#/bin/sh
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# ruijing.guo@intel.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

echo "Installing fuel plugins"
if [ ! -d /opt/opnfv/ ]; then
  echo "Error - found no fuel plugins!"
  exit 1
fi

cd /opt/opnfv

plugins=`ls *.rpm`

for plugin in $plugins
do
    fuel plugins --install $plugin
done

echo "Done installing fuel plugins"
