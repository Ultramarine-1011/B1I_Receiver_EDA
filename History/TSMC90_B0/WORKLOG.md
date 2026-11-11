# 本轮事件

- 2026-11-10，Asia/Singapore。git fetch origin main 退出 0。HEAD 5586384，origin/main fb662d3，正式 RTL 差异检查退出 0。
- VMware Tools 重新发现 IC_EDA 地址 192.168.236.129。SSH 主机密钥严格校验通过。
- 冻结 17 份 RTL/include/隔离源，以及阶段文件列表和脚本，共 24 项 SHA-256。输入包本地与客体 SHA-256 一致。
- 客体 MemTotal 9818 MiB、available 8337 MiB、Swap 10235 MiB/used 0。typical.db SHA-256 与上一轮一致。
- -x 预检及已验证 -f 入口均在读取 Tcl 前返回 DCSH-1。C locale 与原 time/timeout 包装未改变结果，最终最小预检退出 255，0.12 s，峰值 68512 KiB。
- lmstat 退出 0，但内容显示 snpslmd DOWN（-97,121）。等待用户授权恢复既有服务。未启动综合，也未把预检失败认作原始 RTL 的资源失败。

- 用户明确授权恢复现有 snpslmd。`lmutil lmreread -c 27000@IC_EDA -vendor snpslmd` 退出 0，snpslmd UP，最小 DC -f 预检退出 0。既有 .bashrc SHA-256 保持 ae18ee...edf5。
- `nohup bash scripts/run_stage.sh B0` 在客体独立目录启动，supervisor PID 14117，实际 DC PID 14147，工具进程为 common_shell_exec。24 项输入 SHA-256 检查通过。
- B0 analyze、elaborate、link、综合前 check_design/check_timing 完成。DC 参数 ENABLE_FLL=1、ENABLE_CARRIER_AID=1，max_cores=1，10 ns，真实 typical INVX1 驱动与 0.006604 pF 输出负载。
- 每 5 s 保存资源数据。主采样器按 dc_shell 名称未匹配到真实工具，进程树从开始完整保存，另附实际 PID 采样器。B0 停在 Mapping Optimization (Phase 1)。
- 原监督器观测 1222.03 s 后 KILL 外层 GNU time，返回 -9。GNU timeout 自建子进程组，随后对 DC 发 SIGTERM，最终 UTC 起点至日志 mtime 为 1248.69 s。GNU time 文件为空，DC 最终返回码缺失。结束后核实 DC/timeout/采样进程均退出。
- 本轮采样 DC VmHWM 2739704 KiB，进程树 RSS 2740552 KiB，VM 最低 MemAvailable 5752820 KiB，Swap 始终 0。最终面积、时序、QoR 和网表均为 NOT_AVAILABLE，B1 条件不满足并记录 SKIPPED。
- 原始日志约 23.7 MB 和必要报告压缩取回，results.tar.gz 约 584 KiB，传输 SHA-256 主客体一致。原始 WORK 保留客体。
- 监督脚本修正版首次短测退出 1，暴露旧 ps 格式解析问题，dummy 命令组已清理，失败记录保留。修为 /proc 读取及单调时钟后，正常任务 0，2 s 超时入口 1/子命令 SIGTERM=15，time 报告 2.04 s、监督总计 2.55 s，资源文件和回收检查通过。B0 原脚本及24项冻结清单保持，未再运行 RTL 综合。
- `scripts/summarize.py` 实跑退出 0，提取 metrics.json 并核验24项冻结输入。正式工程保护哈希、支持脚本、Markdown 引用和最终 Git 状态核验见 evidence/final_verification.json。

- 2026-11-10，用户追加当前分支提交授权。完整日志无损 gzip 核验通过，原始文本和传输包留本地。首次交付脚本因 Windows 默认 GBK 读取 Markdown 失败，已明确使用 UTF-8 修正。原始源/日志按字节保留，Git 空白检查单独检查本轮正文与脚本。提交范围限定 baseline，提交号见 Git 历史。
