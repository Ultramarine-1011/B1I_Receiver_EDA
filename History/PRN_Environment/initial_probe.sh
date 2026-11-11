#!/bin/bash
exec > /tmp/ic_eda_initial_probe.txt 2>&1
printf '=== ID ===\n'; date -Is; id; hostname; pwd
printf '=== SYSTEM ===\n'; cat /etc/os-release; uname -a; lscpu; free -m; swapon --show; lsblk; df -hT
printf '=== NETWORK ===\n'; ip -4 addr; ip route; nmcli device status; systemctl is-active sshd; systemctl status sshd --no-pager; ss -lnt | head -20
printf '=== TOOLS ===\n'; pgrep -a -f 'vmtoolsd|lmgrd|snpslmd'; command -v dc_shell icc_shell icc2_shell pt_shell vcs python python3 ssh sftp-server; ls -ld /opt/* /eda/* /tools/* /home/* 2>/dev/null
printf '=== USER INIT ===\n'; grep -nE 'source|export|Synopsys|synopsys|LICENSE|Foundry|PATH' ~/.bashrc ~/.bash_profile /etc/profile /etc/bashrc 2>/dev/null
printf '=== HOST KEY ===\n'; for key in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf "$key"; cat "$key"; done