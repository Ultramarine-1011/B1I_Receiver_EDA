# 当前状态

2026-11-06：**M1 工具与 TSMC28 预检已完成。** 功能基线仍是 `main` `947d50b` 上的六通道 RTL；本轮没有改 RTL。实验室虚拟机 `IC` 上，VCS I-2014.03、Design Compiler K-2015.06、PATH 中的 `vcd2saif` L-2016.03-SP1 和 DC 内的 Power Compiler 命令可用。`/home/share/libs/tsmc28` 有教师点名的三套标准单元 TT/SS/FF `.db/.lib`，以及 TPHN28HPCPGV18 的 PAD `.db/.lib` 和 Verilog。详细命令和退出码见 [M1 报告](reports/m1_tsmc28_20261106/REPORT.md)。

**结论：有条件 GO。** 可以在新的授权下开始 M2 的 PAD 顶层和受控首次映射。直接综合现有 `bds_bb_6ch_core` 为 NO-GO：DC 忽略 `initial`（VER-281），`$readmemh` 旋转因子不会进入网表；库中没有 SRAM/存储器宏，PCPS/FFT 明确声明的 2,293,056 bit 多端口数组不能在这台 1991 MB、无 swap 的虚拟机上展开。标准单元门级 Verilog 不在该树中，M4 全芯片门级仿真因此还不能做。100 MHz 仍只是功能吞吐候选，不是 ASIC 时序指标。

**唯一下一候选：** 用户另行授权后的 **M2**。进入前先替换可综合 ROM，并把大存储排除或黑盒，再建立 `bds_bb_6ch_pad_top`。本轮停止，不自动进入 M2。
