#!/usr/bin/python
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

import yaml
import re
import sys
import os

if len(sys.argv) != 3:
    sys.stderr.write("Usage: "+sys.argv[0]+" <nodeid> <dhafile>\n")
    sys.exit(1)

nodeId=int(sys.argv[1])
dhafile=sys.argv[2]

f1 = open("/etc/fuel/astute.yaml", 'r')
doc = yaml.load(f1)
f1.close()

dhaMac = doc["ADMIN_NETWORK"]["mac"]

# Write contribution to DHA file
f2 = open(dhafile, 'a')
f2.write("- id: " + str(nodeId) + "\n")
f2.write("  pxeMac: " + dhaMac + "\n")
f2.write("  isFuel: yes\n")
f2.close()

