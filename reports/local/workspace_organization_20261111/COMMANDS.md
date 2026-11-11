# 实际命令与退出码

本轮日期为 2026-11-11。以下命令从仓库根目录执行，Python 使用 Windows bundled Python。原始工具辅助脚本保存在 `work/workspace_organization_20261111/`。

当前 Windows 环境可用以下完整入口重新检查。

```powershell
& "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" reports/local/workspace_organization_20261111/verify_workspace.py
```

| 命令 | 退出码与范围 |
|---|---|
| `git status --short --branch`、`git branch -avv`、`git worktree list --porcelain`、`git log -7 --oneline` | 0，读取本地真实状态 |
| `git show main:STATUS.md`、`git show main:GOAL.md` | 0，读取正式 main 的状态与授权快照 |
| `git ls-remote origin refs/heads/main` | 0，远端 main 为 fb662d36e85e9cffe02a4b8f003887808f73007c |
| `python work/workspace_organization_20261111/inventory.py` | 0，16310 文件及全量 SHA256 |
| `python work/workspace_organization_20261111/prepare_migration.py` | 0，生成75项计划，132份非缓存安全副本逐成员验证 |
| `& work/workspace_organization_20261111/migrate.ps1` | 0，75项迁移完成，逐项日志保存 |
| `python reports/local/workspace_organization_20261111/verify_workspace.py` | 0，全量文件、历史、重要归档、包内文件与链接核对，机器结果见 verification.json |
| `scripts/run_six_channel.ps1 -Task navigation -EvidenceDirectory reports/local/workspace_organization_20261111/navigation_smoke` | 1，缺 work/verilator 父目录，失败日志保留 |
| `New-Item -ItemType Directory -Path work/verilator -Force` | 0，恢复 runner 需要的构建父目录 |
| `scripts/run_six_channel.ps1 -Task navigation -EvidenceDirectory reports/local/workspace_organization_20261111/navigation_smoke_retry1` | 0，重新构建及六路1080位自检通过 |
| PowerShell `Parser.ParseFile` 检查四个既有入口与 migrate.ps1 | 0，无语法错误 |
| `python work/workspace_organization_20261111/portable_smoke.py` | 0，独立解包、隔离打包入口、迁移后 PRN 核对与原位/解包文件列表检查 |
| `wsl.exe -d Ubuntu -- bash .../work/workspace_organization_20261111/check_paths.sh` 初次 | 2，原 h0_vm_smoke.sh 的 CRLF 导致 Bash 解析失败 |
| 同一 check_paths.sh 在恢复 h0 脚本 LF 后重跑 | 0，20个 Bash 语法、主机/独立包输入 SHA256 与携带包校验通过。缺 tclsh 项显式为 NOT_RUN |
| `git diff --exit-code main -- rtl student_release model scripts synth constraints tb` | 0，正式源与 main 的 Git 内容一致 |
| `git fsck --full` | 0，已有 dangling 对象保留 |
| `git diff --check` | 0，无新增空白格式问题 |
| `git diff --cached --check` | 初次2，保留原字节的 CRLF 日志/JSON 被识别为行末空白。为本轮证据目录设置 cr-at-eol 规则后重跑0，日志字节保持 |

验证工具可在 Windows bundled Python 下重新执行。原始全文件清单保存在本机 work 目录，校验工具需要这些清单及本地归档缓存。当前技术结果固定为 c3ba596，本轮提交只记录整理与验证。
