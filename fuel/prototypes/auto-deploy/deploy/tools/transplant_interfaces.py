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
    sys.stderr.write("Usage: "+sys.argv[0]+" <infile> <deafile> <nodeid>\n")
    sys.exit(1)

infile = sys.argv[1]
if not os.path.exists(infile):
    sys.stderr.write("ERROR: The file "+infile+" could not be opened\n")
    sys.exit(1)

deafile = sys.argv[2]
if not os.path.exists(deafile):
    sys.stderr.write("ERROR: The file "+deafile+" could not be opened\n")
    sys.exit(1)
deafile = sys.argv[2]
nodeid = int(sys.argv[3])

namespace = "interfaces"

f1 = open(infile, 'r')
doc1 = yaml.load(f1)
f1.close()

f2 = open(deafile, 'r')
doc2 = yaml.load(f2)
f2.close()


# Create lookup table network name -> id for current setup
nwlookup = {}
for interface in doc1:
  iface = {}
  networks = []
  for network in interface["assigned_networks"]:
    nwlookup[network["name"]] = network["id"]

# Find network information in DEA for this node
nodeInfo = {}
for node in doc2["nodes"]:
    if node["id"] == nodeid:
        nodeInfo=node
        print "Found nodeinfo for node %d" % nodeid

out = {}
out["interfaces"] = {}

for interface in doc1:
  assigned = []
  nw = {}
  interface["assigned_networks"] = []
  try:
    for nwname in nodeInfo["interfaces"][interface["name"]]:
      iface = {}
      iface["id"] = nwlookup[nwname]
      iface["name"] = nwname
      interface["assigned_networks"].append(iface)
  except:
    print "No match for interface " + interface["name"]

f3 = open(infile, 'w')
f3.write(yaml.dump(doc1, default_flow_style=False))
f3.close()
