#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
mkdir -p "$ROOT"
tar -xzf "${INPUT_ARCHIVE:-/tmp/six_tile_core_tests.tar.gz}" -C "$ROOT"
mkdir -p "$ROOT/if_fifo"
cd "$ROOT/if_fifo"
vcs -full64 -sverilog ../rtl/bds_bb_6ch_core.sv ../tb/tb_if_fifo.sv -top tb_if_fifo -o simv > compile.log 2>&1
python ../scripts/monitor_job.py "$PWD/simulation" 60 "$PWD/simv"
grep '^IF_FIFO_PASS ' simulation/run.log
for test in paced nominal recovery; do
    mkdir -p "$ROOT/six_$test"
    cd "$ROOT/six_$test"
    paced=0;recovery=0
    if [[ "$test" == paced ]]; then paced=1;fi
    if [[ "$test" == recovery ]]; then recovery=1;fi
    vcs -full64 -sverilog +incdir+../rtl -f ../rtl/receiver.f ../tb/tb_six_if.sv \
        -top tb_six_if -pvalue+tb_six_if.PACED="$paced" -pvalue+tb_six_if.RECOVERY="$recovery" \
        -o simv > compile.log 2>&1
    python ../scripts/monitor_job.py "$PWD/simulation" 900 "$PWD/simv"
    grep '^SIX_IF_ITERATIVE_PASS ' simulation/run.log
done
