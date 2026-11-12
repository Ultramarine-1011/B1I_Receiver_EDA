#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT=${ITERATIVE_ROOT:-/home/ICer/six_tile_asic_v2_20261113}
tar -xzf "${INPUT_ARCHIVE:-/tmp/six_tile_integration.tar.gz}" -C "$ROOT"
export RSS_LIMIT_KIB=6291456
for scope in bank core; do
    mkdir -p "$ROOT/$scope${ITERATIVE_ATTEMPT_SUFFIX:-}"
    cd "$ROOT/$scope${ITERATIVE_ATTEMPT_SUFFIX:-}"
    export SCOPE="$scope"
    export REPORT_DIR="$PWD/reports"
    python ../scripts/monitor_job.py "$REPORT_DIR" 600 \
        /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -64bit -f ../scripts/integrate.tcl
    if grep -E '^Error:|^Fatal:' reports/run.log; then exit 1;fi
    grep '^ITERATIVE_INTEGRATION_PASS ' reports/run.log
done
