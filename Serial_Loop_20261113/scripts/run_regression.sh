#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
mkdir -p "$ROOT"
tar -xzf "${INPUT_ARCHIVE:-/tmp/six_tile_asic_regression.tar.gz}" -C "$ROOT"
for test in tracking_equivalence tracking_minimal tracking_legacy; do
    mkdir -p "$ROOT/$test"
    cd "$ROOT/$test"
    bench="$test"
    fll=1
    if [[ "$test" == tracking_legacy ]];then bench=tracking_minimal;fll=0;fi
    parameters=()
    if [[ "$bench" == tracking_minimal ]];then parameters=(-pvalue+tb_tracking_minimal.FLL_TEST="$fll");fi
    vcs -full64 -sverilog +incdir+../rtl ../rtl/b1i_prn_gen.sv ../rtl/code_nco.sv \
        ../rtl/carrier_nco_mixer.sv ../rtl/epl_correlator.sv ../rtl/tracking_frontend_spaced.sv \
        ../rtl/tracking_channel_minimal.sv ../rtl/reference_tracking.sv ../tb/tb_${bench}.sv \
        -top tb_${bench} "${parameters[@]}" -o simv > compile.log 2>&1
    python ../scripts/monitor_job.py "$PWD/simulation" 600 "$PWD/simv"
    grep '_PASS' simulation/run.log
done
