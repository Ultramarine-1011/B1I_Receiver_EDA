#!/bin/bash
export LC_ALL=C
source /home/ICer/.bashrc
set -u
export LC_ALL=C
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/reports/environment"
OUT="$ROOT/reports/environment"
{
  date -Is
  id
  hostname
  cat /etc/centos-release
  uname -a
  lscpu
  free -m
  swapon --show
  lsblk -b
  df -hT
  ip -4 addr
  ip route
  nmcli networking
  systemctl is-active sshd
  vmware-toolbox-cmd -v
  printf '\n=== Existing initialization ===\n'
  sha256sum /home/ICer/.bashrc /etc/sysconfig/network-scripts/ifcfg-ens33
  env | sort | grep -E '^(DC_HOME|PT_HOME|VCS_HOME|SNPSLMD_LICENSE_FILE|LM_LICENSE_FILE|PATH|VCS_ARCH_OVERRIDE)='
  printf '\n=== Executables ===\n'
  for tool in dc_shell icc_shell icc2_shell pt_shell vcs; do
    command -v "$tool" || true
  done
  find /home/synopsys /opt -maxdepth 6 \( -name dc_shell -o -name icc_shell -o -name icc2_shell -o -name pt_shell -o -name vcs \) -print
  printf '\n=== Versions ===\n'
  dc_shell -version
  printf 'DC_VERSION_RC=%s\n' "$?"
  pt_shell -version
  printf 'PT_VERSION_RC=%s\n' "$?"
  vcs -full64 -ID
  printf 'VCS_ID_RC=%s\n' "$?"
  printf '\n=== License server processes ===\n'
  ps -eo pid,comm | grep -E 'lmgrd|snpslmd'
  test -r /home/synopsys/scl/2018.06/admin/license/Synopsys.dat
  printf 'LICENSE_FILE_READABLE_RC=%s\n' "$?"
  timeout 20 /home/synopsys/scl/2018.06/linux64/bin/lmutil lmstat -a -c "$SNPSLMD_LICENSE_FILE"
  printf 'LMSTAT_RC=%s\n' "$?"
} > "$OUT/system_tools.txt" 2>&1
find /home/ic_libs -type f \( -name '*.lib' -o -name '*.db' -o -name '*.lef' -o -name '*.tf' -o -iname '*tlu*' -o -iname '*milkyway*' \) -printf '%p\n' | sort > "$OUT/library_files.txt"
find /home/ic_libs -type d \( -iname '*milkyway*' -o -name 'CEL' -o -name 'FRAM' -o -name 'TECH' \) -print > "$OUT/physical_library_dirs.txt"
{
  printf '=== Selected 90 nm Liberty metadata ===\n'
  head -85 /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.lib
  grep -A 35 '^cell (INVX1)' /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.lib | head -36
  for corner in typical slow fast fastz; do
    printf '\n=== %s ===\n' "$corner"
    grep -m 1 '^library' "/home/ic_libs/TSMC.90/aci/sc-x/synopsys/$corner.lib"
    grep -m 3 -E 'nom_process|nom_voltage|nom_temperature' "/home/ic_libs/TSMC.90/aci/sc-x/synopsys/$corner.lib"
  done
  printf '\n=== 130 nm Liberty metadata ===\n'
  head -70 /home/ic_libs/TSMC_013/synopsys/typical.lib
  printf '\n=== Selected library hashes ===\n'
  sha256sum /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.lib
} > "$OUT/library_metadata.txt" 2>&1
printf 'INVENTORY_DONE\n'
