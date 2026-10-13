# 性能报告模板（未执行值保持空）

正式要求见docs/PERFORMANCE_EVALUATION.md；手算/控制层PASS不填正式receiver PASS。

| 项 | 状态 | 场景/哈希/配置/种子/真值 | 试验次数/失败 | 信号秒/周期/clk处理秒/墙钟 | 指标/CI/原因 |
|---|---|---|---|---|---|
| P01 | BLOCKED_INPUT | 未具备完整条件 | — | — | 40dB-Hz full phase/frequency midpoint/NH coverage scenarios and independent truth |
| P02 | NOT_RUN | 未具备完整条件 | — | — | individual queued/accepted/verified task cycle traces |
| P03 | BLOCKED_INPUT | 未具备完整条件 | — | — | 100 present plus 100 absent independent seeds per CN0 and offline truth |
| P04 | BLOCKED_INPUT | 未具备完整条件 | — | — | 10 independent >=180s >=6D1 PDOP<=4 cold-start scenarios plus causal online solver |
| P05 | BLOCKED_INPUT | 未具备完整条件 | — | — | per-CN0 cold-start scenes, complete 60s followup and causal solver |
| P06 | BLOCKED_INPUT | 未具备完整条件 | — | — | 60s independent code/frequency and transmitted D1 word truth at each CN0 |
| P07 | BLOCKED_INPUT | 未具备完整条件 | — | — | 12D1/40dB-Hz legal D01-D04 scenes and code/frequency/word truth |
| P08 | BLOCKED_INPUT | 未具备完整条件 | — | — | legal nominal 2s signal interruption and restored valid observation scene |
| P09 | BLOCKED_INPUT | 未具备完整条件 | — | — | fixed ECEF truth and uniform geometry/seed/model, full 60s after causal confirmation |
