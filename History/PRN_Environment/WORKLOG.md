# IC_EDA 实验事件

时间为 Asia/Singapore。认证值通过交互提示或本次调用传入，以下记录省略密码。

| 时间 | 实际操作 | 结果与证据 |
|---|---|---|
| 17:51 左右 | `git status --short --branch`、`git fetch origin main`、`git pull --ff-only origin main` | fetch/pull 0，`947d50b` → `fb662d3`，原未跟踪文件保留。读取 AGENTS/STATUS/GOAL/WORKLOG、H0、M1/M2 和技能 |
| 17:52 左右 | VMware inventory、进程与 VMX 检查，`vmrun list`、`checkToolsState`、`getGuestIPAddress` | 唯一运行 IC_EDA，Tools running，getGuestIPAddress 因无客体网卡 IP 失败 |
| 17:54 | `vmrun` 已认证文件传输与 `/bin/bash /tmp/ic_eda_initial_probe.sh` | 包装命令 0，OS、资源、工具目录、SSH 服务与主机公钥见 initial_probe.txt |
| 17:55 左右 | 客体 network_probe、`nmcli connection up id ens33` | 连接退出 4，networking disabled，ens33 unmanaged/DOWN，sshd active |
| 17:56 左右 | 已知用户密码验证 sudo 权限 | 首次命令空参数转义得到 usage，修正后显示 ICer 已有 `(ALL) ALL` 权限，日志为 sudo_probe*.txt |
| 17:56 左右 | sudo 执行 network_up.sh，`ip link set dev ens33 up`、`timeout 40 dhclient -1 -v ens33` | 两命令均 0，取得 192.168.236.129。临时 DHCP 日志保留，现有裸主机名配置导致两条 shell warning |
| 17:57 左右 | Windows OpenSSH，严格校验 Tools 读取的主机密钥，远端 `id; hostname; printf SSH_REMOTE_COMMAND_PASS` | SSH 0，ICer/IC_EDA/成功标记 |
| 17:58 左右 | `dc_shell -version`、`pt_shell -version`、`vcs -ID` 与库元数据探针 | DC 打印 O-2018.06-SP1，PT 打印 O-2018.06-SP1。VCS 未指定 full64 时编译器路径错误，tool_probe.txt 保留 |
| 18:00 | SCP 上传 input.tar.gz，SSH 解包并 `bash scripts/inventory.sh` | SCP/SSH 0，主客体压缩包 SHA-256 一致。工具/库/许可只读记录保存 reports/environment |
| 18:00:27 | `bash scripts/run_smoke.sh`，首轮 180027 | VCS 0，DC 0，DC 5.13 秒。初始入口打印 PASS，报告复查发现 check_timing 的 CMD-010 和 report_lib 的 LCSH-3，首轮保留为适配记录 |
| 18:02:53 | 移除 `check_timing -verbose`，增加完整日志/报告 Error 搜索，SSH 重跑 | 180253 的 VCS/DC 均 0，检查器捕获 library.rpt 的 LCSH-3，入口退出 1 |
| 18:04:46 | 改用 `list_libs`，SSH 运行最终脚本 | 180446 的 VCS/DC/入口均 0，Error 搜索通过。DC 墙钟 2.64 秒、峰值 RSS 267084 KiB，VCS 0.91 秒 |
| 18:06:25 | `bash scripts/final_probe.sh`，结果打包并 SCP 下载 | 客体 SSH active、ens33 UP、DHCP 客户端运行，无残留 DC/VCS/simv 进程。库、初始化与网卡配置哈希前后一致 |
| 交付检查 | Windows bundled Python 执行 `scripts/verify_results.py` | 退出 0，10 份运行清单文件哈希、7 份源复制、面积加和、setup 时序等式、48 个 hold 违例求和、库与配置哈希通过。生成 metrics.json |
| 18:12 后 | 最终脚本打包为 final_input.tar.gz，通过 SCP 上传，读取主客体压缩包哈希并做文档链接核对 | 三份传输包 SHA-256 一致，报告链接均存在，最终检查脚本退出 0。`git diff --check` 0、跟踪文件差异为空，VMware 最终仍只运行 IC_EDA |

实际工具命令及退出码还保存在各 run 的 `reports/commands.txt`、`*/exit_code.txt` 和 `/usr/bin/time -v` 日志中。各轮原始报告与失败保留。独立实验报告、状态和事件保存在本目录。

## 独立分支归档

2026-11-10，用户追加授权提交独立 Git 分支，并注明个人本地环境。执行 `git switch -c codex/ic-eda-personal-local-smoke-20261110` 退出 0，分支基点为 `fb662d3`。REPORT 和 STATUS 增补个人 Windows 主机与本地 IC_EDA 的执行归属。本次提交范围为本实验目录，提交说明记录工具、库、结果和个人本地环境；交付核对复用既有实验数据。

归档采用本目录 `.gitattributes` 的 `-text` 保留原始字节及源哈希。初次完整 `git diff --cached --check` 报告原始工具日志/报告的行尾空格，保留这些证据；手写 Markdown、Shell、Python、Tcl 和属性文件另做空白检查，并逐文件核对暂存区对象与本地字节。
