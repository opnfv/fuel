#!/usr/bin/expect
# Ericsson Research Canada
#
# Author: Daniel Smith <daniel.smith@ericsson.com>
#
# Simple expect script to start up ODL client and load feature set for DLUX and OVSDB
#
#  NOTE: THIS WILL BE REPLACED WITH A PROGRAMATIC METHOD SHORTLY
#  DEPRECATED AFTER ARNO

spawn /opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/client
expect "root>"
send "feature:install odl-base-all odl-aaa-authn odl-restconf odl-nsf-all odl-adsal-northbound odl-mdsal-apidocs  odl-ovsdb-openstack odl-ovsdb-northbound odl-dlux-core"
send "\r\r\r"
expect "root>"
send "logout\r"

