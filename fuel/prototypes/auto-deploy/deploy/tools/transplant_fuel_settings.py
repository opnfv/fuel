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
    sys.stderr.write("Usage: "+sys.argv[0]+" <astutefile> <deafile>\n")
    sys.exit(1)

fuelfile = sys.argv[1]
if not os.path.exists(fuelfile):
    sys.stderr.write("ERROR: The file "+fuelfile+" could not be opened\n")
    sys.exit(1)

deafile = sys.argv[2]
if not os.path.exists(deafile):
    sys.stderr.write("ERROR: The file "+deafile+" could not be opened\n")
    sys.exit(1)

f = open(deafile, 'r')
dea  = yaml.load(f)
f.close()

f = open(fuelfile, 'r')
fuel  = yaml.load(f)
f.close()

dea = dea["fuel"]
for property in dea.keys():
    if property == "ADMIN_NETWORK":
        for adminproperty in dea[property].keys():
            fuel[property][adminproperty] = dea[property][adminproperty]
    else:
        fuel[property] = dea[property]

f = open(fuelfile, 'w')
f.write(yaml.dump(fuel, default_flow_style=False))
f.close()

