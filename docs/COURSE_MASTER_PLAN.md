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
| §8 DC/约束/路径/面积 | [H0 PRN实验](H0_VM_SMOKE.md)已完成 VCS/DC；[综合准备](SYNTHESIS_READINESS.md)列整机风险 | 整机同版本RTL/参数/库/SDC、check_design/timing、四类路径、面积和网表 |
| §9 ICC/布局布线/时序收敛 | NOT_RUN | DC网表、技术/LEF/宏、floorplan、电源、CTS、route、寄生及setup/hold收敛 |
| §10 DRC/LVS/最终STA | NOT_RUN | 规则deck、最终版图/参考网表/寄生；适用DRC通过、LVS匹配、STA收敛 |
| §11/12/附录2 报告、权衡、AI核查、封存 | 三份模块报告及各阶段事实记录 | 同版本规范/RTL/配置/依赖/输出/脚本/网表/版图/寄生/报告、复用许可及短复现 |

阶段授权由 GOAL 与用户当前指令确定。历史 F/G 报告用于成果追溯，不驱动新任务。
