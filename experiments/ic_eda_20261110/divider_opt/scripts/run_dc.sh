#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
label="$1"
budget="$2"
RUN="$ROOT/runs/${label}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN/work"
export BASELINE_REPORT_DIR="$RUN/reports"
export BASELINE_STAGE="$label"
script=scripts/dc_opt.tcl
if [[ "$label" == *probe ]]; then
    export PROBE_VERSION="${label%_probe}"
    script=scripts/dc_probe.tcl
fi
for directory in sources scripts filelists rtl work; do
    ln -s "$ROOT/$directory" "$RUN/work/$directory"
done
builtin cd "$ROOT"
sha256sum -c input_sha256.txt > "$RUN/input_check.txt"
cp input_sha256.txt "$RUN/input_manifest.sha256"
sha256sum /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db \
    /home/synopsys/syn/O-2018.06-SP1/linux64/syn/bin/common_shell_exec \
    /home/synopsys/syn/O-2018.06-SP1/libraries/syn/dw_foundation.sldb > "$RUN/environment_hashes.txt"
free -m > "$RUN/system_before.txt"
echo "$RUN"
builtin cd "$RUN/work"
exec /usr/bin/python "$ROOT/scripts/monitor_job.py" "$RUN/reports" "$budget" \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f "$script"
