#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/work/vcs_arithmetic"
builtin cd "$ROOT/work/vcs_arithmetic"
set +e
/usr/bin/time -v -o compile_time.txt vcs -full64 -sverilog -top tb_divider_equivalence \
    "$ROOT/tb/tb_divider_equivalence.sv" "$ROOT/work/norm_probes.sv" -o simv > compile.log 2>&1
compile_code=$?
echo "$compile_code" > compile_exit.txt
if [[ "$compile_code" != 0 ]]; then tail -n 30 compile.log; exit "$compile_code"; fi
/usr/bin/time -v -o run_time.txt ./simv +PROMPT_REPLAY="$ROOT/work/public_prompt.txt" > run.log 2>&1
run_code=$?
echo "$run_code" > run_exit.txt
cat run.log
if [[ "$run_code" != 0 ]]; then exit "$run_code"; fi
/usr/bin/time -v -o loop_compile_time.txt vcs -full64 -sverilog -top tb_loop_equivalence \
    "$ROOT/tb/tb_loop_equivalence.sv" "$ROOT/work/loop_probes.sv" -o simv_loop > loop_compile.log 2>&1
compile_code=$?
echo "$compile_code" > loop_compile_exit.txt
if [[ "$compile_code" != 0 ]]; then tail -n 30 loop_compile.log; exit "$compile_code"; fi
/usr/bin/time -v -o loop_run_time.txt ./simv_loop > loop_run.log 2>&1
run_code=$?
echo "$run_code" > loop_run_exit.txt
cat loop_run.log
if [[ "$run_code" != 0 ]]; then exit "$run_code"; fi
/usr/bin/time -v -o constant_compile_time.txt vcs -full64 -sverilog -top tb_constant_division_equivalence \
    "$ROOT/tb/tb_constant_division_equivalence.sv" "$ROOT/work/constant_division_probe.sv" -o simv_constant > constant_compile.log 2>&1
compile_code=$?
echo "$compile_code" > constant_compile_exit.txt
if [[ "$compile_code" != 0 ]]; then tail -n 30 constant_compile.log; exit "$compile_code"; fi
/usr/bin/time -v -o constant_run_time.txt ./simv_constant > constant_run.log 2>&1
run_code=$?
echo "$run_code" > constant_run_exit.txt
cat constant_run.log
exit "$run_code"
