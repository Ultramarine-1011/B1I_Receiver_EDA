# CURRENT STATUS

更新时间：2026-10-13 18:32（Asia/Singapore）。状态：MINIMUM_MODULE_DELIVERY_COMPLETE；接收机集成INCOMPLETE。

这是近期最低模块/报告交付完成，**不是完整教师接收机PASS**。目标/验收见GOAL.md；事件与实际命令见WORKLOG.md。

| 项目 | 当前实测结果 | 证据 |
|---|---|---|
| A：解包/协议 | 32bit=16×2bit、LSB最早、每握手+16、末16点完整drain、6拍record背压、唯一end PASS | reports/local/tb_stream_unpacker.run.log、tb_student_transport.run.log |
| A：真实0.01s | 40920字节、10230握手、163680样本逐点核对原IF2、唯一end PASS | tb_student_file_smoke.run.log、transport_structure.log |
| C1：原前端 | 90000事件/4窗、reload/reset PASS | tb_tracking_frontend.run.log |
| B：捕获模块 | 4个静态合成用例/31格点、±1kHz/码偏/错误PRN/时间戳/背压 PASS；float误差最大0.1803% | tb_acquisition_serial.run.log、acquisition_float_score.log、acquisition_cells.csv |
| C2/C3：静态闭环 | 两例各1s、±0.25chip/±0.04turn/±5Hz与ICD NH20 PASS；码RMS0.062345/0.063487chip，相位RMS0.002678/0.002674turn，频率RMS0.847095/0.847133Hz，尾锁定1.0；最终CSV1998窗 | tb_tracking_minimal.run.log、tracking_loop.csv、tracking_metrics.json、3张SVG/PNG |
| D：NH/位/D1模块 | 合成Prompt3相位0/7/19与正反极性、9字BCH/去交织/时间戳 PASS；当前实际RTL999个Prompt恢复phase1/29恒定位 PASS；教师decode_word独立核对9字 PASS | tb_nh_d1.run.log、nh_d1_words.csv、tb_nh_actual_prompt.run.log、nh_d1_software_diagnostic.log |
| 教师顶层/全功能 | 当前全部学生RTL可在官方脚本编译、0.01s TB PASS；完整self_check **FAIL退出1**，Route A INCOMPLETE；顶层仍只输出end，不是可提交定位结果 | official_runner_current.log、official_functional_current.log |

交付文档：docs/ACQUISITION_REPORT.md（10/16）、docs/TRACKING_REPORT.md（10/18）、docs/NH_D1_REPORT.md（10/25）。均为可编辑Markdown，有实际日志/曲线与未覆盖范围，未生成Word/PDF或外部提交。

环境：个人Windows + WSL2 Ubuntu26.04，Verilator5.032、g++15.2.0、make4.4.1、Python3.14.4。绘图依赖仅安装在work/plotdeps，bundled Windows Python执行诊断/制图。VMware/SSH/VCS/DC/ICC/PT未运行或修复。

基线：root六个9.28 RTL/LUT与本轮初始哈希不变，五个关键文件匹配9.28历史manifest；学生目录六份原样副本。新spaced frontend只透传间隔参数；新闭环2.5sample间隔是针对实跑失败的定向修正。保留10.13 Skills/环境/旧日志；15个教师公共文件哈希均不变。当前plan.md本轮未修改，其现有SHA256为0B471B4DDE961E6ADC6309A54126E5148F3C74390FF48D0597F21324CD3F6A28，与旧GOAL的历史记载不同，不强行回滚文本；当前唯一设计基线仍为9.28 RTL。

已保留失败：A4参数丢失；C2瞬时锁定过敏；负向码0.125chip失败；多层defparam编译不支持；官方runner执行标记/null package源问题。最终按原门限重跑，通过范围如上。

未覆盖：全捕获2046chip/±10k实跑、40dB-Hz多星、动态/噪声/FLL/失锁、捕获移交、完整实收D1帧/星历/观测/定位、100s场景。RECORD_FORMAT与decoder的tracking schema差异留在docs/TBD.md，当前end记录不受影响。不得把合成Prompt的9字作为教师场景记录。

下一条可执行任务：10/25实验演示复现，根目录运行 .\scripts\run_local_verilator.ps1 -Task nhd1；这是已有模块的复现入口。当前最低交付完成后停止优化与全系统扩展。
