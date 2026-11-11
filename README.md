# 北斗 B1I 接收机 EDA 工作区

这里保存课程正式工程、本地探索实验、验证证据和实验室交付包。开始接手先读 [STATUS](STATUS.md) 与 [GOAL](GOAL.md)，实际命令和退出码见 [WORKLOG](WORKLOG.md)。

| 要找的内容 | 入口 |
|---|---|
| 正式课程工程 | 本目录唯一 Git 仓库的 `main`，当前正式提交 `fb662d3`。核心源在 [student_release/student_release/rtl](student_release/student_release/rtl)、[rtl](rtl)，课程范围见 [COURSE_MASTER_PLAN](docs/COURSE_MASTER_PLAN.md) |
| 当前本地实验 | 分支 `codex/ic-eda-personal-local-smoke-20261110`，最新技术结果 `c3ba596`，见 [当前实验](experiments/active/README.md) |
| 最新综合网表、DDC 和时序 | [后端单通道 fast_v6_channel](experiments/ic_eda_20261111_backend/evidence/fast_v6_channel/reports) 的 `mapped.v`、`mapped.ddc`、`mapped.sdc`、`area.rpt`、`timing_max.rpt`、`timing_min.rpt`，方法见 [报告](experiments/ic_eda_20261111_backend/REPORT.md) |
| V6 原始映射与重建结果 | [原始 V6](experiments/ic_eda_20261110/night_opt/REPORT.md)、[重建 V6](experiments/ic_eda_20261111_backend/evidence/clean_v6_channel/reports)，大文件恢复清单见对应报告 |
| 实验室携带包与命令 | [deliverables/2026-11-11_backend_lab](deliverables/2026-11-11_backend_lab/README.md)、[LAB_RUNBOOK](experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md) |
| 历史实验与旧资料 | [历史实验索引](experiments/archive/README.md)、[资料与缓存归档](archive/README.md)、[历史目标](docs/archive) |
| 整理记录与回退方法 | [2026-11-11 整理报告](reports/local/workspace_organization_20261111/README.md) |

正式源和本地实验共用一个 checkout，实验 RTL 位于 `experiments/`。Windows 编辑源、WSL Ubuntu/Verilator 轻量回归、VMware/Synopsys 实验各有原路径。两层同名工作区和教师包内层路径继续保留，桌面 `DIC_EDA` 下新增友好入口。

当前 TSMC90 单通道映射完成且仍有时序违例，六通道映射已超时。TSMC28 正式全量结果等待实验室库、模型和存储实现。软件工具与机器记录见 [EDA_ENV_STATUS](EDA_ENV_STATUS.md)。
