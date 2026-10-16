#!/bin/bash
# Repeatable H0 smoke: VCS PRN self-check and SAED90nm DC synthesis.
# Run on the Linux EDA VM from any cwd:
#   bash scripts/h0_vm_smoke.sh
# Vector paths inside tb/tb_b1i_prn_gen.sv are relative to work/<one-level>,
# so VCS is launched from work/h0_prn.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

if [ -f "$HOME/eda_env.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/eda_env.sh"
elif [ -f "$ROOT/scripts/eda_env.sh" ]; then
  # shellcheck disable=SC1091
  . "$ROOT/scripts/eda_env.sh"
fi

OUT="$ROOT/reports/local/h0_vm"
mkdir -p "$OUT" "$ROOT/work/h0_prn" "$ROOT/work/h0_dc"

{
  echo "date: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "host: $(hostname)"
  echo "user: $(id -un)"
  echo "root: $ROOT"
  echo "vcs: $(command -v vcs)"
  echo "dc_shell: $(command -v dc_shell)"
  echo "digital_lib: ${EDA_DIGITAL_LIB:-/home/IC/Foundry_Library/Digital}"
  echo "license_file_readable: $(test -r "${SNPSLMD_LICENSE_FILE:-/opt/Synopsys/License/License.dat}" && echo yes || echo no)"
} > "$OUT/environment.txt"

sha256sum \
  rtl/b1i_prn_gen.sv \
  tb/tb_b1i_prn_gen.sv \
  tb/vectors/b1i_prn_06.mem \
  tb/vectors/b1i_prn_12.mem \
  tb/vectors/b1i_prn_23.mem \
  tb/vectors/b1i_prn_37.mem \
  tb/vectors/b1i_prn_06_37.mem \
  > "$OUT/source_sha256.txt"

echo "vcs -sverilog -R ../../rtl/b1i_prn_gen.sv ../../tb/tb_b1i_prn_gen.sv" > "$OUT/commands.txt"
echo "dc_shell -f ../../scripts/h0_dc_prn.tcl" >> "$OUT/commands.txt"

rm -rf "$ROOT/work/h0_prn/csrc" "$ROOT/work/h0_prn/simv" "$ROOT/work/h0_prn/simv.daidir" "$ROOT/work/h0_prn/DVEfiles"
(
  cd "$ROOT/work/h0_prn" || exit 1
  vcs -sverilog -R ../../rtl/b1i_prn_gen.sv ../../tb/tb_b1i_prn_gen.sv
) > "$OUT/vcs_prn.log" 2>&1
VCS_EC=$?
echo "$VCS_EC" > "$OUT/vcs_exit_code.txt"

if [ "$VCS_EC" -eq 0 ] && grep -q "B1I_PRN_REGRESSION_PASS" "$OUT/vcs_prn.log"; then
  echo "VCS_PASS" > "$OUT/vcs_result.txt"
else
  echo "VCS_FAIL" > "$OUT/vcs_result.txt"
fi

rm -rf "$ROOT/work/h0_dc/command.log" "$ROOT/work/h0_dc/default.svf" "$ROOT/work/h0_dc/filenames.log" "$ROOT/work/h0_dc/WORK"
(
  cd "$ROOT/work/h0_dc" || exit 1
  dc_shell -f ../../scripts/h0_dc_prn.tcl
) > "$OUT/dc_prn.log" 2>&1
DC_EC=$?
echo "$DC_EC" > "$OUT/dc_exit_code.txt"

if [ "$DC_EC" -eq 0 ] && grep -q "H0_DC_COMPILE_DONE" "$OUT/dc_prn.log" \
  && [ -s "$OUT/dc_area.rpt" ] && [ -s "$OUT/dc_timing.rpt" ] && [ -s "$OUT/b1i_prn_gen_saed90nm.v" ]; then
  echo "DC_PASS" > "$OUT/dc_result.txt"
else
  echo "DC_FAIL" > "$OUT/dc_result.txt"
fi

{
  echo "vcs_exit=$VCS_EC"
  echo "vcs_result=$(cat "$OUT/vcs_result.txt")"
  echo "dc_exit=$DC_EC"
  echo "dc_result=$(cat "$OUT/dc_result.txt")"
  echo "vcs_banner=$(grep -m1 'Version I-' "$OUT/vcs_prn.log" || true)"
  echo "dc_banner=$(grep -m1 'Version K-' "$OUT/dc_prn.log" || true)"
} | tee "$OUT/summary.txt"

if [ "$(cat "$OUT/vcs_result.txt")" = "VCS_PASS" ] && [ "$(cat "$OUT/dc_result.txt")" = "DC_PASS" ]; then
  exit 0
fi
exit 1
