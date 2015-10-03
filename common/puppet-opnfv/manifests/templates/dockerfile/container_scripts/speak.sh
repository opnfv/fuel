#!/usr/bin/expect
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Simple expect script to start up ODL client and load feature set for DLUX and OVSDB
#  NOTE: THIS WILL BE REPLACED WITH A PROGRAMATIC METHOD SHORTLY
#################################################################################

spawn /opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/client
expect "root>"
send "feature:install odl-base-all odl-aaa-authn odl-restconf odl-nsf-all odl-adsal-northbound odl-mdsal-apidocs  odl-ovsdb-openstack odl-ovsdb-northbound odl-dlux-core"
send "\r\r\r"
expect "root>"
send "logout\r"
