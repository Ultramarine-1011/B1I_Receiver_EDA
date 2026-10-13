# F 阶段最终报告

2026-10-14；实现版本 **1b9505e**，E基线f8e8de7，F0计划729858f。F0–F6可执行工作完成；G/H/I仅规划，不自动执行。状态见[STATUS](../../STATUS.md)，验收见[GOAL](../../GOAL.md)。

## 新增能力与证据

参数化1/2/4/12独立逻辑槽，默认保持4；共享PCPS/精搜与持续跟踪并行，独立PRN、generation、NCO、环路、NH/D1、导航时间、测量与pending。候选去重/满载延后，失锁撤销/type3，2秒拉入失败后释放/重搜，旧任务/旧捕获窗拒绝，未来4096样本预约预置，已承诺record背压保持、EOF排空/错误标志/配置拒绝。schema3六位generation到63后退休而非静默回绕。

| 实际测试 | 结果与范围 | 证据目录 |
|---|---|---|
| 1/2/4/12 channel_bank | PASS，196416样本/206440拍，同PRN12窗逐bit一致，各运行槽消费同一公共样本；47个短人工epoch/槽无伪有效 | f3_current |
| channel_reuse/manager | PASS，旧承诺记录保持、type3/清状态/代次2/未来样本/reset；12槽满载/去重/旧task与窗/退休/失锁/超时/反压 | f3_current |
| 十二路NAV | PASS，合成Prompt120个RTL字，NH0/7/19、两极性、身份/代次/背压/失锁；不是12星IF | f3_current |
| 12槽自生成双星主码/NH | PASS，3.2信号秒、52377600样本、57456502拍、182.724墙钟秒；后台新星/自然失锁/失败候选超时释放/重搜后末段两星各≥100锁定窗；唯一end/flags0 | f3_recovery |
| reset/EOF/输入错误/配置 | PASS，1/4/12，错误编号正确置underrun、不伪观测；非法3通道退出6为预期拒绝 | f3_current |
| E0直接依赖/tail | PASS原3例正负码偏/±1000Hz，248/249窗、原独立门限评分及尾部排空 | legacy_e0 |
| 公共IF默认4、2s停顿/反压 | PASS，32736000样本、7989记录；每星1995Prompt/尾锁1；早期OBS仍无效 | real2 |
| 公共IF默认4、20s NAV/OBS | PASS，327360000样本、80101记录、40 RTL NAV字与独立教师Prompt解码逐项一致、76 OBS中4有效；原check_records/self_check均0，Route A 0/4星历/19定位历元 | real20/validation_commands.json、metrics/各日志 |
| E前缀对照 | PASS，20s非end80100条逐bit同E（仅acquisition周期字段排除），2s7988条同样相同 | real20/e_prefix_equivalence.json、real2 |
| 输出可用时间审计 | PASS，BIN/sidecar逐序号、信号sample/硬件cycle单调、数量一致 | run_summary.json/log |
| 性能基础 | PASS计算器/缺项拒绝；缩网格真实RTL probe排队14拍、接纳到复核962024拍、0.004信号秒/0.202墙钟秒，只是单例计时 | performance |
| 综合准备 | 源码/存储端口/宽除法/CORDIC/12复制/复位/吞吐风险完成，声明数组约2293056bit；不是DC面积 | synthesis、docs/SYNTHESIS_READINESS |

## E保留与未验证项

原E100秒BIN SHA256 **c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501** 不变；560 NAV/324有效OBS/99定位历元和历史报告保留，另备份reports/e_stage/final/receiver_records.bin（本地忽略）。教师公共文件/原9.28 RTL/plan哈希匹配，integrity_audit记录23份冻结项与链接。

F未重复100秒，不把旧100秒当当前源码新验收。选择2s+20s是因为20s全字段与E输出前缀一致、E100s首次锁定后无失锁、跟踪/NH/D1算法未改、默认四槽满载后台不启动；这是有限复验依据，不能替代新的100s实测。原成功正式交付仍保留。

未验证：12星完整同时IF/D1/PVT、隐藏场景、持续实时输入、正式P01全覆盖/P03统计/P04因果TTFF/P05–P09工作点和精度/D01–D04。双星合成中断仅130ms，2秒是失败候选拉入超时，**不是正式P08的2秒信号中断**。缺合法场景/独立种子/PDOP/码频字及位置真值时BLOCKED_INPUT；完整性能未执行。Route A事后19历元不算TTFF，BCH通过率不当字真值正确率，无真值不报精度。

DC/ICC/PT/DRC/LVS全部NOT_RUN；工艺/宏/目标clk/电气约束待提供，本轮只有风险准备。

## 时间/源版本/失败边界

20s实际617603738拍、710.908墙钟秒；仅按100MHz假设换算为6.17603738处理秒，总平均clk下界30.8801869MHz。Fs16.368MHz来自教师；100MHz是算术假设，非课程目标或实时保证。冷搜成本、有限缓存及持续输入节拍未正式验收，详见run_summary与SYNTHESIS_READINESS。

real20全部RTL/ROM/SVH SHA匹配当前实现，当时C++快照real20/driver_snapshot.cpp。其后只把尾部watchdog从1000万拍改为20亿拍（345M粗搜+最坏32×约25M精搜与有限开销的上界），不改DUT/数据。新driver重编并64样本EOF/唯一end/flags0/原结构检查PASS；最坏长搜尾部预算为静态上界，未另跑该场景。source_audit核实唯一driver差异。

失败均保留：首bank把非零初相半窗误算完整窗，修TB期望；Verilator层级enum编译故障和ROM拷贝路径修runner；默认精搜超过短窗，缩网格仅用于标明范围的合成。首0.8s只有分配PASS，强化锁定后FAIL；延长覆盖2s拉入超时后暴露sample_ready→sample_event→release→ready反馈，修为processed_samples差分，3.2s实际PASS。前缀评分首版按NAV源时刻误索取未来批的12字，改按输出序列，接收算法不变。

## 复现与下一任务

```powershell
.\scripts\run_f_stage.ps1 -Task all
.\scripts\run_fast_verilator.ps1 -Channels 4 -DurationSeconds 20 -EvidenceDirectory reports/f_stage/real20
.\scripts\validate_f_delivery.ps1
.\scripts\run_performance.ps1 -Mode plan
```

本地需教师scenario.if2，409200000字节，SHA256 2c47d1533fa54316952496ffb7905742c34a989b0a6276b867fe69566c5027da。IF/BIN/JSONL/构建不上传。实现1b9505e及报告/轻量证据1dc0e20已正常推送main，HEAD=origin/main实查一致，无强推；最终纯文档完成标记见Git最新提交。

唯一下一任务：登记教师统一12星、动态、中断场景及评分真值；具备输入后另行授权G。本轮不自动进入G/H/I。
