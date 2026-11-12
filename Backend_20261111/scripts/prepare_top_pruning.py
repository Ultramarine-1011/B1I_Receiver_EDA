"""Derive the private six-channel experiment sources from the frozen baseline."""
from pathlib import Path

experiment = Path(__file__).resolve().parent.parent
frozen = experiment.parent / "History/TSMC90_B0/sources/student_release/student_release/rtl"
output = experiment / "rtl"
output.mkdir(exist_ok=True)


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError("Frozen-source edit has an unexpected match count: " + old)
    return text.replace(old, new, 1)


navigation = (frozen / "navigation_d1.sv").read_text()
navigation = replace_once(navigation, "module navigation_d1 (", "module navigation_d1 #(parameter integer EXPORT_RECORDS=1) (")
navigation = replace_once(navigation, "record_data=words[publish_index];", "record_data=EXPORT_RECORDS ? words[publish_index] : 256'd0;")
navigation = replace_once(navigation, "if(bit_meta_step!=0)", "if(EXPORT_RECORDS && bit_meta_step!=0)")
navigation = replace_once(navigation, "    always_comb begin\n", """    // The full 20-bit input range plus six fits below 2*604800.
    function automatic logic [19:0] sow_after_subframe(input logic [19:0] value);
        logic [20:0] advanced;
        advanced={1'b0,value}+21'd6;
        if(advanced>=21'd604800) sow_after_subframe=20'(advanced-21'd604800);
        else sow_after_subframe=20'(advanced);
    endfunction
    always_comb begin
""")
navigation = replace_once(navigation, "20'((32'(previous_sow)+6)%604800)", "sow_after_subframe(previous_sow)")
(output / "navigation_d1.sv").write_text(navigation, newline="\n")

receiver = (frozen / "receiver_channel.sv").read_text()
receiver = replace_once(receiver, "parameter integer CHANNEL_ID=0", "parameter integer CHANNEL_ID=0,EXPORT_RECORDS=1")
receiver = replace_once(receiver, "navigation_d1 navigation(", "navigation_d1 #(.EXPORT_RECORDS(EXPORT_RECORDS)) navigation(")
start = receiver.index("    tracking_record_framer framer(")
end = receiver.index(".record_data(framed_prompt));", start) + len(".record_data(framed_prompt));")
framer = receiver[start:end]
receiver = receiver[:start] + "    generate if(EXPORT_RECORDS) begin: export_prompt_record\n" + framer + \
    "\n    end else begin: omit_prompt_record\n        assign framed_prompt=256'd0;\n    end endgenerate" + receiver[end:]
(output / "receiver_channel.sv").write_text(receiver, newline="\n")

nh = (frozen / "nh20_sync.sv").read_text()
function = """    // Both five-bit phase operands are nonnegative. Their sum is at most 62.
    function automatic logic [4:0] modulo20(input logic [5:0] value);
        if(value>=6'd60) modulo20=5'(value-6'd60);
        else if(value>=6'd40) modulo20=5'(value-6'd40);
        else if(value>=6'd20) modulo20=5'(value-6'd20);
        else modulo20=5'(value);
    endfunction
"""
nh = replace_once(nh, "    integer position;\n", "    integer position;\n" + function)
nh = replace_once(nh, "(int'(tick_mod)+h)%20", "modulo20(6'(tick_mod)+6'(h))")
running = "(int'(tick_mod)+int'(nh_phase))%20"
if nh.count(running) != 3:
    raise ValueError("Unexpected running NH phase expression count")
nh = nh.replace(running, "modulo20(6'(tick_mod)+6'(nh_phase))")
(output / "nh20_sync.sv").write_text(nh, newline="\n")

core = (frozen / "bds_bb_6ch_core.sv").read_text()
core = replace_once(core, "receiver_channel #(.CHANNEL_ID(c))", "receiver_channel #(.CHANNEL_ID(c),.EXPORT_RECORDS(0))")
declarations = """    logic [63:0] predicted_phase_input,phase_distance_input;
    logic [42:0] predicted_phase_remainder,phase_distance_remainder;
    b1i_period_reduce initial_period(.value(code_advance),.quotient(initial_code_epoch),.remainder(initial_code_phase));
    b1i_period_reduce predicted_period(.value(predicted_phase_input),.quotient(),.remainder(predicted_phase_remainder));
    b1i_period_reduce distance_period(.value(phase_distance_input),.quotient(),.remainder(phase_distance_remainder));
"""
core = replace_once(core, "    always_comb begin\n", declarations + "    always_comb begin\n")
core = replace_once(core, "        initial_code_phase=43'(code_advance%64'h7fe00000000);\n        initial_code_epoch=32'(code_advance/64'h7fe00000000);\n", "")
core = replace_once(core,
    "        predicted_phase=(64'(history_phase[search_slot])+\n            (effective_ref-history_ref[search_slot])*64'(history_step[search_slot]))%64'h7fe00000000;\n        phase_distance=(64'(initial_code_phase)+64'h7fe00000000-predicted_phase)%64'h7fe00000000;",
    "        predicted_phase_input=64'(history_phase[search_slot])+\n            (effective_ref-history_ref[search_slot])*64'(history_step[search_slot]);\n        predicted_phase=64'(predicted_phase_remainder);\n        phase_distance_input=64'(initial_code_phase)+64'h7fe00000000-predicted_phase;\n        phase_distance=64'(phase_distance_remainder);")
(output / "bds_bb_6ch_core.sv").write_text(core, newline="\n")
print("PRIVATE_TOP_SOURCES_PREPARED", output)
