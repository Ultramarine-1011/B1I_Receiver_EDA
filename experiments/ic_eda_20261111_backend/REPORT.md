# 本地六通道 ASIC 预演与实验室准备

2026-11-11，个人 Windows + VMware IC_EDA。起点 `b8b887c`，实验分支 `codex/ic-eda-personal-local-smoke-20261110`。实际工具为 DC O-2018.06-SP1、VCS O-2018.09-SP2。综合使用 TSMC90 typical，单核 medium，顶层周期 10 ns。

## 结果

| 项目 | V6 源码重建 | 4 ns 算术分块预算 |
|---|---|---|
| 面积 µm² | 486269.185663 | 499790.599561 |
| Setup WNS ns | −18.646854 | −10.948725 |
| Setup TNS ns，报告端点求和 | −3179.539771 | −2019.864519 |
| Setup 违例端点 | 414 | 414 |
| Hold WNS ns | −0.162817 | −0.162817 |
| Hold 违例端点 | 1917 | 1987 |
| 叶级单元 / 时序单元 | 95123 / 2338 | 97975 / 2338 |
| 完整通道监控墙钟 s | 433.94 | 979.85 |
| 未映射 / 意外黑盒 | 0 / 0 | 0 / 0 |

WNS 改善 7.698129 ns，面积增加 2.78%。当前仍有 setup、hold 违例。两次新完整单通道映射均在 20 分钟以内。功能实现采用同一份 V6 RTL，SHA256 为 `ad3766423995a8ee7d8d2da0c4c87e271df794d25aea277517ed1994e3abee88`。精确指标及各轮资源记录见机器可读清单。[metrics.json](metrics.json)

## V6 来源与重建

原生成流程在独立临时树完整运行，生成逐字节相同的 V6 RTL。原始运行包、当前 RTL、工具、DesignWare、库及五个缓存 DDC 的哈希核对通过。原 DDC 重新导出的 Verilog 与原网表忽略注释、空白后相同，分别读取两者得到一致面积、时序及单元数。

五个算术块从源码重建耗时 971.86 秒，之后完整通道重建得到上表左列，与原 V6 面积和 WNS 相同。45 个网表模块中，44 个的端口和连接语句一致。Code NCO 存在内部命名/映射排列差异，补做了 200000 拍映射网表对比，九组输出逐拍一致，并检查未知值。该项采用零延迟功能仿真。三个重新映射的反馈算术块另经 20007 组独立整数除法参考比较通过。[来源审计](evidence/source_audit.json) [NCO 源清单](evidence/nco_rebuild_sources.json) [NCO 运行](evidence/nco_equivalence/run.log) [算术运行](evidence/mapped_arithmetic/run.log)

DC 将 `**logic_0**`、`**logic_1**` 常量驱动器标为 `is_black_box`，原 DDC 包含 256 个这类伪单元。统计已扣除它们，并与 `report_qor` 的物理叶级单元数核对。

新缓存身份覆盖 RTL、映射 Tcl、目标库、DC、DesignWare、工况、驱动、负载和分块预算。完整通道复用另核对 B0 依赖、include、SDC、参数和网表/DDC 哈希。故意改用 fast 库和错误分块预算均在启动 DC 前被拒绝。实验室综合入口从 RTL 映射全部算术块，导出与功耗阶段恢复同版最终 DDC。[库切换拒绝](evidence/failures/cache_wrong_library.log) [预算切换拒绝](evidence/failures/cache_wrong_profile.log)

## 时序诊断

原最差路径从 `frontend/correlator/qp_reg[11]` 到 `code_step_q_reg[27]`，数据到达 28.381390 ns。PLL 归一化约 9.784723 ns，载波换算约 5.645468 ns，载波辅助换算约 7.921028 ns，三段组合运算在同一反馈拍串联。

本轮仅收紧这三个算术块的内部映射预算。独立块路径分别达到 6.52、3.39、3.23 ns，PLL 归一化仍有块级违例。完整通道重新计时后，最差路径转到 `previous_qp_reg[22] → code_step_q_reg[30]`，经过 Prompt 乘法与加减、16 次 CORDIC 向量旋转、环路限幅、控制字换算及辅助换算。数据到达 20.683758 ns，其中 CORDIC 约 9.757708 ns、载波换算 3.222545 ns、辅助换算 2.947073 ns，共 352 级逻辑。[最终路径](evidence/fast_v6_channel/reports/timing_max.rpt)

高扇出报告中 `clk` 为 2338，`reset_n` 为 796。组合算术串联主导当前最差数据路径。两份结果使用相同的顶层 10 ns、1/0 ns IO 延迟、0.2 ns 不确定度及四倍 INV 输入电容负载。内部虚拟时钟在拼接前清除。当前时钟采用理想模型，库未选择 wire-load model。外部复位继承原例外，复位恢复/移除列为未验收项。实验室专用 SDC 对复位施加 min/max 延迟并传播 PAD/时钟单元弧。[SDC](evidence/fast_v6_channel/reports/mapped.sdc) [扇出](evidence/fast_v6_channel/reports/fanout.rpt) [约束检查](evidence/fast_v6_channel/reports/check_timing.rpt)

## 六通道预演

唯一一次 `bds_bb_6ch_core` 预演采用可靠重建的 V6 通道映射，沿用 M2 的 PCPS 隔离模块。analyze、elaborate、link 及 `check_design` 已执行，确认六个跟踪实例，预检查记录了 PCPS 空模块告警。完整映射在 1800.27 秒受到预算终止，DC 退出 1，监控原因为 TIMEOUT。最终网表、DDC、面积和时序报告尚未生成。

峰值 RSS 为 6602496 KiB，约 6.30 GiB，CPU 99%，采样 swap 峰值为 264 KiB。停止时仍在 DesignWare/GTECH 映射，日志包含 64×33、64×43 等宽除法实现。剩余交接、相位处理及导航/记录运算需继续做模块级成本诊断。本轮捕获存储未综合，PAD 未包含在此核心实验中。[六通道日志](evidence/core6_v6_isolated/reports/run.log) [资源](evidence/core6_v6_isolated/reports/time.txt) [实例层次](evidence/core6_v6_isolated/reports/hierarchy_pre.rpt)

## PCPS/FFT 存储

当前源码的可变数据数组合计 **1768768 bit**。历史 2293056 bit 还包含 PCPS/FFT 两处 cos/sin 表，共 524288 bit。M2 已将这些表改为组合 function/case。

| 数组 | 声明位数 | 端口及访问 |
|---|---|---|
| raw | 196416 | CAPTURE 单写，replay 异步读 |
| base_r/base_i | 523776 | 每四个样本写一次，各有异步读，读写阶段分离 |
| code/signal 四数组 | 524288 | STORE 阶段单写，LOAD_PRODUCT 并行读 |
| accumulated_power | 262144 | EVALUATE 同地址读改写，首窗口直接覆盖 |
| FFT re/im | 262144 | 蝶形同拍双读双写，额外外部异步读，闲时单写装载 |

数组均使用同一上升沿，内容没有全量复位。当前目标库配置没有 RAM 宏。16/64 深度的小探针表明异步和同步写法均展开为触发器。

| 16 bit 宽探针 | 时序单元 | 面积 µm² |
|---|---|---|
| 异步 3R/2W，深度 16 / 64 | 256 / 1024 | 8635.84 / 35160.75 |
| 同步 1R/1W，深度 16 / 64 | 272 / 1040 | 6134.49 / 23897.26 |

最低代价候选包括按工作阶段复用端口、打包实虚部、FFT 用地址各位 XOR 的双银行分配，以及验证后将 base 数据从 16 bit 缩至 4 bit。FFT 每级蝶形的两个地址恰好相差一个地址位，适合分到不同银行。同步宏将引入读延迟，需调整 FFT/PCPS 状态与流水调度，并重跑逐点回归。当前真实全量六通道综合仍受存储实现和映射成本阻塞。[存储探针](evidence/memory_ports/reports/run.log)

## 实验室入口与实际验证范围

携带包包含所需 RTL、脚本、六星 IF 和独立比特真值，约 0.64 MiB。解包后的正常入口已经重新执行过预检、八位移位寄存器综合、SS/FF SDF、MAX/MIN VCS、VCD→SAIF 和 Power Compiler。两角各 300 拍检查通过，SAIF 时长 3.04 µs，nets/ports/pins 活动覆盖 100%。功耗约为内部 9.242 µW、开关 0.984 µW、漏电 0.304 µW、合计 10.530 µW，属于该 TSMC90 小探针。另用实际 VCS 波形验证了 100 ns 活动窗口裁切、时间平移及 SAIF 时长，并通过 20 ns 小探针参数回归。[入口与顺序](LAB_RUNBOOK.md) [携带包](evidence/LAB_INPUTS.tar.gz) [本地流程日志](evidence/lab_validation/portable_validation.log)

六通道 PAD 测试平台通过 VCS 语法分析，完整 TSMC28 PAD、存储宏、六路 SDF 及芯片功耗仍待实验室实跑。计数器冒烟捕获了 XOR2X1/ADDHX1 的 28 条 IOPATH 模型不匹配，自动检查已拒绝该次结果。需取得匹配的标准单元时序模型并核对条件弧与负时序检查。历史 M1 缺少的标准单元 Verilog，以及可实现的 PCPS/FFT 存储源与宏库，均在运行清单中列为实际缺口。[模型匹配失败](evidence/failures/counter_sdf_iopath/compile.log)

原始网表/DDC、大日志和大型路径报告由 `evidence/artifacts.tar.gz` 保存，文件哈希见 `evidence/artifacts.json`。解包命令为 `tar -xzf evidence/artifacts.tar.gz -C evidence`。各阶段实际脚本快照位于 `evidence/frozen_scripts`，监控退出码、时间及资源记录保存在对应运行目录。
