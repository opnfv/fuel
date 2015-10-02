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

if len(sys.argv) != 5:
    sys.stderr.write("Usage: "+sys.argv[0]+" <nodeid> <role> <infile> <dhafile>\n")
    sys.exit(1)

infile = sys.argv[3]
if not os.path.exists(infile):
    sys.stderr.write("ERROR: The file "+infile+" could not be opened\n")
    sys.exit(1)

nodeId=int(sys.argv[1])
nodeRole=sys.argv[2]
dhafile=sys.argv[4]

f1 = open(infile, 'r')
doc = yaml.load(f1)
f1.close()

out = {}

node = {}
node["id"] = nodeId
node["role"] = nodeRole
node["interfaces"] = {}


for interface in doc:
  iface = {}
  networks = []
  for network in interface["assigned_networks"]:
    networks.append(network["name"])
    if network["name"] == "fuelweb_admin":
      dhaMac = interface["mac"]
  if networks:
    node["interfaces"][interface["name"]] = networks

out = [node]

sys.stdout.write(yaml.dump(out, default_flow_style=False))

# Write contribution to DHA file
f2 = open(dhafile, 'a')
f2.write("- id: " + str(nodeId) + "\n")
f2.write("  pxeMac: " + dhaMac + "\n")
f2.close()

