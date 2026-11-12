#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
tar -xzf "${INPUT_ARCHIVE:-/tmp/six_tile_teacher_probe.tar.gz}" -C "$ROOT"
mkdir -p "$ROOT/teacher_capture"
cd "$ROOT/teacher_capture"
export REPORT_DIR="$PWD/reports" RSS_LIMIT_KIB=1048576
python ../scripts/monitor_job.py "$REPORT_DIR" 300 \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f ../scripts/teacher_probe.tcl
if grep -E '^Error:|^Fatal:' reports/run.log;then exit 1;fi
grep '^TEACHER_CAPTURE_PROBE_PASS ' reports/run.log
