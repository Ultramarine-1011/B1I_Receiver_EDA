# 本地六通道 ASIC 预演与实验室准备

2026-11-11，个人 Windows + VMware IC_EDA。起点 `b8b887c`，实验分支 `codex/ic-eda-personal-local-smoke-20261110`。实际工具为 DC O-2018.06-SP1、VCS O-2018.09-SP2。综合使用 TSMC90 typical，单核 medium，顶层周期 10 ns。

## 夜间六通道实验，2026-11-12

**本轮整体墙钟已超过 6 小时上限，发现时约 11 小时 37 分钟。统一守护遗漏了推理与交付时间。发现后停止全部综合与仿真进程，只收集已有结果和整理交付。** 两次大型核心尝试均保存原始日志、退出码和资源记录。

工作分支为个人仓库的 codex/workspace-layout-20261111，起点 2222eff。当前候选 RTL 位于本目录 rtl/，跟踪主体为 V6。

| 范围 | 实际结果 |
|---|---|
| 完整隔离存储核心，第一次 | 提前展开包装层，705.01 s 后因发现缓存链接问题主动停止，采样峰值 3627328 KiB |
| 完整隔离存储核心，第二次 | 修复命名冲突，3009.20 s 后触发 RSS_LIMIT，采样峰值 8416268 KiB，退出 1 |
| 六路跟踪阵列分层集成 | DC 51.43 s，监督墙钟 51.85 s，退出 0，峰值 RSS 1798248 KiB |
| 阵列标准单元面积 | 2998743.597369 µm² |
| 阵列 Setup / Hold WNS | -10.948725 / -0.162817 ns |
| 阵列物理叶级 / 时序单元 | 587850 / 14028 |
| 阵列 setup / hold 违例端点 | 2484 / 11922 |
| 阵列未映射 / 黑盒 | 0 / 0 |

阵列由六份已经验证的 fast V6 完整跟踪通道 DDC 连接而成，使用独立数据和配置端口、共同 clk/reset_n，导出实际层次 Verilog、DDC 和 SDC。范围包括六个跟踪通道，接收管理、导航、捕获及 PAD 处于该阵列范围之外。沿用 TSMC90 typical、10 ns、0.2 ns 不确定度、1/0 ns IO、0.006604 pF 负载及原异步复位例外。完整核心两次尝试均未得到最终 PPA。第二轮在第六阶段优化期间接管为 90 分钟硬上限，随后先触发 8 GiB 内存限制。[网表](Results/tracking_bank6/mapped.v) [DDC](Results/tracking_bank6/mapped.ddc) [面积](Results/tracking_bank6/area.rpt) [Setup](Results/tracking_bank6/timing_max.rpt) [Hold](Results/tracking_bank6/timing_min.rpt)

### 缓存复用与剩余复杂度

旧脚本按网表文本模块名删除设计，遗漏了带前导空白的模块声明，link 对同名 .db/.ddc 给出 UIO-92。检查实际核心实例路径时，六个跟踪实例内合计存在 7734 个 GTECH 单元和 17370 个未映射叶级单元。修正后先在空设计环境读 DDC，以独立命名空间改名，再 elaboration 核心并 change_link。1139 个端口位名称及方向逐项一致，每通道 98231 个含常量伪单元的叶级单元，实际六路路径核对为 589386、GTECH=0、UNMAPPED=0。库、DC、DesignWare、冻结源码、参数和约束身份已核对。

第二轮仍展开导航和记录时间戳除法并耗尽本轮 RSS 预算。后续个人 RTL 增加 EXPORT_RECORDS 参数，默认值 1 保留原记录接口。六通道核心使用值 0，关闭顶层未消费的记录数据构造，保留记录有效、发布和反压控制。共裁剪 24 处源码时间戳宽除法表达式。NH 取模改为六位有界减法，SOW 回绕改为覆盖全部二十位输入的一次比较减法。代码周期除法利用 2046×2^32=1023×2^33 做精确数字折叠，处理全部 unsigned64 输入。

- 周期折叠 VCS 206340 组随机及边界输入通过。独立 DC 4.60 s 完成，面积 1402.732809 µm²，数据到达 3.843522 ns。原表达式探针触及其 512 MiB 限制，未取得最终 PPA。[折叠网表](Results/period_reduce/mapped.v) [模块报告](Results/period_reduce/timing.rpt)
- 新导航与原参考进行 12 路逐拍控制对照，原参考仍按 120 个记录字评分。全部 64 个 NH 取模输入、1048576 个 SOW 输入通过。原记录字段两场景回归通过。
- 新核心 Prompt 级 VCS 检查通过六路 1080 位导航，覆盖六种 NH 相位、双极性、间歇输入、失锁重启和复位。当前 RTL 与实际测试版本去注释空白后逐项一致。
- 导航独立映射探针仍在 NH 相位选择优化中消耗较长时间。几次探针因各自超时或人工停止结束，未保存最终导航 PPA。新候选完整六通道映射尚待实际执行，本轮大型尝试总数为两轮。

### 周五入口与验证范围

`lab/run_lab.sh budgeted` 先在目标工艺从源码映射算术块和完整跟踪通道，保存可恢复检查点，再在真实 PAD 顶层复用六路。主尝试最多 75 分钟。失败时恢复本次单通道检查点，尚无检查点时从源码执行单通道降级，取剩余窗口与 35 分钟的较小值。总工具窗口 5980 秒，加最多约 10 秒清理，为两小时保留约 20 分钟检查保存。RSS 默认上限 8 GiB。内部复位采用 0.1 ns 边界转换时间并保留时序检查，最终芯片按原 PAD SDC 重新计时。

本地原生 DC 检查点恢复 17.27 s 退出 0。错误库拒绝、缺库失败汇总、RSS 限制和独立子进程组超时清理已实测。最终入口做 Bash/Python 语法及四个流程分支检查，最新完整 TSMC28/六通道入口尚未实跑。携带包使用当前源码与脚本清单，原携带包保留。命令见 [LAB_RUNBOOK](LAB_RUNBOOK.md)。[完整新增原始证据](evidence/night6_final_results.tar.gz) [缓存及早期流程证据](evidence/night6_support_20261112.tar.gz) [指标](evidence/night6/metrics.json)

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

本轮仅收紧这三个算术块的内部映射预算。独立块路径分别达到 6.52、3.39、3.23 ns，PLL 归一化仍有块级违例。完整通道重新计时后，最差路径转到 `previous_qp_reg[22] → code_step_q_reg[30]`，经过 Prompt 乘法与加减、16 次 CORDIC 向量旋转、环路限幅、控制字换算及辅助换算。数据到达 20.683758 ns，其中 CORDIC 约 9.757708 ns、载波换算 3.222545 ns、辅助换算 2.947073 ns，共 352 级逻辑。[最终路径](Results/fast_v6_channel/reports/timing_max.rpt)

高扇出报告中 `clk` 为 2338，`reset_n` 为 796。组合算术串联主导当前最差数据路径。两份结果使用相同的顶层 10 ns、1/0 ns IO 延迟、0.2 ns 不确定度及四倍 INV 输入电容负载。内部虚拟时钟在拼接前清除。当前时钟采用理想模型，库未选择 wire-load model。外部复位继承原例外，复位恢复/移除列为未验收项。实验室专用 SDC 对复位施加 min/max 延迟并传播 PAD/时钟单元弧。[SDC](Results/fast_v6_channel/reports/mapped.sdc) [扇出](Results/fast_v6_channel/reports/fanout.rpt) [约束检查](Results/fast_v6_channel/reports/check_timing.rpt)

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
