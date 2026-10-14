# 三份模块报告修订证据（2026-10-14）

仅文档与轻量模块取证，没有修改接收机、教师文件、原测试判据、归档或长场景证据。

- `modelsim*.log`：真实命令、stdout、退出码。九字／双子帧／P02缩网格有自动PASS；跟踪局部停止有明确PARTIAL标识，不能作为完整闭环PASS。
- `wave_sources.json`：实际编译的RTL和隔离TB SHA256。四TB仅将输入及CSV文件路径改到隔离目录，正式判据原样。
- `*_events.csv`：对应PNG窗口内的实际VCD数值，时间单位μs，来自ModelSim逻辑时钟。导航字/SOW按实际record_data位段提取；其它值不由真值补造。枚举状态的VCD未知编码不绘成有效状态。
- `plot_actual_traces.py`：四张真实WLF→VCD时序图的绘制脚本，使用既有work/plotdeps的Matplotlib。`docs/report_assets/waveform_provenance.json`保存源、输入、WLF/VCD/图像/CSV哈希、条件及窗口。
- `document_audit.json`、`delivery_audit.json`、`browser_render_audit.json`：Markdown链接/表格/公式/图、真实渲染、受保护源码及E100哈希等检查。
- `run_waveforms.ps1`、`collect_more.ps1`是本次隔离命令脚本快照，原执行位置为`work/report_waveforms/`；需要重复时先放回该位置，不能从本证据目录直接运行其相对路径。波形及编译库仍在原work目录，不提交构建或波形大文件。

原本机ModelSim GUI已启动并观察真实WLF。网络中断后Computer Use node_repl报“failed to write kernel assets／系统找不到指定路径（os error3）”，reset后仍失败；未改安装、许可、安全或MCP配置。最终四PNG明确为实际VCD绘图，**GUI截图数量为0**；另两SVG来自原模块真实CSV。未将绘图或合成Prompt测试冒充公开IF实收结果。

报告实际引用E历史100秒／F20秒／G52秒及G自生成失败/保持/动态/恢复证据。当前正式性能未全验收，持续实时与ASIC后端未验证。
