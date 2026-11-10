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
free -m > "$RUN/system_before.txt"
echo "$RUN"
builtin cd "$RUN/work"
exec /usr/bin/python "$ROOT/scripts/monitor_job.py" "$RUN/reports" "$budget" \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f "$script"
