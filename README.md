# 个人 TSMC90 实验

本目录为独立本地 Git 仓库，完整复制整理前 `cf8d4df` 的分支和提交对象，再迁移实际实验文件。课程源码位于相邻的 `B1I_Receiver_EDA`。当前分支为 `codex/workspace-layout-20261111`，未配置推送远端。

- [TSMC90_V6/Results](TSMC90_V6/Results) 直接包含 `mapped.v`、`mapped.ddc`、`mapped.sdc`、面积和时序报告。技术版本 `b8b887c`，RTL SHA256 为 `ad3766423995a8ee7d8d2da0c4c87e271df794d25aea277517ed1994e3abee88`。
- [Backend_20261111/Results](Backend_20261111/Results) 包含 `clean_v6_channel` 和 `fast_v6_channel` 的网表、DDC、SDC及报告，配套算术块缓存一同保存。技术版本 `c3ba596`，具体工艺库、参数、机器和验证证据见 [REPORT](Backend_20261111/REPORT.md)。
- [History](History) 实际保存 B0 冻结源码、V1–V4、独立 BDI PRN6 和早期 PRN 环境实验。

V6 使用 TSMC90 typical 库、10 ns 单通道约束。原始 setup WNS −18.646854 ns，11 月 11 日分块预算版本为 −10.948725 ns，仍有时序违例。六通道映射超时，未产生完整六通道网表。

已有证据中的原路径和时间保持原记录。当前脚本使用相邻课程目录，也支持 Python 入口的 `B1I_PROJECT_ROOT` 环境变量。原版实验室包保持原内部结构，新打包入口保留同一解包协议。
