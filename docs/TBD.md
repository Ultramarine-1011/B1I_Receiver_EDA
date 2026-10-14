# 近期未决事项与范围

当前状态只见[STATUS.md](../STATUS.md)，任务范围见GOAL.md。历史未决记录保留[archive/TBD_2026-09-28.md](archive/TBD_2026-09-28.md)。

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
