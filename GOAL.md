# F 阶段：完整多通道集成与系统验证基础

授权日期：2026-10-14。完整用户目标保存在 [F_AUTHORIZATION](docs/archive/F_AUTHORIZATION_2026-10-14.md)。唯一当前状态见 [STATUS](STATUS.md)，实际命令与失败证据见 [WORKLOG](WORKLOG.md)。长期目标见 [COURSE_MASTER_PLAN](docs/COURSE_MASTER_PLAN.md)；G/H/I 本轮仅规划。

## 边界

保留 E 四星100秒、560 NAV、324有效OBS、99 Route A历元、BIN哈希和历史报告，不外推隐藏场景、定位真值精度或ASIC通过。仅现有Windows/WSL2 Ubuntu/Verilator/Python，禁止VMware、SSH/远程EDA、DC/ICC/PT/DRC/LVS。教师公共文件不改，学生实现限其rtl/；测试真值隔离DUT。允许正常Git提交与推送main，不强推、不上传IF/BIN/构建/巨大日志。

## 验收清单

状态用 PASS / FAIL / NOT_RUN / BLOCKED_INPUT / PARTIAL，引用当前源码实际证据。正式性能场景/真值缺失可列BLOCKED_INPUT，不阻塞其他独立任务。

| 阶段 | 验收条件 | 当前状态与证据 |
|---|---|---|
| F0 | 实查main/HEAD/修改，归档E目标/状态，备份成功BIN；逐章总计划；最小修改点 | PASS：f8e8de7、远端同版本0/0、干净；E BIN备份哈希匹配；COURSE_MASTER_PLAN、F_MULTICHANNEL_DESIGN |
| F1 | 参数化1/4/12，独立身份/generation/NCO/环路/同步/电文/测量；短合成一致性/公共样本；默认4；周期预算 | NOT_RUN |
| F2 | 候选去重/分配、后台捕获、满载策略、失锁撤销/type3/释放重捕、generation递增与旧状态拒绝；停顿/反压/EOF/reset/错误配置 | NOT_RUN |
| F3 | 模块→短合成→短真实→必要长真实；记录/共同历元/无伪有效/唯一最后end/样本与flags；直接相关回归 | NOT_RUN |
| F4 | V1.7 P01–P09/D01–D04场景、运行、指标/统计/因果TTFF和模板；低成本实测/独立手算；缺项明确 | NOT_RUN |
| F5 | 存储/端口/宽算术/12通道资源/共享周期/仿真结构/吞吐代码风险与最低代价建议；SYNTHESIS_READINESS | NOT_RUN；不执行正式后端 |
| F6 | E公开四星功能必要复验；源/输入/配置/退出码证据；最终简报/文档一致；分阶段提交与正常推送 | NOT_RUN |

## 执行与停止

按F0→F6，先短后长；昂贵测试先估墙钟。常规设计/修复/测试自主执行，不推倒E、不扫旧环境、不扩展G/H/I。所有可执行目标完成或合理诊断仍阻塞时如实交接；工具/会话中断不是完成。
