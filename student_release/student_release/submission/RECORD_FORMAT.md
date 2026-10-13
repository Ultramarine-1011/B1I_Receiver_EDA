# receiver_records_32byte_le_v1格式

`receiver_tb_template.sv`会把学生RTL输出的`record_data[255:0]`按小端序写入文件。每次`record_valid && record_ready`握手产生一条32字节记录。

公共字段：

```text
bits 7:0      record_type
bits 13:8     PRN编号
bits 17:14    channel_id
bits 95:32    sample_index
```

记录类型：

```text
1 tracking
2 navigation
3 lost
4 common_observation
5 acquisition
6 end
```

## type=1 tracking

```text
bit 18       locked
bit 19       nh_valid
bit 20       frame_valid
bit 21       time_valid
bits 31:24   generation/schema标志
bits 119:96  signed Prompt I
bits 143:120 signed Prompt Q
bits 175:144 signed doppler_word
bits 207:176 carrier_phase
bits 231:208 code_fraction高24位
bits 242:232 code_chip
bits 255:243 code_epoch低13位
```

## type=2 navigation

```text
bit 18       locked
bit 19       nh_valid
bit 20       frame_valid
bit 21       time_valid
bit 22       bch_valid
bits 31:24   generation
bits 125:96  raw_word
bits 151:126 information
bits 155:152 word_number
bits 158:156 subframe_id
bits 178:159 sow
bits 180:179 corrected_bits
bits 196:181 code_epoch
bits 207:197 code_chip
bits 239:208 code_fraction
```

## type=3 lost

使用公共字段表示失锁的PRN、通道、代次和样本位置。实现时应在记录中保留失锁状态，不能继续把旧通道数据标记为有效。

## type=4 common_observation

```text
bit 18       locked
bit 19       nh_valid
bit 20       frame_valid
bit 21       time_valid
bit 22       measurement_valid
bit 23       active
bits 31:24   schema_version
bits 127:96  common_epoch_id
bits 143:128 generation
bits 159:144 code_epoch
bits 170:160 code_chip
bits 202:171 code_fraction
bits 234:203 signed doppler_word
bits 254:235 sow
bit 255       bch_valid
```

只有锁定、NH、帧、时间以及所需导航有效条件满足时，`measurement_valid`才能置1。

## type=5 acquisition

```text
bit 18       detected
bit 23       incomplete
bits 109:96  lag_samples
bits 159:128 signed doppler_word
bits 223:160 peak_power
bits 255:224 acquisition_cycles
```

## type=6 end

```text
bits 95:32   完整输入样本数
bit 18       underrun
bit 19       overflow
bits 159:96  hardware_cycles（可选）
bits 223:160 missing_ticks（可选）
```

最后一条记录必须是唯一的`type=6`记录，`underrun`和`overflow`必须为0。
