# 交接入口

唯一当前状态及下一任务见 [STATUS](../STATUS.md)，当次授权范围见 [GOAL](../GOAL.md)，真实运行/提交事件见 [WORKLOG](../WORKLOG.md)，协作纪律见 [AGENTS](../AGENTS.md)。

2026-11-06 M1 已完成：[预检报告](../reports/m1_tsmc28_20261106/REPORT.md)。工具、三套标准单元角和 TPHN28 PAD 时序/仿真模型已在虚拟机上核对。直接展开现有六通道 RTL 做首次全芯片 DC 被 ROM 初始化被忽略、以及缺少存储器宏这两项挡住。

**当前 M0–M5 规划：** 见[六通道后端里程碑路线图](COURSE_MASTER_PLAN.md#后续里程碑路线图2026-11-02)。下一候选是另行授权后的 M2：先处理 `$readmemh` 和大存储，再做 `bds_bb_6ch_pad_top` 与受控首次映射。不要把 100 MHz 功能测试时钟当成已签核的 ASIC 周期，也不要启动完整接收机 compile、SDF 后仿或 ICC。

六通道功能证据仍是 [最终报告](../reports/six_channel_20261102/FINAL_REPORT.md)。H0/H1 的 SAED90nm 与部分前端综合不等于本次 TSMC28 结果。
