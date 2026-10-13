SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

.PHONY: smoke vcs-smoke dc-smoke prn-regression code-nco-epl-regression carrier-regression frontend-regression clean-smoke

smoke: vcs-smoke dc-smoke

vcs-smoke:
	mkdir -p reports work/vcs
	cd work/vcs && vcs -R ../../rtl/counter.v ../../tb/testbench.v 2>&1 | tee ../../reports/vcs_smoke.log
	test -x work/vcs/simv
	test -s work/vcs/counter.vcd

dc-smoke:
	mkdir -p reports work/dc
	cd work/dc && dc_shell -f ../../scripts/dc_smoke.tcl 2>&1 | tee ../../reports/dc_smoke.log
	test -s reports/counter_after_dc.v
	test -s reports/dc_area.rpt
	test -s reports/dc_timing.rpt

prn-regression:
	mkdir -p reports work/prn
	cd work/prn && vcs -sverilog -R ../../rtl/b1i_prn_gen.sv ../../tb/tb_b1i_prn_gen.sv 2>&1 | tee ../../reports/b1i_prn_vcs.log
	grep -q "B1I_PRN_REGRESSION_PASS" reports/b1i_prn_vcs.log

code-nco-epl-regression:
	mkdir -p reports work/code_nco_epl
	cd work/code_nco_epl && vcs -sverilog -R ../../rtl/b1i_prn_gen.sv ../../rtl/code_nco.sv ../../rtl/epl_correlator.sv ../../tb/tb_code_nco_epl.sv 2>&1 | tee ../../reports/code_nco_epl_vcs.log
	grep -q "CODE_NCO_EPL_REGRESSION_PASS" reports/code_nco_epl_vcs.log

carrier-regression:
	mkdir -p reports work/carrier
	cd work/carrier && vcs -sverilog +incdir+../../rtl -R ../../rtl/carrier_nco_mixer.sv ../../tb/tb_carrier_nco_mixer.sv 2>&1 | tee ../../reports/carrier_vcs.log
	grep -q "CARRIER_REGRESSION_PASS" reports/carrier_vcs.log

frontend-regression:
	mkdir -p reports work/frontend
	cd work/frontend && vcs -sverilog +incdir+../../rtl -R ../../rtl/b1i_prn_gen.sv ../../rtl/code_nco.sv ../../rtl/carrier_nco_mixer.sv ../../rtl/epl_correlator.sv ../../rtl/tracking_frontend.sv ../../tb/tb_tracking_frontend.sv 2>&1 | tee ../../reports/frontend_vcs.log
	grep -q "FRONTEND_REGRESSION_PASS" reports/frontend_vcs.log

clean-smoke:
	rm -rf work/vcs work/dc work/prn work/code_nco_epl reports/vcs_smoke.log reports/dc_smoke.log reports/dc_area.rpt reports/dc_timing.rpt reports/counter_after_dc.v reports/counter_after_dc.sdc reports/b1i_prn_vcs.log reports/code_nco_epl_vcs.log
