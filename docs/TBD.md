# 近期未决事项与范围

当前状态只见[STATUS.md](../STATUS.md)，任务范围见GOAL.md。历史未决记录保留[archive/TBD_2026-09-28.md](archive/TBD_2026-09-28.md)。

## 六通道与TSMC28（2026-11-06 M2 之后）

- 旋转因子已改为 function，数值与 `rom/fft_*_q30.mem` 一致。`initial $readmemh` 仍会被 DC 忽略，不能再加回去。证据见[M2报告](../reports/m2_tsmc28_20261106/REPORT.md)。
- `bds_bb_6ch_pad_top` 已接 TPHN28 8 mA 焊盘。`OEN`/`REN` 低有效；正常工作时 `PVDD2POC` 把 `POC` 驱成 0。DC 的逻辑视图不保留电源 `pg_pin`，SDC 不能对 `VDD/VSS/VDDPST/VSSPST` 调用 `get_ports`。
- 10 ns、输入/输出延迟 2.0 ns、输入转换 0.5 ns、输出负载 5 pF 仍是候选约束，不是签核值。
- 这台 1991 MB、无 swap 的虚拟机不能完成六通道映射。捕获 2,293,056 bit 多端口存储仍然没有 SRAM 宏，M2 只在综合实验里把它隔离。单通道 80 位除法已被 DC 识别为 `DW_div_tc_a_width80_b_width64`，但没有最终时序报告。
- 进入 M3 为 NO-GO，直到另有至少 8 GB 内存的主机。自生成六星的功能评分范围不变。

## 六通道与TSMC28（2026-11-06 预检后）

- 虚拟机已核对 `/home/share/libs/tsmc28`：标准单元 TT/SS/FF `.db/.lib`、TPHN28HPCPGV18 PAD 的 `.db/.lib` 和两份 Verilog 都在。没有 SRAM/存储器宏，也没有标准单元门级 Verilog。证据见[M1报告](../reports/m1_tsmc28_20261106/REPORT.md)。
- 当时的结论是：首次全芯片 DC 前必须处理两项，DC 忽略 `initial $readmemh`（VER-281），以及 2,293,056 bit 多端口存储不能在这台虚拟机上展开。M2 段记录了随后的实际处理结果。
- 当时尚未选定 ASIC 周期和 IO 电气参数。PAD `OEN`/`REN`/POC 的有效电平也尚未核定。M2 段给出了候选值和极性。
- 自生成六星 IF 的功能评分范围不变。正式统计/动态/定位输入缺口仍属原 G 范围。

## 六通道与TSMC28（2026-11-02 当时记录）

- 新教师文件已明确六通道标量IF、状态及串行位接口，并提供TSMC28标准单元TT/SS/FF、ICC及Calibre库路径。当前核心及接口见[SIX_CHANNEL_DESIGN](SIX_CHANNEL_DESIGN.md)，本地功能证据见[六通道报告](../reports/six_channel_20261102/FINAL_REPORT.md)。
- 当时尚未访问远端工艺库。2026-11-06 的预检取代“库/PAD 未验证”这一句，不改变功能验收范围。

## 维护待办（2026-10-23）

逐字节复核：`rtl/` 与 `student_release/student_release/rtl/` 中 `b1i_prn_gen.sv`、`carrier_nco_mixer.sv`、`carrier_quarter_lut.svh`、`code_nco.sv`、`epl_correlator.sv`、`tracking_frontend.sv` 六份基础文件相同。本轮只登记；统一路径需另评估所有编译入口。`receiver_single` / `receiver_multichannel` 的控制、复位及宽运算后续按功能或综合需求处理，风险见 [综合准备](SYNTHESIS_READINESS.md)。

## 已由教师发布解决

- 纯仿真无需SRAM控制器。输入为scenario.if2（409200000字节），Fs=16368000 Hz、IF=4092000 Hz、2 bit -3/-1/+1/+3。
- 文件字节MSB-first；总线32 bit/16样本，stream[1:0]最早，握手索引+16。最后输入字不等于处理结束。
- 固定student_receiver_core端口与256 bit小端记录已发布；type6唯一且最后，排空后提交。无需猜测这些接口。
- 本机WSL2 Ubuntu/Verilator/g++/make/Python现已实际可用。根9.28五个关键RTL哈希匹配历史manifest。A与C1运行事实见STATUS/WORKLOG，旧VCS不代替新验证。

## G阶段剩余正式缺口（2026-10-14）

G0–G7当前可执行工作已完成，分类/实测FAIL及最小正式输入见[G报告](../reports/g_stage/FINAL_REPORT.md)与reports/g_stage/scenario_registry.json。正式全覆盖/100+100/10独立冷启180s/12D1动态/独立ECEF尚缺合格场景和真值；持续实时尚缺clk/SRAM/服务边界/持续12星负载。P02当前周期测量已完成，无统一达标时间上限。真实2s RF自生成恢复通过不替代正式P08。H/I另行授权，当前停止条件不要求缺输入的全部正式PASS。

## F阶段历史未决（2026-10-14当时记录）

以下F当时“本轮/未授权/缺失”表述保持历史范围；G结果以上述段及最终报告为准，不据此重复已完成任务。

- E100秒/check_records/self_check/Route A均已完成，原证据在reports/e_stage/final；E归档不覆盖F新代码。没有教师位置真值，不能宣称定位精度。
- F数字/控制/3.2s合成双星恢复/12路NAV隔离已PASS，默认4公开20s NAV/OBS/Route A PASS且E前缀逐bit匹配。正式12星D1/40dB-Hz/合法动态和2s信号中断场景仍缺失；合成130ms中断不能算正式P08。
- P03每档100+100、P04/05每档10冷启/180s窗/PDOP≤4、P06/07码频/字真值、P09位置真值/完整60s窗待输入。F4建立可执行基础，不填造统计。
- 正式ASIC标准单元/宏/工艺角/电气/clk/IO约束未提供，本轮代码风险审查；DC/ICC/PT/DRC/LVS禁止，G/H/I未授权。

## E阶段历史未决（最终已完成，保留当时描述）

E0单星真实记录与移交、E1真实单星捕获/FLL拉入、E2真实导航字和E3四星短窗已有实跑证据，见STATUS/WORKLOG与RECEIVER_INTEGRATION。下列A–D历史未覆盖项只描述当时范围。

- 完整100秒与最终check_records/self_check/Route A正在运行；未结束不算PASS。当前部分数据Route A实际给出四星星历和33个定位历元，只作为中途诊断。
- 最终输出完整性、当前源/教师公共文件SHA256、轻量Git交付：结束后固化。
- 没有隐藏真值，不能把四星位置方程的小残差当成定位精度证明；报告实际解与内部时间一致性。
- 隐藏/动态/低CNR/失锁重捕未覆盖；本轮不扩展12通道、ASIC后端或SRAM。

## A–D阶段历史未覆盖项（当时记录）

| 事项 | 最小工作 | 实际影响 |
|---|---|---|
| 捕获 | 最低模块报告已交、31格点PASS；全范围/弱星统计和移交待做 | 未证明完整无辅助捕获或40dB-Hz检出率 |
| DLL/PLL反馈 | 两例静态闭环实际PASS、报告/曲线已交；动态/噪声/FLL未覆盖 | 不外推大频差/多星/失锁性能 |
| NH/D1 | 实际Prompt29恒定位与合成Prompt9字PASS、报告已交 | 完整实收子帧/星历/重复帧确认未做 |
| 顶层集成 | 模块跑通后最小连接，pending记录/流水排空 | 当前顶层只输出end，完整教师self_check仍FAIL |
| 教师40dB-Hz场景检测/拉入 | 有实际数据与结果后评分，不能仅凭高SNR合成测试推定 | 正式receiver_records有效性仍未证明 |
| tracking记录schema | RECORD_FORMAT的24bit Prompt字段与decode_records默认legacy 32bit解释不同，schema3需额外标志 | 目前只输出end不受影响；接type1前须核对实际decoder，不猜测或改公共工具 |

## 旧阶段后移事项（不驱动当前F范围）

目标ASIC时钟/PPA、工艺角、SRAM、12通道、复杂失锁/冷启动、高灵敏度、正式DC/ICC/PT和远端SSH修复均后移。完整100s/隐藏动态场景尚未覆盖；不以短仿真代替。WindowsApps的python仅为占位入口，自有runner使用WSL python3，不改教师公共脚本或系统PATH。

## 本地后端预演后的实际缺口（2026-11-11）

- 本次个人 IC_EDA 为9818MB RAM、10235MB swap，六通道隔离预演达到30分钟上限，峰值6.30GiB。当前结果及单通道WNS改善见[本轮报告](../experiments/ic_eda_20261111_backend/REPORT.md)。历史M2的2GB环境事实保留对应日期。
- 当前PCPS/FFT可变数组为1768768bit，另有524288bit逻辑常量表。尚需经过回归的RAM接口/银行方案、实际宏库及模型。剩余64位宽运算的映射成本也需要模块级诊断。
- 实验室还需取得匹配的标准单元时序Verilog。个人TSMC90计数器曾出现28条条件弧IOPATH不匹配，已被入口检查拦截。TSMC28完整PAD/六通道SDF及功耗属于待实跑项。
- 下一次命令和明确前置条件见[LAB_RUNBOOK](../experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md)。10ns及M2 IO参数继续标为候选，正式接口规格发布后统一更新与重跑。
