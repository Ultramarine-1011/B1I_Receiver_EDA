# 本次真实命令与退出结果

日期2026-10-19，Asia/Singapore。逐个Linux编译/仿真命令数组、cwd、耗时、exit_code见 ../runs/20261019_164411/run_summary.json；不以外层PowerShell退出0替代内部检查。

1. `powershell -NoProfile -ExecutionPolicy Bypass -File experiments/bdi_capture/run.ps1`，最终运行目录20261019_164411，退出0；reference 0、build 0、main/gaps/phase3/terminal/zero/restart各0，独立评分全部PASS。
2. `powershell -NoProfile -ExecutionPolicy Bypass -File experiments/bdi_capture/plot.ps1`，退出0；实际Python路径、参数和日志见当前runs的plot_command.json、plot.log；五张PNG逐张人工视觉检查，无裁切或遮挡。
3. `C:/Users/26255/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 experiments/bdi_capture/scripts/audit_delivery.py --run experiments/bdi_capture/runs/20261019_164411`，最终退出0；保护基线、当前源码、模块输入边界、README18链接和新源空白检查通过。
4. `git diff --check -- STATUS.md WORKLOG.md`，退出0，Git只提示本地LF将来可能转CRLF。未运行git add/commit/push/reset/clean/checkout。

保留的失败：

- 首次run.ps1，runs/20261019_164044，实际退出1；参考模型已验证2046码片匹配，随后对教师示例低值表的逐项断言失败，尚未进入编译。继续核对发现实际完整循环表低值与示例六处略异；门限8192及相位10主峰57288不变。最终自检逐样点、逐窗对照当前源的独立模型，README明确列出全部差异。
- 交付审计脚本首次Python退出1：端口正则同时匹配了绝对值function的input value，错误名单为[clk,rst_n,if_sample,if_valid,value]。限定module头后同一命令退出0。该组合PowerShell命令随后运行git status，外层退出0不表示这次Python审计成功；最终单独运行Python所得退出0才作审计证据。未因此修改RTL或测试判据。

开发快照runs/20261019_164133保留；最终当前RTL/TB证据仅绑定164411。完整接收机、历史H0回归、DC/ICC均NOT_RUN。
