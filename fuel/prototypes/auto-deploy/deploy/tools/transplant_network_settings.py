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
    sys.stderr.write("Usage: "+sys.argv[0]+" <file> <deafile>\n")
    sys.exit(1)

file = sys.argv[1]
if not os.path.exists(file):
    sys.stderr.write("ERROR: The file "+file+" could not be opened\n")
    sys.exit(1)

deafile = sys.argv[2]
if not os.path.exists(deafile):
    sys.stderr.write("ERROR: The file "+deafile+" could not be opened\n")
    sys.exit(1)

f1 = open(file, 'r')
doc1 = yaml.load(f1)
f1.close()

f2 = open(deafile, 'r')
doc2 = yaml.load(f2)
f2.close()

# Grab IDs from Fuel version, graft onto DEA version and save
id = []
groupid = []
for nw in doc1["networks"]:
  id.append(nw["id"])
  groupid.append(nw["group_id"])

for nw in doc2["network"]["networks"]:
  nw["id"] = id.pop(0)
  nw["group_id"] = groupid.pop(0)

f3 = open(file, 'w')
f3.write(yaml.dump(doc2["network"], default_flow_style=False))
f3.close()
