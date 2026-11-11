#!/bin/bash
export LC_ALL=C
exec > /tmp/ic_eda_network_up.txt 2>&1
printf 'Existing DHCP profile was not changed. Temporary interface activation.\n'
ip link set dev ens33 up
printf 'LINK_RC=%s\n' "$?"
timeout 40 /sbin/dhclient -1 -v ens33
printf 'DHCLIENT_RC=%s\n' "$?"
ip -4 addr show ens33; ip route; cat /etc/resolv.conf