##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

#!/usr/bin/expect
spawn /opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/client
expect "root>"
send "feature:list | grep -i odl-restconf\r"
send "\r\r\r"
expect "root>"
send "logout\r"


