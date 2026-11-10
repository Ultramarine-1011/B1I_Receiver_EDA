# IC_EDA 环境探索与 PRN 单模块综合

**执行环境归属为个人本地环境。** 本实验在用户个人 Windows 主机及其本地 VMware `IC_EDA` 虚拟机中完成，结果归属于下文记录的 TSMC 90 nm 库与实验约束。独立 Git 分支为 `codex/ic-eda-personal-local-smoke-20261110`，基于 `fb662d3` 保存本次材料。实验室 `EDA` 的 TSMC28 验证记录另见正式工程已有 M1/M2 报告。

日期为 2026-11-10，时间采用 Asia/Singapore。Windows 已通过 SSH 执行真实远程命令，并通过 SCP 上传输入包、下载综合结果。`b1i_prn_gen` 已在实际 TSMC 90 nm 标准单元库上完成映射。最终 VCS、DC 和实验入口均退出 0，日志与产物检查通过。Setup 满足本轮约束，hold 存在违例。

## 1. 工程与虚拟机身份

仓库执行 `git fetch origin main` 和 `git pull --ff-only origin main`，均退出 0，从 `947d50b` 快进到 `fb662d36e85e9cffe02a4b8f003887808f73007c`。本轮阅读了最新 AGENTS、STATUS、GOAL、WORKLOG、H0 以及 2026-11-06 的 M1/M2 报告。最新正式工程仍以 M2 完成、M3 NO-GO 为状态。本实验的状态与事件独立保存在当前目录。

H0 的可复用对象为 PRN RTL、原自检 TB、五份 golden 向量及 DC 流程。M1/M2 使用实验室 `EDA` 的 TSMC28，M2 六通道曾退出 137，单跟踪通道宽除法未取得最终时序报告。本轮选择原 PRN 发生器作为烟雾测试对象。

| 项目 | 本轮实际识别的 IC_EDA |
|---|---|
| 真实 VMX | `C:\IC_EDA_Lite_20220604\IC_EDA_Lite\IC_EDA_Lite\IC_EDA.vmx` |
| VMware 显示名 / Linux 主机名 | `IC_EDA` / `IC_EDA` |
| VMware BIOS UUID | `56 4d 09 6c 47 8b 2e a7-ff 1c 0d 09 d6 57 17 00` |
| 网卡 MAC / 模式 | `00:0c:29:57:17:00` / NAT |
| 运行状态 | 启动时 `vmrun list` 只有这一台运行，Tools 状态为 `running` |
| 账户 | `ICer`，UID/GID 均为 1000 |
| OS / 内核 | CentOS 7.9.2009 / `3.10.0-1160.53.1.el7.x86_64` |
| VMware CPU / 客体 CPU | 8 vCPU / 在线 8，4 插槽 × 2 核 × 1 线程 |
| 客体 CPU 型号 | AMD Ryzen 9 8940HX with Radeon Graphics |
| VMware 内存 / Linux MemTotal | 10240 MiB / 9818 MiB，差约 422 MiB 为客体保留等开销 |
| Swap | 10235 MiB，最终检查使用 0 |
| 虚拟磁盘 | `/dev/sda` 为 400 GiB，与 VMware 配置一致 |
| 文件系统 | `/` 20 GiB、可用约 13 GiB，`/home` 309 GiB、可用约 265 GiB |
| VMware Tools | `vmware-toolbox-cmd -v` 为 `11.0.5.17716 (build-15389592)` |

仓库中原 `EDA` 的历史记录是 `C:\IC\EDA.vmx`、RHEL 6.7、主机名 `IC`、`7901_15@192.168.159.128`、Synopsys 2014/2015。该 VMX 在本 Windows 主机的记录路径不存在。当前 VMware inventory 包含 IC_EDA 和另一台 HLS Ubuntu，运行列表只有 IC_EDA。本轮环境清单均来自 IC_EDA 的实际命令。[VMX 摘录](vmx_selected.txt) [主机事实](host_facts.json) [客体初检](initial_probe.txt)

## 2. 网络与可复现连接

Windows VMnet8 为 `192.168.236.1/24`。客体初始 `ens33` 为 DOWN，只有内部 `virbr0` 地址，缺少外部默认路由。`sshd` 已启用并运行，监听 22。现有 ens33 配置采用 DHCP、`ONBOOT=no`，NetworkManager 全局 networking 为 disabled。直接激活已有连接返回 4。

通过 VMware Tools 使用用户提供的账户认证，核实 ICer 已有 sudo 权限，然后执行临时接口启用和 DHCP。实际取得 `192.168.236.129/24`，网关与 DNS 为 `192.168.236.2`，DHCP 服务器为 `192.168.236.254`，DHCP 退出 0。`dhclient` 在最终检查时仍运行并可续租。已有 `/etc/sysconfig/network` 首行是裸文本 `IC_EDA`，DHCP 脚本因此打印两次 command-not-found，但已成功取得租约。[连接失败记录](connect_probe.txt) [临时联网命令](network_up.sh) [DHCP 实际日志](network_up.txt)

临时联网命令可在 VMware 客体终端复现。需要现有 ICer 的 sudo 认证。

```bash
sudo ip link set dev ens33 up
sudo /sbin/dhclient -1 -v ens33
ip -4 addr show ens33
ip route
```

SSH 使用现有密码认证。主机 Ed25519 公钥先通过已认证 VMware Tools 读取，再写入实验专用 `known_hosts`。指纹为 `SHA256:grp9NQF1zb1ijZGZj23sS2j7piW8DdWGA12agwF+g5Q`。所有 SSH/SCP 调用启用严格主机密钥校验。

从 Windows PowerShell 复现，出现密码提示后输入已知 ICer 密码。

```powershell
$exp = 'C:\Users\26255\Desktop\DIC_EDA\windows-vmware-br-br-br-br\windows-vmware-br-br-br-br\experiments\ic_eda_20261110'
ssh -o "UserKnownHostsFile=$exp\known_hosts" -o StrictHostKeyChecking=yes -o ConnectTimeout=10 ICer@192.168.236.129
ssh -o "UserKnownHostsFile=$exp\known_hosts" -o StrictHostKeyChecking=yes ICer@192.168.236.129 'bash /home/ICer/ic_eda_smoke_20261110/scripts/run_smoke.sh'
scp -o "UserKnownHostsFile=$exp\known_hosts" -o StrictHostKeyChecking=yes "$exp\final_input.tar.gz" ICer@192.168.236.129:/home/ICer/ic_eda_smoke_20261110/final_input.tar.gz
scp -o "UserKnownHostsFile=$exp\known_hosts" -o StrictHostKeyChecking=yes ICer@192.168.236.129:/home/ICer/ic_eda_smoke_20261110/final_results.tar.gz "$exp\final_results.tar.gz"
```

真实 SSH 命令 `id; hostname; printf SSH_REMOTE_COMMAND_PASS` 退出 0，返回 ICer、IC_EDA 和成功标记。首轮输入包通过 SCP 上传，SHA-256 在主客体均为 `ba27f15e3499e02533f0e791fc70a5a4566010b2b70255b73311924daf2b687a`。两次结果包通过 SCP 下载，退出均为 0。`input.tar.gz` 保留首轮脚本，修正版打包为 `final_input.tar.gz`，也已通过 SCP 上传。初版输入、最终输入和最终结果包的主客体 SHA-256 全部一致。[传输哈希](transfer_sha256.txt)

需要从包恢复最终脚本时，在客体实验目录执行以下命令。

```bash
cd /home/ICer/ic_eda_smoke_20261110
tar -xzf final_input.tar.gz
bash scripts/run_smoke.sh
```

当前连接依赖本次临时联网。NetworkManager disabled 与 `ONBOOT=no` 仍是既有配置，重启后需要再次恢复接口，DHCP 地址也可能改变。自动开机联网属于后续持久配置工作。最终检查的 SSH 服务为 active，接口仍 UP。[最终客体检查](reports/environment/final_probe.txt)

## 3. 工具、许可证和库

| 工具 | 实际路径与版本 | 本轮运行程度 |
|---|---|---|
| Design Compiler | `/home/synopsys/syn/O-2018.06-SP1/bin/dc_shell`，O-2018.06-SP1，2018-07-19 | 完成真实映射。`-version` 退出 1 且打印版本，综合命令退出 0 |
| VCS | `/home/synopsys/vcs/O-2018.09-SP2/bin/vcs`，O-2018.09-SP2_Full64 | `-full64 -ID` 退出 0，PRN 编译与仿真退出 0 |
| PrimeTime | `/home/synopsys/pts/O-2018.06-SP1/bin/pt_shell`，O-2018.06-SP1 | `-version` 退出 0，独立 STA 为 NOT_RUN |
| ICC / ICC2 | PATH 和 `/home/synopsys`、`/opt` 的限定安装树搜索均未发现 shell | NOT_RUN |
| Library Compiler 报告接口 | DC 的 `report_lib` 返回 LCSH-3，要求检查 LC 安装 | 当前脚本用 `list_libs` 记录实际已加载库，独立 LC 编译为 NOT_RUN |

加载现有 `/home/ICer/.bashrc` 后，`SNPSLMD_LICENSE_FILE=27000@IC_EDA`。本地许可证文件位置为 `/home/synopsys/scl/2018.06/admin/license/Synopsys.dat`，可读。`lmgrd`、`snpslmd` 在运行，`lmstat -a` 退出 0 并报告 server 与 vendor daemon UP。DC 与 VCS 完成实际受许可作业，所需 feature 可用。许可证授权归属与合同凭据本轮未核验。报告保存了状态输出，许可证文件内容未读入实验材料。[系统、工具与许可状态](reports/environment/system_tools.txt)

数字库根为 `/home/ic_libs`。发现 TSMC 0.13 µm 标准单元 typical/slow/fast/fastz `.db/.lib`，其中 typical Liberty 给出 1.2 V、25 °C。90 nm 标准单元在 `/home/ic_libs/TSMC.90/aci/sc-x/synopsys/`，本轮实际使用该目录的 `typical.db`，其 Liberty 给出如下角。

| 90 nm 库角 | 电压 | 温度 |
|---|---:|---:|
| typical | 1.0 V | 25 °C |
| slow | 0.9 V | 125 °C |
| fast | 1.1 V | −40 °C |
| fastz | 1.1 V | 0 °C |

Liberty 时间单位 1 ns、电容单位 1 pF。目标 DB 的 SHA-256 为 `8022bc0d744d01fcc93b8c7387d9de6d33d674c29c81beba0e0496d2dde1702a`，前后检查一致。90 nm `INVX1` 的 Liberty 面积 2.1168，与 LEF 的 `0.840 × 2.520 µm` 一致，下面单元面积按 µm² 记录。[库元数据与哈希](reports/environment/library_metadata.txt) [LEF 尺寸核对](reports/environment/final_probe.txt)

90 nm 后端资源已发现标准单元 `astro/tsmc090g_fram/{CEL,FRAM}`、`astro/tf/tsmc090_*.tf`、技术 LEF 和 `lef/tsmc090nvt_macros.lef`，另有 tpdn90g18/g2/g3 PAD 的 Milkyway/LEF。对 `/home/ic_libs` 全树文件名扫描未发现 TLU+ 文件。物理资源仅核实存在性，匹配性和完整后端运行均为 NOT_RUN。本轮识别到的目标库为 TSMC 90 nm，TSMC28 未经本轮验证。[库文件清单](reports/environment/library_files.txt) [物理目录清单](reports/environment/physical_library_dirs.txt)

## 4. 综合条件、命令与结果

Linux 独立目录为 `/home/ICer/ic_eda_smoke_20261110`，最终运行号为 `20261110_180446`。RTL 顶层为 `b1i_prn_gen`，RTL、原 TB 和五份 golden 与 GitHub 当前工作树逐 SHA-256 一致，共 7 份文件。PRN 6–37 各完成 2046 chip、回绕和 epoch 检查。脚本从 H0 适配库路径、驱动引脚、64 位工具调用、独立输出目录和日志检查。[脚本](scripts/dc_prn.tcl) [实验入口](scripts/run_smoke.sh) [源与脚本哈希](runs/20261110_180446/reports/source_sha256.txt)

| 条件 | 本轮取值 |
|---|---|
| 映射库与 PVT | TSMC 90 nm `typical`，1.0 V、25 °C |
| DC 线程上限 | `set_host_options -max_cores 1` |
| 时钟 | 10 ns、理想时钟网络、转换 0.1 ns |
| 时钟不确定性 | `set_clock_uncertainty 0.2`，同时作用于 setup 与 hold |
| 输入延迟 | 数据输入 max 1.0 ns、min 0.0 ns |
| 输出延迟 | 全输出 max 1.0 ns、min 0.0 ns |
| 驱动与输出负载 | `typical/INVX1`，4 × `INVX1/A` = 0.006604 pF，即 6.604 fF |
| 复位 | `rst_n` 为异步复位，设从该端口的 false path |
| 线网模型 | enclosed 模式，库实际未指定 wire-load model，时序采用当前逻辑单元/负载模型 |
| 实验约束来源 | 本轮自选烟雾测试条件 |
| 运行上限 | VCS 120 秒，DC 180 秒，实际均正常提前退出 |

以下为实际命令，工作目录分别为该 run 下的 `work/prn`、`work/dc`。标准输出和标准错误合并保存到对应 `reports/vcs/run.log`、`reports/dc/run.log`。

```bash
/usr/bin/time -v -o ../../reports/vcs/time.txt timeout 120 vcs -full64 -sverilog -R ../../rtl/b1i_prn_gen.sv ../../tb/tb_b1i_prn_gen.sv
/usr/bin/time -v -o ../../reports/dc/time.txt timeout 180 dc_shell -64bit -f ../../scripts/dc_prn.tcl
```

DC 完成 analyze、elaborate、link、综合前检查、compile、综合后检查和网表/SDC/DDC 导出。综合后 `check_design` 返回 1，无警告，未映射单元 0、宏/黑盒 0。`check_timing` 的默认检查未报告缺少约束的端点。最终日志与所有 DC 报告均经过 Error/Fatal 搜索。

| 最终指标 | 实际值 |
|---|---:|
| VCS / DC / 实验入口退出码 | 0 / 0 / 0 |
| VCS 墙钟 / 峰值 RSS | 0.91 s / 84632 KiB，约 82.65 MiB |
| DC 墙钟 / 峰值 RSS | 2.64 s / 267084 KiB，约 260.82 MiB |
| DC user / system CPU 时间 | 2.38 s / 0.10 s |
| DC compile 阶段墙钟 | 1.63 s |
| 单元面积 | 1380.153630 µm² |
| 组合 / 时序面积 | 699.955212 / 680.198418 µm² |
| 叶级单元 | 173，其中组合 132、时序 41 |
| 层级计数 | `report_area` 为 174，包含一个映射后的加法器层级实例 |
| 关键约束路径 | `active_prn_reg[1]` → `chip` |
| 该路径数据到达 / 要求时间 | 0.872390 / 8.800000 ns |
| 最差 setup slack | +7.927610 ns |
| Setup WNS / TNS / 违例数 | 0 / 0 ns / 0 |
| Hold WNS / TNS | −0.156530 / 约 −2.92 ns |
| Hold 违例端点数 | 48 |
| 最大转换 / 最大电容违例 | 0 / 0 |

WNS/TNS 用负违例口径，setup 的正裕量另列。Hold TNS 按报告中 48 个端点的六位小数求和为 −2.920424 ns，与 QoR 四舍五入的 −2.92 ns 一致。最差 hold 路径是 `load` → `configured_reg/D`，到达 0.062095 ns、要求 0.218625 ns。`set_clock_uncertainty 0.2` 作用于 hold，且最小 IO 延迟为 0，形成上述保持违例。时序报告已成功产生，保持约束判定为 FAIL。

面积数值为标准单元面积。当前没有 wire-load model，`report_area` 的 Net Interconnect area 和 Total area 为 undefined。关键路径数据来自当前库、理想时钟与输出负载条件。[面积](runs/20261110_180446/reports/dc/area.rpt) [QoR](runs/20261110_180446/reports/dc/qor.rpt) [最大延迟](runs/20261110_180446/reports/dc/timing_max.rpt) [最小延迟](runs/20261110_180446/reports/dc/timing_min.rpt) [约束违例](runs/20261110_180446/reports/dc/constraints.rpt)

### 日志检查与适配过程

- 初次 `vcs -ID` 选择 32 位 linux 编译器路径并报 VCS_COM_UNE。显式 `-full64` 后识别并运行现有 linux64 安装。
- 首轮 `180027` 的 DC/VCS 进程退出均为 0，实验入口当时打印 PASS。但 `check_timing -verbose` 报 CMD-010，`report_lib` 在其独立报告中报 LCSH-3，该轮仅保留为适配记录。
- 第二轮 `180253` 移除 `-verbose` 并增加报告文件 Error 检查。DC/VCS 仍退出 0，检查器捕获 LCSH-3，实验入口正确退出 1。
- 最终 `180446` 用 `list_libs` 记录已加载 DB，并用实际 Liberty 记录元数据。所有错误检查通过。
- 最终综合前保留 C888 不驱动网络的 LINT-1，综合后已消失。8 条 UID-401 来自给 8 个数据输入设置 driving cell 时同步应用设计规则属性。VCS 无 Warning/Error，DC 无 Error/Fatal。48 个 hold 违例独立记录。

最终网表、SDC、DDC、完整 DC 日志与资源记录均在以下目录。Windows 当前目录保存同名副本，Linux 的完整工作构建留在对应 run 下。

- [映射网表](runs/20261110_180446/reports/dc/b1i_prn_gen_tsmc90.v)
- [SDC](runs/20261110_180446/reports/dc/b1i_prn_gen_tsmc90.sdc)
- [DDC](runs/20261110_180446/reports/dc/b1i_prn_gen_tsmc90.ddc)
- [DC 完整日志](runs/20261110_180446/reports/dc/run.log) 与 [耗时资源](runs/20261110_180446/reports/dc/time.txt)
- [VCS 完整日志](runs/20261110_180446/reports/vcs/run.log) 与 [耗时资源](runs/20261110_180446/reports/vcs/time.txt)
- [单元引用统计](runs/20261110_180446/reports/dc/references.rpt) 与 [运算资源](runs/20261110_180446/reports/dc/resources.rpt)
- [结构化指标](metrics.json) 与 [独立核对脚本](scripts/verify_results.py)

## 5. 分项判定与后续适用性

| 验收项 | 判定 |
|---|---|
| Windows → IC_EDA SSH 真实命令 | PASS |
| Windows ↔ IC_EDA SCP 上传、下载 | PASS |
| DC / VCS 实际运行和所需 feature 可用 | PASS |
| 原 RTL 功能回归 | PASS，32 PRN、每路 2046 chip |
| 单模块标准单元逻辑综合 | PASS，完整映射、黑盒与未映射单元均为 0 |
| 面积、最大/最小时序报告产生 | PASS |
| Setup 约束 | PASS |
| Hold 约束 | FAIL，48 个端点，最差 −0.156530 ns |
| 综合网表功能仿真 / SDF / 多角 STA | NOT_RUN |
| PrimeTime 独立分析 / ICC / ICC2 / 后端流程 | NOT_RUN |

**这台 VM 适合在相同库、约束和工具版本下开展小模块 RTL A/B 综合实验。** 当前 PRN 完整 DC 进程约 2.64 秒、峰值 261 MiB，8 vCPU、约 9.59 GiB 内存和约 10 GiB Swap 有充足的本次单模块运行余量。面积与关键路径数据已可复现读取，7 份源文件、3 份运行脚本、目标库和既有初始化配置的对应检查通过。

实际需要处理的条件包括重启后的网络恢复、始终显式使用 VCS `-full64`，以及某些报告命令的版本/LC 依赖。耗时也受缓存影响，首次 DC 5.13 秒、最终 2.64 秒，面积与关键路径数值一致。后续耗时比较需固定核数、宿主负载与冷/热缓存条件，并采用多次测量。当前保持违例、理想时钟和缺少 wire-load model 应作为这组基线的实验条件保存。

本轮验收已完成。实验结束时，所有新增实验文件保存在此独立目录，正式 Git 跟踪文件相对拉取后的 `fb662d3` 无本地差异，工作区原有未跟踪资料仍在。随后用户授权将本目录提交到上述独立分支。实验室 TSMC28 的 M3 能力继续以正式工程当前状态记录为准。[最终主机检查](host_final_checks.json) [交付核对日志](verification.log)
