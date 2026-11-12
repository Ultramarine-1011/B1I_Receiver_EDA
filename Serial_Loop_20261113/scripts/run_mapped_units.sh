#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
MAP="${ITERATIVE_CHANNEL_REPORTS:-$ROOT/channel_retry1/reports}/mapped.v"
CELLS=/home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090.v
for test in normalize aid; do
    mkdir -p "$ROOT/mapped_$test"
    cd "$ROOT/mapped_$test"
    sed -e 's/20016/1024/g' -e 's/|| dut.running//' \
        -e 's/tracking_normalize_iterative dut/tracking_normalize_iterative_ENABLE_FLL1 dut/' \
        -e 's/"NORMALIZE_ITERATIVE_PASS/"MAPPED_NORMALIZE_ITERATIVE_PASS/' \
        -e 's/"AID_ITERATIVE_PASS/"MAPPED_AID_ITERATIVE_PASS/' \
        "$ROOT/tb/tb_$test.sv" > "tb_$test.sv"
    sha256sum "$MAP" "$CELLS" "$ROOT/rtl/reference_tracking.sv" "tb_$test.sv" > sources.sha256
    vcs -full64 -sverilog +delay_mode_zero "$CELLS" "$MAP" "$ROOT/rtl/reference_tracking.sv" \
        "tb_$test.sv" -top "tb_$test" -o simv > compile.log 2>&1
    python "$ROOT/scripts/monitor_job.py" "$PWD/simulation" 180 "$PWD/simv"
    grep '^MAPPED_.*_ITERATIVE_PASS ' simulation/run.log
done
