#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT="$(builtin cd "$(dirname "$0")/.." && pwd)"
export BASELINE_STAGE="$1"
export BASELINE_REPORT_DIR="$ROOT/runs/$1/reports"
mkdir -p "$BASELINE_REPORT_DIR"
builtin cd "$ROOT"
sha256sum -c frozen_sha256.txt > "$BASELINE_REPORT_DIR/input_check.txt"
exec /usr/bin/python scripts/monitor_stage.py "$1" 1200
