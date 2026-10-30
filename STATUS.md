# 当前状态

2026-10-30：已将 EDA 后续 M0–M5 规划和真实缺口统一写入 [课程里程碑路线图](docs/COURSE_MASTER_PLAN.md#后续里程碑路线图2026-10-30)。本次仅更新规划和交接文档，没有运行 EDA、修改 RTL 或自动开启下一阶段。

功能基线为 `main` `697ebaa`（E100 真实教师 IF/self_check/Route A，F 多槽，G 部分正式性能评价）；H0 PRN VCS/DC 已完成。H1 证据位于独立 [`h1-frontend`](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/tree/h1-frontend) 的 `c71c623`：[VCS 两项 PASS，d1_word_sync 部分 DC，nh20_sync INTERRUPTED，navigation_d1 NOT_RUN](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md)。正式 12 通道整机综合、ICC、最终 STA、DRC/LVS 均未完成；P01–P09 正式性能缺口见 [G 报告](reports/g_stage/FINAL_REPORT.md)。

当前决策缺口：教师最新后端验收范围、完整物理库/宏/规则可用性，及整机存储与宽运算的综合可实现性。原实验室 `h0-checkpoint` 搬迁修改保留且已备份，未并入本次更新。

下一可执行任务：**等待用户授权 M0（验收范围核对与后端版本冻结）**；随后 M1 物理工具资源预检。不得仅凭本路线图运行长综合、ICC 或重构正式 RTL。
