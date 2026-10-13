# CURRENT STATUS

更新时间：2026-10-13 22:52（Asia/Singapore）。状态：E0_COMPLETE / E1_COMPLETE；E2实收单星字已核对，最终四星边界时间版本验证中；E3_100S_RUNNING；E4未完成。长期目标未完成。

当前main最近已推送eb0ca7e；E1/E2/E3后续实现待阶段提交。教师公共文件未编辑；scenario.if2仍409200000字节且Git忽略，无VMware/SSH/EDA后端访问。

已实际通过：E0三例合成捕获→移交→跟踪、decoder浮点评分、短/整窗/尾字与backpressure；最新边界framer版 -Task e0退出0，最大码误差0.07617chip、尾频差<0.009Hz。NH/D1旧9字、两例导航封装/双帧确认/时间锚/失锁清除、旧两例1s跟踪均最新源码回归0，reports/e_stage/final_modules。

E1：真实1s/2s重复自主检出PRN8，尾锁均1，FLL只从Prompt，软件答案不进DUT。FFT 12288输出位精确，PCPS全32PRN/4096首格与32候选integer golden PASS。原PLL0锁定FAIL、初版FFT精度、CORDIC保留字编译及WSL并发故障证据保留。

E2：首版真实20s单星生成10条有效type2，SFID3/SOW261012及全部raw/information/word_number与教师prompt_d1逐条一致。后续补充了bit元数据关联并将type1从首时刻修正为本地码周期结束边界，匹配教师自动软件导航的时间约定；最新真实长场景正在验证，不能将旧20s日志混作最终源PASS。

E3：默认四槽，RTL顺序搜索自主分配8/11/13/21（不预设身份）。真实2s原player/writer回归每星1995 Prompt，尾锁1.0，4路逐样本接受事件和公共ref一致，4条epoch1观测均measurement_valid=0，未编造导航。g++ -O3 1s333s；C++纯握手驱动1s228s，与原player/writer3984记录除cycle计数外逐bit一致，背压1s实际PASS。CPU不算捕获/解调答案。

当前100s进程：scripts/run_fast_verilator.ps1 -DurationSeconds 100 -EvidenceDirectory reports/e_stage/e3_100s；shell session 36414。截至本状态处理约9s。日志reports/e_stage/e3_100s/run.log，源/ROM/driver hashes sources.json；最终BIN在student_release/student_release/output/receiver_records.bin，完成前为部分数据。正常段约18.2s墙钟/1s信号，预计总约34分钟（估算，不是完成时间）。禁止在该进程运行时另一个真实输入任务覆盖其output BIN。

唯一下一可执行任务：读取100s run.log进度，完成后先原始check_records/self_check，再model/receiver_multi_score.py --require-navigation与原始route_a_position.py，分别记录退出码；原始self_check尚未PASS。
