"""Stage a cycle-identical hierarchy for bounded bottom-up DC mapping."""
from pathlib import Path
import argparse
import re
import shutil

experiment = Path(__file__).resolve().parent.parent
flat_path = experiment / "rtl/tracking_channel_minimal.sv"
flat = flat_path.read_text(encoding="utf-8")
parser = argparse.ArgumentParser()
parser.add_argument("--activate", action="store_true")
args = parser.parse_args()
if "// Combinational arithmetic partition definitions." in flat:
    raise RuntimeError("Generate flat V5 with prepare_accepted.py before preparing the hierarchy")
staging = experiment / "work/hier"
staging.mkdir(exist_ok=True)
(staging / "flat_v5.sv").write_text(flat, encoding="utf-8")

specifications = [
    ("tracking_ratio_code", "normalized_ratio_q16", "logic [16:0]",
     "input logic [56:0] magnitude,denominator", "magnitude,denominator"),
    ("tracking_ratio_phase", "normalized_phase_ratio_q16", "logic [16:0]",
     "input logic [28:0] magnitude,denominator", "magnitude,denominator"),
    ("tracking_atan", "atan_turn_q16", "logic signed [15:0]",
     "input logic signed [56:0] dot_value,cross_value", "dot_value,cross_value"),
    ("tracking_divide_step", "divide_step_127875", "logic signed [23:0]",
     "input logic signed [39:0] value", "value"),
    ("tracking_divide_aid", "divide_aid_763", "logic signed [23:0]",
     "input logic signed [32:0] value", "value"),
]
helpers = []
source = flat
for module, function, result_type, inputs, arguments in specifications:
    pattern = rf"    function automatic {re.escape(result_type)} {function}\([\s\S]*?    endfunction"
    body = re.search(pattern, source)[0]
    helpers.append(f"module {module}({inputs},output {result_type} result);\n"
                   + body + f"\n    assign result={function}({arguments});\nendmodule\n")
    source = re.sub(pattern, "", source)

declarations = """    logic [16:0] normalized_code_raw,normalized_phase_raw;
    logic signed [15:0] atan_raw;
    logic signed [23:0] code_delta_full,carrier_delta_full;
"""
source = source.replace("    function automatic logic signed [63:0] clamp", declarations +
                        "    function automatic logic signed [63:0] clamp", 1)
instances = """    // Pure combinational boundaries preserve the original feedback edge.
    tracking_ratio_code dll_ratio(.magnitude(code_magnitude),.denominator(den_code[56:0]),.result(normalized_code_raw));
    tracking_ratio_phase pll_ratio(.magnitude(abs_q[28:0]),.denominator(phase_denominator),.result(normalized_phase_raw));
    tracking_atan fll_phase(.dot_value(fll_dot),.cross_value(fll_cross),.result(atan_raw));
    tracking_divide_step code_conversion(.value(40'(64'($signed(code_command))*512)),.result(code_delta_full));
    tracking_divide_step carrier_conversion(.value(40'(64'($signed(carrier_command))*512)),.result(carrier_delta_full));
    tracking_divide_aid initial_aid(.value(33'($signed(init_doppler_word))),.result(initial_aid_word));
    tracking_divide_aid feedback_aid(.value(33'(64'($signed(base_doppler))+carrier_delta_word)),.result(feedback_aid_word));
    assign code_delta_word=14'(code_delta_full);
    assign carrier_delta_word=23'(carrier_delta_full);
"""
source = source.replace("    always_comb begin", instances + "    always_comb begin", 1)
source = source.replace("normalized_ratio_q16(code_magnitude,den_code[56:0])", "normalized_code_raw")
source = source.replace("normalized_phase_ratio_q16(abs_q[28:0],phase_denominator)", "normalized_phase_raw")
source = source.replace("atan_turn_q16(fll_dot,fll_cross)", "atan_raw")
for name in ("code_delta_word", "carrier_delta_word", "initial_aid_word", "feedback_aid_word"):
    source, count = re.subn(rf"        {name}=divide_[^\n]+\n|        {name}=\d+'\(divide_[^\n]+\n", "", source)
    assert count == 1, (name, count)
source = source.replace("        code_ratio=0;", "    end\n    always_comb begin\n        code_ratio=0;", 1)
source = source.replace("        fll_frequency=0;", "    end\n    always_comb begin\n        fll_frequency=0;", 1)
source = source.replace("// Night experiment.", "// Hierarchical night experiment.", 1)
source += "\n// Combinational arithmetic partition definitions.\n" + "\n".join(helpers)
(staging / "tracking_channel_minimal.sv").write_text(source, encoding="utf-8")

bottom_up = """
# Every arithmetic partition is mapped at a 10 ns virtual clock. These are
# internal combinational boundaries with zero IO delay, before the complete
# channel is timed with the unchanged external B0 SDC.
set top_design [get_object_name [current_design]]
set arithmetic_instances [get_cells -hierarchical -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
if {[sizeof_collection $arithmetic_instances] != 7} { exit 1 }
set arithmetic_designs [lsort -unique [get_attribute $arithmetic_instances ref_name]]
foreach arithmetic $arithmetic_designs {
    current_design $arithmetic
    set_operating_conditions typical -library typical
    create_clock -name module_clk -period 10
    set_clock_uncertainty -setup 0.2 [get_clocks module_clk]
    set_clock_uncertainty -hold 0.2 [get_clocks module_clk]
    set_input_delay -clock module_clk -max 0.0 [all_inputs]
    set_input_delay -clock module_clk -min 0.0 [all_inputs]
    set_output_delay -clock module_clk -max 0.0 [all_outputs]
    set_output_delay -clock module_clk -min 0.0 [all_outputs]
    set_driving_cell -lib_cell INVX1 -library typical [all_inputs]
    set_load [expr {4.0 * [load_of typical/INVX1/A]}] [all_outputs]
    puts "PARTITION_COMPILE_BEGIN $arithmetic [clock seconds]"
    if {[compile -map_effort medium] == 0} { exit 1 }
    puts "PARTITION_COMPILE_END $arithmetic [clock seconds]"
    set missing [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]
    if {[sizeof_collection $missing] != 0} { exit 1 }
    redirect $report_dir/${arithmetic}_qor.rpt { report_qor }
    redirect $report_dir/${arithmetic}_timing.rpt { report_timing -delay max -max_paths 1 -significant_digits 6 }
    ungroup -all -flatten
    reset_design
    set_dont_touch [current_design] true
    write -format ddc -hierarchy -output $report_dir/${arithmetic}.ddc
}
current_design $top_design
if {[link] == 0} { exit 1 }
set arithmetic_cells [get_cells -hierarchical -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
set_dont_touch $arithmetic_cells true
set_boundary_optimization $arithmetic_cells false
puts "PARTITION_FIXED_INSTANCES [sizeof_collection $arithmetic_cells]"
"""
tcl = (experiment / "scripts/dc_opt.tcl").read_text(encoding="utf-8")
needle = "set_operating_conditions typical -library typical\nsource scripts/baseline.sdc"
assert needle in tcl
tcl = tcl.replace(needle, bottom_up + "\n" + needle, 1)
(staging / "dc_hier.tcl").write_text(tcl, encoding="utf-8")
if args.activate:
    shutil.copyfile(staging / "tracking_channel_minimal.sv", flat_path)
    shutil.copyfile(staging / "dc_hier.tcl", experiment / "scripts/dc_hier.tcl")
print("HIERARCHY_STAGED five combinational arithmetic partitions, no added registers")
