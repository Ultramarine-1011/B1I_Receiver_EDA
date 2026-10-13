# 交接入口

**唯一当前状态与下一条可执行任务：[STATUS.md](../STATUS.md)。** 目标与验收：[GOAL.md](../GOAL.md)。逐任务实际命令、退出码、失败与证据：[WORKLOG.md](../WORKLOG.md)。

9.28历史断点保留于[archive/NEXT_STEPS_2026-09-28.md](archive/NEXT_STEPS_2026-09-28.md)，不再用于驱动新开发。近期执行Windows + WSL Ubuntu + Verilator，教师流契约优先，暂不修复或调用VMware/VCS/DC/ICC/PT。

本机F入口：`scripts/run_f_stage.ps1`（数字/控制/合成），`scripts/run_fast_verilator.ps1`（公开IF），`scripts/validate_f_delivery.ps1`（记录复验），`scripts/run_performance.ps1`（场景/指标）。原模块入口run_local_verilator保留。F证据范围见[最终报告](../reports/f_stage/FINAL_REPORT.md)，唯一后续任务只见STATUS，不自动扩展G/H/I。
