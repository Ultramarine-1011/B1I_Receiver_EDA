#!/bin/bash
export LC_ALL=C
exec > /tmp/ic_eda_connect_probe.txt 2>&1
nmcli connection up id ens33
printf 'NMCLI_RC=%s\n' "$?"
ip -4 addr show ens33; ip route
nmcli general permissions