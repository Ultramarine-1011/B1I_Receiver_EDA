# 2026-11-10 PRN 环境验证归档

原位置为 `experiments/ic_eda_20261110/`。2026-11-11 将该轮 PRN/环境资料整体迁到此处，B0、算术探索和 V6 继续保留原位。

- [报告](REPORT.md) 保存 TSMC90、SSH/SCP、VCS/DC 实际结果。
- [最终运行](runs/20261110_180446/reports) 包含 PRN 网表、DDC、SDC、日志和时序报告。
- [指标](metrics.json) 和 [核对脚本](scripts/verify_results.py) 用于复核已有证据。
- `input.tar.gz`、`final_input.tar.gz`、`results.tar.gz`、`final_results.tar.gz` 对应初版及修正版传输记录，各自保留。

从仓库根目录运行 `python experiments/archive/2026-11-10_prn_environment/scripts/verify_results.py` 可复核。这里的 `python` 应为实际 Python 解释器，Windows 可用 bundled Python 或 `wsl.exe -d Ubuntu -- python3`。该历史脚本会重写本目录 `metrics.json`，检查时可在安全副本执行。

归档后仅修正报告中的本地路径示例和核对脚本的仓库父目录层级。原工具脚本、源、数据和结果保持原字节。客体路径 `/home/ICer/ic_eda_smoke_20261110` 保留对应历史机器含义，当前可达性未重新测试。
