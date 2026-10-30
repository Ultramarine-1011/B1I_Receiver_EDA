# H1：同步与导航前端的 VCS 复现和增量综合

授权日期 2026-10-30。范围是当前 `nh20_sync`、`d1_word_sync`、`navigation_d1` 的 VCS 自检，以及这三个模块的增量 Design Compiler 综合。不授权完整接收机综合、ICC、PrimeTime 或 DRC/LVS。不改已验收算法。长时间综合按决定跳过并记录，不继续等待。

阶段性完成，存在明确未完成项。不是全 PASS。

| 验收 | 结果 |
|---|---|
| 原工作区未提交修改备份，且原目录不被覆盖 | 完成。补丁和 116 个未跟踪文件在仓库外，哈希已核 |
| H1 使用 GitHub 最新 main，且不整包覆盖搬迁脚本 | 完成。`697ebaaa66b9e513b153a36870abd5f5653e4a10`，搬迁补丁未并入 |
| NH/D1 VCS | PASS。I-2014.03，退出码 0，`NH_D1_MODULE_PASS` |
| 双子帧导航 VCS | PASS。退出码 0，`NAVIGATION_D1_PASS` |
| `d1_word_sync` DC | 映射完成。实验性 10 ns，slack +0.019 ns。black-box 计数 2，对象 UNKNOWN |
| `nh20_sync` DC | INTERRUPTED。映射优化第 14 阶段被中止，不是设计 FAIL |
| `navigation_d1` DC | NOT_RUN |
| 完整接收机 DC / ICC | NOT_RUN |

实验条件、哈希和面积见 [H1 报告](docs/H1_VM_FRONTEND.md)。完整接收机综合仍需新的授权，并且要先有 `nh20_sync` 与 `navigation_d1` 的综合结果。

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
