#!/bin/bash
export LC_ALL=C
ROOT=/home/ICer/ic_eda_smoke_20261110
{
  date -Is
  id
  hostname
  ip -4 addr show ens33
  ip route
  systemctl is-active sshd
  nmcli networking
  free -m
  ps -C dhclient -o pid,args
  printf '\n=== Remaining experiment processes ===\n'
  ps -eo pid,comm | grep -E 'dc_shell|vcs1|simv' || true
  printf '\n=== Configuration hashes ===\n'
  sha256sum /home/ICer/.bashrc /etc/sysconfig/network-scripts/ifcfg-ens33
  printf '\n=== Source and script hashes ===\n'
  sha256sum "$ROOT"/rtl/*.sv "$ROOT"/tb/*.sv "$ROOT"/tb/vectors/*.mem "$ROOT"/scripts/*
  printf '\n=== Library and physical cell size ===\n'
  sha256sum /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.lib
  grep -A 10 '^MACRO INVX1' /home/ic_libs/TSMC.90/aci/sc-x/lef/tsmc090nvt_macros.lef
  printf '\n=== 90 nm library directory ===\n'
  ls -l /home/ic_libs/TSMC.90/aci/sc-x/lef
} > "$ROOT/reports/environment/final_probe.txt" 2>&1
printf 'FINAL_PROBE_DONE\n'
