# G 阶段：真实性能证据与因果评价

授权日期2026-10-14，完整目标见[G_AUTHORIZATION](docs/archive/G_AUTHORIZATION_2026-10-14.md)。F目标/停止状态已归档。当前状态只见[STATUS](STATUS.md)，课程总范围见[COURSE_MASTER_PLAN](docs/COURSE_MASTER_PLAN.md)。

仅使用已有Windows/WSL2 Ubuntu/Verilator/Python/g++；禁止VMware、SSH、Synopsys及H后端。教师公共文件和plan冻结项不改。输入真值只生成/评分，不进入DUT。默认4通道与E100秒成功BIN保持。允许阶段Git提交和正常推送main；不提交大型IF/BIN/构建。

| 阶段 | 本轮验收 | 状态 |
|---|---|---|
| G0 | main/HEAD/工作区、E/F哈希；资源及正式缺口登记，冻结F | 完成：resource_audit.json，23冻结项/25编译RTL/ROM匹配 |
| G1 | 实际RTL→原始记录/周期/可用时间→评分；版本/输入hash/配置/退出码；独立边界算例 | 完成：real51实际204425记录/834768000样本，16边界检查及数据通路审计0 |
| G2 | P01覆盖/成本、P02每任务周期、P03独立种子成功/失败/截尾诊断 | 待执行 |
| G3 | 已输出NAV/OBS、完整同代星历、无未来回填、依赖序号；三连1秒解/第3可用TTFF | 执行中：real51取得49/50两真实因果解，52s确认测试在跑 |
| G4 | P06独立码/频/字诊断；P08真实2秒RF消失恢复与健康通道保持 | 待执行 |
| G5 | D01–04连续真值/动态定向测试；P09无真值不填误差 | 待执行 |
| G6 | 1/4/12服务率/最大等待/ready/记录/缓存；固定速率源；假定clk预算 | 待执行 |
| G7 | 必要回归、E/F保留、分类/缺口/复现报告、提交推送、唯一下一任务 | 待执行 |

分类：OFFICIAL_PASS、SELF_GENERATED_PASS、PARTIAL、FAIL、NOT_RUN、BLOCKED_INPUT、BLOCKED_ENV。框架自测与模块合成PASS单列，不合并为正式性能PASS。

先短测试后估昂贵测试成本。全部当前可执行评价能力和低成本真实性能测试完成、有审计记录后停止。正式场景缺失不阻塞独立任务；G完成不等于课程正式P01–P09全通过，不进入H。
