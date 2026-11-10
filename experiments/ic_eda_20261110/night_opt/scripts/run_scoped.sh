#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
kind="$1"
label="$2"
budget="$3"
RUN="$ROOT/runs/$label"
mkdir -p "$RUN/work"
export BASELINE_REPORT_DIR="$RUN/reports"
export BASELINE_STAGE=B0
export PROBE_VERSION="$label"
script=scripts/dc_radix.tcl
if [[ "$kind" == channel ]]; then script=scripts/dc_opt.tcl; fi
if [[ "$kind" == channel_hier ]]; then script=scripts/dc_hier.tcl; fi
if [[ "$kind" == preflight ]]; then script=scripts/dc_hier_preflight.tcl; fi
if [[ "$kind" == cached || "$kind" == cached_preflight ]]; then
    export CACHED_ARITH_DIR="$ROOT/runs/full_v6_hier_10ns/reports"
    script=scripts/dc_cached.tcl
    if [[ "$kind" == cached_preflight ]]; then script=scripts/dc_cached_preflight.tcl; fi
    awk '$2 == "rtl/tracking_channel_minimal.sv"' "$ROOT/runs/full_v6_hier_10ns/input_manifest.sha256" > "$RUN/cached_rtl.sha256"
    test -s "$RUN/cached_rtl.sha256"
    (builtin cd "$ROOT" && sha256sum -c "$RUN/cached_rtl.sha256") > "$RUN/cached_rtl_check.txt"
    sha256sum "$CACHED_ARITH_DIR"/*.ddc > "$RUN/cached_arithmetic.sha256"
fi
if [[ "$kind" == conversion ]]; then
    script=work/dc_conversion.tcl
    export PROBE_VERSION="${label%%_*}"
fi
for directory in sources filelists work; do
    ln -s "$ROOT/$directory" "$RUN/work/$directory"
done
cp -R "$ROOT/rtl" "$RUN/work/rtl"
cp -R "$ROOT/scripts" "$RUN/work/scripts"
builtin cd "$ROOT"
sha256sum -c input_sha256.txt > "$RUN/input_check.txt"
cp input_sha256.txt "$RUN/input_manifest.sha256"
tar -czf "$RUN/synthesis_inputs.tar.gz" scripts rtl filelists work/*.sv work/*.tcl work/*.sdc
sha256sum /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db \
    /home/synopsys/syn/O-2018.06-SP1/linux64/syn/bin/common_shell_exec \
    /home/synopsys/syn/O-2018.06-SP1/libraries/syn/dw_foundation.sldb > "$RUN/environment_hashes.txt"
if [[ "$kind" == cached || "$kind" == cached_preflight ]]; then
    cmp "$ROOT/runs/full_v6_hier_10ns/environment_hashes.txt" "$RUN/environment_hashes.txt"
fi
free -m > "$RUN/system_before.txt"
echo "$RUN"
builtin cd "$RUN/work"
exec /usr/bin/python "$ROOT/scripts/monitor_job.py" "$RUN/reports" "$budget" \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f "$script"
