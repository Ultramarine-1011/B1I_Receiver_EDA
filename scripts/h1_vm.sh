#!/bin/bash
# H1 VM runner. Usage from the isolated tree:
#   bash scripts/h1_vm.sh vcs
#   bash scripts/h1_vm.sh dc-d1
#   bash scripts/h1_vm.sh dc-nh
#   bash scripts/h1_vm.sh dc-nav
#   bash scripts/h1_vm.sh all
# Does not touch /home/7901_15/B1I_Receiver_EDA.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
STAGE="${1:-all}"

if [ -f "$HOME/eda_env.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/eda_env.sh"
fi

OUT="$ROOT/reports/local/h1_vm"
mkdir -p "$OUT" "$ROOT/reports/local" \
  "$ROOT/work/h1_vcs_nh" "$ROOT/work/h1_vcs_nav" \
  "$ROOT/work/h1_dc_d1" "$ROOT/work/h1_dc_nh" "$ROOT/work/h1_dc_nav"

{
  echo "date: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "host: $(hostname)"
  echo "user: $(id -un)"
  echo "root: $ROOT"
  echo "stage: $STAGE"
  echo "vcs: $(command -v vcs || true)"
  echo "dc_shell: $(command -v dc_shell || true)"
  echo "digital_lib: ${EDA_DIGITAL_LIB:-/home/IC/Foundry_Library/Digital}"
  echo "license_file_readable: $(test -r "${SNPSLMD_LICENSE_FILE:-/opt/Synopsys/License/License.dat}" && echo yes || echo no)"
  echo "saed_db_readable: $(test -r /home/IC/Foundry_Library/Digital/saed90nm_typ.db && echo yes || echo no)"
} > "$OUT/environment.txt"

sha256sum \
  student_release/student_release/rtl/nh20_sync.sv \
  student_release/student_release/rtl/d1_word_sync.sv \
  student_release/student_release/rtl/navigation_d1.sv \
  tb/tb_nh_d1.sv \
  tb/tb_navigation_d1.sv \
  tb/vectors/nh_d1/nav_bits.mem \
  tb/vectors/nh_d1/expected_words.mem \
  work/navigation/bits.mem \
  work/navigation/raw.mem \
  work/navigation/info.mem \
  scripts/h1_vm.sh \
  scripts/h1_dc_common.tcl \
  scripts/h1_dc_d1_word_sync.tcl \
  scripts/h1_dc_nh20_sync.tcl \
  scripts/h1_dc_navigation_d1.tcl \
  > "$OUT/source_sha256.txt"

vcs_nh() {
  rm -rf "$ROOT/work/h1_vcs_nh/csrc" "$ROOT/work/h1_vcs_nh/simv" \
    "$ROOT/work/h1_vcs_nh/simv.daidir" "$ROOT/work/h1_vcs_nh/DVEfiles"
  (
    cd "$ROOT/work/h1_vcs_nh" || exit 1
    vcs -sverilog -R \
      ../../student_release/student_release/rtl/nh20_sync.sv \
      ../../student_release/student_release/rtl/d1_word_sync.sv \
      ../../tb/tb_nh_d1.sv
  ) > "$OUT/vcs_nh_d1.log" 2>&1
  local code=$?
  echo "$code" > "$OUT/vcs_nh_d1_exit_code.txt"
  local cases
  cases=$(grep -c 'NH_D1_CASE_PASS' "$OUT/vcs_nh_d1.log" || true)
  if [ "$code" -eq 0 ] && grep -q 'NH_D1_MODULE_PASS cases=3 words=9 phases=0,7,19 polarity=normal,inverted' "$OUT/vcs_nh_d1.log" && [ "$cases" -eq 3 ]; then
    echo "VCS_PASS" > "$OUT/vcs_nh_d1_result.txt"
  else
    echo "VCS_FAIL" > "$OUT/vcs_nh_d1_result.txt"
  fi
  if [ -f "$ROOT/reports/local/nh_d1_words.csv" ]; then
    cp -f "$ROOT/reports/local/nh_d1_words.csv" "$OUT/nh_d1_words.csv"
  fi
}

vcs_nav() {
  cp -f "$ROOT/work/navigation/bits.mem" "$ROOT/work/navigation/raw.mem" "$ROOT/work/navigation/info.mem" "$ROOT/work/h1_vcs_nav/"
  rm -rf "$ROOT/work/h1_vcs_nav/csrc" "$ROOT/work/h1_vcs_nav/simv" \
    "$ROOT/work/h1_vcs_nav/simv.daidir" "$ROOT/work/h1_vcs_nav/DVEfiles"
  (
    cd "$ROOT/work/h1_vcs_nav" || exit 1
    vcs -sverilog -R \
      ../../student_release/student_release/rtl/nh20_sync.sv \
      ../../student_release/student_release/rtl/d1_word_sync.sv \
      ../../student_release/student_release/rtl/navigation_d1.sv \
      ../../tb/tb_navigation_d1.sv
  ) > "$OUT/vcs_navigation_d1.log" 2>&1
  local code=$?
  echo "$code" > "$OUT/vcs_navigation_d1_exit_code.txt"
  local cases
  cases=$(grep -c 'NAVIGATION_D1_CASE_PASS' "$OUT/vcs_navigation_d1.log" || true)
  if [ "$code" -eq 0 ] \
    && grep -q 'NAVIGATION_D1_PASS cases=2 two_frame_confirmation=1 backpressure=1 lost_reset=1' "$OUT/vcs_navigation_d1.log" \
    && [ "$cases" -eq 2 ]; then
    echo "VCS_PASS" > "$OUT/vcs_navigation_d1_result.txt"
  else
    echo "VCS_FAIL" > "$OUT/vcs_navigation_d1_result.txt"
  fi
}

dc_one() {
  local name="$1"
  local workdir="$2"
  local script="$3"
  local log="$OUT/dc_${name}.log"
  rm -rf "$workdir/command.log" "$workdir/default.svf" "$workdir/filenames.log" "$workdir/WORK" \
    "$workdir/alib-52" "$workdir/WORKLIB"
  (
    cd "$workdir" || exit 1
    dc_shell -f "../../scripts/$script"
  ) > "$log" 2>&1
  local code=$?
  echo "$code" > "$OUT/dc_${name}_exit_code.txt"
  local latch unmapped bbox errors
  latch=$(grep -m1 '^H1_LATCH_COUNT ' "$log" | awk '{print $2}' || true)
  unmapped=$(grep -m1 '^H1_UNMAPPED_COUNT ' "$log" | awk '{print $2}' || true)
  bbox=$(grep -m1 '^H1_BLACKBOX_COUNT ' "$log" | awk '{print $2}' || true)
  errors=$(grep -E -c '^(Error|ERROR):' "$log" || true)
  if [ "$code" -eq 0 ] \
    && grep -q 'H1_DC_ANALYZE_OK' "$log" \
    && grep -q 'H1_DC_ELABORATE_OK' "$log" \
    && grep -q 'H1_DC_LINK_OK' "$log" \
    && grep -q 'H1_DC_COMPILE_DONE' "$log" \
    && [ -s "$OUT/${name}_area.rpt" ] \
    && [ -s "$OUT/${name}_timing.rpt" ] \
    && [ -s "$OUT/${name}_saed90nm.v" ] \
    && [ -s "$OUT/${name}_saed90nm.sdc" ] \
    && [ "${latch:-x}" = "0" ] \
    && [ "${unmapped:-x}" = "0" ] \
    && [ "${bbox:-x}" = "0" ] \
    && [ "$errors" -eq 0 ]; then
    echo "DC_PASS" > "$OUT/dc_${name}_result.txt"
  elif [ "$code" -eq 0 ] && grep -q 'H1_DC_COMPILE_DONE' "$log"; then
    echo "DC_COMPILE_WITH_ISSUES" > "$OUT/dc_${name}_result.txt"
  else
    echo "DC_FAIL" > "$OUT/dc_${name}_result.txt"
  fi
}

mapped_ok() {
  local name="$1"
  local result
  result=$(cat "$OUT/dc_${name}_result.txt" 2>/dev/null || echo MISSING)
  [ "$result" = "DC_PASS" ] || [ "$result" = "DC_COMPILE_WITH_ISSUES" ]
}

case "$STAGE" in
  vcs)
    vcs_nh
    vcs_nav
    ;;
  dc-d1)
    dc_one d1_word_sync "$ROOT/work/h1_dc_d1" h1_dc_d1_word_sync.tcl
    ;;
  dc-nh)
    dc_one nh20_sync "$ROOT/work/h1_dc_nh" h1_dc_nh20_sync.tcl
    ;;
  dc-nav)
    if mapped_ok d1_word_sync && mapped_ok nh20_sync; then
      dc_one navigation_d1 "$ROOT/work/h1_dc_nav" h1_dc_navigation_d1.tcl
    else
      echo "DC_SKIPPED_PREVIOUS" > "$OUT/dc_navigation_d1_result.txt"
      echo "navigation_d1 skipped because d1_word_sync or nh20_sync did not map" > "$OUT/dc_navigation_d1.log"
    fi
    ;;
  all)
    vcs_nh
    vcs_nav
    if [ "$(cat "$OUT/vcs_nh_d1_result.txt")" = "VCS_PASS" ] && [ "$(cat "$OUT/vcs_navigation_d1_result.txt")" = "VCS_PASS" ]; then
      dc_one d1_word_sync "$ROOT/work/h1_dc_d1" h1_dc_d1_word_sync.tcl
      dc_one nh20_sync "$ROOT/work/h1_dc_nh" h1_dc_nh20_sync.tcl
      if mapped_ok d1_word_sync && mapped_ok nh20_sync; then
        dc_one navigation_d1 "$ROOT/work/h1_dc_nav" h1_dc_navigation_d1.tcl
      else
        echo "DC_SKIPPED_PREVIOUS" > "$OUT/dc_navigation_d1_result.txt"
      fi
    else
      echo "DC_SKIPPED_VCS" > "$OUT/dc_skipped.txt"
    fi
    ;;
  *)
    echo "unknown stage: $STAGE" >&2
    exit 2
    ;;
esac

{
  echo "stage=$STAGE"
  echo "vcs_nh=$(cat "$OUT/vcs_nh_d1_result.txt" 2>/dev/null || echo NOT_RUN)"
  echo "vcs_nh_exit=$(cat "$OUT/vcs_nh_d1_exit_code.txt" 2>/dev/null || echo NA)"
  echo "vcs_nav=$(cat "$OUT/vcs_navigation_d1_result.txt" 2>/dev/null || echo NOT_RUN)"
  echo "vcs_nav_exit=$(cat "$OUT/vcs_navigation_d1_exit_code.txt" 2>/dev/null || echo NA)"
  echo "dc_d1=$(cat "$OUT/dc_d1_word_sync_result.txt" 2>/dev/null || echo NOT_RUN)"
  echo "dc_d1_exit=$(cat "$OUT/dc_d1_word_sync_exit_code.txt" 2>/dev/null || echo NA)"
  echo "dc_nh=$(cat "$OUT/dc_nh20_sync_result.txt" 2>/dev/null || echo NOT_RUN)"
  echo "dc_nh_exit=$(cat "$OUT/dc_nh20_sync_exit_code.txt" 2>/dev/null || echo NA)"
  echo "dc_nav=$(cat "$OUT/dc_navigation_d1_result.txt" 2>/dev/null || echo NOT_RUN)"
  echo "dc_nav_exit=$(cat "$OUT/dc_navigation_d1_exit_code.txt" 2>/dev/null || echo NA)"
} | tee "$OUT/summary.txt"
