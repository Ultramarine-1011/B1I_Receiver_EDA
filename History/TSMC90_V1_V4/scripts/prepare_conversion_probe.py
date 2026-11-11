"""Isolate the control-word conversion chain with identical clamped input domains."""
from pathlib import Path
import re

experiment = Path(__file__).resolve().parent.parent
original = (experiment.parent / "TSMC90_B0/sources/student_release/student_release/rtl/tracking_channel_minimal.sv").read_text(encoding="utf-8")
optimized = (experiment / "rtl/tracking_channel_minimal.sv").read_text(encoding="utf-8")
clamp = re.search(r"    function automatic logic signed \[63:0\] clamp\([\s\S]*?    endfunction", original)[0]
helpers = "\n".join(re.findall(r"    function automatic logic signed \[23:0\] divide_(?:step_127875|aid_763)\([\s\S]*?    endfunction", optimized))
modules = []
for version in ("original", "optimized"):
    declarations = ("logic signed [63:0] code_command,carrier_command,code_delta_word,carrier_delta_word;" if version == "original" else
        "logic signed [21:0] code_command; logic signed [30:0] carrier_command; logic signed [13:0] code_delta_word; logic signed [22:0] carrier_delta_word; logic signed [23:0] feedback_aid_word;")
    if version == "original":
        conversion = """        code_delta_word=(code_command*65536)/16368000;
        carrier_delta_word=(carrier_command*65536)/16368000;
        code_next=33'(64'sh20000000+code_delta_word+(64'($signed(base_doppler))+carrier_delta_word)/763);
"""
    else:
        conversion = """        code_delta_word=14'(divide_step_127875(40'(64'($signed(code_command))*512)));
        carrier_delta_word=23'(divide_step_127875(40'(64'($signed(carrier_command))*512)));
        feedback_aid_word=divide_aid_763(33'(64'($signed(base_doppler))+carrier_delta_word));
        code_next=33'(64'sh20000000+code_delta_word+64'($signed(feedback_aid_word)));
"""
    modules.append(f"""module conversion_{version}(
    input logic clk,reset_n,
    input logic signed [31:0] raw_code,raw_carrier,base_doppler,
    output logic [32:0] code_step,
    output logic [31:0] carrier_step
);
    localparam logic signed [63:0] CODE_LIMIT=64'sd1638400,CARRIER_LIMIT=64'sd655360000;
    {declarations}
    logic [32:0] code_next;
    logic [31:0] carrier_next;
{clamp}
{helpers if version == 'optimized' else ''}
    always_comb begin
        code_command=clamp(64'($signed(raw_code)),CODE_LIMIT);
        carrier_command=clamp(64'($signed(raw_carrier)),CARRIER_LIMIT);
{conversion}        carrier_next=32'(64'sh40000000+64'($signed(base_doppler))+carrier_delta_word);
    end
    always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) begin code_step<=0;carrier_step<=0;end
        else begin code_step<=code_next;carrier_step<=carrier_next;end
endmodule
""")
(experiment / "work/conversion_probes.sv").write_text("\n".join(modules), encoding="utf-8")
tcl = (experiment / "scripts/dc_probe.tcl").read_text(encoding="utf-8")
tcl = tcl.replace("work/norm_probes.sv", "work/conversion_probes.sv")
tcl = tcl.replace('if {[analyze -format sverilog work/probe_registers.sv] == 0} { exit 1 }\n', '')
tcl = tcl.replace("elaborate probe_$env(PROBE_VERSION)", "elaborate conversion_$env(PROBE_VERSION)")
(experiment / "work/dc_conversion_probe.tcl").write_text(tcl, encoding="utf-8")
print("CONVERSION_PROBES_PREPARED")
