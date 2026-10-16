view wave
delete wave *
add wave /tb_nh_d1/nh_locked
add wave -radix unsigned /tb_nh_d1/nh_phase /tb_nh_d1/bit_valid /tb_nh_d1/data_bit /tb_nh_d1/word_valid /tb_nh_d1/word_number
add wave -radix hexadecimal /tb_nh_d1/raw_word /tb_nh_d1/information
add wave -radix unsigned /tb_nh_d1/corrected_bits /tb_nh_d1/bch_valid
configure wave -namecolwidth 250 -valuecolwidth 180 -timelineunits us
wave zoom range 19.5us 25us
puts DEMO_WAVE_READY_nh
