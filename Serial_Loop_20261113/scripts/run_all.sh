#!/bin/bash
set -euo pipefail
export INPUT_ARCHIVE="$(readlink -f "${1:?Pass the staged inputs.tar.gz archive}")"
export ITERATIVE_ROOT="${ITERATIVE_ROOT:-$PWD/iterative_$(date +%Y%m%d_%H%M%S)}"
if test -e "$ITERATIVE_ROOT";then
    echo "Select a fresh ITERATIVE_ROOT to preserve previous run evidence" >&2
    exit 2
fi
mkdir -p "$ITERATIVE_ROOT"
tar -xzf "$INPUT_ARCHIVE" -C "$ITERATIVE_ROOT"
bash "$ITERATIVE_ROOT/scripts/run_guest.sh"
bash "$ITERATIVE_ROOT/scripts/run_regression.sh"
bash "$ITERATIVE_ROOT/scripts/run_core_tests.sh"
export ITERATIVE_CHANNEL_REPORTS="$ITERATIVE_ROOT/channel/reports"
bash "$ITERATIVE_ROOT/scripts/run_mapped_units.sh"
bash "$ITERATIVE_ROOT/scripts/run_integration.sh"
bash "$ITERATIVE_ROOT/scripts/run_teacher.sh"
echo ITERATIVE_FLOW_PASS
