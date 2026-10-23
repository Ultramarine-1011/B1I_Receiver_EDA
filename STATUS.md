# CURRENT STATUS

2026-10-23：最小交付收尾检查完成，仅修正教师依赖说明、合并后只读审计及状态。当前审计退出0，195个受保护版本文件核对通过；994个本机文件前后原始SHA256不变，含教师资料、RTL、H0、全部捕获历史结果及三份未跟踪PDF。32条文档链接、4份Python语法、Git空白检查及只读故障注入通过，详见WORKLOG及 reports/local/bdi_closeout_2026-10-23。H0原PRN的VCS/DC与独立BDI单星捕获均已完成并合并推送；新捕获电路尚未在虚拟机完成DC/ICC验证，本次未运行EDA或下一阶段实验。

2026-10-19：独立简化BDI单星捕获实验完成并已提交推送；入口 [experiments/bdi_capture/README.md](experiments/bdi_capture/README.md)。严格采用新教师默认MEO-6/PRN6源及8192门限，原样复用PRN RTL构建循环表；从相位0逐窗推进，第11窗相位10主峰57288，单拍hit，随后两窗57288复核。全部6项自检/独立评分退出0，13窗212784有效样点，连续dump间隔16368拍，三窗49104样点码逐点一致；停顿/末样点非零/零输入/复位重搜及同一PRN6相位3补充验证通过。完整VCD和全样点CSV留在本机；运行摘要、轻量日志、PNG和源hash见 experiments/bdi_capture/runs/20261019_164411。说明示例低值表六处略异，独立模型及实际RTL一致、错误相位最大1848低于8192，差异和首次失败保留。861个既有文件除状态/日志外859个SHA不变；教师源、PRN源、三报告/PDF均保护。完整接收机/H0整机回归/后端流程NOT_RUN；Git交付已推送。

2026-10-16：H0 已在虚拟机解压工程 `/home/7901_15/B1I_Receiver_EDA` 实际完成。未从 GitHub 下载或覆盖该目录，也未改 PRN RTL。VCS I-2014.03 对当前 `rtl/b1i_prn_gen.sv` 与 `tb/tb_b1i_prn_gen.sv` 退出码 0，32 个 PRN 各 2046 chip 通过，日志含 `B1I_PRN_REGRESSION_PASS`。Design Compiler K-2015.06 用 SAED90nm typical 完成 analyze/elaborate/link、check_design、实验性 10 ns 时钟与 14.08528 fF 输出负载下的 compile。单元面积 3006.259234，含线网总面积 3134.467888；关键路径 `active_prn_reg[1]` 到 `chip` 到达 1.650 ns，slack 7.150 ns（MET），无约束违例，网表已导出。重复入口 `scripts/h0_vm_smoke.sh`。证据见 `docs/H0_VM_SMOKE.md` 与 `reports/local/h0_vm/`。本阶段停止，不做完整接收机综合或 ICC。

2026-10-16：线下验收演示准备完成。入口scripts/demo_acceptance.cmd及demo_acceptance.ps1，菜单1→2→3→9→4；捕获3.032s、NH1.993s、导航2.281s实跑PASS，跟踪原双用例完整ModelSim77.324s PASS/WLF保留，重复运行耗时波动后按用户要求固定回放。最终all现场流程退出0、约9s（不含GUI与讲解），菜单/原E100日志读取验证；三模块GUI重点波形已检查，四份do保存信号/进制/时间窗。操作、讲解及8问答见docs/ACCEPTANCE_DEMO.md，真实预演与一次重复超时记录见reports/local/acceptance_demo_2026-10-16。未改RTL/教师/原TB判据/三报告/历史证据，未重跑整机IF。只保存本次入口、轻量证据与交接，项目唯一下一任务仍为本文末条。

2026-10-15：按用户反馈完成三份课程实验报告的全面重写，主体以算法、RTL实现、仿真方法和实际成果为主线，补充六幅原图的信号/数据分析，将必要改进事项集中到各报告末尾一小段。保留E100/F20/G52版本及真实结果对应关系、边界失败数据与来源，删除重复验收免责声明和环境故障叙述。80个引用、六图、16表、三Mermaid及61处公式的解析/浏览器渲染检查PASS；RTL、测试结果、历史证据、图片字节保持不变，未运行仿真。本次只更新三报告及STATUS/WORKLOG，正常Git提交推送main；项目唯一下一任务仍为本文末条。

2026-10-14：本次三份课程模块报告更新与轻量取证已完成，报告／图片／轻量证据提交9ea31ab已正常推送main（0/0）。报告按当前PCPS／FLL码速辅助／双子帧type2修订，E100／F20／G52与正式FAIL分开；四张实际WLF→VCD时序PNG、两张历史CSV-SVG已归档，Computer Use中断后路径错误而无GUI截图，图文明确说明。ModelSim九字／双子帧／缩网格PCPS退出0；跟踪仅局部182反馈，不称完整回归。86引用、三Mermaid、53公式、六图真实渲染及受保护源／E100 BIN哈希检查PASS。原SVG/stdout字节保留，通用空白检查尾空格警告单列，正文／脚本检查0。本条最终状态与Git检查由随后交接提交固化。本次停止，唯一项目后续任务仍为本文末条，不开展接收机研发。

2026-10-14（Asia/Singapore），原G会话异常已无损恢复，G0–G7全部当前可执行评价、低成本真实测试和报告交付完成并停止。恢复HEAD=origin/main=c0d4d91；修改/失败证据保留，无遗留任务，未重跑长仿真。源码和轻量证据63ea9c5已正常推送main；最终状态/课程文档随后固化。正式P01–P09未完成验收，持续实时未证明，H未授权。

默认4公开52s实际851136000样本/208429记录/1174500118拍/1492.005s；教师检查、独立NAV、E前缀208428非end记录逐bit比对（除全局cycle）均退出0。真实RTL NAV/OBS因果49/50/51三解，依赖TTFF51.0000009775s、PDOP约9.32；离线因果重放，未调度实时PVT。real51截尾保留，52s同一输入不算独立第二试验。

捕获40档1/6、50档5/6，均0/2虚警，PARTIAL且子集FAIL；50档NH边界−200Hz偏置保留。50档完整60s单环路SELF_GENERATED_PASS，40档连续锁FAIL；短D01–04实际评分/完整轨迹自测完成，不是12星正式PASS。真实20–22s RF恢复自生成PASS：16ms检测、generation3恢复锁23.093s、NAV/有效OBS36.000001s；健康通道锁100%，错误候选及两次失锁保留。

1/4/12 active数字槽服务结构PASS/性能PARTIAL；假定100MHz源64word FIFO实际溢出FAIL，102400word仅0.1s有界窗口PASS/峰18363word。默认4 RUN平均clk下界17.403MHz、总平均22.587MHz、最大冷阻塞269543639拍；目标clk/SRAM/服务上界缺，持续实时未证明。

18边界检查、8公开52交付检查、12源清单、16最终仿真退出0及因果依赖审计PASS。25项RTL/ROM匹配F，23冻结项及E100成功BIN/备份SHA c9c4d23d...eccdd501保持。完整事实/分类/缺口/复验见reports/g_stage/FINAL_REPORT.md，无OFFICIAL_PASS或新100s实跑声明。

原G后续条件（本次不执行）：取得教师正式性能IF场景及独立真值。

唯一下一步状态：本次收尾完成后停止，等待用户下一阶段明确授权。
