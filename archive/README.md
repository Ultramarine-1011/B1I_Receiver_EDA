# 保留资料与构建缓存

| 目录 | 内容与使用方式 |
|---|---|
| [reference/2026-10_course_plan](reference/2026-10_course_plan) | 根目录原 `plan.docx`，按原字节保留。当前冻结文本方案仍在根目录 `plan.md` |
| `rebuildable/2026-11-11_verilator/course` | 原 `work/verilator`，含生成的 C++、对象、预编译头和仿真可执行程序 |
| `rebuildable/2026-11-11_verilator/divider_opt` | V1–V4 的 `build_*` 缓存，保留原相对层级 |
| `rebuildable/2026-11-11_verilator/night_opt` | V5/V6 和候选实现的 `build_*` 缓存，保留原相对层级 |

缓存只做本地迁移，未压缩、未删除，也不纳入 Git。已有 runner 会在原工作目录重新生成构建。源/刺激/波形、结果 CSV、DDC 和正式日志继续位于原所属目录。

迁移对应关系及回退方式见 [整理记录](../reports/local/workspace_organization_20261111/README.md)。历史实验入口见 [实验索引](../experiments/archive/README.md)。
