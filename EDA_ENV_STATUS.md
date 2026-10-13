# EDA 环境状态

本文只记录截至 2026-09-21 已经通过主机命令、VMware 配置、虚拟机命令或 SSH 实际确认的状态。未完成的验证会明确标出。

# 当前架构

当前采用以下工作方式：

```text
Windows 主机运行 Codex / Cursor
              ↓ SSH
Linux VMware 虚拟机运行 EDA 工具
```

Linux 虚拟机保留已有的老版本 EDA、工艺库和本地 license 环境。后续 AI 在 Windows 上编辑文件，通过 SSH 在 Linux 中执行工具并取回日志、报告和生成文件。

# Windows 主机信息

| 项目 | 已确认状态 |
|---|---|
| Windows | Windows 10 Enterprise 22H2，build 19045.3803，x64 |
| CPU | Intel Core i5-9400F |
| 内存 | 16 GB |
| VMware | VMware Workstation 15.5.0 |

# Linux EDA 虚拟机信息

| 项目 | 已确认状态 |
|---|---|
| 虚拟机名称 | `EDA` |
| VM 配置文件 | `C:\IC\EDA.vmx` |
| Linux | Red Hat Enterprise Linux Server 6.7 (Santiago) |
| Kernel | `2.6.32-573.el6.x86_64` |
| Architecture | `x86_64` |
| glibc | 2.12 |
| CPU | 2 vCPU；虚拟机内显示 Intel Core i5-9400F |
| RAM | 2,039,008 kB，约 2 GB |
| Swap | 0 |
| 磁盘 | `/dev/sda` 500 GB；根文件系统约 492 GB，已用 41 GB，可用 427 GB |
| Shell | `/bin/bash` |
| 主机名 | `IC` |
| IPv4 | `192.168.159.128/24` |
| VMware 网络模式 | NAT |
| 默认网关 | `192.168.159.2`，已通过 ping 验证 |
| DNS | NetworkManager 配置 `192.168.159.2`；域名能够解析 |

网络连通测试已确认：虚拟机可以 ping 通 `192.168.159.2` 和公网地址 `1.1.1.1`。虚拟机内置的 `curl 7.19.7` 使用 NSS 3.18，访问现代 HTTPS 时出现 `SSL connect error`，因此没有确认虚拟机内的现代 HTTPS 可用性。

现有 NetworkManager 连接名称为 `System eth0`，采用 DHCP。系统连接的 `connection.autoconnect` 和 `/etc/sysconfig/network-scripts/ifcfg-eth0` 中的 `ONBOOT` 均为 `no`。已为桌面用户增加登录后的自动连接脚本，见“已完成配置”。

# SSH 连接

| 项目 | 已确认状态 |
|---|---|
| SSH 服务 | 已安装并运行，Windows 到虚拟机 TCP 22 可达 |
| 用户名 | `7901_15` |
| IP | `192.168.159.128` |
| Windows 私钥位置 | `C:\Users\IC\.ssh\id_rsa_eda_codex` |
| Windows 公钥位置 | `C:\Users\IC\.ssh\id_rsa_eda_codex.pub` |
| 虚拟机授权文件 | `/home/7901_15/.ssh/authorized_keys` |

推荐连接命令：

```powershell
ssh -i $HOME\.ssh\id_rsa_eda_codex 7901_15@192.168.159.128
```

该 RSA 密钥连接已实际验证成功。早先生成的 Ed25519 密钥不适用于虚拟机中的旧版 OpenSSH；推荐使用上面的 RSA 密钥。

# EDA 工具环境

EDA 环境入口位于 `/home/IC/.bashrc`。在 shell 中加载该文件后，已确认以下命令和路径：

| 工具 | 路径 | 已确认版本或状态 |
|---|---|---|
| VCS | `/opt/Synopsys/VCS2014/bin/vcs` | 可执行文件存在。安装目录标识为 VCS 2014；`vcs -version` 不受该版本支持，因此精确版本号尚未确认 |
| `dc_shell` | `/opt/Synopsys/Synplify2015/bin/dc_shell` | K-2015.06，build date 2015-05-28；该路径是指向 `snps_shell` 的符号链接 |
| `icc_shell` | `/opt/Synopsys/ICC2016/bin/icc_shell` | L-2016.03-SP1，build date 2016-04-11 |
| `icc2_shell` | 无 | PATH 和已检查的 Synopsys 安装目录中均未找到 |
| `pt_shell` | `/opt/Synopsys/PrimeTime2015/bin/pt_shell` | K-2015.06，build date 2015-05-21 |

## License 状态

- Synopsys `lmgrd` 和 `snpslmd` 进程已确认正在运行。
- `SNPSLMD_LICENSE_FILE` 已设置为本地文件 `/opt/Synopsys/License/License.dat`，该文件可读。
- `/home/IC/.bashrc` 还设置了 `CDS_LIC_FILE`、`MGLS_LICENSE_FILE`、`LM_LICENSE_FILE` 和 `AGILEESOFD_LICENSE_FILE`。本次没有对这些变量对应的其他厂商 license 做功能测试。
- 未修改任何 license 文件、license 环境变量或 license daemon 配置。
- 尚未通过完整的 VCS/DC 作业确认实际 feature checkout。

## 已确认的库和工艺入口

数字标准单元与工艺文件：

- `/home/IC/Foundry_Library/Digital/saed90nm_typ.db`
- `/home/IC/Foundry_Library/Digital/saed90nm_typ.lib`
- `/home/IC/Foundry_Library/Digital/saed90nm_icc_1p9m.tf`
- `/home/IC/Foundry_Library/Digital/milkyway/`
- `/home/IC/Foundry_Library/Digital/tluplus/`

模拟 PDK 入口：

- `/home/IC/Foundry_Library/Analog/PDK40nm/`
- `/home/IC/Foundry_Library/Analog/PDK40nm/cds.lib`
- `/home/IC/Foundry_Library/Analog/PDK40nm/smic40ll/tech.db`
- `/home/IC/Foundry_Library/Analog/PDK40nm/smic40ll/techfile.tf`
- `/home/IC/Foundry_Library/Analog/PDK0.5um/`
- `/home/IC/Foundry_Library/Analog/PDK0.5um/cds.lib`
- `/home/IC/Foundry_Library/Analog/PDK0.5um/st02/tech.db`
- `/home/IC/Foundry_Library/Analog/PDK0.5um/st02/techfile.tf`

Design Compiler 初始化文件 `/home/IC/.synopsys_dc.setup` 已确认设置：

- `target_library` 和 `synthetic_library`：`saed90nm_typ.db`
- 库搜索入口：`/home/IC/Foundry_Library/Digital`

# 当前课程工程资源

已发现三个主要数字课程工程目录：

- `/home/IC/zhxwjl/lab1/`
- `/home/IC/cbl_qys/lab1/`
- `/home/IC/Desktop/counter/`

已确认的 RTL、测试和约束文件包括：

- `/home/IC/zhxwjl/lab1/counter.v`
- `/home/IC/zhxwjl/lab1/testbench.v`
- `/home/IC/zhxwjl/lab1/counter.sdc`
- `/home/IC/zhxwjl/lab1/counter_after_dc.v`
- `/home/IC/cbl_qys/lab1/counter.v`
- `/home/IC/cbl_qys/lab1/testbench.v`
- `/home/IC/cbl_qys/lab1/counter.sdc`
- `/home/IC/cbl_qys/lab1/counter_after_dc.v`
- `/home/IC/Desktop/counter/counter.v`
- `/home/IC/Desktop/counter/testbench.v`
- `/home/IC/Desktop/counter/counter.sdc`
- `/home/IC/Desktop/counter/counter_after_dc.v`

已确认的参考或生成脚本：

- `/home/IC/cbl_qys/lab1/csrc/Makefile`
- `/home/IC/cbl_qys/lab1/DVEfiles/session.tcl`
- `/home/IC/Desktop/counter/csrc/Makefile`
- `/home/IC/Desktop/counter/DVEfiles/session.tcl`
- `/home/IC/.synopsys_pt_prefs.tcl`
- `/home/IC/.synopsys_icc_prefs.tcl`
- `/home/IC/.synopsys_dve_prefs.tcl`
- `/home/IC/.synopsys_dve_ini.tcl`

# 已完成配置

## SSH

- 确认虚拟机的 `sshd` 正在运行。
- 为 Windows 主机创建专用 RSA SSH 密钥。
- 将公钥写入 `/home/7901_15/.ssh/authorized_keys` 并设置目录和文件权限。
- 已从 Windows 实际执行 SSH 命令，并确认远端用户、主机名和命令输出正常。

## 网络

- 启用了现有的 VMware NAT 连接 `System eth0`。
- DHCP 已取得 `192.168.159.128/24`。
- 已确认默认路由、VMware NAT 网关、DNS 配置和公网 IP 连通性。
- 创建了 `/home/7901_15/bin/eda-network-up`。
- 创建了 `/home/7901_15/.config/autostart/eda-network-up.desktop`，用于该用户进入 GNOME 桌面后启动现有网络连接。
- 未修改系统级 `ifcfg-eth0`，其 `ONBOOT=no` 状态保持不变。

## 已验证命令

- Windows OpenSSH 到 Linux 的密钥认证。
- `dc_shell -version`。
- `icc_shell -version`。
- `pt_shell -version`。
- VCS 可执行文件定位和启动；其 `-version` 参数不受支持，尚未执行编译闭环。
- `nmcli con up id 'System eth0'`。
- 到 NAT 网关及公网 IP 的 ping。

## 已解决问题

- 找到加密的 `EDA` 虚拟机并通过 VMware Tools 执行客体命令。
- 识别出 VMware 网络模式为 NAT。
- 在没有系统管理员权限的虚拟机用户下，通过本地图形登录会话激活网络。
- 建立了 Windows 到 Linux 的稳定免密 SSH 路径。
- 定位了 EDA 初始化文件、主要工具、license 入口、数字库、模拟 PDK 和已有课程工程。

# 当前未完成事项

- Linux Codex 安装已经取消。官方安装脚本和 Linux musl 发布包曾下载到 Windows 工作目录，但没有传入虚拟机、安装或执行；下载包也没有完成最终哈希校验，因此不得视为可用安装包。
- 后续工作方式确定为 Windows Codex/Cursor 通过 SSH 控制 Linux EDA。
- 尚未完成最小 VCS 编译与仿真 smoke test，因此尚未确认 VCS 精确版本及其 license feature checkout。
- 尚未完成 DC 读取 RTL、综合、生成网表和报告的 smoke test，因此尚未确认综合闭环及其 license feature checkout。
- 尚未执行 ICC 的最小工程流程；目前只确认了 shell 版本。
- 尚未执行 PrimeTime 的时序分析流程；目前只确认了 shell 版本。
- `icc2_shell` 未找到。
- 尚未建立最终的 `/home/7901_15/eda_project/` 项目结构。
- 尚未建立统一的 `/home/7901_15/eda_env.sh` 环境入口。
- 尚未建立 Windows 与 Linux 项目文件的同步或部署命令。
- 系统级网卡仍然是 `ONBOOT=no`；当前网络恢复依赖 GNOME 用户登录后的自动启动项。
- Linux 自带 curl 的现代 HTTPS TLS 问题尚未解决。
- 用户 `7901_15` 不在 sudoers 中；没有取得或设置 root 权限。

# 后续推荐流程

1. 在 Windows Codex/Cursor 中编辑 SystemVerilog、Tcl、Makefile 和辅助脚本。
2. 使用专用 RSA 密钥 SSH 进入 Linux，或通过 `scp`/`sftp` 把工程文件送入虚拟机。
3. 在 Linux shell 中加载 `/home/IC/.bashrc`，然后调用 VCS、`dc_shell`、`icc_shell` 和 `pt_shell`。
4. 将工具日志、报告、网表和仿真结果通过 SSH 读取或复制回 Windows，由 Codex/Cursor 分析并继续修改工程。
5. 下一次会话应直接从最小 VCS/DC smoke test 和建立统一项目结构开始，无需重新扫描虚拟机、重新定位工具或重新测试 SSH。

# 2026-09-21 工程初始化与 smoke test 追加记录

以下事实由本次 Windows → SSH → Linux 实际运行确认；前文历史状态保留不改。

## 统一入口与项目路径

- 已创建 `/home/7901_15/eda_env.sh`。该脚本只设置已验证的 Synopsys 工具路径、`SNPSLMD_LICENSE_FILE=/opt/Synopsys/License/License.dat` 和数字库路径，不修改或依赖写入 `/home/IC/.bashrc`。
- 已创建 Linux 工程目录 `/home/7901_15/eda_project/`，包含 `rtl/`、`tb/`、`scripts/`、`constraints/`、`reports/`、`work/` 和 `docs/`。
- 从 Windows 非交互 SSH 中执行 `source ~/eda_env.sh` 后，`vcs` 解析为 `/opt/Synopsys/VCS2014/bin/vcs`，`dc_shell` 解析为 `/opt/Synopsys/Synplify2015/bin/dc_shell`；license 文件和 `/home/IC/Foundry_Library/Digital/saed90nm_typ.db` 均可读。

## VCS smoke test

- 复用了课程 counter RTL/testbench 和历史命令形式 `vcs -R counter.v testbench.v`，在新工程中完成解析、编译、elaborate、链接和仿真。
- VCS 实际报告 Compiler/Runtime 版本 `I-2014.03`。
- 仿真运行到时间 500，由 testbench 的 `$finish` 正常结束；生成了 `simv` 和 `counter.vcd`。
- Synopsys license server `27000@IC` 与 `snpslmd` 在运行期间可达；VCS 完成受许可的编译和仿真操作，未出现 license checkout 错误，因此 VCS 所需 license checkout 已实际验证。
- Windows 端能够直接看到 SSH stdout，并已将日志取回本工程 `reports/vcs_smoke.log`。

## Design Compiler smoke test

- 使用 `analyze -format verilog`、`elaborate`、`link`、现有 `counter.sdc`、`compile -exact_map` 完成最小综合流程。
- DC 实际版本为 `K-2015.06`；运行中实际加载 `/home/IC/Foundry_Library/Digital/saed90nm_typ.db`，使用 `TYPICAL` operating condition。
- DC 完成受许可的 HDL Compiler/Design Compiler 映射操作，未出现 license checkout 错误，因此 DC 所需 license checkout 已实际验证。
- 已生成 `counter_after_dc.v`、`counter_after_dc.sdc`、`dc_area.rpt` 和 `dc_timing.rpt`。报告中 total cell area 为 `210.124800`，setup slack 为 `7.14 ns (MET)`。
- `check_design` 有一条与该教学 counter 结构有关的 `LINT-1` warning（内部 cell `B_2` 未驱动网络），不影响本次最小综合闭环成功结论。
- Windows 已取回 DC stdout/log、网表和报告到本工程 `reports/`。

## 本阶段边界

- 本次未执行 ICC 或 PrimeTime 完整流程。
- 未修改 `/home/IC/.bashrc`、任何 license 文件/daemon 配置或系统网络配置。
- 未开始 GNSS 大规模 RTL 实现。

# 2026-09-21 B1I PRN VCS 回归追加记录

- 第一块正式 SystemVerilog RTL `b1i_prn_gen` 已通过现有 Windows → SSH → Linux VCS 流程验证。
- 使用 VCS I-2014.03，以 `-sverilog` 编译 RTL 和自检 testbench。
- PRN 6–37 全部 32 个 MEO/IGSO 序列分别完成 2046 chip 全周期逐 chip golden 比对、周期回绕和 epoch 检查；PRN 6、12、23、37 另做代表序列差异检查；最终日志标记 `B1I_PRN_REGRESSION_PASS`。
- 本次没有运行 DC/ICC/PT，也没有修改 EDA、license 或网络环境。

# 2026-09-21 Code NCO + E/P/L VCS 回归追加记录

- 新增 `code_nco` 与固定 accepted-sample 窗口的 `epl_correlator`，并通过现有 Windows → SSH → Linux VCS 流程实际验证。
- 使用 VCS I-2014.03，以 `-sverilog` 编译 `b1i_prn_gen.sv`、`code_nco.sv`、`epl_correlator.sv` 和自检 testbench。
- Python exact-rational/reference model 生成四组 golden vectors；VCS 逐事件检查相位、E/P/L、回绕、周期计数、六路积分、窗口边界和参考位置。
- 回归覆盖 PRN 6/12/23/37、标称与正/负码速微调、`sample_valid` 间歇停顿、2045→0 回绕、连续窗口、中途重装及 17 bit 累加器 `±65472` 极值，最终日志标记 `CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4`。
- 本次没有运行 DC/ICC/PT，也没有修改 EDA、license 或网络环境。

# 2026-09-28 跟踪前端回归追加记录

- Windows 经既有 RSA key 连接 `7901_15@192.168.159.128:22`，在 `/home/7901_15/eda_project` 实际完成 `make prn-regression code-nco-epl-regression carrier-regression`，整体退出状态 0。
- PRN 依赖回归再次出现 `B1I_PRN_REGRESSION_PASS`。
- 当前 NCO 的 reset/init 接纳屏蔽通过新增同周期冲突测试：`RELOAD_COLLISION_PASS`；原事件回归仍为 `CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4`。
- 新 Carrier NCO/Mixer 在 VCS I-2014.03 编译并自检通过：`CARRIER_REGRESSION_PASS events=29775 accepted=22043`。
- Windows 已取回三份日志；15 个远端源文件/向量哈希与 Windows 一致，详见 `reports/carrier/regression_manifest.json`。9 月 21 日原日志保留在 `reports/archive/2026-09-21/`。
- VM 起初未运行，启动要求加密密码，由用户解锁启动。后续连接恢复；成功命令使用客户端 `-o IPQoS=none`，未据此断言先前失败根因。未修改 VM 网络、license、`.bashrc` 或系统安装。
- 老版 SCP 的多远端文件一次取回曾报 `filename does not match request`，改用已知绝对路径逐文件复制成功；未关闭主机密钥或文件名校验。
- 本次未运行 DC/ICC/PT；以上为功能回归，不是完整跟踪闭环或 PPA 验收。

# 2026-10-13 个人本机前仿追加记录

当前近期交付使用Windows + WSL2 Ubuntu26.04（ultramarine）、Verilator5.032、g++15.2.0、make4.4.1、Python3.14.4。初始缺Verilator；wsl.exe -d Ubuntu -u root -- bash -lc 'apt-get install -y --no-install-recommends verilator' 实际安装退出0，仅新增必要包，未升级发行版。版本日志reports/local/environment.log。桥接、0.01s文件冒烟及9.28前端已在本机实跑，结果范围见STATUS/WORKLOG。当前完整接收机self_check仍FAIL。未调用或修复VMware/SSH/VCS/DC/ICC/PT。前文9.28远端可用性为历史事实，不能当作今天确认。

# 2026-10-14 F阶段环境边界追加
E阶段已在本机WSL2/Verilator完成100秒真实四星与原始检查/Route A，前一追加段的FAIL是当时快照。F继续使用相同现有本地工具，不重新扫描/访问VMware、SSH、Synopsys/license；F新增代码以本轮reports/f_stage实际日志为准。正式ASIC仍未执行。
