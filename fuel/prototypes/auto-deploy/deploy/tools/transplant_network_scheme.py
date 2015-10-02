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
    sys.stderr.write("Usage: "+sys.argv[0]+" <file> <deafile> [compute|controller]\n")
    sys.exit(1)

file = sys.argv[1]
if not os.path.exists(file):
    sys.stderr.write("ERROR: The file "+file+" could not be opened\n")
    sys.exit(1)

deafile = sys.argv[2]
namespace = sys.argv[3]

f1 = open(file, 'r')
doc1 = yaml.load(f1)
f1.close()

f2 = open(deafile, 'r')
doc2 = yaml.load(f2)
f1.close()

doc1["network_scheme"]["transformations"] = doc2[namespace]

f2 = open(file, 'w')
f2.write(yaml.dump(doc1, default_flow_style=False))
f2.close()

