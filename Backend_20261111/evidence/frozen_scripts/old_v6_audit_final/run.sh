#!/bin/bash
# Run in a new per-job work directory. Source the installed tool environment first.
set -euo pipefail
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
kind="$1"
label="$2"
budget="$3"
[[ "$label" =~ ^[a-zA-Z0-9_]+$ ]]
export STD_DB="${STD_DB:-/home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db}"
export STD_LIB="${STD_LIB:-typical}"
export OPCOND="${OPCOND:-typical}"
export DRIVE_CELL="${DRIVE_CELL:-INVX1}"
export DRIVE_PIN="${DRIVE_PIN:-A}"
export EXTRA_LINK_DB="${EXTRA_LINK_DB:-}"
export ARITH_PROFILE="${ARITH_PROFILE:-baseline}"
export DC_BIN="${DC_BIN:-/home/synopsys/syn/O-2018.06-SP1/bin/dc_shell}"
export RUN="$ROOT/runs/$label"
test ! -e "$RUN"
mkdir -p "$RUN/work"
export REPORT_DIR="$RUN/reports"
cd "$ROOT"
sha256sum -c inputs.sha256 > "$RUN/input_check.txt"
cp inputs.sha256 "$RUN/input_manifest.sha256"
# A technology-specific cache is valid only for this complete identity.
{
    sha256sum rtl/tracking_channel_minimal.sv scripts/partitions.tcl scripts/library.tcl
    sha256sum "$STD_DB" "$(readlink -f "$DC_BIN")" /home/synopsys/syn/O-2018.06-SP1/linux64/syn/bin/common_shell_exec
    sha256sum /home/synopsys/syn/O-2018.06-SP1/libraries/syn/dw_foundation.sldb
    printf '%s\n' "$STD_LIB" "$OPCOND" "$DRIVE_CELL" "$DRIVE_PIN" "$EXTRA_LINK_DB"
    if [[ "$ARITH_PROFILE" == baseline ]]; then
        echo 'module_clock=10 uncertainty=0.2 io=0 load=4x effort=medium'
    elif [[ "$ARITH_PROFILE" == fast ]]; then
        printf 'phase_step_aid_clock=4 other_clock=10 script='
        sha256sum scripts/fastparts.tcl | awk '{print $1}'
    else
        echo 'Unknown arithmetic profile' >&2
        exit 1
    fi
} > "$RUN/cache_identity.txt"
for directory in rtl sources filelists scripts probes; do
    cp -R "$ROOT/$directory" "$RUN/work/$directory"
done
if [[ "$kind" == channel || "$kind" == core ]]; then
    : "${CACHE_RUN:?Set CACHE_RUN to a completed fresh partition run}"
    cmp "$CACHE_RUN/cache_identity.txt" "$RUN/cache_identity.txt"
    (cd "$CACHE_RUN/reports" && sha256sum -c partitions.sha256) > "$RUN/cache_check.txt"
    export CACHE_DIR="$CACHE_RUN/reports"
fi
if [[ "$kind" == fastparts ]]; then
    : "${CACHE_RUN:?Set CACHE_RUN to the fresh baseline partition run}"
    [[ "$ARITH_PROFILE" == fast ]]
    # All lines except the last identify RTL, libraries, tool, DW and IO conditions.
    diff <(sed '$d' "$CACHE_RUN/cache_identity.txt") <(sed '$d' "$RUN/cache_identity.txt")
    (cd "$CACHE_RUN/reports" && sha256sum -c partitions.sha256) > "$RUN/cache_check.txt"
    export BASE_CACHE_DIR="$CACHE_RUN/reports"
fi
cd "$RUN/work"
/usr/bin/python "$ROOT/scripts/monitor_job.py" "$REPORT_DIR" "$budget" "$DC_BIN" -64bit -f "scripts/$kind.tcl"
if grep -E '^Error:|^Fatal:' "$REPORT_DIR/run.log"; then exit 1; fi
if [[ "$kind" == partitions || "$kind" == fastparts ]]; then
    grep -q '^BACKEND_PARTITIONS_PASS$' "$REPORT_DIR/run.log"
    (cd "$REPORT_DIR" && sha256sum tracking_*.ddc > partitions.sha256)
fi
