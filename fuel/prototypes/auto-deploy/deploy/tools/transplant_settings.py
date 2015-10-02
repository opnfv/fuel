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

f1 = open(deafile, 'r')
doc = yaml.load(f1)
f1.close()

out = doc["settings"]
f2 = open(file, 'w')
f2.write(yaml.dump(out, default_flow_style=False))
f2.close()

