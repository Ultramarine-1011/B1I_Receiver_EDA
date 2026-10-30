# 课程要求与成果索引

依据本地《集成电路 EDA 实验指导书 V1.7》和教师 2026-10-13 包。第7章印刷 pp63–69、第8章 pp70–78、第9章 pp79–84、第10章 pp85–88、第11章 pp89–93（PDF 页+1）。教师单 BIN 仿真定义阶段接口，完整课程按 V1.7；新规范发布时更新来源。

本文件映射课程要求与权威文档。当前任务见 [STATUS](../STATUS.md)，P01–P09 判据见 [PERFORMANCE_EVALUATION](PERFORMANCE_EVALUATION.md)，实测及正式输入缺口见 [G 最终报告](../reports/g_stage/FINAL_REPORT.md)。

| 课程要求 | 实现/成果来源 | 后续交付依赖 |
|---|---|---|
| §1–2 架构、控制、输入时基 | [架构](ARCHITECTURE.md)、[F 报告](../reports/f_stage/FINAL_REPORT.md)：16样本拆包、握手、反压和 EOF | 正式硬件节拍与 SRAM 宏；当前教师接口免 SRAM |
| §3 全2046chip、±10kHz无辅助捕获 | [捕获报告](ACQUISITION_REPORT.md)：PRN6–37、500Hz PCPS与局部精搜 | P01–03 场景与统计 |
| §4–5 码/载波跟踪 | [跟踪报告](TRACKING_REPORT.md)：DLL/PLL、启动FLL、载波辅助、E100s尾锁 | P06–07 动态及功率真值 |
| §6 NH/位/帧/BCH/D1/导航时间 | [NH/D1报告](NH_D1_REPORT.md)：E560个RTL导航字独立逐字一致 | 帧起点、字真值和因果可用时间 |
| §7.1–3 12逻辑通道、后台捕获/遮挡/释放 | [F设计](F_MULTICHANNEL_DESIGN.md)及 F 报告：数字控制、12槽双星3.2s恢复、12路NAV120字、公开4星20s | 正式12星D1输入及持续吞吐 |
| §7.4–7.7 P01–P09 | G 报告维护逐项实测、PASS/FAIL、覆盖与正式缺口 | 合格场景、独立码频/字/位置真值 |
| §2/7.9 OBS/NAV/RINEX3.05/吞吐 | G 报告维护BIN检查、因果NAV/OBS、服务与FIFO预算；RINEX尚未交付 | clk、SRAM、输入输出服务上界、持续12星负载 |
| §8 DC/约束/路径/面积 | [H0 PRN实验](H0_VM_SMOKE.md)已完成 VCS/DC；[H1 同步/解调 VCS 与部分 DC](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md)；[综合准备](SYNTHESIS_READINESS.md)列整机风险 | 整机同版本RTL/参数/库/SDC、check_design/timing、四类路径、面积和网表 |
| §9 ICC/布局布线/时序收敛 | NOT_RUN | DC网表、技术/LEF/宏、floorplan、电源、CTS、route、寄生及setup/hold收敛 |
| §10 DRC/LVS/最终STA | NOT_RUN | 规则deck、最终版图/参考网表/寄生；适用DRC通过、LVS匹配、STA收敛 |
| §11/12/附录2 报告、权衡、AI核查、封存 | 三份模块报告及各阶段事实记录 | 同版本规范/RTL/配置/依赖/输出/脚本/网表/版图/寄生/报告、复用许可及短复现 |

阶段授权由 GOAL 与用户当前指令确定。历史 F/G 报告用于成果追溯，不驱动新任务。

## 后续里程碑路线图（2026-10-30）

本节是后续工作**唯一的跨阶段规划入口**，不代替 `GOAL.md` 的当前任务授权、`STATUS.md` 的实时状态或技术报告中的实测细节。里程碑编号 M0–M5 是后续规划标签，不意味着已授权、已开始或已完成。原则：优先获得符合课程要求的可验证最低交付；确认输入和工具条件后再投入高成本开发。

### 基线、已完成成果与当前差距

- 功能基线：`main` 的 `697ebaa`（2026-10-23）。E100 真实教师 IF 已经输出合法记录、560 个 RTL D1 字、4 份星历及 99 个 Route A 定位历元；F 阶段有 12 槽数字/导航隔离验证；G 阶段得到 52 秒真实 IF 的 49/50/51 秒三个因果定位解。这些不等于 P01–P09 全 PASS、完整 12 星实际 RF 或已验证位置精度。证据见 [G 报告](../reports/g_stage/FINAL_REPORT.md)及 E/F 报告。
- H0：实验室虚拟机已有 PRN 的 VCS PASS 和 SAED90nm DC 综合结果，见 [H0 报告](H0_VM_SMOKE.md)。
- H1：独立 [`h1-frontend` 分支](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/tree/h1-frontend) 的 `c71c623`（2026-10-30），[详细报告](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md)：NH/D1 与双子帧 VCS 均 PASS；`d1_word_sync` 在实验性 10 ns 下映射完成，slack +0.019 ns，black-box 属性计数 2 但报告列出 0 个对应单元，未消歧；`nh20_sync` DC 在优化阶段被人工中止（INTERRUPTED），`navigation_d1` DC 未执行（NOT_RUN）。H1 尚未合并 `main`，正式 RTL 未改。
- 后端尚无整机综合网表、ICC 布线、寄生提取、最终 STA、DRC/LVS 通过证据。教师 `student_release` 当前定义的是纯仿真、32 字节 BIN 的功能交付；完整课程 V1.7 的后端和 12 通道要求应在 M0 核实最新适用范围，未经教师确认不以 PRN 的小模块物理实验替代整机验收。
- 实验室原 `h0-checkpoint` 工作区存在未提交的搬迁适配，已有仓库外补丁/未跟踪文件备份，未并入 H1；后续严禁覆盖或意外混入正式 RTL。环境事实见 [H0](H0_VM_SMOKE.md)与 H1 报告。

### 未解决任务和优先级

| 等级 | 未解决任务 | 影响 / 证据归属 | 处理原则 |
|---|---|---|---|
| P0 | 教师最新后端验收范围：是否必须完整 12 通道综合/布局布线、允许何种模块级演示；最终 clk/IO/工艺/宏要求 | 决定能否以小模块结束；现有 V1.7 课程索引见上表 | M0 先核实；无新要求时按 V1.7 完整范围理解，不擅自缩减 |
| P0 | ICC、工艺物理视图、RC 模型、SRAM 宏、DRC/LVS deck、许可的真实可用性 | 仅 VCS/DC/SAED90nm `.db` 已实测，不能外推物理流程 | M1 只读/轻量预检，缺失即停止 |
| P0 | 整机捕获/FFT 存储约 2.29 Mbit 的真实映射、多端口/异步访存和宽算术 | [综合准备](SYNTHESIS_READINESS.md)中有结构风险，尚无整机 DC 网表 | M3 明确资源条件后才做；不盲跑全设计 |
| P1 | H1 的 NH/DC 中断、NAV/DC 未运行、`d1_word_sync` black-box 计数不一致与 10 ns 近零时序裕量 | [H1 报告](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md)；不能称为综合全 PASS | 后续真需组合/综合时定向处理，不为了填满状态表反复运行长命令 |
| P1 | P01–P09 正式性能：40 dB-Hz/动态/12 星/持续实时/独立位置真值和正式统计覆盖 | 细项与实际 PASS/FAIL 仅见 [G 报告](../reports/g_stage/FINAL_REPORT.md) | 必须等合格场景及真值；已知 FAIL 不能写成缺输入 |
| P2 | RINEX 3.05 OBS/NAV 和正式课程封存；搬迁脚本未合并；H1 入口默认 `all` 可能重启长任务 | [课程索引](#课程要求与成果索引)、[H1 报告](https://github.com/Ultramarine-1011/B1I_Receiver_EDA/blob/h1-frontend/docs/H1_VM_FRONTEND.md) | 随有收益的验收/迁移处理，避免独立开工 |

### M0–M5：任务、门槛、交付与停止条件

| 里程碑 | 核心工作 | 进入条件 | 最低可核实交付 / 结束判断 |
|---|---|---|---|
| **M0 验收与版本冻结**（下一候选） | 对照教师最新发布与 V1.7 §8–10，明确 12 通道/整机还是允许模块级后端成果；确定顶层、参数、RTL commit、教师版本、目标 clk、工艺角与可交付记录 | 用户单独授权 M0；不需要运行综合 | 一份已确认/待教师确认的验收矩阵及基线清单；不确定项列阻塞，不假定模块级成果已获认可 |
| **M1 物理工具链与库预检** | 在隔离 VM 目录确认 ICC 可执行、许可、技术/物理库（Milkyway/LEF 等）、RC/寄生模型、SRAM 宏视图、DRC/LVS deck 及路径；不要改变系统/网络/license | M0 至少明确目标和必要材料；用户授权访问 VM | 资源清单、只读命令/退出码、明确 GO/NO-GO；关键视图缺失即停止，不自行安装或伪造 |
| **M2 PRN 小模块后端探路（可选）** | 仅在 M1 GO 时复用 H0 的 PRN 网表、SDC，尝试导入、floorplan、放置、CTS、布线、提取及实际可执行的报告；真实完成到哪步记到哪步 | H0 网表与匹配工艺物理库、ICC 可用，且用户另行授权 | PRN 的真实物理流程数据库/日志/报告或明确失败；**不等于整机后端通过**。若课程只接受整机，M2 仅作调试，不能作为最终交付替代 |
| **M3 整机可综合性与完整 DC**（高成本） | 首先做静态存储/算术成本评估和宏端口可行性判断；必要时分级修正 PCPS/FFT SRAM 映射、宽除法、NH/NAV 低速运算、12 槽资源；逐改做等价性/真实 IF 受影响回归，最后形成完整网表 | M0 明确必须整机，M1 具有匹配宏/库/时钟/IO 输入；用户专项授权 | 同版本 12 通道顶层完整映射网表、SDC、面积/四类路径/时序、无未解释 black box；若成本明显失控或宏不可实现，则报告 NO-GO，停止盲目优化 |
| **M4 整机物理实现与签核检查** | 在完整网表上做 ICC 布局、CTS、布线、寄生与 STA，执行具备规则的 DRC/LVS；记录工艺角、setup/hold、违例与修复 | M3 已有适用完整网表和完整物理视图；用户授权 | 同一设计版本的数据库、版图/寄生、时序与 DRC/LVS 记录；缺 deck 或不收敛记实际限制，不称为签核 PASS |
| **M5 最终报告/课程封存** | 复用 E/F/G/H0/H1 和实际后端证据，整理 RTL/参数/标准单元/宏/脚本/网表/版图、演示与 AI 核查；核对教师 BIN 与 RINEX 需要的实际交付边界 | 可在其他阶段并行整理；最终封存须确定验收范围 | 可复现项目包、版本与证据索引、报告、实测 PASS/FAIL/NOT_RUN，未交付项目逐项列出 |

**执行顺序及停机准则：** 优先 M0 → M1；M2 是低风险但可跳过的工具链探路，M3 是成本最大的技术决策，M4 依赖 M3；M5 可提前整理。M0/M1 的结论可能改变后续范围，不预设一定做到 M4。每个里程碑需新的 `GOAL.md` 授权，完成后更新 `STATUS.md` 和 `WORKLOG.md`；本次路线图落库只是规划，不授权运行 VCS/DC/ICC、修改 RTL 或合并工作区。

### 最近一次应执行的任务

仅在用户授权后开展 **M0：教师最终验收口径与后端基线冻结**。优先收集已有教师记录，不为填表重跑 100 秒 IF，不继续执行 H1 中断的 DC 任务。若 M0 仅能得到现有 V1.7 的要求，标注范围待教师确认，同时将 M1 作为下一项轻量环境可行性检查；不得默认教师允许缩减整机后端目标。
