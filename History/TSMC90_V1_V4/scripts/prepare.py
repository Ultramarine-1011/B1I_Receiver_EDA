"""Generate isolated arithmetic probes and a renamed, frozen reference channel."""
from pathlib import Path
import os
import hashlib
import json
import re

experiment = Path(__file__).resolve().parent.parent
repository = Path(os.environ.get("B1I_PROJECT_ROOT", experiment.parent.parent.parent / "B1I_Receiver_EDA"))
baseline = experiment.parent / "TSMC90_B0"
work = experiment / "work"
work.mkdir(exist_ok=True)
original = baseline / "sources/student_release/student_release/rtl/tracking_channel_minimal.sv"
optimized = experiment / "rtl/tracking_channel_minimal.sv"
texts = {"original": original.read_text(encoding="utf-8"),
         "optimized": optimized.read_text(encoding="utf-8")}
(work / "tracking_channel_original.sv").write_text(
    texts["original"].replace("module tracking_channel_minimal", "module tracking_channel_original", 1),
    encoding="utf-8")

probes = []
wrappers = []
for version, source in texts.items():
    arithmetic = source[source.index("        ie2="):source.index("        valid_energy=")]
    divider_declarations = ("logic signed [79:0] code_numerator,phase_numerator;" if version == "original" else
        "logic [56:0] code_magnitude; logic [28:0] phase_denominator; logic [16:0] code_ratio,phase_ratio; logic signed [17:0] code_ratio_signed,phase_ratio_signed;")
    code_width = re.search(r"logic signed \[(\d+):0\] dcode", source)
    phase_width = re.search(r"logic signed \[(\d+):0\] dphase", source)
    code_width = code_width[1] if code_width else "63"
    phase_width = phase_width[1] if phase_width else "63"
    function = ""
    if version == "optimized":
        function = "\n".join(re.findall(r"    function automatic logic \[16:0\] normalized_(?:phase_)?ratio_q16\([\s\S]*?    endfunction", source))
    header = f"""module norm_{version} (
    input logic window_done,
    input logic signed [27:0] ie,qe,ip,qp,il,ql,
    output logic signed [{code_width}:0] dcode,
    output logic signed [{phase_width}:0] dphase
);
    logic signed [55:0] ie2,qe2,ip2,qp2,il2,ql2;
    logic [63:0] pe,pp,pl,den_code,abs_i,abs_q;
    {divider_declarations}
{function}
    always_comb begin
{arithmetic}    end
endmodule
"""
    probes.append(header)
    wrappers.append(f"""module probe_{version}(
    input logic clk,reset_n,window_done,
    input logic signed [27:0] ie,qe,ip,qp,il,ql,
    output logic signed [63:0] dcode,dphase
);
    wire signed [{code_width}:0] code_value;
    wire signed [{phase_width}:0] phase_value;
    norm_{version} arithmetic(.*,.dcode(code_value),.dphase(phase_value));
    always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) begin dcode<=0;dphase<=0;end
        else begin dcode<=64'($signed(code_value));dphase<=64'($signed(phase_value));end
endmodule
""")
(work / "norm_probes.sv").write_text("\n".join(probes), encoding="utf-8")
(work / "probe_registers.sv").write_text("\n".join(wrappers), encoding="utf-8")
constant_functions = re.findall(
    r"    function automatic logic signed \[23:0\] divide_(?:step_127875|aid_763)\([\s\S]*?    endfunction",
    texts["optimized"])
assert len(constant_functions) == 2
(work / "constant_division_probe.sv").write_text(
    "module constant_division_probe(input logic signed [39:0] step_value,"
    "input logic signed [32:0] aid_value,output logic signed [23:0] step_result,aid_result);\n"
    + "\n".join(constant_functions)
    + "\n always_comb begin step_result=divide_step_127875(step_value);aid_result=divide_aid_763(aid_value);end\nendmodule\n",
    encoding="utf-8")
files = [original, optimized, experiment / "scripts/prepare.py"]
(experiment / "evidence/input_hashes.json").write_text(json.dumps({
    os.path.relpath(path, repository): hashlib.sha256(path.read_bytes()).hexdigest() for path in files
}, indent=2), encoding="utf-8")
print("PREPARE_PASS frozen reference and exact arithmetic probes generated")

# Preserve the existing scenario and assertions, adding a full-cycle reference comparison.
testbench = (repository / "tb/tb_tracking_minimal.sv").read_text(encoding="utf-8")
testbench = testbench.replace("module tb_tracking_minimal", "module tb_tracking_equivalence", 1)
testbench = testbench.replace('"../../reports/local/tracking_loop.csv"', '"tracking_loop.csv"')
linux_repository = ("/mnt/" + repository.drive[0].lower() + repository.as_posix()[2:]) if repository.drive else str(repository)
testbench = testbench.replace('"../../tb/vectors/', '"' + linux_repository + '/tb/vectors/')
header = texts["original"].split(");", 1)[0]
outputs = []
for declaration in re.findall(r"output logic[^,\n]*(?:,[^\n]*)?", header):
    # Each declaration is one original source line, possibly naming several outputs.
    names = re.sub(r"^output logic\s*(?:signed\s*)?(?:\[[^]]+\]\s*)?", "", declaration)
    outputs.extend(name.strip() for name in names.rstrip(",").split(","))
inputs = ["clk", "reset_n", "init_valid", "init_prn", "init_code_phase_q", "init_doppler_word",
          "sample_valid", "sample_data", "sample_ref"]
connections = [f".{name}({name})" for name in inputs]
connections += [".init_code_period_count(32'd0)", ".init_carrier_phase_word(32'd0)"]
connections += [f".{name}()" for name in outputs]
monitor = """
    tracking_channel_original #(.ENABLE_FLL(FLL_TEST)) reference_dut(
        %s
    );
    always @(negedge clk) if(reset_n) begin
        if({%s} !== {%s})
            $fatal(1,"CHANNEL_CYCLE_MISMATCH sample=%%0d feedback=%%0d",sample_ref,feedbacks);
    end
""" % (",\n        ".join(connections),
       ",".join("dut." + name for name in outputs),
       ",".join("reference_dut." + name for name in outputs))
testbench = testbench.replace("    // Extra receiver snapshot ports", monitor + "    // Extra receiver snapshot ports")
(work / "tb_tracking_equivalence.sv").write_text(testbench, encoding="utf-8")
print("CHANNEL_COMPARISON_PORTS", len(outputs))
