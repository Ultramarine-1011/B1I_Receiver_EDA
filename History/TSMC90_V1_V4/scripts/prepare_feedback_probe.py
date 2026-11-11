"""Probe the unchanged V4 combinational feedback controller at 10 and 30 ns."""
from pathlib import Path
import re

experiment = Path(__file__).resolve().parent.parent
source = (experiment / "work/loop_probes.sv").read_text(encoding="utf-8")
header = re.search(r"module loop_optimized #\(parameter integer ENABLE_FLL=1\)\(([\s\S]*?)\);", source)[1].strip()
header = re.sub(r",\noutput logic \[[^]]+\] observed_values$", "", header)
wrapper = f"""module feedback_controller_probe(
input logic clk,reset_n,
{header},
output logic [32:0] code_step,
output logic [31:0] carrier_step
);
    logic [1151:0] observed_values;
    logic signed [63:0] code_delta_word,carrier_delta_word,feedback_aid_word;
    logic [32:0] code_next;
    logic [31:0] carrier_next;
    loop_optimized math(.*);
    always_comb begin
        code_delta_word=$signed(observed_values[767:704]);
        carrier_delta_word=$signed(observed_values[703:640]);
        feedback_aid_word=$signed(observed_values[63:0]);
        code_next=33'(64'sh20000000+code_delta_word+feedback_aid_word);
        carrier_next=32'(64'sh40000000+64'($signed(base_doppler))+carrier_delta_word);
    end
    always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) begin code_step<=0;carrier_step<=0;end
        else begin code_step<=code_next;carrier_step<=carrier_next;end
endmodule
"""
(experiment / "work/feedback_controller_probe.sv").write_text(wrapper, encoding="utf-8")
base = (experiment / "scripts/dc_probe.tcl").read_text(encoding="utf-8")
base = base.replace("work/norm_probes.sv", "work/loop_probes.sv")
base = base.replace("work/probe_registers.sv", "work/feedback_controller_probe.sv")
base = base.replace("elaborate probe_$env(PROBE_VERSION)", "elaborate feedback_controller_probe")
base = base.replace('puts "PROBE_COMPILE_BEGIN', 'write_sdc $report_dir/constraints_pre.sdc\nputs "PROBE_COMPILE_BEGIN')
base = base.replace('puts "PROBE_REPORTS_DONE"', 'set unmapped [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]\nputs "PROBE_UNMAPPED [sizeof_collection $unmapped]"\nputs "PROBE_REPORTS_DONE"')
sdc = (experiment / "scripts/baseline.sdc").read_text(encoding="utf-8")
for period in (10, 30):
    (experiment / f"work/feedback_{period}ns.sdc").write_text(
        sdc.replace("-period 10 ", f"-period {period} "), encoding="utf-8")
    (experiment / f"work/dc_feedback_{period}ns.tcl").write_text(
        base.replace("scripts/baseline.sdc", f"work/feedback_{period}ns.sdc"), encoding="utf-8")
print("FEEDBACK_PROBES_PREPARED periods=10,30 same V4 arithmetic, same IO and load")
