# 北斗 B1I 六通道基带接收机｜数字 IC EDA 实验

本仓库实现北斗 B1I 基带接收机，包括捕获与精搜、码/载波跟踪、NH 副码与 D1 导航数据处理，以及六通道共享 IF 输入和独立通道控制。工程同时保留早期参数化接收机、教师公开接口适配、参考模型及可复现的功能验证证据。

**当前课程专项**（2026-11）：六通道 B1I 基带处理器、TSMC28 标准单元逻辑综合、真实 PAD、时序分析、MAX/MIN SDF 门级后仿及 VCD/SAIF 功耗评估。这里的“通过”只对应实际执行过的版本、环境和测试范围。

## 当前进度

截至本仓库 `main` 最近的正式工程记录（2026-11-06）：

| 工作 | 结果 | 证据 |
| --- | --- | --- |
| 六通道 RTL 与功能验证 | **PASS**：六星正常接收、PRN 重排、失锁恢复与通道隔离；串行导航位逐位比对；16.368 MHz 定速输入测试 | [六通道功能报告](reports/six_channel_20261102/FINAL_REPORT.md) |
| TSMC28 工具、标准单元与 PAD 预检（M1） | **完成**：实际工具和工艺库检查，识别 ROM 与大型存储映射风险 | [M1 报告](reports/m1_tsmc28_20261106/REPORT.md) |
| 真实 PAD 连接、旋转因子 ROM 修复及首次 DC 可综合性检查（M2） | **部分通过**：PAD 连接与 FFT 针对性验证 PASS；隔离 PCPS 存储后可展开、链接及检查设计 | [M2 报告](reports/m2_tsmc28_20261106/REPORT.md) |
| TSMC28 六通道完整映射、时序收敛（M3） | **未完成**：M2 六通道映射未获得最终面积/时序；PCPS/FFT 存储实现仍有阻塞 | [当前状态](STATUS.md) |
| TSMC28 MAX/MIN SDF 门级后仿、功耗与最终交付（M4–M5） | **NOT_RUN**：没有正式验收证据 | [课程里程碑](docs/COURSE_MASTER_PLAN.md) |

六通道核心为 [`bds_bb_6ch_core.sv`](student_release/student_release/rtl/bds_bb_6ch_core.sv)，PAD 顶层为 [`bds_bb_6ch_pad_top.sv`](student_release/student_release/rtl/bds_bb_6ch_pad_top.sv)。六路使用同一 2-bit IF 输入，各槽独立维护跟踪、同步及导航状态；公共捕获计算资源按槽复用。接口、数据顺序、时间语义和结构说明见 [六通道设计](docs/SIX_CHANNEL_DESIGN.md)。

**个人实验与正式课程结果分开管理。** 另有本地 TSMC90 单通道 RTL/综合优化及后端脚本预演成果；这些本地实验尚未并入此 GitHub `main`，不能当作 TSMC28 六通道完整综合或时序签核通过。以对应实验分支和本地原始报告为准。

## 本地复现

在 Windows PowerShell 中，从仓库根目录运行已有六通道 RTL 验证入口：

```powershell
# 六路 NH/D1 串行导航位测试
.\scripts\run_six_channel.ps1 -Task navigation

# 六通道相关测试全套（运行时间较长）
.\scripts\run_six_channel.ps1 -Task all
```

运行环境主要为 WSL2 Ubuntu、Verilator、C++ 与 Python；ASIC 部分使用相应 Synopsys 工具及授权工艺库。工具环境见 [EDA_ENV_STATUS.md](EDA_ENV_STATUS.md)，综合可行性与限制见 [M2 报告](reports/m2_tsmc28_20261106/REPORT.md)。功能仿真 PASS 不代表完整门级仿真或时序通过。

## 仓库结构

- `student_release/student_release/rtl/`：接收机、六通道核心及主要 RTL。
- `rtl/`、`tb/`、`model/`：可复用模块、测试平台、向量及模型。
- `scripts/`、`constraints/`、`synth/`：仿真、综合与约束入口。
- `reports/`：对应版本的功能验证、EDA 实验记录和证据。
- `docs/`：接口、架构及课程交付范围。
- `work/` 等：本机中间产物，通常不提交。

教师发布的约 409 MB `scenario.if2` 不包含在仓库中；使用旧版公开输入验证时，需从课程文件获取并放入 `student_release/student_release/input/scenario.if2`。旧版完整 `self_check` 和定位类任务属于不同验证范围，不能用六通道专项测试的 PASS 直接代替。

**进一步阅读：** [当前正式状态](STATUS.md) · [已授权工作范围](GOAL.md) · [课程里程碑](docs/COURSE_MASTER_PLAN.md) · [工作记录](WORKLOG.md) · [协作约定](AGENTS.md)
