"""Build the iterative candidate from the preserved, exact V6 implementation."""
from pathlib import Path
import hashlib
import json
import shutil
import tarfile

root = Path(__file__).resolve().parents[1]
experiments = root.parent
course = experiments.parent / "B1I_Receiver_EDA"
rtl = root / "rtl"
rtl.mkdir(parents=True, exist_ok=True)
baseline = experiments / "TSMC90_V6/rtl/tracking_channel_minimal.sv"
source = baseline.read_text(encoding="utf-8")
parent = source.split("// Combinational arithmetic partition definitions.")[0]
parent = parent.replace("// Hierarchical night experiment. DLL normalizer=r4, exact signed constant conversion.",
                        "// Iterative exact feedback. Accepted-sample behavior matches the preserved V6.")
comment_start = parent.index("    // Exact signed ceil-reciprocal")
comment_end = parent.index("    // Pure combinational boundaries")
parent = parent[:comment_start] + parent[comment_end:]
start = parent.index("    // Pure combinational boundaries")
end = parent.index("    always_comb begin", start)
parent = parent[:start] + '''    typedef enum logic [2:0] {WAIT_WINDOW, NORMALIZE, CONVERT_CODE,
        CONVERT_CARRIER, CONVERT_AID, WAIT_AID, COMMIT} feedback_state_t;
    feedback_state_t feedback_state;
    logic math_done,aid_done,initial_aid_pending;
    logic feedback_commit;
    logic signed [39:0] conversion_input;
    logic signed [23:0] conversion_result, aid_result;
    logic [63:0] pending_feedback_ref;
    assign feedback_commit=feedback_state==COMMIT;
    tracking_normalize_iterative #(.ENABLE_FLL(ENABLE_FLL)) normalize(
        .clk(clk),.reset_n(reset_n && !init_valid),
        .start(window_done && feedback_state==WAIT_WINDOW),
        .code_magnitude(code_magnitude),.code_denominator(den_code[56:0]),
        .phase_magnitude(abs_q[28:0]),.phase_denominator(phase_denominator),
        .dot_value(fll_dot),.cross_value(fll_cross),
        .code_ratio(normalized_code_raw),.phase_ratio(normalized_phase_raw),
        .angle(atan_raw),.done(math_done));
    // One exact conversion multiplier serves both loop commands on separate clocks.
    assign conversion_input=feedback_state==CONVERT_CODE ?
        40'(64'($signed(code_command))*512) : 40'(64'($signed(carrier_command))*512);
    tracking_divide_step conversion(.value(conversion_input),.result(conversion_result));
    // Initialization and feedback never need this conversion simultaneously.
    tracking_aid_iterative aid(.clk(clk),.reset_n(reset_n),
        .start(init_valid || feedback_state==CONVERT_AID),
        .value(init_valid ? 33'($signed(init_doppler_word)) :
            33'(64'($signed(base_doppler))+carrier_delta_word)),
        .result(aid_result),.done(aid_done));
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) initial_aid_pending<=0;
        else if(init_valid) initial_aid_pending<=1;
        else if(aid_done) initial_aid_pending<=0;
    end
    assign code_delta_word=14'(code_delta_full);
    assign carrier_delta_word=23'(carrier_delta_full);
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            feedback_state<=WAIT_WINDOW;
            code_delta_full<=0;carrier_delta_full<=0;feedback_aid_word<=0;
            pending_feedback_ref<=0;
        end else if(init_valid) begin
            feedback_state<=WAIT_WINDOW;
            code_delta_full<=0;carrier_delta_full<=0;feedback_aid_word<=0;
            pending_feedback_ref<=0;
        end else case(feedback_state)
            WAIT_WINDOW: if(window_done) begin
                pending_feedback_ref<=sample_ref;
                feedback_state<=NORMALIZE;
            end
            NORMALIZE: if(math_done) feedback_state<=CONVERT_CODE;
            CONVERT_CODE: begin code_delta_full<=conversion_result;feedback_state<=CONVERT_CARRIER;end
            CONVERT_CARRIER: begin carrier_delta_full<=conversion_result;feedback_state<=CONVERT_AID;end
            CONVERT_AID: feedback_state<=WAIT_AID;
            WAIT_AID: if(aid_done) begin feedback_aid_word<=aid_result;feedback_state<=COMMIT;end
            COMMIT: feedback_state<=WAIT_WINDOW;
            default: feedback_state<=WAIT_WINDOW;
        endcase
    end
''' + parent[end:]
parent = parent.replace("sample_ready=reset_n && enabled && code_valid && !init_valid;",
                        "sample_ready=reset_n && enabled && code_valid && !init_valid &&\n"
                        "            feedback_state==WAIT_WINDOW && !window_done && !initial_aid_pending;")
# The integration outputs remain stable while feedback is evaluated. No accepted
# sample can advance either NCO until the same exact commands have been committed.
parent = parent.replace("if(window_done)", "if(feedback_state!=WAIT_WINDOW)")
parent = parent.replace("!window_done ?", "feedback_state==WAIT_WINDOW ?")
parent = parent.replace("window_done && ENABLE_FLL", "feedback_state!=WAIT_WINDOW && ENABLE_FLL")
parent = parent.replace(".sample_valid(sample_valid && enabled)", ".sample_valid(sample_valid && sample_ready)")
parent = parent.replace("            if(feedback_state!=WAIT_WINDOW) begin\n                feedback_valid<=1;",
                        "            if(feedback_commit) begin\n                feedback_valid<=1;")
parent = parent.replace("                feedback_ref<=sample_ref;", "                feedback_ref<=pending_feedback_ref;")
# The controller start is the actual dump pulse, including its WAIT_WINDOW edge.
parent = parent.replace("WAIT_WINDOW: if(feedback_state!=WAIT_WINDOW)", "WAIT_WINDOW: if(window_done)")
parent = parent.replace("initial_aid_word, feedback_aid_word", "feedback_aid_word")
parent = parent.replace("code_step_q<=33'(64'sh20000000+(ENABLE_CARRIER_AID ? 64'($signed(initial_aid_word)) : 64'sd0));",
                        "code_step_q<=33'h020000000;")
parent = parent.replace("            feedback_valid<=0;\n            if(feedback_commit)",
                        "            feedback_valid<=0;\n"
                        "            if(initial_aid_pending && aid_done)\n"
                        "                code_step_q<=33'(64'sh20000000+(ENABLE_CARRIER_AID ? 64'($signed(aid_result)) : 64'sd0));\n"
                        "            if(feedback_commit)")
conversions = source[source.index("module tracking_divide_step"):source.index("module tracking_divide_aid")]
candidate = (parent + (root / "rtl/tracking_normalize_iterative.sv").read_text() + "\n" +
             (root / "rtl/tracking_aid_iterative.sv").read_text() + "\n" + conversions)
candidate = candidate.rstrip() + "\n"
(rtl / "tracking_channel_minimal.sv").write_text(candidate, encoding="utf-8", newline="\n")
(rtl / "reference_tracking.sv").write_text(
    source.replace("tracking_channel_minimal", "reference_tracking_channel_minimal"),
    encoding="utf-8", newline="\n")
# Reference arithmetic names have no collisions with the new iterative engine.
reference = (rtl / "reference_tracking.sv").read_text()
for name in ["tracking_divide_step", "tracking_divide_aid"]:
    reference = reference.replace(name, "reference_" + name)
(rtl / "reference_tracking.sv").write_text(reference, encoding="utf-8", newline="\n")
for name in ["b1i_prn_gen.sv", "code_nco.sv", "carrier_nco_mixer.sv",
             "tracking_frontend_spaced.sv", "epl_correlator.sv", "carrier_quarter_lut.svh"]:
    shutil.copyfile(course / "student_release/student_release/rtl" / name, rtl / name)
for directory in ["scripts", "tb", "evidence"]:
    (root / directory).mkdir(exist_ok=True)
manifest = {str(path.relative_to(root)).replace("\\", "/"): hashlib.sha256(path.read_bytes()).hexdigest()
            for directory in ["rtl", "scripts", "tb"] for path in sorted((root / directory).rglob("*"))
            if path.is_file() and "__pycache__" not in path.parts}
(root / "evidence/inputs.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
with tarfile.open(root / "inputs.tar.gz", "w:gz") as archive:
    for directory in ["rtl", "scripts", "tb", "teacher"]:
        archive.add(root / directory, arcname=directory)
print("ITERATIVE_INPUTS_READY", manifest["rtl/tracking_channel_minimal.sv"])
