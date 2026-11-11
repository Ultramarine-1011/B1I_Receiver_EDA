#!/bin/bash
# Run after sourcing the lab's existing EDA environment. No system changes.
set -euo pipefail
export LC_ALL=C
export LAB_DIR="$(builtin cd "$(dirname "$0")" && pwd)"
export EXPERIMENT_ROOT="$(builtin cd "$LAB_DIR/.." && pwd)"
if [[ -d "$EXPERIMENT_ROOT/../../B1I_Receiver_EDA/student_release" ]]; then
    default_repo="$(builtin cd "$EXPERIMENT_ROOT/../../B1I_Receiver_EDA" && pwd)"
else
    default_repo="$(builtin cd "$EXPERIMENT_ROOT/../.." && pwd)"
fi
export REPO_ROOT="${REPO_ROOT:-$default_repo}"
if [[ -n "${LAB_CONFIG:-}" ]]; then
    set -a
    source "$LAB_CONFIG"
    set +a
fi
source "$LAB_DIR/config.sh"
export LAB_OUT="${LAB_OUT:-$REPO_ROOT/work/tsmc28_lab}"
mkdir -p "$LAB_OUT"/{output,logs,reports,activity,sim}
builtin cd "$LAB_OUT"
stage="${1:?Use preflight, synth-isolated, synth-full, export, gls-max, gls-min, or power}"

check_logs() { "$PYTHON" "$LAB_DIR/check.py" logs "$@"; }
run_dc() {
    export LAB_STAGE="$1"
    export REPORT_DIR="$LAB_OUT/reports/$LAB_STAGE"
    "$PYTHON" "$MONITOR_SCRIPT" "$LAB_OUT/logs/$LAB_STAGE" "$2" \
        "$DC_SHELL" -64bit -f "$LAB_DIR/flow.tcl"
    check_logs "$LAB_OUT/logs/$LAB_STAGE" "$REPORT_DIR"
}
verify_design() {
    sha256sum -c output/design.sha256
    sha256sum -c output/libraries.sha256
    sha256sum -c output/inputs.sha256
    "$PYTHON" "$LAB_DIR/check.py" environment
}

case "$stage" in
preflight)
    command -v "$DC_SHELL" "$VCS" "$VCD2SAIF" "$PYTHON" > logs/tool_paths.txt
    free -m > reports/host_memory.txt
    "$PYTHON" "$LAB_DIR/check.py" config > reports/preflight_config.json
    run_dc preflight 120
    if [[ -z "$STD_MODELS_F" || ! -s "$STD_MODELS_F" ]]; then
        echo 'GLS_BLOCKED missing STD_MODELS_F. Obtain matching standard-cell timing Verilog from the lab.'
    fi
    echo LAB_PREFLIGHT_COMPLETE
    ;;
synth-isolated|synth-full)
    test ! -e output/final.ddc
    export SYNTH_MODE="${stage#synth-}"
    if [[ "$LOCAL_PROBE" == 0 ]]; then
        test -s "$EXPERIMENT_ROOT/work/stage/inputs.sha256"
        (cd "$EXPERIMENT_ROOT/work/stage" && sha256sum -c inputs.sha256) > logs/staged_inputs_check.txt
        if [[ "$SYNTH_MODE" == full ]]; then
            : "${PCPS_IMPL_F:?Supply the verified PCPS/FFT implementation file list, including RAM wrappers and models}"
            test -s "$PCPS_IMPL_F"
        fi
    fi
    "$PYTHON" "$LAB_DIR/check.py" config > output/config.json
    "$PYTHON" "$LAB_DIR/check.py" inputs > output/inputs.sha256
    sha256sum "$STD_TT" "$STD_SS" "$STD_FF" > output/libraries.sha256
    if [[ "$LOCAL_PROBE" == 0 ]]; then sha256sum "$PAD_TT" "$PAD_SS" "$PAD_FF" >> output/libraries.sha256; fi
    if [[ -n "${MEMORY_MAX_DB:-}" ]]; then sha256sum "$MEMORY_MAX_DB" "$MEMORY_MIN_DB" >> output/libraries.sha256; fi
    printf '%s\n' "$SYNTH_MODE" > output/synthesis_mode.txt
    run_dc synth "$SYNTH_BUDGET"
    sha256sum output/final.v output/final.ddc output/final.sdc output/config.json > output/design.sha256
    "$PYTHON" "$LAB_DIR/check.py" synthesis
    ;;
export)
    verify_design
    run_dc export 300
    "$PYTHON" "$LAB_DIR/check.py" sdf
    sha256sum output/final_max.sdf output/final_min.sdf > output/sdf.sha256
    ;;
gls-max|gls-min)
    verify_design
    sha256sum -c output/sdf.sha256
    "$PYTHON" "$LAB_DIR/check.py" timing
    if [[ "$LOCAL_PROBE" == 0 ]]; then
        [[ "$(cat output/synthesis_mode.txt)" == full ]] || { echo 'GLS_BLOCKED PCPS is isolated'; exit 2; }
    fi
    corner="${stage#gls-}"
    run_key="$stage"
    if [[ "$GLS_MODE" != nominal ]]; then run_key="${stage}_$GLS_MODE"; fi
    activity_tag="${corner}_$GLS_MODE"
    corner_define=+define+GLS_MAX
    if [[ "$corner" == min ]]; then corner_define=+define+GLS_MIN; fi
    test ! -e "logs/$run_key"
    mkdir -p "logs/$run_key"
    "$PYTHON" "$LAB_DIR/check.py" models
    tb="$LAB_DIR/tb.sv"
    if [[ "$LOCAL_PROBE" == 1 ]]; then tb="$LAB_DIR/smoke.sv"; fi
    {
        cat sim/models.f
        printf '%s\n' "$LAB_OUT/output/final.v" "$tb"
    } > sim/gls.f
    "$VCS" -full64 -sverilog -debug_pp +neg_tchk +incdir+"$LAB_OUT/sim" "$corner_define" \
        -f sim/gls.f -top tb -o "sim/simv_$activity_tag" -l "logs/$run_key/compile.log"
    check_logs "logs/$run_key/compile.log"
    select=MAXIMUM
    if [[ "$corner" == min ]]; then select=MINIMUM; fi
    # One SDF log per invocation, then preserve it under the matching corner.
    "$PYTHON" "$MONITOR_SCRIPT" "$LAB_OUT/logs/$run_key/run" "$GLS_BUDGET" \
        "$LAB_OUT/sim/simv_$activity_tag" +sdfverbose \
        +IF_DIR="$IF_DIR" +MODE="$GLS_MODE" +CLOCK_NS="$CLOCK_NS" +VCD="activity/raw_$activity_tag.vcd" \
        +INTERVAL="activity/interval_$activity_tag.txt" \
        +DUMP_BEGIN_SAMPLE="$DUMP_BEGIN_SAMPLE" +DUMP_END_SAMPLE="$DUMP_END_SAMPLE"
    cp logs/sdf.log "logs/$run_key/sdf.log"
    check_logs "logs/$run_key"
    grep -Eq 'LAB_GLS_(SMOKE|SIX)_PASS' "logs/$run_key/run/run.log"
    test -s "logs/$run_key/sdf.log"
    "$PYTHON" "$LAB_DIR/check.py" annotation "logs/$run_key"
    echo "LAB_GLS_PASS $select"
    ;;
power)
    verify_design
    run_key=gls-max
    if [[ "$GLS_MODE" != nominal ]]; then run_key="gls-max_$GLS_MODE"; fi
    test -s "logs/$run_key/run/run.log"
    grep -Eq 'LAB_GLS_(SMOKE|SIX)_PASS' "logs/$run_key/run/run.log"
    if [[ "$LOCAL_PROBE" == 1 ]]; then
        cp "activity/raw_max_$GLS_MODE.vcd" activity/run.vcd
    else
        "$PYTHON" "$LAB_DIR/check.py" clip-vcd "activity/raw_max_$GLS_MODE.vcd" activity/run.vcd "activity/interval_max_$GLS_MODE.txt"
    fi
    "$VCD2SAIF" -input activity/run.vcd -output activity/run.saif > logs/vcd2saif.log 2>&1
    check_logs logs/vcd2saif.log
    "$PYTHON" "$LAB_DIR/check.py" saif
    run_dc power 300
    "$PYTHON" "$LAB_DIR/check.py" power
    ;;
*) echo "Unknown stage $stage" >&2; exit 2 ;;
esac
