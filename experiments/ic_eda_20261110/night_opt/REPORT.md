**完整单通道综合最终成功了吗？成功。完整映射、网表和报告已生成，10 ns 下有 setup 与 hold 违例。**

2026-11-11，Asia/Singapore。最终采用 V6，源码 SHA256 为 `ad3766423995a8ee7d8d2da0c4c87e271df794d25aea277517ed1994e3abee88`。

## 最终结果

| 项目 | 实际结果 |
|---|---:|
| DC 退出码 / 未映射单元 / 黑盒 | 0 / 0 / 0 |
| 标准单元面积 | 486269.185663 µm² |
| 叶级单元 / 时序单元 | 95123 / 2338 |
| 最差数据路径 | 28.381390 ns，420 级逻辑 |
| Setup WNS / TNS | −18.646854 / −3179.539771 ns |
| Setup 违例端点 | 414 |
| 最差 hold slack / 违例端点 | −0.162817 ns / 1917 |
| DC 墙钟 / 宿主观测 | 464.37 / 470.19 秒 |
| 峰值 RSS | 635876 KiB，约 621 MiB |
| 最大转换 / 电容违例 | 0 / 0 |

使用原 B0 的 O-2018.06-SP1、TSMC90 typical、`ENABLE_FLL=1`、`ENABLE_CARRIER_AID=1`、单核 medium 映射和 10 ns 外部 SDC。工具、DesignWare、目标库的 SHA256 与 B0 一致。面积为标准单元面积，时序采用理想时钟，当前库没有选定 wire-load model。

最终实现采用分块综合并固定已映射算术块。块内使用 10 ns 虚拟时钟和零内部 IO 延迟，随后清除块约束，完整顶层按原 B0 的 1 ns 外部 IO 延迟、负载和 10 ns 时钟重新计时。最终 SDC 包含一个 `clk`，时序例外为原异步复位。默认约束检查对 `reset_n` 报 TIM-216，与该复位例外对应。

## 优化与验证

- DLL 采用 8 级 radix-4 精确试减。相同独立模块探针从 92.15 秒降到 68.96 秒，面积从 41266.31 增到 49580.40 µm²。radix-16 的面积和耗时明显恶化，结果归档。
- 控制字换算采用精确 signed ceil-reciprocal 乘法及负数舍入，覆盖完整 signed 40/33 位输入域。换算模块面积从 32080.81 降到 23779.43 µm²，降低 25.9%，耗时从 44.79 降到 13.32 秒。
- Verilator/VCS 均通过 214883 组归一化、210169 组常数除法、100625 组 18 字段完整环路及 995 窗公开 Prompt 重放。四个单通道场景的 32 输出逐拍一致。六通道正常、恢复各处理 49104000 样本、235 正确导航位，周期为 50518067/50516937。顶层端口、参数和整个时序块与 V4 统一行尾后文本一致。
- 综合网表的三个常零输出为 `fll_error_q16[2:0]`，与乘数 1000 可被 8 整除一致。五组短接输出位均位于 DesignWare 算术的符号扩展位。其余设计警告主要来自截断、常数连接和分块保留的无负载内部端口。[功能及来源检查](evidence/delivery_checks.json) [综合后审计](evidence/postmap_audit.json)

最差路径为 `frontend/correlator/qp_reg[11]` 到 `code_step_q_reg[27]`，经过 PLL 归一化、环路计算、载波换算和载波辅助除法。该路径中三个算术块分别占约 9.785、5.645、7.921 ns。10 ns 的主要障碍是这些组合运算串接在同一反馈拍内。

## 尝试与交付

三次完整尝试依次为 V5 平坦综合、V6 分块预映射、V6 复用映射块。前两次在宿主截止后退出 1，实际分别为 1188.02/1188.66 秒。第二次保存了五种模块的真实 DDC，第三次复用这些结果后完成完整通道。V5 已保存为本地提交 `346606e`，最终 V6 源码、证据和本交接保存在本实验分支最新提交。

- [最终网表](evidence/full_v6_cached_10ns/mapped.v)、[DDC](evidence/full_v6_cached_10ns/mapped.ddc)、[SDC](evidence/full_v6_cached_10ns/mapped.sdc)
- [面积](evidence/full_v6_cached_10ns/area.rpt)、[Setup 路径](evidence/full_v6_cached_10ns/timing_max.rpt)、[Hold 路径](evidence/full_v6_cached_10ns/timing_min.rpt)、[完整日志](evidence/full_v6_cached_10ns/run.log)
- [各轮指标](metrics.json)、[独立模块原始证据](evidence/module_dc.tar.gz)、[网表与模块 DDC 归档](evidence/dc_netlists.tar.gz)

大网表及 DDC 在 Git 中按压缩包保存，本机保留解包原件。可在本目录运行 `tar -xzf evidence/dc_netlists.tar.gz -C evidence` 恢复同名文件，逐文件 SHA256 见 [归档清单](evidence/netlist_archive.json)。

复现 RTL 生成顺序为 `prepare_radix.py`、`prepare_constants.py`、`prepare_accepted.py`、`prepare_hier.py --activate`、`prepare.py` 和 `prepare_loop_equivalence.py`。测试入口为 `scripts/run_local.ps1` 与 `scripts/run_vcs.sh`。完整综合入口为 `bash scripts/run_scoped.sh cached <新标签> 1200`，读取第二次 run 的五个 DDC，并核对源码与环境哈希。宿主同时使用 `scripts/run_host.py`，凭据经 stdin 传入。该入口在 1185 秒发出终止信号，为 1200 秒上限保留退出时间。

最终功能、来源、约束和归档检查通过。本轮 DC 与仿真进程已清理，工作结束。
