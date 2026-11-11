#!/bin/bash
# Exercise library/SDF/GLS/SAIF/power scripts on a TSMC90 8-bit shift register.
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
LAB="$(builtin cd "$(dirname "$0")" && pwd)"
ROOT="$(builtin cd "$LAB/.." && pwd)"
export REPO_ROOT="$ROOT"
export MONITOR_SCRIPT="$ROOT/scripts/monitor_job.py"
export LAB_OUT="${LAB_OUT:-$ROOT/work/lab_smoke}"
export LOCAL_PROBE=1 TOP=backend_smoke
export STD_TT=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
export STD_SS=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/slow.db
export STD_FF=/home/ic_libs/TSMC.90/aci/sc-x/synopsys/fast.db
export STD_TT_LIB=typical STD_SS_LIB=slow STD_FF_LIB=fast
export STD_SS_OC=slow STD_FF_OC=fast
export DC_SHELL=/home/synopsys/syn/O-2018.06-SP1/bin/dc_shell
export SYNTH_BUDGET=180 GLS_BUDGET=120
mkdir -p "$LAB_OUT"
printf '%s\n' /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090_neg.v > "$LAB_OUT/models.f"
export STD_MODELS_F="$LAB_OUT/models.f"
for stage in preflight synth-isolated export gls-max gls-min power; do
    echo "LOCAL_TSMC90_STAGE $stage"
    bash "$LAB/run_lab.sh" "$stage"
done
echo LOCAL_TSMC90_LAB_FLOW_PASS
