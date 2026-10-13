# 北斗 B1I 接收机 EDA 项目

本仓库包含 B1I 基带接收机的 RTL、参考模型、自检 testbench、公开接口适配、实验报告和可追溯回归证据。近期交付范围及当前唯一状态见 [GOAL.md](GOAL.md) 与 [STATUS.md](STATUS.md)，事件日志见 [WORKLOG.md](WORKLOG.md)。

## 当前状态

捕获、跟踪、NH/D1 模块与报告的最低交付已完成。学生 RTL 可通过教师入口编译并完成 0.01 s 输入冒烟；教师完整 `self_check` 仍失败，接收机顶层集成尚未完成，不能将本仓库描述为完整定位接收机通过。

## 本地复现

在 Windows PowerShell 中，从仓库根目录运行：

```powershell
.\scripts\run_local_verilator.ps1 -Task nhd1
```

本工程使用 WSL2 Ubuntu、Verilator、g++、make 和 Python。各任务入口见脚本参数及 [STATUS.md](STATUS.md)。工具版本与环境实测记录在 [EDA_ENV_STATUS.md](EDA_ENV_STATUS.md)。

## 教师场景文件

教师公开包中的 409,200,000 字节 `scenario.if2` 不在 Git 中。需从课程发布包取得后放到 `student_release/student_release/input/scenario.if2`；公开输入契约 `input_contract.json`、仿真模板、接口、工具和学生 RTL 均在仓库中。该文件未被复制、修改或上传。

## 目录

- `rtl/`, `model/`, `tb/`: 基线 RTL、参考模型、自检和向量
- `student_release/student_release/rtl/`: 学生接收机及模块实现
- `docs/`: 架构、模块设计与交付报告
- `reports/`: 回归日志、数值结果、图表和来源/交付清单
- `scripts/`: 本机 Verilator 与教师入口

运行产物和本机缓存由 `.gitignore` 排除。
