#!/bin/bash



ok .. so they created br-int

so lets add a physical nic to it


# First - Removal all the bridges you find

for i in $(ovs-vsctl list-br)
do
	if [ "$i" == "br-int" ];
	then	
		echo "skipped br-int"
	elif [ "$i" == "br-prv"];
	then
		echo "skipped br-pr"
	else
		ovs-vsctl del-br $i
	fi
done
