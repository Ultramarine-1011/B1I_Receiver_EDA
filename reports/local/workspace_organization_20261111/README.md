# 2026-11-11 工作区整理记录

本轮起点为本地实验分支的 `c3ba596`。盘点、迁移和验证原始材料保存在仓库根目录 `work/workspace_organization_20261111/`。所有迁移已完成，未删除文件，验证结果见下表。

## 原始问题与采用的结构

仓库藏在两层同名 `windows-vmware-br-br-br-br` 目录内。仓库 README 停留在早期接收机状态，PRN 环境探测文件与后续优化实验混放，当前成果、旧版本和缓存缺少统一入口。

整理前主要层级如下。

```text
DIC_EDA/
├─ Report_Template/
└─ windows-vmware-br-br-br-br/
   └─ windows-vmware-br-br-br-br/  [唯一 Git 仓库]
      ├─ EDA_2026-10-13.md, plan.docx
      ├─ experiments/ic_eda_20261110/ [PRN 散文件、B0、V4、V6]
      ├─ experiments/ic_eda_20261111_backend/
      └─ work/verilator/ 及各实验 work/build_*/
```

整理后主要层级如下。

```text
DIC_EDA/
├─ README.md
├─ B1I_Receiver_EDA.lnk  [直达原 Git 目录]
├─ Report_Template/
└─ 原两层目录/  [物理路径保留]
   ├─ README.md, STATUS.md, GOAL.md
   ├─ rtl/, student_release/, model/, tb/, scripts/, synth/
   ├─ experiments/
   │  ├─ active/README.md
   │  ├─ archive/2026-11-10_prn_environment/
   │  ├─ ic_eda_20261110/{baseline,divider_opt,night_opt}/
   │  └─ ic_eda_20261111_backend/
   ├─ deliverables/2026-11-11_backend_lab/
   ├─ archive/{reference,rebuildable}/
   └─ reports/local/workspace_organization_20261111/
```

## 五类文件及处理

| 类别 | 内容 | 处理 |
|---|---|---|
| 当前源和脚本 | 正式 RTL、教师接口、测试数据、模型、runner、V6 源、B0 冻结源与 V4 比较参考 | 保留原位及原字节 |
| 最新有效成果 | 原始/重建 V6、fast_v6_channel 网表/DDC/SDC/报告、实验室准备与功能证据 | 保留原位，增加 [当前入口](../../../experiments/active/README.md) |
| 历史实验 | PRN 环境实验、B0、V1–V4、V5、BDI 捕获、旧目标和课程附件 | PRN 与旧附件实际迁移，仍作输入的历史实验原位归档并建立 [索引](../../../experiments/archive/README.md) |
| 可重建缓存 | 40 个 Verilator 构建目录，含 C++、对象、预编译头和可执行程序 | 迁到 `archive/rebuildable/2026-11-11_verilator/`，保留全部文件 |
| 用途或依赖尚未逐项确认 | work 中的旧安装包、网络诊断、partial、绘图依赖、回放波形和重复输入 | 保留原位，清单及内容哈希随原始盘点保存 |

教师 `261102/`、`BDI_signal_source_student/` 与三份未跟踪 PDF 保持原位。`Report_Template/`、`.git`、虚拟磁盘、许可证和工艺库均未参加迁移。

`duplicates.json` 依据 SHA256 记录不少于 1 MB 的 24 组相同内容。样点 CSV、原始库探针 DDC、生成器输入副本各有来源或运行依赖，继续保留。四份 PRN 传输包分别对应初始/修正版，按各自内容保存。没有删除文件，也未将大缓存重新压缩。

## 迁移与回退

75 项迁移、4697 个文件共 8317732974 字节。其中 40 个缓存目录约 7.75 GiB。逐项对应见 [migration_plan.json](migration_plan.json)。原始文件清单、目录清单、Git 状态及引用、迁移完成日志、安全副本分别为 `work/workspace_organization_20261111/` 中的 `before_files.json`、`before_directories.json`、`before_git.json`、`migration_journal.jsonl`、`safety_originals.tar.gz`。

安全副本包含 132 个非缓存迁移文件，移动前已逐成员校验。缓存采用同卷移动，移动后按整理前全量 SHA256 复核。最新映射成果保持原址，未新增大文件副本。

如需回退，以迁移清单逆序把 target 移回 source。先核对 SHA256，若 source 已由后续回归重建，则另存新构建或选择只恢复所需项，避免覆盖。原 root README/GOAL/STATUS、移动前脚本和报告可从 `c3ba596` 读取，非缓存迁移原件另有安全副本。旧 GOAL 同时按原字节保存于 [历史目标](../../../docs/archive/GOAL_BACKEND_2026-11-11.md)。

## 路径与验证范围

保留正式工程和 B0/V4/V6/后端物理路径，现用源清单、SDC、DDC 缓存路径继续沿用原路径。早期 PRN 历史报告的 Windows 命令改为仓库相对路径，核对脚本仅修正仓库父目录层级。实验室运行清单补充从仓库根目录打包的完整命令和当前携带包入口。

Windows 的 VMware 可执行程序、vmx 路径及客体 `/home/ICer`、工具和库路径继续对应原机器。实验室入口继续使用可覆盖的 `LAB_CONFIG`、`PDK_ROOT`、`REPO_ROOT`、`IF_DIR`。本轮没有改变这些外部依赖的实际位置。

本轮未重新执行 DC 原生 DDC 读取、TSMC28、SDF 或功耗实跑。V6/后端综合输入和缓存位置保持原样，DDC/网表以哈希及归档成员核对。本轮产生的轻量验证与历史综合证据分别按本轮/原日期记录。

## 实际验证与修复

| 检查 | 实际结果 |
|---|---|
| 全量原文件对应 | 16310 个文件均找到，16300 个逐字节相同，10 项有明确目的的文本变化，详见 [verification.json](verification.json) |
| Git 与正式基线 | main 与所有原有其他引用保持，四个指定提交仍为当前分支祖先。`git fsck --full` 退出0，已有 dangling 对象保留。正式源目录与 main 的 Git 内容差异为空 |
| 用户原未提交资料 | 13 个未跟踪文件的路径、字节和未跟踪状态保持 |
| 压缩包 | 35 个 tar.gz 完整读取及 gzip CRC 检查通过，三份网表/模块/后端清单的 218 个成员及本机原件逐 SHA256 匹配。旧 plan.docx 的 ZIP 完整性通过 |
| 实验室携带包 | 98 个文件与整理前快照一致，校验文件匹配。原包独立解包、包内 stage 清单、六星刺激和综合文件列表解析通过 |
| 打包脚本 | 隔离副本中，从 deliverables 工作目录执行原 prepare.py --lab-bundle 退出0，生成包的 98 个文件与副本输入匹配 |
| 历史 PRN 核对 | 迁移后的 verify_results.py 退出0，结果写到本次报告目录，原 metrics 保留。原 hold FAIL 继续记录 |
| 轻量功能回归 | 原 run_six_channel.ps1 的 navigation 任务最终退出0，SIX_NAVIGATION_PASS，6 路共 1080 位 |
| 脚本与链接 | 20 个 Bash 脚本语法通过，5 个 PowerShell 入口解析通过，Python AST 与当前导航文档链接检查通过 |
| 尚未直接验证 | WSL 无 tclsh，Tcl 完整性检查未执行。DC 原生 DDC 加载及外部 VMware/SSH、工艺模型可用性本轮未重测 |

首次导航构建退出1，原因为迁走整个缓存目录后缺少 `work/verilator` 父目录。恢复该父目录后，原 runner 完整重建并通过。初次失败和最终重跑日志分别保存在 `navigation_smoke/` 与 `navigation_smoke_retry1/`。

额外脚本检查发现 Windows 工作副本的 `scripts/h0_vm_smoke.sh` 含 CRLF，Bash 在 elif 处解析失败。已把本机行尾恢复成与 main blob 完全一致的 LF，并新增根 `.gitattributes` 的 `scripts/*.sh text eol=lf`，避免后续 checkout 再引入该问题。原脚本逻辑和 Git blob 未改变。初次失败与重试日志均保留。

Windows 两层同名物理目录继续保留，以保持成熟脚本和证据中的路径。`DIC_EDA/README.md` 与 `B1I_Receiver_EDA.lnk` 提供直接入口。尚未发现本轮新增的失效工作路径。具体命令与退出码见 [COMMANDS.md](COMMANDS.md)。
