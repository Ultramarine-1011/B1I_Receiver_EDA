#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
export PYTHON=/usr/bin/python
ROOT=/home/ICer/ic_eda_backend_20261111
PORT="$ROOT/work/portable_handoff"
test ! -e "$PORT"
mkdir -p "$PORT"
tar -xzf /tmp/backend_lab_bundle.tar.gz -C "$PORT"
export FLOW="$PORT/experiments/ic_eda_20261111_backend/lab/run_lab.sh"
EXPERIMENT="$PORT/experiments/ic_eda_20261111_backend"
(builtin cd "$EXPERIMENT/work/stage" && sha256sum -c inputs.sha256) > "$ROOT/portable_stage_check.txt"
for path in "$EXPERIMENT"/lab/*.sh "$EXPERIMENT"/work/stage/scripts/*.sh; do bash -n "$path"; done
echo PORTABLE_BASH_AND_INPUTS_PASS
export DC_SHELL=/home/synopsys/syn/O-2018.06-SP1/bin/dc_shell
export LAB_OUT="$PORT/work/missing_tsmc28"
set +e
bash "$FLOW" preflight > "$ROOT/portable_missing_libraries.log" 2>&1
missing_rc=$?
set -e
test "$missing_rc" != 0
echo "MISSING_LIBRARY_REJECTION_PASS rc=$missing_rc"
export LAB_OUT="$PORT/work/validated_tsmc90"
export LOCAL_PROBE=1 TOP=backend_smoke
export STD_TT=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
export STD_SS=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/slow.db
export STD_FF=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/fast.db
export STD_TT_LIB=typical STD_SS_LIB=slow STD_FF_LIB=fast
export STD_SS_OC=slow STD_FF_OC=fast
export SYNTH_BUDGET=180 GLS_BUDGET=120
export STD_MODELS_F="$PORT/std_models.f"
printf '%s\n' /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090_neg.v > "$STD_MODELS_F"
for stage in preflight synth-isolated export gls-max gls-min power; do
    echo "PORTABLE_STAGE $stage"
    bash "$FLOW" "$stage"
done
(
 export CLOCK_NS=20 LAB_OUT="$PORT/work/validated_20ns"
 for stage in preflight synth-isolated export gls-max gls-min power; do
  bash "$FLOW" "$stage"
 done
) > "$ROOT/portable_handoff_clock20.log" 2>&1
echo CLOCK_PARAMETER_20NS_PIPELINE_PASS
builtin cd "$LAB_OUT"
mkdir -p sim_analysis
printf 'WORK > DEFAULT\nDEFAULT : ./sim_analysis\n' > synopsys_sim.setup
vlogan -full64 -sverilog +incdir+"$LAB_OUT/sim" "$EXPERIMENT/lab/tb.sv" -l logs/six_tb_analysis.log
"$PYTHON" "$EXPERIMENT/lab/check.py" logs logs/six_tb_analysis.log
echo PORTABLE_PIPELINE_AND_SIX_TB_ANALYSIS_PASS
