# P01–P09 执行与统计契约

来源：V1.7 §7.4–7.7（印刷 pp65–68）。本文件维护 P01–P09 的运行、统计与因果评分契约；实测结果、覆盖和正式输入缺口统一见 [G 最终报告](../reports/g_stage/FINAL_REPORT.md)，课程映射见 [COURSE_MASTER_PLAN](COURSE_MASTER_PLAN.md)。

## 场景登记与运行

统一入口 `scripts/run_performance.ps1 -Mode plan` 由model/performance_plan.py生成reports/f_stage/performance/scenario_plan.json并验证计算器；`-Mode run -Metric Pxx`在无合法cases时退出2并保存BLOCKED_INPUT，不伪运行。未来登记合法case后可执行相同默认RTL；仿真退出0仍仅RUN_COMPLETE_METRICS_PENDING，另用`-Mode metrics -MetricInput TRACE.json`离线评分。条目保存official/self_generated、IF路径/SHA256、Fs、时长、PRN/功率/NH/帧起点/噪声种子、几何PDOP、真值来源、动态与传播模型。真值只评分，不传学生RTL。状态使用 BLOCKED_INPUT（缺输入）、NOT_RUN（未运行）、PARTIAL（覆盖不足）；执行成功与性能达标分别报告。

公开IF只能验证已公开的静态6星40dB-Hz开发场景，不能自动当12星、不同种子、PDOP≤4、180s冷启或有位置真值的正式场景。2bit前量化C/N0与噪声底须来自场景元数据；不能把无噪声数字码测试声明40dB-Hz。

运行入口 `scripts/run_fast_verilator.ps1 -Channels 4|12 -DurationSeconds ... -EvidenceDirectory ...`；可用独立InputPath指定登记过的合法IF。默认全PRN6–37、±10kHz/500Hz和完整精搜。测试bench缩网格只用于低成本控制/集成，不计P01全覆盖。先用短窗查完整性，按信号时长/实测周期量化成本再批量。

## 各项必需证据

| 项 | 运行/计量契约 | 原始评分输入与完整性 |
|---|---|---|
| P01 | 40dB-Hz、全2046chip、±10kHz端点/每格中点、NH相位；成功须正确身份/相位/频偏及复核 | 覆盖列表全保留；参数生成包含16368离散样本相位、41粗格/40中点、20NH相位（巨大笛卡尔积先估成本，不自动全跑） |
| P02 | 排队另记；任务接纳到可用结果复核结束，信号/周期/假定clk/墙钟分别报 | queued_cycle/accepted_cycle/verified_cycle，不用type5全局cycle冒充单PRN执行时间；没有trace则NOT_RUN |
| P03 | 每档100有星+100目标缺失、候选同时含有/无星、10s观察窗 | 独立seed、检出经真值复核、虚警、前4有效星首次可用时间；≥90%/≤1%工作点，Wilson95%CI；未完成保留10s下界 |
| P04 | 每档10独立冷启，清星历/捕获/同步，不同帧起点，180s窗；至少6D1/PDOP≤4 | 逐试因果三连1s有效解/第3实际输出信号时刻、阶段时间、失败/完成率/分布 |
| P05 | 同几何/功率、逐档C/N0，边界附近1dB；≥9/10启动且各成功随后60s有效≥95% | 完整60历元有效性；只报已验证档，未找到失效边界不填灵敏度界限 |
| P06 | 捕获、已建立后的60s跟踪保持、D1字分别计量 | 无重捕/连续锁、码RMS≤0.1chip、完整1s均频误RMS≤5Hz；字真值正确≥99%；BCH通过率不代替字正确 |
| P07 | 12有效D1/40dB-Hz，先同步后D01–04各≥30s | 每槽连续锁/无意外重捕、码/频门限、字≥99%、每槽有效OBS≥95%；D03累计距离保持连续，D05单列可选 |
| P08 | 标称中断2s后恢复 | 中断起止、失锁、调度、重捕/拉入、首次有效共同OBS；控制注入不算真实信号恢复 |
| P09 | 无附加动态，确认定位后连续完整60s，固定真值与解算模型 | ENU均值偏差、水平/绝对垂直/3D RMS/95%分位、60历元有效解比例；无真值BLOCKED_INPUT、无解不填0 |

动态轨迹定义：D01 约±3m/s²、±2m/s³；D02 ±5m/s²保持2s且有限jerk；D03 j=+5,-5,-5,+5各1s后静止1s，6循环30s，累计距离、码/载波相位连续；D04 接近±50m/s包络内及±10kHz总频偏。可选 D05 为 j=±10、每0.8s，单列评价。

## 因果 TTFF

快仿driver逐记录额外保存`receiver_records.bin.availability.jsonl`：sequence、输出握手时available_sample、hardware_cycle。available_sample是实际已接纳的IF样本量（最多含一字16样本缓冲），与payload中的源时刻分开，不读真值。

在线评估适配器必须顺输出顺序读取NAV/OBS，保留PRN+generation、当前已恢复星历及每个参数首次可用序号；位置结果显式列used_nav/used_obs序号和available_sample。`performance_metrics.causal_ttff`检查所有依赖已可用、每个有效OBS当时已有同代NAV、≥4有效观测、同一epoch、连续3个1s历元及第3输出时刻。缺任一依赖拒绝或CENSORED，不利用后来的星历回填旧OBS。

评分trace的kind=nav必须标ephemeris_ready（当时已恢复完整可用星历），由在线适配器记录所用原始NAV序号；单个type2字的bch_valid不等于完整星历。计算器只核查给定trace，不能证明适配器的广播参数恢复本身正确。

教师 Route A 全文件求解会用后续 Prompt/NAV 回溯早期历元，适合作功能诊断。TTFF 使用 `model/online_navigation.py` 按实际 RTL NAV/OBS 顺序重放；CPU 求解服务时间另计。真实 52s 结果及同代30字依赖证据见 G 报告的“默认4真实输出与因果TTFF”。

## 指标入口与模板

`python3 model/performance_metrics.py --self-test`运行独立手算算例（时间、CI、截尾、因果TTFF拒绝、ENU、60s、D03），只验证计算器。实际JSON trace可用`--input TRACE.json --output METRICS.json`，metric=acquisition/cold_start/ttff/tracking/words/recovery/position/timing。跟踪频误先按完整1s的1000个Prompt求均值再取RMS，不能用逐msRMS替代；缺真值/字/完整窗不强行资格化。

报告逐项填：场景类别/版本/哈希/种子/CN0/通道/搜索范围/真值与模型 → 信号秒/硬件周期/假定clk处理秒/主机墙钟 → 成功定义/次数分母/失败/未完成下界/CI → 实测值/通过覆盖/尚缺依赖。`reports/f_stage/performance/PERFORMANCE_REPORT_TEMPLATE.md`由计划入口生成，未执行项保留状态与原因。

已有记录复验用 `scripts/validate_g_delivery.ps1`（教师协议、独立NAV、E前缀、数据通路和因果重放）；按指标重评分用 `scripts/rescore_g_evidence.ps1`。两者会写派生结果，应对新证据副本执行。历史冻结/全阶段审计独立保留，不再纳入默认复验。长采集和定向实验入口见 G 报告。
