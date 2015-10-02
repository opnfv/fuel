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

def test(arr):
    print "Nodes"
    nodes = doc["nodes"]
    for node in nodes:
        print "Node %d " % node["id"]
        print "  Mac: %s" % node["adminMac"]
        print "  Role: %s" % node["role"]

def get(arg):
    try:
        if doc[arg[0]]:
            print doc[arg[0]]
        else:
            print ""
    except KeyError:
        print ""

def getNodes(arg):
    for node in doc["nodes"]:
        print node["id"]

# Get property arg2 from arg1
def getNodeProperty(arg):
    id=arg[0]
    key=arg[1]

    for node in doc["nodes"]:
        if node["id"] == int(id):
            try:
                if node[key]:
                    print node[key]
                    exit(0)
            except:
                print ""
                exit(0)
    exit(1)



infile = sys.argv[1]

if not os.path.exists(infile):
    sys.stderr.write("ERROR: The file "+infile+" could not be opened\n")
    sys.exit(1)


f1 = open(infile, 'r')
doc = yaml.load(f1)
f1.close()

cmd = sys.argv[2]
args = sys.argv[3:]

if cmd  == "test":
    test(args)
elif cmd == "getNodes":
    getNodes(args)
elif cmd == "getNodeProperty":
    getNodeProperty(args)
elif cmd == "get":
    get(args)
else:
  print "No such command: %s" % cmd
  exit(1)

#print "Dumping"
#print yaml.dump(doc, default_flow_style=False)

#Functions:

#getIdRole
