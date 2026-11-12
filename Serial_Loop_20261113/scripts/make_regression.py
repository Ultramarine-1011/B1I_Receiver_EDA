"""Generate a two-instance accepted-sample differential test and existing loop tests."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
course = root.parent.parent / "B1I_Receiver_EDA"
text = (root / "rtl/tracking_channel_minimal.sv").read_text()
header = text[text.index(") (")+3:text.index(");")]
inputs, outputs = [], []
direction = None
port_type = ""
for part in header.split(","):
    part = part.strip()
    match = re.match(r"(input|output)\s+(logic(?:\s+signed)?(?:\s+\[[^]]+\])?)\s+(\w+)$", part)
    if match:
        direction, port_type, name = match.groups()
    else:
        name = part
    (inputs if direction == "input" else outputs).append((port_type, name))
declarations = "\n".join(f"    {kind} u_{name},v_{name};" for kind, name in outputs)
connections = {}
for prefix in ["u", "v"]:
    connections[prefix] = ",\n        ".join(
        [f".{name}({name})" for _, name in inputs] +
        [f".{name}({prefix}_{name})" for _, name in outputs])
frontend = ["code_phase_q", "code_period_count", "carrier_phase_word", "code_step_q", "carrier_step_word",
            "ie", "qe", "ip", "qp", "il", "ql", "window_ref", "window_energy"]
loop = ["usable", "locked", "dll_error_q16", "pll_error_q16", "code_correction_q16",
        "carrier_correction_q16", "fll_error_q16", "feedback_ref"]
def packed(prefix, names):
    return "{" + ",".join(prefix + "_" + name for name in names) + "}"
test = '''`timescale 1ns/1ps
module tb_tracking_equivalence;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,init_valid=0,sample_valid=0;
    logic [5:0] init_prn=6;
    logic [42:0] init_code_phase_q=43'h040000000;
    logic [31:0] init_code_period_count=0,init_carrier_phase_word=0;
    logic signed [31:0] init_doppler_word=0;
    logic signed [2:0] sample_data=0;
    logic [63:0] sample_ref=0;
DECLARATIONS
    tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) dut(
        CANDIDATE_CONNECTIONS);
    reference_tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) reference_dut(
        REFERENCE_CONNECTIONS);
    logic prn[0:2045];
    integer n,scenario,stalls=0,feedbacks=0,accepted=0,max_stall=0,run_stall=0;
    real analog,hz,phase;
    integer sign_code,nh_sign;
    always @(negedge clk) if(reset_n && !init_valid) begin
        if(u_feedback_valid) begin
            feedbacks=feedbacks+1;
            if(CANDIDATE_LOOP !== REFERENCE_LOOP)
                $fatal(1,"feedback mismatch sample=%0d dll=%0d/%0d pll=%0d/%0d code=%0d/%0d carrier=%0d/%0d ref=%0d/%0d",
                    sample_ref,u_dll_error_q16,v_dll_error_q16,u_pll_error_q16,v_pll_error_q16,
                    u_code_correction_q16,v_code_correction_q16,u_carrier_correction_q16,v_carrier_correction_q16,
                    u_feedback_ref,v_feedback_ref);
        end
    end
    always @(posedge clk) if(reset_n && sample_valid) begin
        if(!u_sample_ready || !v_sample_ready) $fatal(1,"testbench violated handshake");
        if(CANDIDATE_FRONTEND !== REFERENCE_FRONTEND)
            $fatal(1,"accepted-sample state mismatch sample=%0d code=%h/%h carrier=%h/%h",
                sample_ref,u_code_step_q,v_code_step_q,u_carrier_step_word,v_carrier_step_word);
        accepted=accepted+1;
    end
    initial begin
        $readmemh("../tb/b1i_prn_06.mem",prn);
        repeat(4) @(negedge clk);reset_n=1;
        // Cover the full signed32 initialization domain before accepting samples.
        for(n=0;n<40;n=n+1) begin
            init_valid=1;
            init_doppler_word=n==0 ? 32'sh80000000 : n==1 ? 32'sh7fffffff : $random;
            @(negedge clk);init_valid=0;
            while(!u_sample_ready || !v_sample_ready) @(negedge clk);
            if(u_code_step_q!==v_code_step_q || u_carrier_step_word!==v_carrier_step_word)
                $fatal(1,"initial aid mismatch value=%0d",init_doppler_word);
        end
        for(scenario=0;scenario<2;scenario=scenario+1) begin
            @(negedge clk);sample_valid=0;init_valid=1;
            init_code_phase_q=scenario==0 ? 43'h040000000 : (43'd2046<<32)-43'h040000000;
            init_doppler_word=scenario==0 ? 32'sd32000 : -32'sd32000;
            hz=scenario==0 ? 125.0 : -125.0;phase=scenario==0 ? 0.13 : -0.13;
            @(negedge clk);init_valid=0;
            for(n=0;n<16368000;n=n+1) begin
                sample_valid=0;
                run_stall=0;
                while(!u_sample_ready || !v_sample_ready) begin
                    @(negedge clk);stalls=stalls+1;run_stall=run_stall+1;
                end
                if(n>0 && run_stall>max_stall) max_stall=run_stall;
                sign_code=prn[(n/8)%2046] ? -1 : 1;
                nh_sign=((20'b00000100110101001110 >> (19-((n/16368)%20))) & 1) ? -1 : 1;
                analog=2.0*real'(sign_code*nh_sign)*$cos(6.283185307179586*(phase+(4092000.0+hz)*real'(n)/16368000.0));
                sample_data=analog < -1 ? -3 : analog < 0 ? -1 : analog < 1 ? 1 : 3;
                sample_ref=64'(n);sample_valid=1;
                @(negedge clk);
            end
            sample_valid=0;repeat(64) @(negedge clk);
            if(!u_locked || !v_locked) $fatal(1,"loop failed to lock scenario=%0d",scenario);
        end
        $display("TRACKING_ITERATIVE_EQUIVALENCE_PASS accepted=%0d feedbacks=%0d stalls=%0d max_feedback_stall=%0d",accepted,feedbacks,stalls,max_stall);
        $finish;
    end
    initial begin #500000000; $fatal(1,"equivalence timeout");end
endmodule
'''
for key, value in {
    "DECLARATIONS": declarations,
    "CANDIDATE_CONNECTIONS": connections["u"],
    "REFERENCE_CONNECTIONS": connections["v"],
    "CANDIDATE_LOOP": packed("u", loop), "REFERENCE_LOOP": packed("v", loop),
    "CANDIDATE_FRONTEND": packed("u", frontend), "REFERENCE_FRONTEND": packed("v", frontend),
}.items():
    test = test.replace(key, value)
(root / "tb/tb_tracking_equivalence.sv").write_text(test, encoding="utf-8", newline="\n")
shutil_source = course / "tb/vectors/b1i_prn_06.mem"
(root / "tb/b1i_prn_06.mem").write_bytes(shutil_source.read_bytes())
test = (course / "tb/tb_tracking_minimal.sv").read_text()
test = test.replace('"../../tb/vectors/b1i_prn_06.mem"', '"../tb/b1i_prn_06.mem"')
test = test.replace('"../../reports/local/tracking_loop.csv"', '"tracking_loop.csv"')
test = test.replace("                sign_code=", "                while(!sample_ready) begin sample_valid=0;@(negedge clk);end\n                sign_code=")
test = test.replace("repeat(5) @(negedge clk)", "repeat(64) @(negedge clk)")
test = test.replace("        if(window_done) windows=windows+1;", "")
test = test.replace("    task automatic run_case", "    always @(posedge clk) if(reset_n && window_done) windows=windows+1;\n    task automatic run_case")
(root / "tb/tb_tracking_minimal.sv").write_text(test, encoding="utf-8", newline="\n")
print("TRACKING_DIFFERENTIAL_TEST_READY", len(inputs), len(outputs))
