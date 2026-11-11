# 历史实验索引

| 实验 | 版本 | 最终结果与位置 |
|---|---|---|
| 2026-11-10 PRN 环境验证 | `fb662d3` 的 PRN 源，随本地实验分支保存 | [已归档目录](2026-11-10_prn_environment/README.md)，VCS 32 PRN 通过，DC 产生网表/DDC，48 个 hold 违例 |
| 2026-11-10 B0 原始通道 | `400de3a` | [原位归档](../ic_eda_20261110/baseline/REPORT.md)，完整映射超时，冻结源仍供后续实验读取 |
| 2026-11-10 V1–V4 算术探索 | `ce173b6` | [原位归档](../ic_eda_20261110/divider_opt/REPORT.md)，位精确回归通过，完整 DC 超时，V4 保留作 V6 参考 |
| 2026-11-10 V5 检查点 | `346606e` | [V6 报告中的过程记录](../ic_eda_20261110/night_opt/REPORT.md)，完整映射超时，源码版本由 Git 保存 |
| 2026-10-19 PRN-6 捕获 | `b17f3d0` 合入正式 main | [原位归档](../bdi_capture/README.md)，独立捕获验证通过，原始 VCD/CSV 留在所属 run |

原位归档的目录承担实际复现依赖。构建缓存已移到根目录 [archive/rebuildable](../../archive/README.md)，源文件、刺激、关键日志和映射证据继续保留原位。
