# 交接入口

H0 已在虚拟机解压工程完成当前 PRN 的 VCS 回归和 SAED90nm 首次综合，证据见[H0_VM_SMOKE](H0_VM_SMOKE.md)。重复命令是虚拟机上的 `bash scripts/h0_vm_smoke.sh`。完整接收机综合和 ICC 未授权。

G当前可执行交付已完成，证据/分类/缺口见[G最终报告](../reports/g_stage/FINAL_REPORT.md)。复验优先`scripts/rescore_g_evidence.ps1`及`scripts/validate_g_delivery.ps1`，只读取既有结果。长采集`run_g_rtl.ps1`、定向`run_g_tests.ps1`、FIFO`run_g_fifo.ps1`与因果`model/online_navigation.py`保留；不要从旧断点重跑已完成长仿真。设计见[G_PERFORMANCE_DESIGN](G_PERFORMANCE_DESIGN.md)。当前状态和唯一下一任务只见STATUS。

**唯一当前状态与下一条可执行任务：[STATUS.md](../STATUS.md)。** 目标与验收：[GOAL.md](../GOAL.md)。逐任务实际命令、退出码、失败与证据：[WORKLOG.md](../WORKLOG.md)。

9.28历史断点保留于[archive/NEXT_STEPS_2026-09-28.md](archive/NEXT_STEPS_2026-09-28.md)，不再用于驱动新开发。近期执行Windows + WSL Ubuntu + Verilator，教师流契约优先，暂不修复或调用VMware/VCS/DC/ICC/PT。

历史F入口：`scripts/run_f_stage.ps1`（数字/控制/合成），`scripts/run_fast_verilator.ps1`（公开IF），`scripts/validate_f_delivery.ps1`（记录复验），`scripts/run_performance.ps1`（场景/指标）。原模块入口run_local_verilator保留。F证据范围见[最终报告](../reports/f_stage/FINAL_REPORT.md)，唯一后续任务只见STATUS，不自动扩展H/I。
