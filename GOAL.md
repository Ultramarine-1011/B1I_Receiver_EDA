# E阶段：B1I最小端到端集成与教师功能验收

2026-10-13用户授权E0→E1→E2→E3→E4连续自主设计、实现、测试、修复、分阶段Git提交及正常推送。唯一状态见[STATUS.md](STATUS.md)，实际命令和证据见[WORKLOG.md](WORKLOG.md)。A–D目标归档于[原文](docs/archive/GOAL_ABCD_2026-10-13_original.md)，原日志和已验证模块保留。

## 执行边界

- 启动实查最新main；本轮起点3d09daf，远端同提交，工作区干净。
- Windows源码/PowerShell入口，现有WSL2 Ubuntu、Verilator、g++、make、Python仿真；复用scripts/run_local_verilator.ps1及教师仿真入口。不访问/启动/修复VMware、远程EDA、SSH或VCS/DC/ICC/PT/DRC/LVS及其库/license。
- 复用已验证RTL/模型/TB，学生实现主要在student_release/student_release/rtl；自有验证在model/tb/scripts/reports。plan.md历史冻结版保留，教师公开接口优先。不提前扩展12通道/ASIC后端。
- 教师公共input/sim/interface/scripts/tools/submission及README保持不变。scenario.if2不进Git，不上传数据；构建/缓存忽略。真值仅供激励/独立评分，不供DUT；禁止硬编码卫星答案、伪造记录或以软件后处理替代RTL。
- 验证先短后长；性能问题先量化，不盲跑全网格。保留FAIL原因，不放宽评分凑PASS。结构检查、导航恢复、定位分别报告。

## 验收清单

### E0：合成单星端到端

- [x] E0.1 解包→捕获→跟踪在同一学生顶层协作，16→1握手、反压和真实样本编号无丢失/重复。
- [x] E0.2 按lag_samples/result_ref/Doppler移交，推进到实际跟踪首样本；覆盖正负码偏、频偏、计算延迟及初始化边界。
- [x] E0.3 真实type5/type1、32字节小端、28→24bit Prompt缩位/量纲/schema3、仲裁和背压稳定；实际流水与待发记录排空后唯一type6。
- [x] E0.4 原模块及新增端到端TB实际PASS，教师decode_records回读，独立核对捕获/连续Prompt/码与载波/样本时间/end。E0不要求四星self_check PASS。

### E1：真实单星捕获与稳定跟踪

- [x] 本地教师40dB-Hz IF由短窗口扩大，真实PRN/Doppler搜索且可重复type5检出。
- [x] 诊断频差拉入；必要的最小FLL/细频搜索有依据，稳定锁定type1与连续Prompt。
- [x] 实测逻辑周期/墙钟，按需要改进搜索；软件捕获答案不得初始化DUT。

### E2：真实NH/D1导航恢复

- [x] 实际Prompt贯通nh20_sync/d1_word_sync/BCH；核对NH相位、位边界/极性、连续子帧确认及失步处理。
- [x] 从真实解码恢复subframe_id/SOW/字与导航时间，诚实维护locked/nh_valid/frame_valid/time_valid/bch_valid并输出type2。
- [x] 至少一星连续真实D1字和可靠时间可独立核对；prompt_d1.py仅诊断。

### E3：最小四星与共同历元

- [x] 复用单通道，最低PRN搜索/分配/generation管理，同一IF时间轴至少四星实际捕获/跟踪。
- [x] 真实码周期/码片/分数与导航锚点，一秒共同接收历元type4；有效性条件齐全，不重复/不混旧generation/失锁后撤销。
- [x] 真实100秒原始check_records.py、self_check.py退出0；完整样本数1,636,800,000，唯一最后end，数据关联正确。
- [x] 原始route_a_position.py实际运行并分别报告定位PASS/FAIL；有效定位是争取项，结构PASS不能冒充定位成功。

### E4：固化交付

- [x] 最终receiver_records.bin及必要回归、命令/配置/退出码/报告可复现。
- [x] STATUS/WORKLOG/设计/GOAL同步；教师公共文件哈希不变，无大型IF/构建/缓存提交。
- [x] 分阶段Git提交，正常权限和远端同步下推送；不强推/覆盖已有修改。
- [x] 最终简报列实际通过/未通过、复现入口、交付路径和commit。

## 停止条件

完成最低交付后停止，不主动扩展架构。仅缺必需文件/权限、超范围不可逆决策、合理诊断仍不可解决的实际技术阻塞，或量化证明超出本地计算资源/可用执行时间时请求介入。会话/工具限额不是完成，必须保存证据、唯一下一任务和断点。

最终验收：2026-10-13完整100s、原始self_check退出0、Route A实际99个定位历元；报告见[FINAL_REPORT](reports/e_stage/final/FINAL_REPORT.md)。目标完成后停止。
