view wave
delete wave *
add wave /tb_tracking_minimal/window_done /tb_tracking_minimal/feedback_valid
add wave -radix decimal /tb_tracking_minimal/ip /tb_tracking_minimal/qp /tb_tracking_minimal/ie /tb_tracking_minimal/il
add wave -radix decimal /tb_tracking_minimal/dll_error_q16 /tb_tracking_minimal/pll_error_q16
add wave -radix hexadecimal /tb_tracking_minimal/code_step_q /tb_tracking_minimal/carrier_step_word
add wave /tb_tracking_minimal/locked
configure wave -namecolwidth 250 -valuecolwidth 180 -timelineunits us
wave zoom range 29810.220us 29810.300us
puts {DEMO_WAVE_READY_tracking; locked tail: wave zoom range 140000us 160000us}
