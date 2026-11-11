# 原始 RTL 综合基线 B0 / B1

2026-11-10，Asia/Singapore。个人 Windows + VMware `IC_EDA`，TSMC90 typical。B0 为 TIMEOUT，B1 为 SKIPPED。

## 冻结条件

| 项目 | 本轮设置 |
|---|---|
| 仓库 HEAD | `5586384`，完整 SHA 见 `evidence/start.json` |
| 最新远端 main | `fb662d36e85e9cffe02a4b8f003887808f73007c`，本轮 fetch 退出 0 |
| 分支 | `codex/ic-eda-personal-local-smoke-20261110` |
| 正式源比较 | HEAD 与 origin/main 的 RTL、隔离源及 M2 脚本差异检查退出 0 |
| B0 顶层 | `tracking_channel_minimal` |
| B0 参数 | `ENABLE_FLL=1, ENABLE_CARRIER_AID=1`，其余参数沿用源码 |
| B1 候选顶层 | `bds_bb_6ch_core`，保留全部默认参数及六个 `CHANNEL_ID` |
| 工具 | Design Compiler O-2018.06-SP1，linux64，2018-07-19 |
| DC 可执行文件 | `/home/synopsys/syn/O-2018.06-SP1/linux64/syn/bin/common_shell_exec` |
| DC 可执行文件 SHA-256 | `39f25799c524d8c15f5e0e6dcc9100137db860edfed2147640420ce750637038` |
| 标准单元 DB | `/home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db` |
| DB SHA-256 | `8022bc0d744d01fcc93b8c7387d9de6d33d674c29c81beba0e0496d2dde1702a` |
| 工艺角 | `typical`，1.0 V，25 °C |
| 时间 / 电容 / 面积单位 | ns / pF / µm²，沿用上一轮 Liberty 与 LEF 核对 |
| DesignWare | `dw_foundation.sldb`，目标库仅 typical.db，link 含 `*`、typical.db、dw_foundation.sldb |
| DesignWare SHA-256 | `6e8b2e24d9f502a070be8876923fa9e006d98cd12a531c52656beab1f2767d70` |
| 分析与映射选项 | `analyze -format sverilog -define SYNTHESIS`，`compile -map_effort medium` |
| CPU | VM 8 vCPU，`set_host_options -max_cores 1`，与上一轮 PRN 实验相同 |
| 内存与 Swap | VM 配置 10240 MiB，Linux MemTotal 9818 MiB，Swap 10235 MiB |
| 运行预算 | 每阶段完整 DC 进程 1200 s，TERM 后 10 s 仍未退出则 KILL |
| 内存提前停止条件 | MemAvailable <256 MiB 且 Swap 使用 >2048 MiB |
| 进程资源上限 | 沿用现有 shell `ulimit`，实际输出保存在阶段 `system_before.txt` |
| 客体目录 | `/home/ICer/ic_eda_baseline_20261110` |

DC 核数上限由本轮自主选择，沿用上一轮条件以方便后续 A/B 对照。实际 CPU 使用由 `/usr/bin/time` 和 5 秒采样给出。VM 配置的 8 vCPU 仅表示客体资源。

[冻结输入 SHA-256](frozen_sha256.txt)覆盖 17 份 RTL/include/隔离源、两份文件列表及五份运行脚本，共 24 项。`sources/` 是当前工作树逐字节副本。B0 的文件列表含 PRN、码 NCO、载波混频、E/P/L、spaced frontend 和 tracking channel 六份 SV，另保留载波 LUT include。后加的进程采样及报告提取脚本分别记录版本与用途。[B0 文件列表](filelists/B0.txt) [B1 候选文件列表](filelists/B1.txt)

## 约束

| 项目 | 设置与依据 |
|---|---|
| 时钟 | `clk`，10 ns，理想时钟网络，clock transition 0.1 ns |
| Setup / hold uncertainty | 分别 0.2 ns，与上一轮条件相同 |
| 数据输入延迟 | max 1.0 ns，min 0.0 ns，涵盖所有非时钟/复位输入 |
| 输出延迟 | max 1.0 ns，min 0.0 ns，涵盖全部输出 |
| 数据输入驱动 | `typical/INVX1`，同步继承库的设计规则属性 |
| 输出负载 | 每个输出 `4 × INVX1/A`，DC 实算 0.006604 pF |
| 外部异步复位 | B0 `reset_n`，B1 `rst_n`，从该端口设 false path，与上一轮一致 |
| 线网模型 | enclosed，库实际未指定 wire-load model |

上述为独立对照实验条件。输入输出延迟为周期的 10%，驱动和负载取真实库单元。完整约束源文件及展开后的 SDC 随本轮保存。[SDC 源](scripts/baseline.sdc) [DC 脚本](scripts/dc_baseline.tcl)

B0 综合前 `check_timing` 已检查时钟、环路、输入延迟和 unconstrained_endpoints。无未约束功能端点条目。外部异步复位因上述 false path 未设 IO 延迟，保留一条 `TIM-216`。由此产生的复位时序排除纳入对照条件。[综合前检查](runs/B0/reports/check_timing_pre.rpt) [展开 SDC](runs/B0/reports/constraints_pre.sdc)

## 实际执行与恢复

VMware Tools 重新发现客体地址为 `192.168.236.129`。SSH 使用已有实验 `known_hosts` 严格校验，凭据仅通过进程 stdin 传递。客体启动时 available 8337 MiB，Swap 使用 0，目标库哈希与前轮一致。[环境初检](evidence/environment_initial.txt)

DC 首次预检在加载 Tcl 前退出 255，报 `DCSH-1`。同样的 `-f`、C locale、time/timeout 包装均未解决。`lmstat` 内容显示 lmgrd UP、snpslmd DOWN，尽管命令退出码为 0。用户随后明确授权恢复原服务，`lmutil lmreread -c 27000@IC_EDA -vendor snpslmd` 退出 0，snpslmd 恢复 UP，最小 DC 预检退出 0。预检失败单独保存。[失败定位](evidence/license_status_and_timed_preflight.txt) [授权后恢复](evidence/license_restore.txt)

运行入口先检查冻结源 SHA-256，再由独立 supervisor 运行 DC。监控器每 5 秒保存进程树 RSS、CPU、VM MemAvailable、Swap 及换页累计值。进程名最初按 `dc_shell` 匹配，而该版本实际为 `common_shell_exec`，所以主 CSV 的直接 DC 字段为 0。进程树数据从启动即完整保留，随后附加采样器按实际 PID 记录直接 RSS/VmHWM。本轮 GNU time 报告因下述停止处理缺陷缺失，内存结果采用附加采样器的累计 VmHWM。[实际监督脚本](scripts/monitor_stage.py) [附加采样器](scripts/sample_dc.py)

```bash
cd /home/ICer/ic_eda_baseline_20261110
bash scripts/run_stage.sh B0
```

阶段只可在新的空 `runs/B0` 或独立恢复目录中复现，避免覆盖本次证据。完整运行 argv、cwd 和 UTC 启动时间保存在阶段 `command.json`。大型 WORK、DDC 中间构建留在客体 `runs/B0/work`。Windows 仅取回必要证据及完成时的映射输出。

## B1 隔离边界

候选 B1 文件列表复用 M2 的 `synth/m2_isolate/acquisition_pcps_blackbox.sv`，替代正式 `acquisition_pcps`。隔离实例为顶层 `acquisition`，保留完整端口及参数，并设置 `dont_touch` 和禁止该实例的 boundary optimization。其内的 PCPS/FFT 逻辑、2,293,056 bit 捕获存储和相关 ROM 面积均缺失，缺失面积为 `NOT_AVAILABLE`。正式 PAD 顶层不在本轮文件列表中。

候选层次继续使用真实六通道 `receiver_channel`、带 FLL/载波辅助的跟踪、NH/D1 导航、精搜和顶层控制。后续若执行 B1，仍须以实际映射层次验证保留情况。B0 与 B1 面积受顶层可观测输出、层次共享和映射优化影响，不能直接相减计算通道面积。

## 最终结果

| 指标 | B0 单通道 | B1 六通道 |
|---|---|---|
| 状态 | TIMEOUT | SKIPPED |
| 观测墙钟 | 1248.69 s，约 20 分 49 秒，含终止处理 | N/A |
| 预算设置 | 1200 s | 1200 s 候选，未启动 |
| DC 峰值内存 | 2,739,704 KiB，2.613 GiB，累计 VmHWM 采样值 | N/A |
| 进程树峰值 RSS | 2,740,552 KiB，2.614 GiB，5 秒采样值 | N/A |
| VM 最低可用内存 | 5,752,820 KiB，约 5.49 GiB | N/A |
| VM 峰值 Swap 使用 | 0 | N/A |
| 末次采样 DC 累计 CPU | 124500 ticks，按客体 100 Hz 约 1245 s | N/A |
| 采样 CPU 峰值 | 111.56%，100% 对应一个逻辑 CPU | N/A |
| 单元面积 / 面积构成 / 单元数量 | NOT_AVAILABLE | NOT_AVAILABLE |
| 关键路径 | NOT_AVAILABLE | NOT_AVAILABLE |
| Setup WNS / TNS | NOT_AVAILABLE | NOT_AVAILABLE |
| Hold 违例 | NOT_AVAILABLE | NOT_AVAILABLE |
| 最后综合阶段 | `Mapping Optimization (Phase 1)`，无 compile 结束标记 | B0 进入条件未满足 |
| 主要瓶颈 | 宽算术映射耗时超过预算 | B0 未完成 |

从本次 UTC 启动时间 `2026-11-10T10:35:36.990430Z` 到最终终止消息的日志 mtime `1794308185.679907` 计算出 1248.69 s。采样内存是观测到的累计高水位，最后一次直接采样距离日志终点约 3.30 s。GNU time 的精确峰值和 user/system CPU 分项为 N/A。[结构化指标](metrics.json) [DC 原始日志压缩包](runs/B0/reports/run.log.gz) [直接进程采样](runs/B0/reports/dc_process.csv) [全程资源采样](runs/B0/reports/resources.csv) [时间戳原始观察](runs/B0/reports/completion_observation.json)

本轮监督器存在停止处理缺陷。它使用 `time.time()` 计时，并在自身观测到 1222.03 s 时对外层进程组发 KILL，返回 `-9`。GNU timeout 自行建立了独立进程组，DC 因而在该动作后仍运行，最终日志明确记录由 timeout PID 14146 发出的 SIGTERM。外层 GNU time 已结束，`time.txt` 为空，DC 最终退出码未被该包装器回收。实际结束后已核实 DC、timeout、两个采样进程全部退出。上述观测差异保留在报告中，未把设置的 1200 s 填作实测墙钟。[停止结果](runs/B0/reports/result.json) [结束及清理证据](evidence/B0_termination_cleanup.txt)

运行脚本已补充修正版 `monitor_job.py`，使用 `/proc/uptime` 单调计时和独立 DC 子进程组，停止 DC 时保留 GNU time。修正版短任务正常退出测试为 0，2 s 超时测试按预期返回 1，受监督命令因 SIGTERM 返回 15，GNU time 记录 2.04 s，外层监督总计 2.55 s，time 文件和内存报告完整。首次短测因旧版 ps 字段格式解析失败，已保存失败和清理记录，修正版改为直接读 `/proc`，最终回收验证通过。本轮 B0 仍对应原冻结脚本，修正后没有再次运行 RTL 综合。[修正版监督器](scripts/monitor_job.py) [修正版入口](scripts/run_stage_fixed.sh) [最终短测](evidence/monitor_fix_verification_final.txt)

原样复现上述 B0 执行使用 `run_stage.sh`。后续对照实验采用修正版入口，并固定其支持脚本哈希。

```bash
cd /home/ICer/ic_eda_baseline_20261110
bash scripts/run_stage_fixed.sh B0
```

B0 已完成 analyze、带参数 elaborate、link、综合前设计/时序检查，并进入映射。最终映射网表、DDC、最终 SDC、面积、QoR、setup/hold、DRC 和未映射单元统计均未产生。综合前约束和层次报告已取回。B1 的状态依据 B0 结果记录为 SKIPPED，候选捕获隔离脚本仅保存备查。[B1 条件记录](runs/B1/reports/gate.json)

## 警告与后续单项优化对象

DC 原始日志无 Error/Fatal 行。主要警告包括 185204 条 OPT-112、214 条 UID-401、20 条 VER-318、4 条 VER-281。OPT-112 来自移除无负载的内部 GTECH 单元，UID-401 来自驱动单元属性。VER-318 为现有 signed/unsigned 转换，VER-281 对应四处 `initial` 参数断言。综合前设计检查还保留未驱动负载、无负载网及未连接端口等 LINT 项。时序检查的 TIM-134 指出八条高扇出网，另保留上述复位 TIM-216。最终设计规则违例数量为 N/A。[日志提取](runs/B0/reports/log_analysis.json) [综合前设计检查](runs/B0/reports/check_design_pre.rpt)

后续最值得单独评估的对象为 `tracking_channel_minimal` 的宽组合除法实现，优先关注 DLL/Costas 归一化。原源码第 100、102 行的两个变量除法保持原样，DC 实际展开了 80×64、76×59、64×25、64×11、33×11 等 DesignWare 除法器。完整单通道在固定核数和预算内仍停留在宽算术映射，内存和 Swap 尚有余量。可以据此开展一次保持数学运算和精度要求的迭代除法实现实验，再用本轮冻结条件对照。由于最终路径与面积报告缺失，本轮尚不能量化各除法器面积占比或确定最终最差路径。[原始运算源码](sources/student_release/student_release/rtl/tracking_channel_minimal.sv) [DesignWare 展开证据](runs/B0/reports/check_timing_pre.rpt)

## 收尾

本轮成果全部保存在当前独立目录。源文件哈希与正式工程一致，正式 STATUS、GOAL、WORKLOG、AGENTS 及 M2 历史报告的哈希核对结果保存于最终验证记录。原有未跟踪资料保留，Git HEAD 仍为 `5586384`。本轮停止。[最终验证](evidence/final_verification.json)

## 本地 Git 交付

用户追加授权将本轮成果提交到当前实验分支。完整 DC 日志采用无损 gzip 保存，解压后的 SHA-256 与原始日志一致。原始文本及重复传输包保留本地，提交范围限定为本目录。[日志压缩核验](evidence/dc_log_archive.json)
