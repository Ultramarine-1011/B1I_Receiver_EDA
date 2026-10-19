# H0：虚拟机 PRN 功能回归与首次综合

2026-10-16 在 Linux 虚拟机已解压工程 `/home/7901_15/B1I_Receiver_EDA` 上完成。该目录是本阶段唯一源码基线。没有从 GitHub 重新下载、checkout、pull 或 reset。RTL 与 testbench 未修改，因此没有另做实验副本。

重复命令：

```bash
bash scripts/h0_vm_smoke.sh
```

脚本先加载 `$HOME/eda_env.sh`。VCS 在 `work/h0_prn` 启动，使 testbench 中的 `../../tb/vectors/` 仍指向现有 golden。DC 在 `work/h0_dc` 启动。`work/` 不提交；轻量日志在 `reports/local/h0_vm/`。

## 环境

| 项目 | 实际值 |
|---|---|
| 主机 / 用户 | `IC` / `7901_15` |
| 工程 | `/home/7901_15/B1I_Receiver_EDA` |
| 时间 | 2026-10-16 15:16:36 +0800 |
| VCS | `/opt/Synopsys/VCS2014/bin/vcs`，I-2014.03 |
| Design Compiler | `/opt/Synopsys/Synplify2015/bin/dc_shell`，K-2015.06 for linux64，2015-05-28 |
| 库 | `/home/IC/Foundry_Library/Digital/saed90nm_typ.db` |
| 许可证 | `snpslmd` 已在运行；许可证文件可读。两次工具均完成，说明对应 feature 可检出 |
| 库时间单位 | 1 ns |
| 库电容单位 | 1 fF |

未改 `/home/IC/.bashrc`、许可证、网卡或系统安装。虚拟机没有 `git` 可执行文件；`.git` 存在，提交在 Windows 上对同一 HEAD 的工作区完成，不把远端树覆盖回虚拟机。

## 源码

本阶段使用的 RTL、testbench 与向量哈希：

| 文件 | SHA-256 |
|---|---|
| `rtl/b1i_prn_gen.sv` | `0bbede9a3ec59a6c9d6165a3a12157f698cb7f32d8a63ba26d9b01e01de36475` |
| `tb/tb_b1i_prn_gen.sv` | `75532b9f7a708f118773e9f3352b2d4ad66632301d419efbaf69db0b678e8aeb` |
| `tb/vectors/b1i_prn_06.mem` | `3dbea507d1724706fda377d33276f83462bdabe81557d0df13ccba96a8912b99` |
| `tb/vectors/b1i_prn_12.mem` | `7d46e7dcc8b3d57a73a7e67e54435b456fc9fec4b5e6e3f1e0c4ec1138696b92` |
| `tb/vectors/b1i_prn_23.mem` | `37fb841a3c5fd96358c100a69596559e2d869405c9e4f201340d3e798b655829` |
| `tb/vectors/b1i_prn_37.mem` | `370b55e9a5e59ac33aee79b4481e23c53bf569aafa879dc59d257c507b81de22` |
| `tb/vectors/b1i_prn_06_37.mem` | `5d40ad61e94a926318460236ebb5f3dfacbaffe75f2cbcfc1753b42f3e7a2220` |

被测模块是 B1I MEO/IGSO PRN 6–37 的 Gold 码发生器。G1/G2 初相为 `11'b01010101010`。码片在 `chip_enable` 推进 LFSR 之前输出；chip 2045 之后跳过第 2047 个 Gold 码片并回到初相，同时拉高一个周期的 `epoch`。

## VCS

命令，工作目录 `work/h0_prn`：

```text
vcs -sverilog -R ../../rtl/b1i_prn_gen.sv ../../tb/tb_b1i_prn_gen.sv
```

退出码 0。日志 `reports/local/h0_vm/vcs_prn.log` 含 `B1I_PRN_REGRESSION_PASS`。PRN 6–37 共 32 条均打印 `2046 chips and wrap verified`。仿真结束时间 655406000 ps。编译、精化、链接与仿真 CPU 时间见该日志末尾。这是当前解压树的新运行，不沿用 2026-09-28 `eda_project` 的历史日志。

## 实验性约束

约束只用于这次面积和时序观察，不是课程规定时钟，也不是签核约束。

| 约束 | 值 |
|---|---|
| `create_clock` | 名称 `clk`，周期 10 ns，即实验性 100 MHz |
| uncertainty | 0.2 ns |
| 输入延迟 | 1.0 ns，对象为 `load`、`chip_enable`、`prn_select[5:0]` |
| 输出延迟 | 1.0 ns，对象为 `chip`、`chip_index[10:0]`、`configured`、`epoch` |
| 驱动单元 | `INVX1` |
| 输出负载 | 14.08528 fF，等于 4 × `INVX1/INP`（3.52132 fF） |
| 复位 | `rst_n` 设 `set_false_path` |
| 工作条件 | 库默认 `TYPICAL` |
| 线负载 | `enclosed`，模型 `8000` |

`compile` 使用普通编译，没有 `compile_ultra`。脚本是 `scripts/h0_dc_prn.tcl`。

## 综合结果

DC 退出码 0，日志含 `H0_DC_COMPILE_DONE`。`report_constraint -all_violators` 为 “This design has no violated constraints.” 无 black box，无未映射宏单元。

综合前 `check_design` 有一条 LINT-1：单元 `C888` 不驱动任何网络。`compile` 之后的 `check_design` 没有警告文本，命令返回 1。面积与时序取综合后报告。

| 项目 | 数值 |
|---|---|
| 端口 / 网络 / 单元 | 46 / 260 / 189 |
| 组合单元 | 147 |
| 时序单元 | 41 |
| buf/inv | 18 |
| 组合面积 | 1692.979217 |
| 非组合面积 | 1313.280018 |
| 单元面积 | 3006.259234 |
| 线网面积 | 128.208654 |
| 总面积 | 3134.467888 |
| 逻辑级数 | 9 |
| 关键路径延迟 | 1.650 ns |
| 关键路径 slack | 7.150 ns，MET |
| 建立违例路径 | 0 |
| 保持违例 | 0 |

面积是 `saed90nm_typ` 的 `report_area` 数值。已读库头给出时间、电容、电压、电流和泄漏功率单位，没有单独的 `area_unit`。`INVX0` 为 5.5296，`DFFARX1` 为 32.256001，与该教育库以 μm² 计的单元面积一致。

41 个触发器与 RTL 状态对应：G1 11 位、G2 11 位、`active_prn` 6 位、`chip_index` 11 位、`configured` 1 位、`epoch` 1 位。

`report_resources` 列出三个 DesignWare 运算：宽度 6 的 `DW01_cmp2` 两只，分别对应 PRN 上下界比较；宽度 11 的 `DW01_inc` 一只，实现为 `rpl`，对应码片序号加一。网表中的 `b1i_prn_gen_DW01_inc_0` 已映射到 `HADDX1`、`INVX0` 和 `XOR2X1`，不是黑盒。

最长路径起点是 `active_prn_reg[1]`（`DFFARX1`），终点是输出 `chip`。数据到达 1.650 ns，要求时间 8.800 ns，slack 7.150 ns。路径经过 G2 相位选择的 NOR、INV、OA、MUX 和 XOR。第二条路径从 `load` 到 `g1_state_reg[3]`，slack 7.637 ns。

网表与约束副本：

- `reports/local/h0_vm/b1i_prn_gen_saed90nm.v`
- `reports/local/h0_vm/b1i_prn_gen_saed90nm.sdc`
- `reports/local/h0_vm/dc_area.rpt`
- `reports/local/h0_vm/dc_resources.rpt`
- `reports/local/h0_vm/dc_timing.rpt`
- `reports/local/h0_vm/dc_qor.rpt`

## 边界

这次只证明当前 PRN RTL 在 VCS I-2014.03 上功能自检通过，并在 SAED90nm typical、10 ns 实验时钟和约 14.1 fF 输出负载下可映射且建立/保持无违例。它不是全接收机综合，不是多角 PVT，不是物理实现，也没有用综合后门级网表回放 golden。线负载模型 `8000` 对这个小模块偏大，面积中的线网项是该模型的估计。

下一阶段需另行授权。建议仍以本解压树为基线，按模块扩展 VCS 与 DC；不直接做完整接收机综合或 ICC 布局布线。
