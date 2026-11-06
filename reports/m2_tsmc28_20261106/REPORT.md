# M2：六通道 PAD 顶层与首次 DC 可综合性验证

日期：2026-11-06。Windows 正式工程从 `main` `8c9113a` 改起。综合和 VCS 在虚拟机 `IC`（`7901_15@192.168.159.128`）上执行，Design Compiler K-2015.06，VCS I-2014.03。标准单元库 `tcbn28hpcplusbwp40p140tt0p9v25c`，PAD 库 `tphn28hpcpgv18tt0p9v1p8v25c`。`h0-checkpoint` 上原有未提交修改没有并入。

## 结论

**当前这台虚拟机不能进入 M3。判定为 NO-GO。**

PAD 顶层和旋转因子 ROM 已经按真实库做完，并有功能证据。六通道顶层在隔离捕获存储之后能够 elaborate、link，`check_design` 也写出来了。随后的面积报告被系统杀掉。单独映射一个带 FLL 和载波辅助的跟踪通道时，80 位除法被 DC 认成 DesignWare 除法器，但 34 分钟后面积和进度表不再变化，最终 `report_timing` / `report_area` 没有写出。这不是六通道综合通过，也不是时序收敛。

M3 需要一台内存明显高于这次峰值的机器，并且先保持捕获存储不展开。本轮没有改捕获算法，也没有做 SDF 后仿。

## 1. ROM

M1 的 `initial $readmemh` 在这次又复现了。16×32 的非零表，地址 1 应为 `32'h000001A5`，地址 15 应为 `32'h80000001`。四种写法在同一 TT 库上 `compile` 后，映射网表里的常数是：

| 写法 | 地址 1 | 地址 15 | 总单元面积 |
|---|---|---|---|
| `initial $readmemh` | 常数 0（面积 0.252，一个 `TIEL`） | 常数 0 | 0.252000 |
| `always @(*)` case | `0x000001A5` | `0x80000001` | 22.176000 |
| function 内 case | `0x000001A5` | `0x80000001` | 22.176000 |
| 打包 `parameter` 再做变址 | `0x000001A5` | `0x80000001` | 16.758000 |

面积与小 ROM 网表里的 `TIELBWP40P140`（0.252）使用同一套库单位。`case` 和 function 的映射结果相同。function 可以让 PCPS 和 FFT 共用一张表，因此正式 RTL 采用 function。打包 parameter 更小，但 4096 项的单张参数不利于和现有查表调用对齐。

`student_release/student_release/rtl/fft_twiddle_rom.svh` 由 `rom/fft_cos_q30.mem` 与 `rom/fft_sin_q30.mem` 生成，4096 个 Q30 数值没有改。对真实表的 8 个常数地址再做一次映射，面积 0.504000，网表常数为：

| 地址 | cos | sin |
|---|---|---|
| 0 | `0x40000000` | `0x00000000` |
| 1 | `0x3ffffb11` | `0x001921fb` |
| 2048 | `0xc0000000` | `0x00000000` |
| 4095 | `0x3ffffb11` | `0xffe6de05` |

与 mem 文件对应行一致。VCS 用这张表跑了原 FFT 自检三例：每例 24576 拍，`FFT4096_PASS outputs=12288 bit_exact=1`。这是功能回归通过。它不表示 4096×32 的整张 ROM 已经被映射成门；常数地址被折叠成 tie，整表面积没有在这次测量。

## 2. PAD 顶层

`rtl/bds_bb_6ch_pad_top.sv` 例化 `bds_bb_6ch_core`。16 个功能输入和 25 个功能输出的位序与核心一致：`IF[1:0]`、`cfg_channel[2:0]`、`cfg_prn[5:0]`，以及槽 0 在 `[0]`、槽 5 在 `[5]` 的四组 6 位输出。

极性来自 `tphn28hpcpgv18_pwr.v` 和 TT liberty，不是假设：

- `OEN` 低有效。模型是 `bufif0 (PAD_q, I, OEN)`，liberty 上 `I -> PAD` 为负单端相关于 `OEN`。输入焊盘 `OEN=1`，输出焊盘 `OEN=0`。
- `REN` 低有效。`not (RE, REN)` 之后才打开弱上/下拉；liberty 写 `pull_down_function : "!REN"` 或 `pull_up_function : "!REN"`。输入 `REN=0`，输出 `REN=1`，避免弱拉和驱动争用。
- `primitive_poc` 的表是：`VDD=1, VSS=0, VDDPST=1` 时 `POC=0`；`VDD=0, VSS=0, VDDPST=1` 时 `POC=1`。正常工作时 POC 为 0。`HZ = ~VDD & VDDPST & POC`，只有核心掉电且 POC 为 1 时才把驱动关成高阻。
- 电源单元是 `PVDD1DGZ_H_G`、`PVSS1DGZ_H_G`、`PVDD2POC_H_G`。功能焊盘是 8 mA、水平、非施密特的 `PDDW08DGZ_H_G`；`rst_n` 用 `PDUW08DGZ_H_G`，悬空时被拉到 1，不会停在复位。8 mA 是本轮候选，不是签核驱动档。

DC 链接到的逻辑引脚只有 `I`、`OEN`、`REN`、`PAD`、`C`。`POC/VDD/VSS/VDDPST/VSSPST` 在 liberty 里是 `pg_pin`。带电源端口的探针和只连信号端口的探针都能 link 到同一 `PDDW08DGZ_H_G`。因此 SDC 不再对这四个电源口调用 `get_ports`；第一次这样写得到 `UID-95`。时钟建在 `inout pad_clk` 上，工具给出 `UID-376`。

候选 SDC 在 `constraints/bds_bb_6ch_pad_top_m2.sdc`。周期 10 ns 明确是候选，不是签核周期。PAD liberty 的 `default_max_transition` 是 5.0 ns，`PDDW08` 的 `PAD->C` 在表的第一项是 0.5165 ns，PAD 脚 `max_capacitance` 是 100 pF。外部输入转换取 0.5 ns，输入/输出延迟取 2.0 ns（周期的 20%），输出负载取 5 pF。这些数都在库给出的范围内，仍然是候选，不是板级规格。

VCS 使用 `tphn28hpcpgv18_pwr.v`，并且只指定顶层 `tb_bds_bb_6ch_pad`。不指定顶层时，未例化的库单元也会在 0 时刻执行 `$stop`。指定顶层后，PRN 37（`6'b100101`）的输入位序、复位/时钟、POC=0，以及强制的六槽输出 `capture_ok=100101`、`bit_sync_ok=011010`、`nav_data=111000`、`nav_valid=000111` 都传到对应焊盘。日志有 `M2_PAD_CONNECT_PASS`。这是焊盘连接检查，不是捕获或跟踪功能仿真。

## 3. 首次 DC 实际跑到哪里

脚本是 `scripts/m2_dc_pad.tcl`。捕获存储用 `synth/m2_isolate/acquisition_pcps_blackbox.sv` 替换正式 `acquisition_pcps`，因此 `fft4096_serial` 也不会被展开。这个空模块只出现在该综合文件列表里，功能仿真仍用原来的 PCPS。`satellite_manager` 不在这条层次里；若把它放进 analyze，`$countones` 会报 `ELAB-939`。

隔离后的 `bds_bb_6ch_pad_top`：

- analyze、elaborate、link 完成。link 使用上述 TT 标准单元库和 PAD 库。
- 实例 `core/acquisition` 的参考名是带参数的 `acquisition_pcps_..._CONFIGURED_PRN1`。
- `check_design` 对这个空设计给出 `LINT-55`：没有单元也没有网。这就是本轮的黑盒。它代表未综合的 PCPS/FFT，包括 2,293,056 bit 多端口存储和旋转因子在捕获路径中的使用。旋转因子本身已在第 1 节单独映射。
- link 之后、`compile` 之前，`free` 显示 buffers/cache 口径已用 1153 MB，可用 837 MB。
- `compile -map_effort low` 被 K-2015.06 改成 medium（`OPT-1303`）。返回值是 0，紧接着的 `check_design`/`report_area` 使进程被杀掉，退出码 137。没有留下六通道面积、QoR 或时序报告。

所以：**PAD 顶层可解析、可 link、有 check_design；没有六通道映射面积和时序。** 不能写成综合通过。

## 4. 宽运算和这台虚拟机

`scripts/m2_dc_channel.tcl` 只 elaborate 一个 `tracking_channel_minimal`，参数与六通道核心相同：`ENABLE_FLL=1`、`ENABLE_CARRIER_AID=1`。`current_design` 用未加参数的名字会报 `UID-109`，当前设计实际是 `tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1`，link 和 compile 都在这个设计上进行。

DC 列出的除法器包括：

- `DW_div_tc_a_width80_b_width64`（对应跟踪环里的 80 位除法）
- `DW_div_tc_a_width76_b_width59`
- `DW_div_tc_a_width64_b_width25`
- `DW_div_tc_a_width64_b_width11`
- `DW_div_tc_a_width33_b_width11`

compile 前已用约 894 MB。映射过程中升到约 1627 MB，机器总共 1991 MB 且没有 swap。进度表在 34 分 25 秒停在面积 133831.2、worst-slack 列 +115.01、setup cost 32047.3，终点 `code_step_q_reg[32]/D`，之后不再变化。该表的 slack 列和 setup cost 同时存在，又没有最终 `report_timing`，因此不能把 +115.01 说成时序满足或违例纳秒数。进程随后被停掉，避免它占满这台没有 swap 的虚拟机。单通道也没有最终面积/时序报告文件。

由此得到的资源判断是：

- 2 GB、无 swap 的虚拟机完不成六通道映射，也没有在合理时间内写完一个跟踪通道的最终报告。
- 单通道映射已经把可用内存压到约 360 MB。六通道是六个这样的通道，再加导航、精搜和 PAD。下一台机器需要明显高于 2 GB；按这次单通道峰值，至少应准备 8 GB 并打开 swap，再尝试完整映射。这是由本次峰值推出的下限，不是已在 8 GB 机器上验证过的配置。
- 捕获数组仍不能在这台机器上展开成寄存器。库里没有 SRAM 宏。FFT 同拍读两个地址、写两个地址，另有异步 `read_address`；PCPS 对 `raw` 异步读。单口同步 SRAM 不能原样替换这些端口。

## 5. 完整综合的最低代价路径

保留现在的六通道功能 RTL，不重写 PCPS/FFT 算法。综合文件列表继续把 `acquisition_pcps` 换成实验黑盒，直到有更大的机器。旋转因子保持这次的 function，不再使用 `$readmemh`。

下一阶段若要做完整网表，顺序应是：

1. 换到至少 8 GB 内存的主机，先把隔离存储之后的六通道 PAD 顶层 `compile` 跑完，拿到面积和四类路径。这一步仍然不是带捕获存储的完整芯片。
2. 跟踪环的 80 位组合除法是面积和时序的主要风险。只有在第 1 步的真实报告出来之后，才决定要不要把除法改成每窗迭代，而不是现在就改算法。
3. 捕获存储单独处理。在没有多端口宏之前，最低代价是继续把该模块隔离，并在报告里保持“未综合”。若以后把数组改成同步单口/双口，必须同时改 FFT/PCPS 的拍数并重跑功能回归。本轮没有做这件事。

## 6. 分项状态

| 项目 | 状态 |
|---|---|
| 旋转因子数值与 FFT 三例 | 功能 PASS |
| 小型 ROM 与 8 个真实常数地址进入映射网表 | PASS |
| 16 输入 / 25 输出 PAD 连接、位序、POC/OEN/REN | VCS PASS |
| 隔离存储后的 PAD 顶层 link 与 check_design | 完成 |
| 六通道映射面积和时序 | 未完成，进程退出 137 |
| 单通道最终面积/时序报告 | 未完成；只有优化进度表 |
| 2,293,056 bit 捕获/FFT 存储 | 未综合，黑盒 |
| 完整六通道综合、时序收敛、SDF | NOT_RUN |

证据目录：[reports/m2_tsmc28_20261106](.)。复现入口是 `scripts/m2_dc_rom_probe.tcl`、`scripts/m2_dc_twiddle.tcl`、`scripts/m2_dc_pad.tcl`、`scripts/m2_dc_channel.tcl`，以及虚拟机上对 `tb/tb_fft4096.sv`、`tb/tb_bds_bb_6ch_pad.sv` 的 VCS。
