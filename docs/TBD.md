# 近期未决事项与范围

当前状态只见[STATUS.md](../STATUS.md)，任务范围见GOAL.md。历史未决记录保留[archive/TBD_2026-09-28.md](archive/TBD_2026-09-28.md)。

## 已由教师发布解决

- 纯仿真无需SRAM控制器。输入为scenario.if2（409200000字节），Fs=16368000 Hz、IF=4092000 Hz、2 bit -3/-1/+1/+3。
- 文件字节MSB-first；总线32 bit/16样本，stream[1:0]最早，握手索引+16。最后输入字不等于处理结束。
- 固定student_receiver_core端口与256 bit小端记录已发布；type6唯一且最后，排空后提交。无需猜测这些接口。
- 本机WSL2 Ubuntu/Verilator/g++/make/Python现已实际可用。根9.28五个关键RTL哈希匹配历史manifest。A与C1运行事实见STATUS/WORKLOG，旧VCS不代替新验证。

## 近期仍需落实

| 事项 | 最小工作 | 实际影响 |
|---|---|---|
| 捕获 | 最低模块报告已交、31格点PASS；全范围/弱星统计和移交待做 | 未证明完整无辅助捕获或40dB-Hz检出率 |
| DLL/PLL反馈 | 两例静态闭环实际PASS、报告/曲线已交；动态/噪声/FLL未覆盖 | 不外推大频差/多星/失锁性能 |
| NH/D1 | 实际Prompt29恒定位与合成Prompt9字PASS、报告已交 | 完整实收子帧/星历/重复帧确认未做 |
| 顶层集成 | 模块跑通后最小连接，pending记录/流水排空 | 当前顶层只输出end，完整教师self_check仍FAIL |
| 教师40dB-Hz场景检测/拉入 | 有实际数据与结果后评分，不能仅凭高SNR合成测试推定 | 正式receiver_records有效性仍未证明 |
| tracking记录schema | RECORD_FORMAT的24bit Prompt字段与decode_records默认legacy 32bit解释不同，schema3需额外标志 | 目前只输出end不受影响；接type1前须核对实际decoder，不猜测或改公共工具 |

## 后移，不阻塞近期模块前仿

目标ASIC时钟/PPA、工艺角、SRAM、12通道、复杂失锁/冷启动、高灵敏度、正式DC/ICC/PT和远端SSH修复均后移。完整100s/隐藏动态场景尚未覆盖；不以短仿真代替。WindowsApps的python仅为占位入口，自有runner使用WSL python3，不改教师公共脚本或系统PATH。
