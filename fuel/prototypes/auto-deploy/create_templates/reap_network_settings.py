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

if len(sys.argv) != 4:
    sys.stderr.write("Usage: "+sys.argv[0]+" <infile> <outfile> <outnamespace>\n")
    sys.exit(1)

infile = sys.argv[1]
if not os.path.exists(infile):
    sys.stderr.write("ERROR: The file "+infile+" could not be opened\n")
    sys.exit(1)

outfile = sys.argv[2]
namespace = sys.argv[3]

f1 = open(infile, 'r')
doc = yaml.load(f1)
f1.close()

for nw in doc["networks"]:
  try:
    del nw["id"]
  except:
    pass

  try:
    del nw["group_id"]
  except:
    pass

out = {}
out[namespace] = doc
f2 = open(outfile, 'a')
f2.write(yaml.dump(out, default_flow_style=False))
f2.close()
