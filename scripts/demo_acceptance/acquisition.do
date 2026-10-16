view wave
delete wave *
add wave -radix unsigned /tb_p02_probe/coarse_valid /tb_p02_probe/coarse_detected /tb_p02_probe/prn
add wave -radix unsigned /tb_p02_probe/coarse_lag /tb_p02_probe/coarse_peak /tb_p02_probe/coarse_mean
add wave -radix decimal /tb_p02_probe/coarse_doppler
add wave -radix unsigned /tb_p02_probe/fine_valid /tb_p02_probe/fine_detected /tb_p02_probe/fine_lag
add wave -radix decimal /tb_p02_probe/fine_doppler
add wave -radix unsigned /tb_p02_probe/fine_peak
configure wave -namecolwidth 250 -valuecolwidth 180 -timelineunits us
wave zoom range 9620.350us 9620.460us
puts DEMO_WAVE_READY_acquisition
