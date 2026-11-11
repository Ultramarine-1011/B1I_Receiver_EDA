#!/bin/bash
exec > /tmp/backend_probe.txt 2>&1
hostname
id
free -m
df -h /home
ip -4 addr show ens33
ps -eo pid,comm,rss,args | awk '$2 ~ /dc_shell|common_shell|simv|vcs/ {print $1,$2,$3}'
test -d /home/ICer/ic_eda_night_20261110 && echo NIGHT_ROOT_EXISTS
ls -l /home/ICer/ic_eda_night_20261110/runs/full_v6_hier_10ns/reports/*.ddc
ls /home/ic_libs/TSMC.90/aci/sc-x
echo GUEST_PROBE_DONE
