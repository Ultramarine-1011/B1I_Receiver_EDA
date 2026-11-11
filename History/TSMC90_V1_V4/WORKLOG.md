# 本轮实验记录

日期采用 Asia/Singapore，完整实际 argv 保存在各运行日志或 `command.json`。

- 2026-11-10 19:20，读取当前 Git、AGENTS、正式状态/目标及最新相关工作日志。HEAD 为 `400de3a`，无已跟踪用户改动。使用当前个人实验分支，保留五项既有未跟踪资料。
- 建立本目录及独立 RTL 副本。SSH 严格使用已有 known_hosts，核实 TSMC90 typical.db 哈希与 B0 相同，VM 9818 MiB RAM，10235 MiB swap，初始 swap 使用为零。
- V1 将两个归一化变量除法改为精确 17 位有界商组合结构。Verilator 和 VCS 各比较 214883 组，最终退出 0。VCS 首次因生成探针缺默认 timescale 返回 255，调整编译文件顺序后通过，失败输出保留在 `evidence/vcs_arithmetic_timescale_fail.txt`。
- `scripts/run_local.ps1 -Task tracking` 和 `-Task fll` 均退出 0。复用原场景和原断言，每组两例、每例 999 窗，额外逐拍比较全部 32 个输出。独立 Python 重算 3996 个实际闭环窗，结果与反馈及 16369 样本参考差一致。
- `-Task six`、`-Task recovery` 均退出 0，每例 49104000 样本、235 导航位正确。正常场景 50518067 拍，恢复场景 50516937 拍，终态六锁。沿用原失锁、重捕、重配置、反压和位输出断言。
- 原版和 V1 的隔离归一化探针各使用 180 秒预算，均由修正监督器记录 TIMEOUT，保留 time/CPU/RSS/退出状态。原版尚在 DW 映射，V1 已进入时序优化。本探针不提供最终面积或时序。
- 19:33，`bash scripts/run_dc.sh B0 1200` 启动 V1 单通道综合，冻结 B0 的库、角、10 ns、两个开启参数、单核及 medium 映射。首次异步等待命令因 pgrep 匹配自身而未启动 DC，已终止该等待 shell，确认无 DC 后重新启动，只有一个完整 V1 DC 进程。
- 独立 elaborate/check_timing/report_hierarchy 实验确认 DLL 为 `DW_div_tc_a_width76_b_width59`，PLL 为 `DW_div_tc_a_width80_b_width64`，识别实验 DC 退出 0。
- V1 展开仍保留 `48×48` 平方及 64 位换算。V2 scratch 对鉴别结果、限幅结果与 NCO 增量标注严格位宽，预展开退出 0，平方变为 `15×15`，常数除法分子操作数为 38/47 位。100000 组完整组合环路、16 个字段逐位一致，包括全范围积分器与历史状态。FLL 场景全部输出逐拍一致。
- 995 个已保存公开 IF Prompt 窗在本轮 Verilator/VCS 中重放通过。来源哈希及重放范围见 `evidence/public_prompt_source.json`。
- V1 最终 TIMEOUT，客体 uptime 1200.91 秒，GNU time 墙钟 1264.88 秒，峰值 1364484 KiB，退出 1。发现该 VM 的 uptime 比墙钟慢，后续附加宿主机单调计时截止，不改系统时间或虚拟机设置。
- V2 全部算术、逐拍与六通道测试通过。20:18 由宿主机截止监督发 SIGTERM，停止在 Mapping Phase 11。GNU time 为 1197.44 秒，峰值 1184468 KiB，退出 1，宿主机观测截止 1200.154 秒。客体 result 的 stop_reason 为 null，最终分类结合宿主机记录为 HOST_TIME_BUDGET，未当作自然完成。
- V3 对归一化除法改用一次带符号试减法同时取得比较结果和余数，DLL/PLL 分别保持 57/29 位余数。控制字换算在单次向零截断前将 65536/16368000 精确约为 512/127875。100000 组完整环路、214883 组除法及 995 窗公开 Prompt 重放在 Verilator/VCS 均通过。静态与 FLL 每例 999 窗、全部 32 个输出逐拍一致，3996 窗的两份 CSV 与 V1/V2 的 SHA 完全一致。
- V3 六通道正常与恢复重新编译实跑，退出均 0，各 49104000 样本、235 导航位、终态六锁，周期数仍分别为 50518067/50516937。原断言全部保留。
- V3 独立探针首次因 test wrapper 的 64 位线连接 16/15 位端口被 DC LINK-3 拒绝。修正 wrapper 的显式符号扩展后完成链接和映射，180 秒探针预算在时序优化中到期。两次日志均保留，瞬时映射面积未作为最终 PPA。
- 20:27，V3 的全部冻结输入 SHA 检查通过。`bash scripts/run_dc.sh B0 1200` 在 `runs/B0_20261110_202705` 启动，DC PID 38156。宿主机 `host_deadline.py` 从启动前记录的 host epoch 计算独立 1200 秒截止，信号前校验 DC 的工作目录。
- V3 完整 DC 经宿主机截止停止，GNU time 1199.09 秒、峰值 1055516 KiB、退出 1，最后 Mapping Phase 39。完整网表及最终 PPA 缺失。
- V4 在严格边界内将 CORDIC x/y 缩到 signed 59 位、角度和 z 缩到 signed 32 位、返回 Q16 缩到 signed 16 位，FLL 频率/调整分别为 signed 26/22 位。边界与角常数和保存在 `evidence/fll_bounds.json`。
- V4 将常数除法实现为无符号倒数乘法、一次余数校正和符号恢复。D=127875 使用 W=40/M=8598331，D=763 使用 W=33/M=11258105，覆盖全 signed 40/33 位输入。新增 210169 组逐位检查及整数边界用例，Verilator/VCS 均通过；完整组合比较增强到 100625 组、18 字段，加入 Prompt 极值笛卡尔积及全 32 位 Doppler 输入。
- V4 全部单通道与六通道回归重新编译实跑通过，CSV 与此前版本字节一致。21:07 完整同配置 DC 启动于 `runs/B0_20261110_210718`。宿主机 1200 秒截止发 TERM，GNU time 1199.14 秒、峰值 832452 KiB、退出 1。进度表最终最差端点为 code_step_q_reg[31]/D，负 slack 13.39 是未结束优化中的数值，不作为最终 WNS。
- 用户最新指令要求冻结 V4、先诊断 10 ns 与放宽时钟，停止新的完整综合。V4 原样保存，正式源和原始基线保持。
- 控制字换算独立原版探针在 165 客体秒预算内 TIMEOUT。优化版同接口、同夹限输入域的 10 ns 探针成功，GNU time 57.93 秒，面积 32080.809748，setup WNS/TNS 0，hold 97 条违例。另以 Verilator 对两个探针的输出执行 20000 组比较，退出 0。
- `dc_evidence.tar.gz` 保存 190 项完整日志、报告及生成探针，传输 SHA256 核验通过。31 份过程观察另作逐字节核验归档，原文件留在本机，以 Git ignore 排除重复提交。
- V4 checkpoint 校验全部七组测试的实际日志与源 SHA，17 份正式来源与冻结副本逐字节一致，正式 tracked 路径相对 400de3a 无差异。本地提交 `d713867`，提交说明明确完整 DC 仍 TIMEOUT、RTL 反馈节拍保持。
- 时钟诊断先保留层次化的 18 字段观测输出，10/30 ns 均在短预算内超时。随后将同一算术体平坦化，仅保留 code/carrier NCO 输出，排除不相关观测量对探针的影响。正式 10 ns SDC 保持，诊断 SDC 为 work 下的独立副本。
- 平坦反馈 10 ns 实测 190.77 秒 TIMEOUT，30 ns 322.77 秒 TIMEOUT。100 ns 实测 95.12 秒退出 0、PROBE_UNMAPPED=0，面积 279722.418313，Critical Path Length 98.72 ns、setup WNS/TNS 0，hold 最差 -0.16 ns、97 条违例。100 ns 的实际映射路径从 il[1] 到 code_step_reg[32]，包含 Late 平方和 sub_113_C184 至 sub_113_I16_C184 共 16 级依赖试减，随后为 DLL/控制字换算。该数据只证明局部实现及约束压力，不当作完整通道 PPA。
- 最终证据包包含 242 项原始日志、报告和生成探针，传输 SHA256 为 e883b402a406fe6face0e3b037ab91440198a9949c76790171f93daad8b3e444。全部 DC 探针进程已退出。V4 源码保持，停止新 RTL 修改及完整综合；最终说明见 REPORT。
- 用户准备关机并要求立即保存结束。再次 SSH 确认无 common_shell_exec，WSL 检查无本轮仿真可执行程序。V4 RTL 与 242 项 DC 证据包 SHA256 复核通过，当前已验证源码、测试、日志和脚本均保存在本地实验分支。追加关机交接后本地提交，停止执行。
