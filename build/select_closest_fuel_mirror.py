#!/usr/bin/python
##############################################################################
# Copyright (c) 2016 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Select closest fuel mirror based on latency measured with ping.
# Failsafe: The us1 mirror

from subprocess import Popen,PIPE
import re
from operator import itemgetter

mirrors = [ "us1", "cz1" ]
FNULL = open('/dev/null', 'w')
try:
    re_avg = re.compile(r'.* = [^/]*/([^/]*).*')

    pingtime = {}
    for mirror in mirrors:
        fqdn = "mirror.seed-"+mirror+".fuel-infra.org"
        pingtime[fqdn] = 0
        pipe = Popen("ping -c 3 " + fqdn + " | tail -1",shell = True, stdout=PIPE, stderr=FNULL)
        avg  = pipe.communicate()[0]
        pipe.stdout.close()
        pingtime[fqdn] = float(re_avg.split(avg)[1])

    print sorted(pingtime.items(), key=itemgetter(1))[0][0]
except:
    print "mirror.seed-"+mirrors[0]+".fuel-infra.org"
