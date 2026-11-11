#!/bin/bash
set -euo pipefail
builtin cd "$(dirname "$0")"
sha256sum mapped_nco.sv tb_mapped_nco.sv /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090_neg.v > sources.sha256
vcs -full64 -sverilog +delay_mode_zero +notimingcheck -top tb_mapped_nco /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090_neg.v mapped_nco.sv tb_mapped_nco.sv -o simv > compile.log 2>&1
./simv > sim.log 2>&1
cat sim.log
grep -q MAPPED_NCO_EQUIVALENCE_PASS sim.log
