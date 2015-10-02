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
    sys.stderr.write("Usage: "+sys.argv[0]+" <controllerfile> <computefile> <outfile>\n")
    sys.exit(1)

controller = sys.argv[1]
if not os.path.exists(controller):
    sys.stderr.write("ERROR: The file "+controller+" could not be opened\n")
    sys.exit(1)

compute = sys.argv[2]
if not os.path.exists(compute):
    sys.stderr.write("ERROR: The file "+compute+" could not be opened\n")
    sys.exit(1)

outfile = sys.argv[3]

f_controller = open(controller, 'r')
doc_controller = yaml.load(f_controller)
f_controller.close()

f_compute = open(compute, 'r')
doc_compute = yaml.load(f_compute)
f_compute.close()

out = {}
out["opnfv"] = {}
out["opnfv"]["controller"] = doc_controller["opnfv"]
out["opnfv"]["compute"] = doc_compute["opnfv"]

f2 = open(outfile, 'a')
f2.write(yaml.dump(out, default_flow_style=False))
f2.close()

