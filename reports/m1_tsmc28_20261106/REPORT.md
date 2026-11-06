# M1：VMware 工具与 TSMC28 工艺库预检

日期：2026-11-06。主机 Windows，检查在既有虚拟机 `IC`（`7901_15@192.168.159.128`）完成。功能基线 `main` `947d50b`。没有修改 RTL，没有对 `bds_bb_6ch_core` 做 analyze/compile，没有跑 ICC。

## 结论

**有条件 GO。** Design Compiler、VCS、`vcd2saif` 和 DC 中的 Power Compiler 命令可用；教师点名的 TT/SS/FF 标准单元库和 TPHN28 PAD 的 `.db/.lib`、PAD Verilog 都在 `/home/share/libs/tsmc28`。这些资源足够开始 `bds_bb_6ch_pad_top` 和一次受控的库加载。

**直接综合现有六通道 RTL：NO-GO。** 两件必须在首次全芯片 compile 之前处理：

1. DC K-2015.06 对 16 项 `$readmemh` 探针给出 `VER-281`，`initial` 被忽略，网表只剩一个 `TIELBWP40P140`（面积 0.252）。FFT 旋转因子使用同一写法，按原样综合会丢内容。
2. 该树没有 SRAM 或存储器宏。PCPS 与 FFT 明确声明的数组合计 2,293,056 bit，且同拍多端口。虚拟机内存 1991 MB、swap 0，不能把这些数组展开成寄存器。

标准单元门级 Verilog 不在这棵树里。PAD 可以做门级仿真，全芯片 SDF 后仿还缺标准单元仿真模型。这挡住 M4，不挡住使用 `.db` 的 DC。

## 1. 工具与许可

| 工具 | 路径 | 结果 |
|---|---|---|
| VCS | `/opt/Synopsys/VCS2014/bin/vcs` | `vcs -ID` 退出 0，Compiler `I-2014.03`。本轮没有重新编译 |
| `dc_shell` | `/opt/Synopsys/Synplify2015/bin/dc_shell` | 版本横幅 `K-2015.06`，2015-05-28。`dc_shell -version` 退出 1，但仍打印版本。`dc_shell -f` 空脚本退出 0 |
| Power Compiler | 同一 `dc_shell` | 启动横幅含 Power Compiler。`report_power` 命令存在；无设计时报告 `UID-4`，不是许可证拒绝。脚本退出 0 |
| `vcd2saif` | `/opt/Synopsys/ICC2016/bin/vcd2saif` | `L-2016.03-SP1`。`-help` 退出 1。改正后的 20 ns 小 VCD 转换退出 0，SAIF 309 字节，时标 1 ns |
| `icc2_shell`、`pw_shell` | 不在 PATH | 本阶段不需要 ICC2。功耗入口是 DC 的 `report_power` |

`lmgrd` 与 `snpslmd` 在运行，`/opt/Synopsys/License/License.dat` 可读。本轮没有打印许可证文件。小 ROM 探针实际加载了 `tcbn28hpcplusbwp40p140tt0p9v25c.db`，会话峰值 475 MB。

日志：[precheck_stage1.txt](precheck_stage1.txt)、[precheck_stage3.txt](precheck_stage3.txt)、[precheck_stage4.txt](precheck_stage4.txt)。

## 2. TSMC28 与 PAD

安装根目录 `/home/share/libs/tsmc28` 存在。`logic/selected_db/` 中三份标准单元库各约 20 MB：

| 角 | 文件名中的条件 | 已打开的 liberty 属性 |
|---|---|---|
| TT | `tt0p9v25c` | `nom_voltage 0.9`，`nom_temperature 25`，`operating_conditions("tt0p9v25c")` |
| SS | `ssg0p81v125c` | `.db` 与 `.lib` 都在；本轮没有逐项再读 SS 标称值 |
| FF | `ffg0p99vm40c` | `.db` 与 `.lib` 都在；本轮没有逐项再读 FF 标称值 |

对应 `.lib` 在 `logic/nldm/extracted/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/`。标准单元时间单位 1 ns，电容单位 1 pF，`default_max_transition` 0.628。

PAD 系列是安装说明中的 **TPHN28HPCPGV18**，内核 0.9 V、I/O 1.8 V。与标准单元三角对齐的时序库是：

- `tphn28hpcpgv18tt0p9v1p8v25c.db/.lib`，liberty `nom_voltage 1.8`，`nom_temperature 25`，条件名 `tt0p9v1p8v25c`
- `tphn28hpcpgv18ssg0p81v1p62v125c.db/.lib`
- `tphn28hpcpgv18ffg0p99v1p98vm40c.db/.lib`

路径在 `pad/timing_nldm/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn28hpcpgv18_170a/`。PAD liberty 的时间单位也是 1 ns，电容单位 1 pF。

仿真模型只有两份 Verilog，都在 `pad/simulation_vlg/.../tphn28hpcpgv18_110a/`：`tphn28hpcpgv18.v` 与 `tphn28hpcpgv18_pwr.v`。安装说明写明 109 个 I/O 单元有 Verilog，14 个转角/填充只有物理视图。数字双向单元（`PDDW`/`PDUW`/`PRDW`/`PRUW`，驱动 04/08/12/16，含 H/V）的信号端口是 `I`、`OEN`、`REN`、`PAD`、`C`；带电源视图另有 `POC`、`VDD`、`VSS`、`VDDPST`、`VSSPST`。电源/地与上电控制单元包括 `PVDD1DGZ_H_G`、`PVSS1DGZ_H_G`、`PVDD2POC_H_G`，liberty 中能找到同名 cell。

`bds_bb_6ch_core` 需要 16 个输入焊盘和 25 个输出焊盘：`clk`、`rst_n`、`IF[1:0]`、`if_valid`、`cfg_*`，以及 `if_ready` 和四组 6 位状态/数据。加上内核/IO 电源、地和 POC，现有单元种类够构成 `bds_bb_6ch_pad_top`。`OEN`/`REN` 的有效电平本轮没有从 databook 核定，M2 绑定时要读对应 pin function。驱动档和 H/V 仍是可选参数。

整棵树中 `.v/.sv` 只有上述 2 个 PAD 文件，`logic` 下 Verilog 计数为 0，也没有 `.vg/.gv`。工艺树里的 `.sdf` 计数为 0；SDF 仍要由以后的 `write_sdf` 产生。`find` 名称匹配没有 SRAM、memory 或 RF 宏。

## 3. 综合结构

声明位数与源码一致，合计 **2,293,056 bit**：

| 对象 | 计算 |
|---|---|
| `raw[0:65471]` × 3 | 196,416 |
| `base_r/i[0:16367]` × 16 × 2 | 523,776 |
| `code/signal` 四组 `[0:4095]` × 32 | 524,288 |
| PCPS `cosine/sine` × 32 | 262,144 |
| `accumulated_power` × 64 | 262,144 |
| FFT `re/im/cosine/sine` × 32 | 524,288 |

FFT 在一个周期读 `a`/`b` 两地址并写回两地址，同时按 `read_address` 异步读；PCPS 对 `raw[replay_address]` 异步读。单口或双口同步 SRAM 不能原样代替这些端口。宽除法在 `tracking_channel_minimal` 的 80 位除法和导航/帧的 64 位除法里，复位包含 `rst_n` 异步低有效，以及 `search_reset_n`、`channel_reset_n` 组合撤销。这些是面积和时序风险，不是本轮新的库缺失。

ROM 探针是 `/tmp` 中的 16×32 异步读 ROM，目标库为 TT `.db`。`dc_shell` 退出 0，日志有 `VER-281`。mem 文件内容是 `0`–`F`，结果却是常数 0 的 tie 单元。`acquisition_pcps` 与 `fft4096_serial` 的 `initial $readmemh(...)` 在首次有意义的 DC 之前要改成该工具会保留的常数或 ROM 写法。

## 4. 约束：已规定、已验证、仍待选

| 项目 | 归属 |
|---|---|
| 标准单元 TT 0.9 V / 25 °C，PAD TT 记录的标称电压 1.8 V / 25 °C；SS/FF 文件名给出 0.81 V/125 °C 与 0.99 V/−40 °C，PAD 文件名另含 1.62 V 与 1.98 V I/O | 库文件与安装说明已给出。SS/FF 的 liberty 标称行本轮未逐份打开 |
| 时间单位 1 ns，电容单位 1 pF；标准单元 `default_max_transition` 0.628 ns | TT liberty 已读到。PAD 的 max transition 未单独摘出 |
| Fs = 16.368 MHz，IF = 4.092 MHz | 功能设计已用 |
| 逻辑时钟 100 MHz、10 ns，0.4 s 定速输入无反压 | 零延迟功能测试候选。不是 TSMC28 STA 结果，不能写入已满足的周期约束 |
| 输入/输出延迟、输入转换、输出负载、驱动档、复位恢复/移除 | 教师材料和本轮库检查都没有给定数值。H0 的 SAED90nm 14.08528 fF 属于另一套库，电容单位还是 1 fF，不能套用 |
| `OEN`/`REN`/POC 绑法，PAD 驱动 4/8/12/16 mA 与 H/V | 单元存在，具体选择留到 M2 |

M2 的试验 SDC 可以把 10 ns 标成候选周期，并显式写出 IO 延迟；在读到 PAD pin 电容之前，不要填一个冒充工艺负载的常数。

## 5. M2 最短路径

1. 得到新的 GOAL 授权后再改代码。
2. 替换两处 `initial $readmemh`，用同一 DC 对一个非零地址做小编译，确认输出不是常数 0。
3. 首次 compile 不展开 PCPS/FFT 大数组：黑盒或先不编译 `acquisition_pcps`/`fft4096_serial` 的存储。虚拟机没有 swap，全展开会超出 1991 MB。
4. 新建 `bds_bb_6ch_pad_top`，逐位连接 41 个功能 PAD，并例化 `PVDD`/`PVSS`/`PVDD2POC`。先读 liberty pin function 再绑 `OEN`、`REN`、`POC`。
5. `target_library` 用标准单元 TT `.db`，`link_library` 加上 `tphn28hpcpgv18tt0p9v1p8v25c.db`。先看 analyze、elaborate、link、`check_design`。通过后再谈面积和时序。
6. 标准单元 Verilog 补齐之前，不把全芯片 SDF 后仿列为可执行项。

## 6. 本轮边界

教师三份原件不在这台 Windows 工作副本里。已记录的文件名和 SHA-256 仍在 [stimulus_and_waveforms.json](../six_channel_20261102/stimulus_and_waveforms.json)：综合要求 PDF `1c5caddb…d1f8e6`（123,948 字节），功耗说明 PDF `44b2a3ff…b7fe5a`（114,351 字节），`tsmc28_学生使用说明.docx` `6ae6e6b5…69654f`（44,479 字节）。库路径与 `947d50b` 设计说明一致，并在虚拟机上找到了对应文件。

第一次 SSH 在客体地址进入 ARP 之前超时；随后 ping 与 SSH 退出 0。未改网卡、`/home/IC/.bashrc`、许可证或系统安装。便携工作区里原有未提交修改留在 `h0-checkpoint`，没有并入本次提交。
