#!/usr/bin/expect
spawn /opt/odl/distribution-karaf-0.2.3-Helium-SR3/bin/client
expect "root>"
send "feature:list | grep -i odl-restconf\r"
send "\r\r\r"
expect "root>"
send "logout\r"

