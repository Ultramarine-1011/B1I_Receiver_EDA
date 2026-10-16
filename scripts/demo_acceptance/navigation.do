view wave
delete wave *
add wave -radix unsigned /tb_navigation_d1/nh_valid /tb_navigation_d1/nh_phase
add wave /tb_navigation_d1/dut/word_valid
add wave -radix unsigned /tb_navigation_d1/dut/word_number /tb_navigation_d1/dut/sow
add wave /tb_navigation_d1/frame_valid /tb_navigation_d1/time_valid /tb_navigation_d1/record_valid /tb_navigation_d1/record_ready
add wave -radix hexadecimal /tb_navigation_d1/record_data
configure wave -namecolwidth 250 -valuecolwidth 180 -timelineunits us
wave zoom range 1537.370us 1537.660us
puts DEMO_WAVE_READY_navigation
