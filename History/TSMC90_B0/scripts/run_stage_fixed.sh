#!/bin/bash
# Future reruns use a fresh directory and the verified corrected supervisor.
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
export BASELINE_STAGE="$1"
RUN="$ROOT/runs/${1}_fixed_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN/work"
builtin cd "$ROOT"
sha256sum -c frozen_sha256.txt > "$RUN/input_check.txt"
sha256sum -c support_sha256.txt > "$RUN/support_check.txt"
export BASELINE_REPORT_DIR="$RUN/reports"
ln -s "$ROOT/sources" "$RUN/work/sources"
ln -s "$ROOT/scripts" "$RUN/work/scripts"
ln -s "$ROOT/filelists" "$RUN/work/filelists"
builtin cd "$RUN/work"
exec /usr/bin/python "$ROOT/scripts/monitor_job.py" "$RUN/reports" 1200 \
    /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f scripts/dc_baseline.tcl
