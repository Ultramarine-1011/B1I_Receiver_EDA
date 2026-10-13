# Skills 安装状态

检查日期：2026-10-13。已安装 **8 个项目 Skills**，唯一安装目录为 `.agents/skills/`；不创建全局副本、Cursor 副本或符号链接，不改已有工程配置、RTL、模型、Makefile、冻结方案及历史日志。

| Skill | 来源 / 用途 |
|---|---|
| `systemverilog` | babyworm/rtl-agent-team；SV 编码、定点与工具兼容审查 |
| `tb-best-practices` | codejunkie99/Gateflow-Plugin；自检 TB、scoreboard、超时与边界 |
| `systematic-debugging` | openai/plugins/superpowers；模型、RTL、工具与 SSH 故障定位 |
| `nature-writing` | Mubuky/nature-skills；已适配为技术报告、忠实润色和排版 |
| `rtl-vcs-verification` | 项目专用；Windows 源同步、Linux VCS、日志与哈希证据 |
| `gnss-b1i-design` | 项目专用；B1I 跟踪算法、独立模型和时间语义 |
| `synopsys-asic-flow` | 项目专用；既有 VCS/DC/ICC/PT 环境与流程边界 |
| `eda-autonomous-workflow` | 项目专用；按 GOAL 执行、验证和维护交接 |

## 兼容与精简

[Codex 官方说明](https://learn.chatgpt.com/docs/build-skills)与 [Cursor 官方说明](https://cursor.com/docs/skills)均支持项目 `.agents/skills/`。统一使用可移植的 `name`、`description` YAML 元数据，默认按请求自动选择；Codex 可用 `$skill-name`，Cursor 可用 `/skill-name`。在本项目新一轮对话可用；列表未刷新时重新打开聊天或重启应用。

四个上游均固定到提交，来源、原始入口哈希及安装文件哈希见 [.agents/skills-lock.json](.agents/skills-lock.json)。保留各来源 LICENSE、Nature NOTICE 和只供溯源的 `references/upstream.txt`。有效入口已明确标注衍生适配，保留必要支持材料，移除未使用资源。

未安装多代理编排、强制 TDD、重复验证工作流、Gateflow CLI/PCB/FPGA 流程、Nature 投稿/专利/下载等无关 Skills。移除了 Claude 专用工具声明、插件状态文件依赖、强制端口改名和固定 SRAM 阈值。TB 失败必须 fatal/非零退出，覆盖率示例不作为课程验收门限。

## 自动检查结果

- **Codex 实际发现 PASS**：本机 CLI 0.133.0 的 `app-server skills/list` 返回全部 8 项，均 `enabled=true`、`scope=repo`，无发现错误；见 [发现证据](reports/skills/codex_discovery.json)。没有创建聊天或运行模型代理。
- **Cursor 兼容检查 PASS**：本机安装版本 3.23.23，其实现中存在 `.agents/skills` 发现路径；8 项满足官方格式。未操作 Cursor UI，因此不把此结果声称为 UI 列表实测。
- **格式与资源 PASS**：官方 `quick_validate.py` 对 8 项均通过；项目校验检查名称、元数据、有效入口引用、重复名称和文件哈希，全部通过。
- **模型依赖 PASS**：PRN、Code NCO/EPL、Carrier、tracking_reference 四个模型成功导入；未运行扫描、生成向量或更改模型。见 [校验记录](reports/skills/validation.json)。
- 修复官方校验器缺少 PyYAML 和 Windows 默认 GBK 解码问题：PyYAML 6.0.3 仅装在 `.agents/.validation-deps/`，校验使用 `-X utf8`。Superpowers ZIP 遇长路径错误，改用稀疏 Git 安装成功。没有修改全局 Python、Git或系统设置。
- **远端 EDA 实测受限**：历史 `C:\Users\IC\.ssh\id_rsa_eda_codex` 和当前账户同名路径均不存在；非交互 SSH 返回 `Connection closed by 192.168.159.128 port 22`，命令失败。无法在本次验证 VCS/DC/ICC/PT 可执行性；历史 PASS 不作为此次实测。Skills 支持有效现有密钥/SSH agent，并保留既有用户、地址、环境和镜像路径。后续实际 EDA 操作需恢复既有 SSH 接入；未创建凭据、改网络或扫描 VM。

复查：使用已配置 Windows Python 执行 `-X utf8 .agents/check_skills.py`；Codex 发现复查入口为 `.agents/probe_codex_skills.py`。维护安装脚本 `.agents/configure_skills.py` 仅面向本次新建包，日常复查不要重新执行适配，以免覆盖后续 Skill 编辑。

本次只安装配置 Skills，不推进 M1；未改 RTL，无需重跑 EDA 回归。下一项开发仍以 `GOAL.md` 和 `docs/NEXT_STEPS.md` 为准。
