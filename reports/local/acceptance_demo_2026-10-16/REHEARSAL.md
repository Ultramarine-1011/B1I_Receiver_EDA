# 线下演示预演记录

日期：2026-10-16，Asia/Singapore。环境：本机 Windows PowerShell 5.1、ModelSim SE-64 10.5；使用当前学生 RTL 和原自检 TB。TB 隔离副本只重定向输入/输出路径，导航向量由已有 `work/navigation/*.mem` 原样复制到 `scripts/demo_acceptance/vectors/`。

## 实际运行

| 项目 | 退出码 | 自检与实测耗时 | 现场模式 | 日志 |
|---|---:|---|---|---|
| PCPS＋原始 IF 精搜 | 0 | PASS，3.032 s；PRN6、lag0、FCW0、65472 样本 | 实跑 | [acquisition.log](acquisition.log) |
| 跟踪双用例，各 1 s IF | 0 | PASS，77.324 s；各 999 次反馈，尾段锁定率均 1.0 | 读取完整 PASS 日志及 WLF | [tracking.log](tracking.log) |
| NH/位/字/BCH | 0 | PASS，1.993 s；NH0/7/19、三例九字 | 实跑 | [nh.log](nh.log) |
| 双子帧导航 | 0 | PASS，2.281 s；两例共 20 条 type2，背压和失锁复位检查通过 | 实跑 | [navigation.log](navigation.log) |

最终 `powershell.exe -NoProfile -File scripts/demo_acceptance.ps1 -Action all` 退出 0，完整现场命令流程约 9 s（跟踪采用已完成结果回放，不含 GUI 启动和讲解）。`-Action evidence` 读取 E100 原有教师 self_check PASS，退出 0；未运行整机采集。菜单 5→0 的输入、结果显示和退出已测试。

捕获、跟踪、NH、导航的 `.do` 文件保存了信号列表、进制、列宽和局部时间范围。已通过 Computer Use 打开并观察 ModelSim 的捕获、跟踪反馈和导航确认视图；NH 的 WLF 打开及配置执行也已核对。WLF 保存在本机 `work/acceptance_demo/runs/`，对应位置及哈希见 [rehearsal.json](rehearsal.json)。运行源与输入哈希见 [sources.json](sources.json)。

## 演示入口调整记录

最初包装脚本修正了 Windows PowerShell 原生进程退出码读取、大小写不敏感变量重名、NH 完整 PASS 标记和字符串 JSON 序列化问题；这些问题均发生在新演示入口，原 RTL/TB 判据未改。完整跟踪首次 77.324 s PASS；随后一次重复试跑在已有 GUI 并行打开时耗时波动，包装器超时清理及管道等待共 360.783 s，退出 124，保留[该次日志](tracking_repeat_timeout.log)。按现场时间预算，最终入口固定重放首次完整 PASS 与 WLF，输出明确标为 REPLAY；轻量实跑入口加入进程树超时终止，保留新目录和失败日志。

跟踪首次运行的源与后来演示目录的源、向量逐内容哈希核对一致；导航三份向量只改变存放路径。已完成的完整跟踪 WLF 保留启动至两个用例末尾，取代 10 月 14 日仅启动片段的旧波形。本次准备未更改接收机 RTL、教师文件、原测试、三份报告和历史证据。
