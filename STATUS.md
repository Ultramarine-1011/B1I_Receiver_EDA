# CURRENT STATUS

更新时间：2026-10-13 20:41（Asia/Singapore）。状态：E0_COMPLETE；E1_IN_PROGRESS；E2–E4 NOT_RUN。长期目标未完成。

本轮起点main/origin/main=3d09daf，A–D原目标/日志保留，当前验收见GOAL。E0合成单星捕获→移交→跟踪/真实type5/type1/schema3/end已实际PASS：3例各4092000样本，lag0/+16/−8、0/+1k/−1kHz，248–249窗，locked55–56。decoder独立评分最大码误差0.07609chip、尾频差<0.009Hz。短48、恰好16368、尾16384样本/reset/backpressure/end PASS。

E0最终命令：scripts/run_local_verilator.ps1 -Task e0，退出0；日志reports/e_stage/tb_receiver_e0.*、tb_receiver_tail.*、e0_score.log；BIN/JSONL/metrics在reports/local/e0_*。受影响桥接、旧捕获31格点、两例1秒跟踪回归均本轮退出0，reports/e_stage对应日志。原reports/local历史文件已恢复，后续runner默认reports/e_stage保存本轮证据。

本轮并发WSL调用曾挂起、/bin/true返回E_UNEXPECTED，结束本轮client并定向terminate Ubuntu后恢复；现串行执行WSL，不改配置。没有访问VMware/SSH/后端。教师公共文件待阶段hash审计（未编辑）；真实IF未提交。

E1性能：串行31格点0.194s推估全32PRN约8小时，不能盲跑。独立软件4ms FFT诊断0.406s，对全PRN6–37/±10kHz候选有收益，结果reports/e_stage/pcps_float_diagnostic.json仅设计诊断，不供DUT。准备位精确FFT/PCPS RTL，候选由RTL自主搜索，精修消除补零周期误差。

唯一下一可执行任务：实现/运行4096点位精确FFT与PCPS自检，随后接真实IF全PRN候选与单星拉入。
