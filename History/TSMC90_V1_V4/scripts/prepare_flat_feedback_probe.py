"""Flatten the feedback-only probe so unused observation outputs cannot preserve logic."""
from pathlib import Path
import re

experiment = Path(__file__).resolve().parent.parent
source = (experiment / "work/loop_probes.sv").read_text(encoding="utf-8")
source = source.split("module loop_optimized", 1)[1]
header, body = source.split(");", 1)
ports = header.split(")(", 1)[1].strip()
ports = re.sub(r",\noutput logic \[[^]]+\] observed_values$", "", ports)
body = re.sub(r"    assign observed_values=\{[^\n]+\};\n", "", body)
body = body.rsplit("endmodule", 1)[0]
wrapper = f"""module feedback_controller_flat #(parameter integer ENABLE_FLL=1)(
input logic clk,reset_n,
{ports},
output logic [32:0] code_step,
output logic [31:0] carrier_step
);
{body}
    logic [32:0] code_next;
    logic [31:0] carrier_next;
    always_comb begin
        code_next=33'(64'sh20000000+code_delta_word+64'($signed(feedback_aid_word)));
        carrier_next=32'(64'sh40000000+64'($signed(base_doppler))+carrier_delta_word);
    end
    always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) begin code_step<=0;carrier_step<=0;end
        else begin code_step<=code_next;carrier_step<=carrier_next;end
endmodule
"""
(experiment / "work/feedback_controller_flat.sv").write_text(wrapper, encoding="utf-8")
for period in (10, 30, 100):
    tcl = (experiment / "work/dc_feedback_30ns.tcl").read_text(encoding="utf-8")
    tcl = tcl.replace("work/feedback_30ns.sdc", f"work/feedback_{period}ns.sdc")
    sdc = (experiment / "scripts/baseline.sdc").read_text(encoding="utf-8")
    (experiment / f"work/feedback_{period}ns.sdc").write_text(
        sdc.replace("-period 10 ", f"-period {period} "), encoding="utf-8")
    tcl = tcl.replace('if {[analyze -format sverilog -define SYNTHESIS work/loop_probes.sv] == 0} { exit 1 }\n', '')
    tcl = tcl.replace("work/feedback_controller_probe.sv", "work/feedback_controller_flat.sv")
    tcl = tcl.replace("elaborate feedback_controller_probe", "elaborate feedback_controller_flat")
    (experiment / f"work/dc_feedback_flat_{period}ns.tcl").write_text(tcl, encoding="utf-8")
print("FLAT_FEEDBACK_PREPARED only NCO outputs observable; original receiver RTL untouched")
