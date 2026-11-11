# IC_EDA 本轮状态

本实验由个人本地 Windows 主机及其 VMware `IC_EDA` 完成。材料归档分支为 `codex/ic-eda-personal-local-smoke-20261110`，实验库为 TSMC 90 nm typical。

2026-11-10，本轮完成并停止。Windows SSH 真实命令和 SCP 双向传输 PASS，PRN 源 RTL 功能回归 PASS，TSMC 90 nm typical 单模块映射 PASS，面积与时序报告生成 PASS，setup PASS，hold FAIL。

最终运行 `20261110_180446`，DC 退出 0、墙钟 2.64 秒、单元面积 1380.153630 µm²、关键路径 0.872390 ns。Hold WNS 为 −0.156530 ns，共 48 个违例端点。当前 DHCP 网络为临时恢复，重启需重新联网。

报告与复现入口见 [REPORT.md](REPORT.md)。后续任务等待用户另行授权。
