#!/bin/bash
# Functional mapping check, without SDF. The formal GLS flow keeps timing enabled.
set -euo pipefail
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAP="$ROOT/runs/fast_v6_parts/reports"
cd "$ROOT/work/mapped_gates"
sha256sum "$MAP"/tracking_{ratio_phase,divide_step,divide_aid}.v \
    /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090.v "$ROOT/probes/tb_mapped_arithmetic.sv" > sources.sha256
vcs -full64 -sverilog +delay_mode_zero -top tb_mapped_arithmetic \
    /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090.v \
    "$MAP"/tracking_{ratio_phase,divide_step,divide_aid}.v "$ROOT/probes/tb_mapped_arithmetic.sv" \
    -o simv > compile.log 2>&1
./simv > sim.log 2>&1
cat sim.log
grep -q MAPPED_ARITHMETIC_EQUIVALENCE_PASS sim.log
