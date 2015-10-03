#!/bin/bash
python /usr/local/bin/failover.py $1
mysql -uroot -e"flush hosts"
service mysql restart
