# 北斗 B1I 接收机线下验收演示

准备日期：2026 年 10 月 16 日。本机使用 ModelSim SE-64 10.5，演示直接运行现有自检 TB 和学生 RTL。建议总时长 **6～8 分钟**，无需联网。

## 1. 到场后先做什么

1. 接通电源，打开工程文件夹，双击 **`scripts/demo_acceptance.cmd`**。保持弹出的菜单窗口开启。
2. 输入 **5** 查看已预演的 PASS、耗时和日志路径。
3. 正常顺序为 **1 → 2 → 3 → 9 → 4**。每次输入数字后按回车；ModelSim 打开后切换到波形窗口讲解，讲完回到菜单。
4. 如果时间紧，按 **6 → 7 → 8 → 9 → 4**，直接打开本机已预演 WLF 和 E100 检查结果，约 5 分钟即可完成。

从工程根目录启动菜单的等价命令：

```powershell
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1
```

菜单 1、3 会现场运行自检并打开 WLF；2 读取已完成的跟踪双用例 PASS 并打开完整 WLF；6、7、8、9 只打开已保存波形。GUI 已配置好信号、进制和局部时间窗口。波形查看模式下无需点击 Run。菜单 **0** 退出；ModelSim 可单独关闭。

## 2. 现场演示顺序与讲解

| 顺序 | 菜单操作 | 建议用时 | 展示与讲解 |
|---|---|---|---|
| 开场 | 5 | 30 s | “设计由捕获、码载波跟踪、NH/位同步和导航电文恢复组成。下面先展示可控模块自检，再展示真实 IF 的整机结果。” |
| 捕获 | 1；赶时间用 6 | 1 min | 展示 PRN6、lag=0、频偏=0、粗峰和精搜有效脉冲。“FFT 粗搜产生候选，原始 IF 精搜确认参数，然后握手输出。” |
| 跟踪 | 2；只看图用 7 | 1～2 min | 读取已预演的完整双用例 PASS，展示积分结果和下一拍反馈。“DLL 调码速，Costas PLL 调载波；相关器窗口、控制字更新和真实样本编号有明确流水关系。” |
| 导航封装 | 3；赶时间用 8 | 1 min | 展示末字、frame/time_valid、record_ready 和 record_data。“连续两个完整子帧确认 SOW，再发布十字；反压期间首条记录保持。” |
| NH/BCH | 9 | 1 min | 展示 NH 锁定、bit_valid、word_valid、纠错数。“先擦除 NH，20 个 Prompt 合成一位；前导码统一极性，去交织后 BCH 纠错。” |
| 整机结果 | 4 | 30～60 s | “E 版本实际处理教师 100 s IF，自主捕获四星，RTL 恢复 560 字、324 条有效观测，教师 self_check PASS。” |

与三份报告对应：[捕获](ACQUISITION_REPORT.md)、[跟踪](TRACKING_REPORT.md)、[同步与电文](NH_D1_REPORT.md)。

### 捕获波形：结果确认与移交

配置文件：[acquisition.do](../scripts/demo_acceptance/acquisition.do)，打开范围 9620.350～9620.460 μs。

关注 `coarse_valid`、`coarse_detected`、`prn`、`coarse_lag/doppler`、`coarse_peak/mean`、`fine_valid/detected`、`fine_lag/doppler`。本例无噪声 PRN6、4 ms IF，缩网格搜索的预期 lag 和频偏均为 0。粗峰值为 308569539412，均值 222921079；精搜确认后 fine_valid 脉冲出现，握手后撤销。终端应显示 `P02_RTL_TIMING_PROBE_PASS`，样本数 65472。

讲解要点：完整设计使用 4096 点 FFT 同时搜索码相位，对 4 个 1 ms 窗累加相关功率；局部精搜回到原始采样周期，细化延迟与多普勒。现场用小网格展示相同两级 RTL 的连接和结果判决。

### 跟踪波形：相关积分与反馈

配置文件：[tracking.do](../scripts/demo_acceptance/tracking.do)，默认放大到 29810.220～29810.300 μs 的反馈更新。

关注 `ip/qp`、`ie/il`、`window_done`、`feedback_valid`、`dll_error_q16`、`pll_error_q16`、`code_step_q`、`carrier_step_word`、`locked`。本窗 Prompt I/Q 为 51708188/−3114158，window_done 后一拍发布反馈，载波字由 `400005b0` 变为 `40000577`。此处位于启动过程，接着展示完整测试的尾段锁定与 RMS。

想看锁定尾段，在 ModelSim 下方 **Transcript** 输入以下 ModelSim 命令并回车：

```tcl
wave zoom range 140000us 160000us
```

这一范围位于第一个 1 s 信号用例尾段，`locked=1`。默认波形范围和尾段范围均使用 TB 逻辑时间；原测试的两个用例各含 1 s IF。终端应出现两条 `TRACKING_CASE_PASS` 和 `TRACKING_MINIMAL_PASS cases=2`。正负初差码 RMS 约 0.062345/0.063487 chip，相位 RMS 约 0.002678/0.002674 turn，频率 RMS 约 0.847095/0.847133 Hz，尾段锁定率均为 1。

讲解要点：单边 E/P、P/L 间距为 5/16 chip；DLL 利用归一化功率差，Costas 鉴别器对数据反相保持不变。现场双用例测试采用原小误差配置；实际接收机还启用启动 FLL 和载波辅助码速，报告中有 ±125 Hz 拉入及真实 IF 四星结果。

### NH 与导航波形：位、字和时间逐层建立

菜单 **9** 的配置为 [nh.do](../scripts/demo_acceptance/nh.do)，范围 19.5～25 μs。`nh_locked=1`，每 20 个有效 Prompt 产生数据位，收齐 30 bit 给出 `word_valid`。字 2 的 raw=`1666677c`、information=`00aaeab`、corrected_bits=1，展示 BCH 单错纠正。九字测试覆盖 NH 相位 0/7/19、正反极性及纠错数 0/1/2。

菜单 **8** 的配置为 [navigation.do](../scripts/demo_acceptance/navigation.do)，范围 1537.370～1537.660 μs。NH19 反相用例的第二子帧末字到达后，frame_valid/time_valid/record_valid 建立，SOW 为 100006；record_ready 暂停期间 record_data 保持，恢复后依次输出十字。完整自检还检查时间锚点和失锁清除。

## 3. 预演结果与文件位置

本机预演的最终耗时和原始日志见[预演记录](../reports/local/acceptance_demo_2026-10-16/REHEARSAL.md)。最终现场流程中，捕获 3.032 s、NH 1.993 s、双子帧导航 2.281 s，跟踪读取本次已完成的 77.324 s 双用例 PASS。整套命令预演约 9 s，GUI 打开各另留数秒，讲解后总时长约 6～8 分钟。重复跟踪仿真的耗时发生波动，因此现场固定使用已验证完整 WLF，不再等待重跑。

| 内容 | 本地位置 |
|---|---|
| 主菜单 | `scripts/demo_acceptance.ps1`；双击入口 `scripts/demo_acceptance.cmd` |
| 固定波形配置 | `scripts/demo_acceptance/*.do` |
| 本次最近 PASS 指针 | `work/acceptance_demo/latest_*.json` |
| 每次运行日志、WLF、CSV | `work/acceptance_demo/runs/<时间>_<模块>/` |
| 编译库及源文件哈希 | `work/acceptance_demo/build/` |
| 既有 E100 原始自检 | [self_check.log](../reports/e_stage/final/self_check.log) |
| GUI 备用静态图 | [捕获](report_assets/acquisition_pcps_refine.png)、[跟踪](report_assets/tracking_feedback_timing.png)、[NH/BCH](report_assets/nh_d1_words.png)、[导航](report_assets/navigation_confirmation.png) |

命令行按模块运行：

```powershell
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1 -Action acquisition -ShowWave
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1 -Action tracking -ShowWave
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1 -Action navigation -ShowWave
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1 -Action evidence
```

一次预演完整现场流程（捕获/NH/导航实跑，跟踪结果回放）：

```powershell
powershell.exe -NoProfile -File .\scripts\demo_acceptance.ps1 -Action all
```

每次实跑使用新目录；TB 副本只调整输入与输出路径，保留原判据。脚本同时要求仿真退出码为 0 和完整自检 PASS 标记，失败或超过 30 s 显示 FAIL 及日志路径；跟踪明确显示 REPLAY PASS 和原始运行日期。打开波形前核对源文件签名；源若变化，应先重新核对再验收。保留 `work/acceptance_demo/` 中的本机 WLF 和运行记录。若现场 GUI 无响应，直接打开本节列出的静态图并结合菜单 5 的日志讲解。E100 只读取已有结果，不启动整机采集。

## 4. 老师可能问的问题

**1. 为什么使用 FFT 捕获，还要做精搜？**
FFT 在每个频点同时求所有码延迟，减少串行重复积分。4092 个抽取样本补零至 4096 后，循环周期与真实主码周期有差别；原始 IF 精搜用准确的 16368 样本周期，并细化至 1 sample、约 50 Hz 网格。

**2. 为什么采用四窗非相干积分？**
每个 1 ms 窗先算复相关，再累加四窗模平方，使不同窗口的数据或 NH 符号反相时仍能积累能量。窗内 NH 翻转会改变相关目标，报告中保留了相应边界实验及分析。

**3. 捕获计算完后，怎样保证跟踪初相位正确？**
捕获结果附带窗口首样本 ref。用实际跟踪启动样本与 ref 的差值推进码、载波 NCO；码相位对 2046 chip 取模，载波对一周取模。计算等待拍数和 IF 样本时间分别计量。

**4. DLL、PLL、FLL 各自做什么？**
DLL 用 E/L 功率差对准主码，Costas PLL 用 Prompt 相位误差保持载波相位；前 128 窗启动 FLL 用相邻 Prompt 相角差帮助拉入残余频差。载波多普勒还按 763 的射频/码率比辅助码速。

**5. 相关器积分结束时，新控制字什么时候生效？**
末样本在拍 t 接纳，t+1 输出 window_done，t+2 注册反馈，t+3 的下一接纳样本使用新字。相位连续，空拍保持信号状态。图中 window_done 与 feedback_valid 的先后关系就是这一级寄存器流水。

**6. 如何解决 NH 相位与载波 180° 模糊？**
并行评分 20 个 NH 候选，正确相位擦除后每位的 20 个 Prompt 同相积累；再同时搜索前导码和补码，确认后统一极性，因此整体反相仍恢复同一电文字。

**7. BCH 纠错数为 2，是否表示单码字可纠正两错？**
普通 D1 字去交织为两组 BCH(15,11)，每组纠正一错，合计可显示 2。字 1 前 15 bit 直接保留，后 15 bit 经过一组 BCH。raw_word 保留接收内容，information 是译码结果。

**8. 怎样确认导航时间有效，整机是否实际解出了电文？**
两个完整子帧需满足 SFID 顺序、SOW 增加 6 s、首位参考相差 98208000 样本，随后发布 type2。E100 真实 IF 中 RTL 输出 560 字，与独立教师解码逐字一致，self_check PASS；F20、G52 对应版本分别恢复 40、240 字。现场模块波形使用可控激励，整机结果由上述实际 IF 日志展示。
