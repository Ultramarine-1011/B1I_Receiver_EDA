# 课程要求与成果索引

**当前执行依据（2026-11-02）**：教师新发的《北斗基带信号处理器六通道逻辑综合实验要求》《北斗六通道基带处理器VCD功耗评估说明》和《tsmc28_学生使用说明》（原件仅在本地 `261102/`）。本次专项交付对象是**六通道、真实 PAD、TSMC28 DC 综合、最大/最小延迟 SDF 门级后仿及 VCD/SAIF 功耗分析**。不把原 V1.7 指导书的 12 通道、ICC、DRC/LVS 自动列为本次专项验收前置条件；教师以后若另行布置，单独更新范围。

**已完成**：2026-11-02 六通道核心 `bds_bb_6ch_core` 的本地功能仿真，包括自生成六星 IF 三组共 705 个串行导航位、Prompt 层 1080 位逐位一致，恢复/重配/通道隔离、100MHz 假定时钟下 16.368MHz 定速采样及相关旧回归 PASS。证据：[六通道最终报告](../reports/six_channel_20261102/FINAL_REPORT.md)、[接口/结构说明](SIX_CHANNEL_DESIGN.md)，对应基线为 `main` `3ecef38`。现有 PASS 是 RTL 功能证据，尚无真实 TSMC28 PAD/DC/STA/SDF/功耗成果。

## 新实验要求与成果入口

| 2026-11-02 教师要求 | 当前对应实现或交付 | 状态 |
|---|---|---|
| 六路共享 2-bit IF，独立捕获/跟踪/位同步及 `capture_ok/bit_sync_ok/nav_data/nav_valid[5:0]` | [六通道核心与接口](SIX_CHANNEL_DESIGN.md)、[真实运行日志及评分](../reports/six_channel_20261102/FINAL_REPORT.md) | 本地 RTL 功能 PASS |
| 实际工艺 PAD，含 PAD 的 `bds_bb_6ch_pad_top`；TSMC28 标准单元和 PAD 库、模型 | 教师给出标准单元 TT/SS/FF 路径；PAD 具体库/时序/仿真模型尚须在 VM 核实 | NOT_RUN |
| 六通道 DC、完整 SDC、全路径及复位时序、时序修复/面积优化、最终网表/DDC/SDF | [综合风险](SYNTHESIS_READINESS.md)、[待确定条件](TBD.md) | NOT_RUN |
| 最大与最小延迟 SDF 反标 VCS 后仿，六路状态、导航比特及独立性检查 | 复用已验证 RTL 测试思想；需含 PAD 的门级测试平台/真实单元时序模型 | NOT_RUN |
| 门级完整 VCD → SAIF → DC Power Compiler；内部/开关/漏电/总功耗 | 教师手册指定 `output/final.v/.ddc/.sdc`、`final_max.sdf` 和 `tb.dut` 活动层次 | NOT_RUN |
| 同一版的网表、约束、SDF、时序/面积/功耗报告、脚本及日志 | M5 汇总 | NOT_RUN |

原 V1.7 课程全貌（12 通道、定位性能 P01–P09、RINEX、ICC、DRC/LVS）及旧教师 `student_release` 单 BIN 任务的历史证据仍分别见 [F 多通道设计](F_MULTICHANNEL_DESIGN.md)、[G 阶段报告](../reports/g_stage/FINAL_REPORT.md)、[H0 VCS/DC](H0_VM_SMOKE.md) 和 [H1 独立分支报告](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md)。它们不等于本次六通道 ASIC 门级验收通过。历史路线图可由 2026-10-30 Git 版本追溯。

## 后续里程碑路线图（2026-11-02）

本节是当前跨阶段规划入口；实时状态见 [STATUS](../STATUS.md)，当次授权见 [GOAL](../GOAL.md)。完成一项再决定下一项，减少昂贵工具的无效尝试。

| 里程碑 | 工作与进入条件 | 最低验收/停止条件 | 状态 |
|---|---|---|---|
| **M0 六通道规范和功能基线** | 核对 `261102` 最新接口、工作范围，固定 `bds_bb_6ch_core` 及 `3ecef38` 功能证据；把真实约束未定项移至 M1 | 六星功能报告与代码可复查；明确 6 通道专项不以旧 12 通道后端为前提 | **已完成主要部分**。工艺角文件已在 M1 找到；ASIC 周期和 IO 延迟仍是待选参数 |
| **M1 VMware 工具与工艺库预检** | 在原有隔离 VM 目录只读核对 `dc_shell`、`vcs`、`vcd2saif`、Power Compiler 与许可；核对 `/home/share/libs/tsmc28` 标准单元 .db、PAD .db/.lib、门级 Verilog/SDF 模型、供电控制及实际可用性。选取有依据的 clk、复位、IO min/max 延迟/转换/驱动/负载、TT/SS/FF 与存储策略 | 记录命令、版本、路径及 GO/NO-GO；必要 PAD/库/模型不存在则标阻塞，不进入盲目综合 | **已完成**。[报告](../reports/m1_tsmc28_20261106/REPORT.md)：有条件 GO。PAD 与三角标准单元可用；直接展开现有 RTL 的首次全芯片 compile 为 NO-GO |
| **M2 六通道 PAD 顶层与首次 DC 可实现性验证** | M1 GO 后建立 `bds_bb_6ch_pad_top`，逐位接入全部必要输入输出 PAD，保留核心功能；建立库加载/RTL/SDC/初次映射脚本。首先定位捕获 FFT/PCPS **2,293,056 bit** 存储、异步多端口、宽除法、ROM 和复位的实际映射问题 | 含 PAD 的顶层可解析/link/check_design，首次真实面积/时序及阻塞清单；如存储/PAD 不可实现，先给出有证据的 NO-GO 和最低代价修复方案 | NOT_RUN |
| **M3 完整 DC、时序修复与面积优化** | M2 可继续时，按同一接口约束检查输入→寄存器、寄存器→寄存器、寄存器→输出和存在的输入→输出路径，以及恢复/移除/最小脉宽；修复实际关键路径、优化面积并验证影响范围 | 最终 setup/hold WNS≥0、TNS=0、违例=0、有效路径未约束数=0；记录优化前后对比。导出同版 `output/final.v`、`final.ddc`、`final.sdc`、MAX/MIN 对应 SDF 及完整报告，无未解释黑盒 | NOT_RUN |
| **M4 VCS SDF 门级后仿与功耗** | M3 网表/模型齐备后，以 `tb.dut` 为含 PAD DUT，检查 MAX/MIN 反标与时序检查均有效；复用六通道功能判据并适配门级延迟。后仿完整 VCD → SAIF，加载同版 DDC/SDC 由 Power Compiler 报告功耗 | 六路捕获/位同步/数据输出、复位、错时同步与恢复用例实际 PASS；无未解决时序/X/Z 失败；SAIF 映射、时长与活动覆盖可审计，四类功耗和条件齐全 | NOT_RUN |
| **M5 专项交付与封存** | 汇总本次六通道专项所有真实成果，引用 H0/H1/G 只作历史背景 | 一致的 RTL、工艺及 PAD 库/模型信息、DC/VCS/Power 脚本、最终网表/DDC/SDC/SDF、时序/面积/功耗、日志/波形与复现说明；逐项 PASS/FAIL/NOT_RUN | NOT_RUN |

**执行顺序**：M0（功能与范围已核对）→ M1 → M2 → M3 → M4 → M5。每个新执行阶段应先更新 GOAL 授权；后端遇到真实阻塞时只修必要 RTL 并运行受影响的本地回归，不重复无收益的 3 秒/公开 IF 全套仿真。最终以教师本次六通道实验文件及实际工具证据验收，不以 `SYNTHESIS` lint 冒充 DC 或以稀疏功能 VCD 冒充功耗 VCD。

**当前唯一下一候选**：另行授权后的 M2。进入前先替换被 DC 忽略的 `$readmemh`，并避免在 1991 MB 虚拟机上展开 2,293,056 bit 捕获存储。不要把 M1 的有条件 GO 当成全芯片 compile、SDF 后仿或 ICC 已经可做。
