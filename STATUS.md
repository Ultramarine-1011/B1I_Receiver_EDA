# 当前状态

2026-11-06：**M2 已完成，M3 为 NO-GO。** 正式改动在 `main`，起点 `8c9113a`。`h0-checkpoint` 的未提交修改没有并入。

`bds_bb_6ch_pad_top` 已用 TPHN28HPCPGV18 的 8 mA 焊盘接上 16 个输入和 25 个输出。VCS 连接检查 `M2_PAD_CONNECT_PASS`。PCPS/FFT 旋转因子改为与原 mem 一致的 function；VCS FFT 三例逐点 PASS。隔离 2,293,056 bit 捕获存储后，PAD 顶层能 link，`check_design` 把空的 `acquisition_pcps` 标成无单元设计。六通道 `compile` 之后的面积报告被杀掉（退出 137）。一个跟踪通道的 80 位除法被 DC 识别，但 34 分钟后进度表不再变化，没有最终时序报告。

**唯一下一候选：** 用户另行授权，并且换到至少 8 GB 内存、带 swap 的主机之后，才做 M3 的完整映射。不要在这台虚拟机上展开捕获存储，也不要启动 SDF 后仿。细节见 [M2 报告](reports/m2_tsmc28_20261106/REPORT.md)。
