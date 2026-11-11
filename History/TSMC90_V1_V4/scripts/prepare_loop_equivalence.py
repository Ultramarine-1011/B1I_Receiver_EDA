"""Extract both complete combinational loop bodies, preserving their declared widths."""
from pathlib import Path
import re
import sys

experiment = Path(__file__).resolve().parent.parent
optimized = Path(sys.argv[1]) if len(sys.argv) > 1 else experiment / "rtl/tracking_channel_minimal.sv"
original = experiment.parent / "TSMC90_B0/sources/student_release/student_release/rtl/tracking_channel_minimal.sv"
state_names = set("base_doppler code_integral carrier_integral previous_ip previous_qp seen previous_prompt_valid previous_prompt_ref population validity_history phase_mean_square_q32 code_mean_q16 frequency_mean_q16 previous_phase_valid previous_phase_q16".split())
external_ports = """input logic window_done,
input logic signed [27:0] ie,qe,ip,qp,il,ql,
input logic [41:0] window_energy,
input logic [63:0] window_ref,
input logic signed [31:0] init_doppler_word"""
observed = "dcode dphase ci_next pi_next code_command carrier_command code_delta_word carrier_delta_word phase_square phase_mean_next code_mean_next frequency_mean_next fll_adjustment fll_frequency fll_dot fll_cross initial_aid_word feedback_aid_word".split()
probes = []
for version, path in (("original", original), ("optimized", optimized)):
    source = path.read_text(encoding="utf-8")
    body = source[source.index("    localparam"):source.index("    tracking_frontend_spaced #")]
    declarations, rest = body.split("    function automatic", 1)
    ports = [external_ports]
    for match in list(re.finditer(r"    (logic\s+(?:signed\s+)?(?:\[[^]]+\]\s*)?)([^;]+);", declarations))[::-1]:
        type_text, names = match.groups()
        names = [name.strip() for name in names.split(",")]
        inputs = [name for name in names if name in state_names]
        if not inputs:
            continue
        ports.append("input " + type_text + ",".join(inputs))
        remaining = [name for name in names if name not in state_names]
        replacement = "    " + type_text + ",".join(remaining) + ";" if remaining else ""
        declarations = declarations[:match.start()] + replacement + declarations[match.end():]
    if version == "original":
        declarations += "    logic signed [23:0] initial_aid_word,feedback_aid_word;\n"
    body = declarations + "    logic fll_active;\n    function automatic" + rest
    body = re.sub(r"        sample_ready=[^;]+;\n", "", body)
    if version == "original":
        position = body.rfind("    end")
        body = body[:position] + "        initial_aid_word=24'(64'($signed(init_doppler_word))/763);\n        feedback_aid_word=24'((64'($signed(base_doppler))+carrier_delta_word)/763);\n" + body[position:]
    ports.append(f"output logic [{64*len(observed)-1}:0] observed_values")
    probes.append("module loop_" + version + " #(parameter integer ENABLE_FLL=1)(\n" + ",\n".join(ports) + ");\n" + body +
                  "    assign observed_values={" + ",".join("64'($signed(" + name + "))" for name in observed) + "};\nendmodule\n")
(experiment / "work/loop_probes.sv").write_text("\n".join(probes), encoding="utf-8")
print("LOOP_EQUIVALENCE_PREPARE_PASS observed=" + str(len(observed)))
