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

# Remove control and management network transformations from file.
# Only to be used together with f_control_bond_example (enable in
# pre-deploy.sh)

import yaml
import re
import sys
import os

if len(sys.argv) != 2:
    sys.stderr.write("Usage: "+sys.argv[0]+" <filename>\n")
    sys.exit(1)

filename = sys.argv[1]
if not os.path.exists(filename):
    sys.stderr.write("ERROR: The file "+filename+" could not be opened\n")
    sys.exit(1)

ignore_values = [ "eth0", "eth1", "br-mgmt", "br-fw-admin" ]

infile = open(filename, 'r')
doc = yaml.load(infile)
infile.close()

out={}

for scheme in doc:
    if scheme == "network_scheme":
        mytransformation = {}
        for operation in doc[scheme]:
            if operation == "transformations":
                # We need the base bridges for l23network to be happy,
                # remove everything else.
                mytrans = [ { "action": "add-br", "name": "br-mgmt" },
                            { "action": "add-br", "name": "br-fw-admin" } ]
                for trans in doc[scheme][operation]:
                    delete = 0
                    for ignore in ignore_values:
                        matchObj = re.search(ignore,str(trans))
                        if matchObj:
                            delete = 1
                    if delete == 0:
                        mytrans.append(trans)
                    else:
                        pass
                        #print "Deleted", trans

                mytransformation[operation] = mytrans
            else:
                mytransformation[operation] = doc[scheme][operation]
        out[scheme] = mytransformation
    else:
        out[scheme] = doc[scheme]

outfile = open(filename, 'w')
outfile.write(yaml.dump(out, default_flow_style=False))
outfile.close()
