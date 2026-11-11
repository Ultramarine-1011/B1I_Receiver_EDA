"""Prepare a cycle comparison for the renamed Code-NCO cone in the clean map."""
import hashlib
import json
from pathlib import Path
import os
import re

experiment = Path(__file__).resolve().parent.parent
repository = Path(os.environ.get("B1I_PROJECT_ROOT", experiment.parent.parent / "B1I_Receiver_EDA"))
paths = [experiment.parent / "TSMC90_V6/Results/mapped.v",
         experiment / "Results/clean_v6_channel/reports/mapped.v"]
top = "code_nco_PHASE_FRAC32_PERIOD_COUNT_WIDTH32_EPL_HALF_SPACING_NUMERATOR5_EPL_HALF_SPACING_DENOMINATOR16"
outputs = "code_valid init_done sample_accepted code_epoch early_code prompt_code late_code code_phase_q code_period_count".split()
inputs = "clk rst_n init_valid init_prn init_code_phase_q init_code_period_count sample_valid code_step_q".split()
mapped = []
instances = []
for suffix, path in zip(("old", "new"), paths):
    source = path.read_text()
    modules = {name: text for text, name in re.findall(r"(\bmodule\s+(\S+)\s*\(.*?\bendmodule)", source, re.S)}
    needed = {top}
    previous = set()
    while previous != needed:
        previous = set(needed)
        for name in previous:
            references = set(re.findall(r"\b(\w+)\s+[^\s(]+\s*\(", modules[name]))
            needed.update(references & modules.keys())
    text = "\n".join(modules[name] for name in sorted(needed))
    for name in sorted(needed, key=len, reverse=True):
        text = re.sub(r"\b" + re.escape(name) + r"\b", name + "_" + suffix, text)
    mapped.append(text)
    declarations = f"wire code_valid_{suffix},init_done_{suffix},sample_accepted_{suffix},code_epoch_{suffix},early_code_{suffix},prompt_code_{suffix},late_code_{suffix};\n"
    declarations += f"wire [42:0] code_phase_q_{suffix}; wire [31:0] code_period_count_{suffix};\n"
    connections = [f".{name}({name})" for name in inputs]
    connections += [f".{name}({name}_{suffix})" for name in outputs]
    declarations += top + "_" + suffix + " dut_" + suffix + "(\n" + ",\n".join(connections) + ");\n"
    instances.append(declarations)
work = experiment / "work"
(work / "mapped_nco.sv").write_text("`timescale 1ns/1ps\n" + "\n".join(mapped), encoding="utf-8", newline="\n")
tb = """`timescale 1ns/1ps
module tb_mapped_nco;
    reg clk=0,rst_n=0,init_valid=0,sample_valid=0;
    reg [5:0] init_prn=6;
    reg [42:0] init_code_phase_q=0;
    reg [31:0] init_code_period_count=0;
    reg [32:0] code_step_q=33'h020000000;
    reg [31:0] random_state=32'hb1a12026;
    integer checks=0;
    always #5 clk=~clk;
    function automatic reg [31:0] random_word;
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
INSTANCES
    initial begin
        repeat(3) @(negedge clk);
        for(integer cycle=0;cycle<200000;cycle=cycle+1) begin
            rst_n=cycle%37001!=0;
            init_valid=cycle%5000==1;
            init_prn=6+random_word()%32;
            if(init_valid) begin
                init_code_phase_q=43'({random_word(),random_word()});
                init_code_period_count=random_word();
            end
            sample_valid=(random_word()%7)!=0;
            case(cycle%5)
                0: code_step_q=33'h020000000;
                1: code_step_q=33'h0ffffffff;
                2: code_step_q=33'd1;
                default: code_step_q=33'(random_word());
            endcase
            @(posedge clk);#0.1;
            if((^{OBSERVED_OLD})===1'bx) $fatal(1,"MAPPED_NCO_UNKNOWN cycle=%0d",cycle);
            if({OBSERVED_OLD} !== {OBSERVED_NEW}) $fatal(1,"MAPPED_NCO_CYCLE_MISMATCH cycle=%0d",cycle);
            checks=checks+1;
            @(negedge clk);#0.01;
        end
        $display("MAPPED_NCO_EQUIVALENCE_PASS cycles=%0d seed=b1a12026",checks);
        $finish;
    end
endmodule
"""
tb = tb.replace("INSTANCES", "\n".join(instances))
for suffix in ("old", "new"):
    tb = tb.replace("OBSERVED_" + suffix.upper(), ",".join(name + "_" + suffix for name in outputs))
(work / "tb_mapped_nco.sv").write_text(tb, encoding="utf-8", newline="\n")
manifest = {os.path.relpath(path, repository): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in paths + [work / "mapped_nco.sv", work / "tb_mapped_nco.sv"]}
(experiment / "evidence/nco_rebuild_sources.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("MAPPED_NCO_PROBE_PREPARED")
