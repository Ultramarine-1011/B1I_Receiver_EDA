# 本次交付收尾（2026-10-23）

范围仅补齐独立BDI实验的教师依赖/本机大文件说明，修复合并后的只读交付审计，校正文档状态；验收为新审计、文档链接、Python语法、Git空白检查及受保护文件前后SHA256核对通过，随后仅提交本次文件并正常推送main。独立BDI单星捕获已完成六组Verilator测试并提交推送；H0原PRN的VCS/DC也已完成合并。新捕获电路尚未在虚拟机完成DC/ICC验证。本次不重复实验，不进入下一阶段；完成后停止，等待用户授权。当前状态只见[STATUS](STATUS.md)。

# H0：已完成的虚拟机 VCS 功能回归与 DC 首次综合

授权日期 2026-10-16。用户指定以虚拟机内已解压工程为唯一基线，GitHub 只在本阶段实验完成后接收成果。范围仅当前 `b1i_prn_gen`：确认既有 VCS、Design Compiler、许可证和 SAED90nm，跑通完整 PRN 自检，并做一次实验性综合。不授权完整接收机综合或 ICC。

| 验收 | 结果 |
|---|---|
| VCS 当前 PRN RTL 自检退出码 0，且输出 `B1I_PRN_REGRESSION_PASS` | 完成。I-2014.03，32 路各 2046 chip |
| DC analyze/elaborate/link、check_design、实验时钟、compile、面积、时序、网表 | 完成。K-2015.06，SAED90nm typical，10 ns 实验时钟，slack 7.150 ns |
| 可重复脚本与轻量证据 | `scripts/h0_vm_smoke.sh`，`docs/H0_VM_SMOKE.md`，`reports/local/h0_vm/` |
| 成果推送 main，且不用远端覆盖虚拟机工程 | 已完成，H0提交7ce233b经1e0308f合并推送main |

实验条件、哈希、面积和路径见 [H0_VM_SMOKE](docs/H0_VM_SMOKE.md)。本节保留已完成的H0目标与证据，不再作为当前待执行任务；扩展VCS/DC、完整接收机综合和ICC需新的授权。

# G 阶段：真实性能证据与因果评价

授权日期2026-10-14，完整目标见[G_AUTHORIZATION](docs/archive/G_AUTHORIZATION_2026-10-14.md)。F目标/停止状态已归档。当前状态只见[STATUS](STATUS.md)，课程总范围见[COURSE_MASTER_PLAN](docs/COURSE_MASTER_PLAN.md)。

仅使用已有Windows/WSL2 Ubuntu/Verilator/Python/g++；禁止VMware、SSH、Synopsys及H后端。教师公共文件和plan冻结项不改。输入真值只生成/评分，不进入DUT。默认4通道与E100秒成功BIN保持。允许阶段Git提交和正常推送main；不提交大型IF/BIN/构建。

| 阶段 | 本轮验收 | 状态 |
|---|---|---|
| G0 | main/HEAD/工作区、E/F哈希；资源及正式缺口登记，冻结F | 完成：resource_audit.json，23冻结项/25编译RTL/ROM匹配 |
| G1 | 实际RTL→原始记录/周期/可用时间→评分；版本/输入hash/配置/退出码；独立边界算例 | 完成：real51/52真实记录、逐PRN计时/版本输入审计、18独立边界检查0 |
| G2 | P01覆盖/成本、P02每任务周期、P03独立种子成功/失败/截尾诊断 | 当前可执行完成：两档6+2捕获及完整逐任务计时；子集FAIL保留，正式统计缺输入 |
| G3 | 已输出NAV/OBS、完整同代星历、无未来回填、依赖序号；三连1秒解/第3可用TTFF | 当前可执行完成：52s真实49/50/51三解、依赖TTFF51.000001s；实时PVT/正式批次未验证 |
| G4 | P06独立码/频/字诊断；P08真实2秒RF消失恢复与健康通道保持 | 当前可执行完成：50档60s环路PASS/40档连续锁FAIL，独立预期字20/20，真实2s RF恢复自生成PASS |
| G5 | D01–04连续真值/动态定向测试；P09无真值不填误差 | 当前可执行完成：连续轨迹自测/短RTL评分；连续锁FAIL，正式12D1/P09 BLOCKED_INPUT |
| G6 | 1/4/12服务率/最大等待/ready/记录/缓存；固定速率源；假定clk预算 | 当前可执行完成：active槽服务、64FIFO容量FAIL/102400FIFO有界PASS及预算；持续实时未证明 |
| G7 | 必要回归、E/F保留、分类/缺口/复现报告、提交推送、唯一下一任务 | 完成：18边界/8交付/12源清单/16最终仿真审计、分类报告/正式缺口/复验入口；源码证据63ea9c5已推送，最终文档随后固化 |

分类：OFFICIAL_PASS、SELF_GENERATED_PASS、PARTIAL、FAIL、NOT_RUN、BLOCKED_INPUT、BLOCKED_ENV。框架自测与模块合成PASS单列，不合并为正式性能PASS。

先短测试后估昂贵测试成本。全部当前可执行评价能力和低成本真实性能测试完成、有审计记录后停止。正式场景缺失不阻塞独立任务；G完成不等于课程正式P01–P09全通过，不进入H。

当前可执行G0–G7已按上述范围完成并停止。事实/失败/输入缺口与复验见[最终报告](reports/g_stage/FINAL_REPORT.md)，唯一下一任务只见STATUS。没有OFFICIAL_PASS或持续实时通过声明。
