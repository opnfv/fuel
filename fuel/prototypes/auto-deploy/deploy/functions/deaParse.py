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

def getNodeRole(arg):
    for node in doc["nodes"]:
        print node
        try:
            if node["role"] == arg[0]:
                print doc["id"]
        except KeyError:
            exit(1)

def getNodes(arg):
    for node in doc["nodes"]:
        print node["id"]


def getProperty(arg):
    result = doc
    for level in arg:
        result = result[level]
    print result

def getNodeRole(arg):
    for node in doc["nodes"]:
        if int(arg[0]) == node["id"]:
            print node["role"]

def getNode(arg):
    id=arg[0]
    key=arg[1]
    for node in doc["nodes"]:
        if int(node["id"]) == int(id):
            print node[key]

    # for node in doc["nodes"]:
    #     if int(node["id"]) == int(arg[0]):
    #         print node

infile = sys.argv[1]

if not os.path.exists(infile):
    sys.stderr.write("ERROR: The file "+infile+" could not be opened\n")
    sys.exit(1)


f1 = open(infile, 'r')
doc = yaml.load(f1)
f1.close()

cmd = sys.argv[2]
args = sys.argv[3:]

if cmd == "getProperty":
    getProperty(args)
elif cmd == "getNodeRole":
    getNodeRole(args)
elif cmd == "getNode":
    getNode(args)
elif cmd == "get":
    get(args)
else:
  print "No such command: %s" % cmd
  exit(1)
