#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
mkdir -p "$ROOT"
tar -xzf "${INPUT_ARCHIVE:-/tmp/six_tile_asic_inputs.tar.gz}" -C "$ROOT"
cd "$ROOT"
for test in normalize aid; do
    mkdir -p "$ROOT/unit_$test"
    cd "$ROOT/unit_$test"
    vcs -full64 -sverilog ../rtl/tracking_channel_minimal.sv ../rtl/reference_tracking.sv \
        ../tb/tb_${test}.sv -top tb_${test} -o simv > compile.log 2>&1
    python ../scripts/monitor_job.py "$PWD/simulation" 180 "$PWD/simv"
    grep '_ITERATIVE_PASS' simulation/run.log
done
cd "$ROOT"
mkdir -p channel
cd channel
export REPORT_DIR="$PWD/reports"
export RSS_LIMIT_KIB=6291456
python ../scripts/monitor_job.py "$REPORT_DIR" 1200 \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f ../scripts/synth.tcl
if grep -E '^Error:|^Fatal:' reports/run.log; then exit 1;fi
grep '^ITERATIVE_TRACKING_DC_PASS$' reports/run.log
