# 当前状态与下一步

## 跨会话断点

- 最后更新：2026-09-28，Carrier NCO/Mixer 完成模块回归，全精度跟踪模型进入参数研究。
- 当前目标：根目录 [GOAL.md](../GOAL.md) 中的 `M1_B1I_SINGLE_CHANNEL_TRACKING`。
- 状态：`IN_PROGRESS`。用户已确认当前 plan 定稿并要求继续；`plan.md` SHA-256 为 `BE227D7C9F062301A809B5D57F45EABFA21F5D846BB3C71106DAE42A219E8CD8`，本阶段不改定稿文件。
- 当前进度：PRN、Code NCO、E/P/L 及新 Carrier NCO/Mixer 独立模块 VCS 均 PASS；NCO reset/init 冲突验证已补齐。DLL/FLL/PLL RTL、完整单通道连接与最终验收尚未完成。
- 新增 `model/carrier_model.py`、`rtl/carrier_nco_mixer.sv`、四分之一 LUT、配套 TB/向量、参数报告和 `docs/CARRIER_NCO_MIXER.md`；Makefile 增加 `carrier-regression`。
- `model/tracking_reference.py` 已在量化实 IF 上实现全精度 E/P/L、DLL、FLL→PLL、反馈与初版状态模型。初版静态正负偏差收敛；噪声状态迟滞和较大码速初差正在扫描。模型研究结果不是位精确/RTL 闭环 PASS。
- Windows/Linux 已同步本次 VCS 所用 RTL/TB/向量和 Makefile，回收三项日志；15 个远端文件哈希与本地一致，证据为 `reports/carrier/regression_manifest.json`。模型和更新文档仍以 Windows 为源。
- 不再调查远端身份或扫描环境。既有 SSH 已完成本次 VCS；后续直接执行工程命令。

## 已有实现与最近验证证据

下表为 2026-09-28 新运行证据。模块通过不等于单通道闭环 milestone 已完成，也不覆盖此后再改动的源文件。

| 阶段 | 已有产物 | 最近证据 |
|---|---|---|
| B1I PRN | `rtl/b1i_prn_gen.sv`、`model/b1i_prn_golden.py`、`tb/tb_b1i_prn_gen.sv` | `reports/b1i_prn_vcs.log`：`B1I_PRN_REGRESSION_PASS`；PRN 6–37 全周期比对 |
| Code NCO + E/P/L | `rtl/code_nco.sv`、`rtl/epl_correlator.sv`、`model/code_nco_epl_model.py`、`tb/tb_code_nco_epl.sv` | `RELOAD_COLLISION_PASS` 及 `CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4` |
| Carrier NCO/Mixer | `rtl/carrier_nco_mixer.sv`、`rtl/carrier_quarter_lut.svh`、`model/carrier_model.py`、`tb/tb_carrier_nco_mixer.sv` | `reports/carrier_vcs.log`：`CARRIER_REGRESSION_PASS events=29775 accepted=22043` |
| 参数扫描/向量 | `reports/code_nco_width_scan.csv`、`reports/epl_spacing_scan.csv`、`reports/accumulator_width_scan.csv`、`reports/code_nco_epl_analysis.json`、`tb/vectors/` | 设计依据及覆盖见 `docs/PRN_GENERATOR.md`、`docs/CODE_NCO_EPL.md` |

当前实现 baseline：Q11.32 Code phase、Q1.32 code step、E/P/L 单边 `delta=0.25 chip`、16368 accepted-sample 窗口、最小累加器位宽 `IQ_WIDTH+14`。Carrier 为 32 bit 周内相位、10 bit 地址、12 bit ±2047 幅值，3 bit 输入输出 14 bit I/Q，通道连接时使用 28 bit 和。任意相位 PRN 预置最坏 2046 个逻辑时钟，是否优化仍属 TBD。

## 当前下一项工作

完成全精度研究，比较直接 PLL 与 FLL→PLL、DLL 带宽 1/2/5/10 Hz 和 PLL 带宽 5/10/15 Hz，记录失败用例而不只保留最容易通过的场景。运行入口为 `model/tracking_reference.py --suite scan --report-dir reports/tracking_reference/scan_v2`。已有数学自检与初始研究见 `reports/tracking_reference/`，当前扫描只有运行结束写出 `summary.json` 后才算完整结果。

当前研究采用 128 accepted-sample 反馈等待假设、一毫秒更新、二阶 PI，以及本地 Code NCO 首次回绕后开始固定样本窗口。这些需要对齐到后续算术流水线并做位精确验证，尚未作为系统接口冻结。不得把模型真实相位/频率作为反馈输入；真值只用于信号生成、可控初始误差构造和评分。

后续可按依赖自主调整顺序：

1. 完成全精度算法和验收矩阵，扩展到真实动态包络、噪声种子、低能量与初始化扰动，不停留在初版四场景。
2. 收敛 DLL、Costas/FLL 鉴别与环路的位宽、舍入/饱和和延迟，完成位精确模型及 RTL 模块回归。
3. 接入已通过的 Carrier 与 Code NCO/E/P/L，确保一拍 Mixer 延迟、反馈生效和窗口首末样本准确对应。
4. 连接单通道反馈与基础状态，验证组合动态、扰动、初始化、空拍和边界。
5. 形成 `docs/TRACKING_CHAIN.md`，逐项核验 `GOAL.md`；全部满足后停止。

每项完成后，替换本节的“下一项”，更新已完成产物、最近命令/配置/结果、未解决问题。不要把本任务表当作无需模型依据就可以固定的算法方案。

## TBD 对当前目标的影响

- 继续自主收敛：DLL/FLL/PLL 算法/带宽/系数与定点、反馈时序、基础锁定判据、带数值范围和容限的验收矩阵。Carrier NCO/Mixer 首版已解决。
- 外部未发布：SRAM 接口、正式输入数据与 metadata、系统 `clk`、正式验收配置。保持参数化与显式记录；合成模型验证可以继续，不能宣称已经验证实际课程数据或目标时钟。
- 当前范围外：捕获并行度、两级管理、12 通道调度、完整同步/测量/输出、后端 PPA。

完整清单见 [TBD.md](TBD.md)。这里区分当前依赖与后续系统缺项，避免由全系统 TBD 阻断单通道 milestone。

## 已有 smoke test 结论

| 项目 | 结果 | 产物/证据 |
|---|---|---|
| Windows → Linux SSH | 成功 | RSA key 非交互调用正常，Windows 可见 stdout |
| VCS | 成功 | I-2014.03；编译、链接、仿真到 time 500；`reports/vcs_smoke.log` |
| VCS license | 成功 | Synopsys server/daemon 可达，受许可编译/仿真实际完成，无 checkout 错误 |
| DC | 成功 | K-2015.06；analyze/elaborate/link/compile/report 全部完成 |
| DC library | 成功 | 实际加载 `saed90nm_typ.db`，TYPICAL corner |
| DC license | 成功 | 受许可 HDL Compiler/DC 映射实际完成，无 checkout 错误 |
| DC 输出 | 成功 | 网表、SDC、面积报告、时序报告已生成并取回 Windows |

DC smoke 数据仅用于证明闭环：total cell area `210.124800`，20 ns 教学约束下 setup slack `7.14 ns (MET)`。这不是 GNSS 设计的正式 PPA 目标。

## 项目目录

```text
.
├── AGENTS.md
├── GOAL.md
├── plan.md
├── EDA_ENV_STATUS.md
├── Makefile
├── docs/
│   ├── ARCHITECTURE.md
│   ├── PRN_GENERATOR.md
│   ├── CODE_NCO_EPL.md
│   ├── CARRIER_NCO_MIXER.md
│   ├── TBD.md
│   └── NEXT_STEPS.md
├── model/               # 独立 Python golden/reference model
├── rtl/                 # PRN、Code/Carrier NCO、Mixer、E/P/L 与 smoke counter
├── tb/                  # 自检 testbench 和 golden vectors
├── constraints/         # smoke SDC
├── scripts/             # EDA 环境、DC Tcl、Windows 远端入口
├── reports/             # 已取回的日志、报告和网表
└── work/                # 临时工作目录
```

Linux 镜像工程路径为：

```text
/home/7901_15/eda_project
```

统一 EDA 环境入口为：

```text
/home/7901_15/eda_env.sh
```

## Windows → Linux 调用与证据维护

Windows 工作区为文档和源文件的编辑源，Linux 为 EDA 执行镜像。此次用于 VCS 的文件已同步并核对哈希，文档/模型继续在 Windows 维护。继续开发时仍须同步本次改动，再运行对应回归；无需重新确认环境或远端身份。

现有三个模块回归已通过以下流程实际执行：

```powershell
ssh -o BatchMode=yes -o ConnectTimeout=15 -o IPQoS=none -i C:\Users\IC\.ssh\id_rsa_eda_codex 7901_15@192.168.159.128 "bash -lc 'source ~/eda_env.sh && cd ~/eda_project && make prn-regression code-nco-epl-regression carrier-regression'"
```

执行前用 `scp`/`sftp` 同步需要的 RTL、TB、golden vectors、Makefile 和模型配置；执行后检查退出状态及自检 PASS/FAIL，取回三个对应日志。老版 SCP 多远端源路径曾报文件名不匹配，已用 `/home/7901_15/eda_project/reports/<filename>` 绝对路径逐文件复制成功，不需要关闭安全校验。改变 golden 生成器时先重建向量，再运行 RTL 回归。

现有 Python 模型在 Windows 的工作区运行时中运行，VM 上此前尝试 `python3` 返回 command not found；无需为模型重新安装 VM 软件。已使用的 Windows 入口为：

```powershell
$pythonExe = 'C:\Users\IC\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $pythonExe model\code_nco_epl_model.py --report-dir reports --vector-dir tb\vectors\code_nco_epl
& $pythonExe -X utf8 model\carrier_model.py
& $pythonExe -X utf8 model\tracking_reference.py --suite scan --report-dir reports\tracking_reference\scan_v2
```

若本地运行时路径因应用更新失效，定位已配置的工作区依赖即可，不扩展为 EDA 环境重新调查。

既有环境 smoke 入口仍为 `scripts/run_remote_smoke.ps1` / Linux `make smoke`，包含 VCS 和 DC；它们不替代模块自检，也不需要每次启动都重复运行。EDA 环境事实和历史追加结果见 `EDA_ENV_STATUS.md`。

## 每次交接必须维护的信息

- 更新日期、milestone ID 和当前执行状态，保持与 `GOAL.md` 一致。
- 已完成和未完成的具体文件/功能，不把候选方案写成已实现。
- 最近验证的命令、配置/种子、日期、结果、日志路径；注明是否对应当前源文件，有版本号或源文件哈希时保留。
- 尚未运行/失败的测试、已知限制、定位尝试及是否影响当前目标。
- 下一项依赖已满足、可直接执行的任务；若等待用户，列出确切缺项。
- Windows/Linux 文件同步状态，避免在旧镜像上验证新代码。
