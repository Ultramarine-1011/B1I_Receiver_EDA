#!/bin/bash
exec > /tmp/ic_eda_network_probe.txt 2>&1
export LC_ALL=C
id; ip link show ens33; nmcli con show; systemctl is-active NetworkManager network; cat /etc/sysconfig/network-scripts/ifcfg-ens33; cat /etc/sysconfig/network; ls -l /usr/sbin/dhclient /usr/sbin/ifup; sudo -n -l
printf '\n=== INIT AND TOOLS ===\n'
sed -n '1,125p' /home/ICer/.bashrc
find /home/synopsys -maxdepth 4 -type f \( -name dc_shell -o -name icc_shell -o -name icc2_shell -o -name pt_shell -o -name vcs \) -print
find /home/ic_libs -maxdepth 5 -type f \( -name '*.db' -o -name '*.lib' -o -name '*.lef' -o -name '*.tf' -o -name '*.tluplus' -o -name '*.tlu+' \) -printf '%p\n' | head -100
ls -ld ~/.ssh; command -v vmware-toolbox-cmd; vmware-toolbox-cmd -v