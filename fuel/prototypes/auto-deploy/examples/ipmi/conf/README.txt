Add this snippet into /etc/network/interfaces after making sure to
replace p1p1.20 with your actual outbound interface in order to
provide network access to the Fuel master for DNS and NTP.

iface vfuelnet inet static
	bridge_ports em1
	address 10.30.0.1
	netmask 255.255.255.0
	pre-down iptables -t nat -D POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
	pre-down iptables -D FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"
	post-up iptables -t nat -A POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
	post-up iptables -A FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"
