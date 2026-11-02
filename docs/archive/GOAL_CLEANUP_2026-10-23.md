# 工程精简（2026-10-23）

本轮授权：合并重复文档，减少防御性写作及无收益的审计检查，完成必要验证、文档更新和 main 正常提交推送。基线为 GitHub 最新 main 与本地文件；保留用户未提交内容。

## 验收

- STATUS 管当前状态，GOAL 管本轮范围，WORKLOG 管历史，AGENTS 管长期规则；技术事实由对应报告维护。
- 默认启动只读 Git 状态、STATUS、GOAL、AGENTS 及 WORKLOG 最近相关事件，其余按需读取。
- 默认验证聚焦实际编译源、配置、退出码、断言及输出；历史完整性审计作为独立工具保留。
- 保留教师判据、真实 PASS/FAIL、必要实验条件和复现入口；登记六份基础 RTL 副本问题。
- 正式 RTL、ROM、算法、教师文件、原测试及历史原始证据不改；三份正式模块报告以保留为主。
- 文档引用、受影响脚本语法、轻量成功/失败路径及 Git diff 检查通过，记录实际命令和退出码。

不运行长接收机仿真，不进入 DC/ICC，不合并 RTL 目录，不新增审计框架。确认范围及检查后正常提交推送；远端发生实际冲突时保留本地成果并停止推送。完成即停止。

历史授权及成果见 [G 授权](docs/archive/G_AUTHORIZATION_2026-10-14.md)、[H0 实验](docs/H0_VM_SMOKE.md)、[BDI 实验](experiments/bdi_capture/README.md) 与 [WORKLOG](WORKLOG.md)。当前状态见 [STATUS](STATUS.md)。

本轮验收已完成，检查证据见 [整改记录](reports/local/cleanup_2026-10-23.md)；完成 Git 交付后停止。
