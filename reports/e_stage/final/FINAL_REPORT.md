# E阶段最终功能验收（2026-10-13）

结论：E0–E4最低端到端交付完成。教师公开100秒真实IF已由RTL自主捕获/跟踪四星、恢复真实NH/D1导航时间、输出共同历元观测与唯一end；原始self_check退出0，原始Route A退出0并实际给出定位解。

## 实际结果

| 项目 | 结果与证据 |
|---|---|
| 完整输入 | 409200000字节IF2，1636800000样本；FAST_RTL_PASS，2038.942秒墙钟；e3_100s/run.log |
| 捕获/跟踪 | PRN8/11/13/21由RTL顺序搜索与精修实际检出；每星99995 Prompt，尾200窗锁定1.0；metrics.json |
| 导航 | 每星140条type2，全部560字的raw/information/word/SFID/SOW与原始prompt_d1独立解码一致；独立评分退出0 |
| 共同观测 | 每星99条1秒历元记录，19–99共81个有效历元；总396条，其中324条measurement_valid；唯一epoch/PRN且flags齐全 |
| 原始结构检查 | check_records.py退出0；check_records.log |
| 原始功能自检 | self_check.py退出0，PASS student self-check；self_check.log |
| 原始定位 | route_a_position.py退出0：64子帧、4星历、99个定位历元（1–99）；route_a.log、position.jsonl、ephemeris.json |
| 定位内部检查 | 所有解有限、ECEF在地球附近；纬度中位29.99985499°、经度110.00015265°、高119.536m；delivery_summary.json |
| 输出结构 | 400941条：acquisition4/tracking399980/navigation560/common_observation396/end1；最终样本数正确，underflow/overflow均0 |

交付文件：`student_release/student_release/output/receiver_records.bin`（本地生成，Git忽略）。大小12830112字节，SHA256 `c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501`。

输入文件SHA256：`2C47D1533FA54316952496FFB7905742C34A989B0A6276B867FE69566C5027DA`；本地IF未上传或进入Git。100s编译源/ROM/driver和当前源码逐项哈希一致，见e3_100s/sources.json、final_source_audit.json。教师公共文件及原9.28基础RTL保持哈希不变，见final_integrity.json。

## 复现

根目录PowerShell：

```powershell
.\scripts\run_fast_verilator.ps1 -DurationSeconds 100 -EvidenceDirectory reports/e_stage/reproduce100
.\scripts\validate_receiver_delivery.ps1
```

已有交付只需第二条重新验收。直接C++入口仅负责公开16样本握手、IF2位序和原样LE记录；捕获、环路、NH/BCH/D1、时间/观测与record仲裁全部在RTL。使用未改教师player/writer的短窗回归与直接时钟入口3984个记录非cycle字段逐bit相同；背压实跑稳定。最终type1用真实NCO推导的码周期结束边界与对应载波相位，使原始定位工具的软件导航时间恢复兼容，未用软件答案初始化DUT或改写BIN。

必要回归：E0三例合成/独立float与尾包，NH/D1三相位九字，导航封装双帧/极性/时间锚/背压/失锁清除，旧两例1秒闭环全部当前相关版本PASS；日志e0_boundary、final_modules。完整100秒源哈希对应最终实现。初版PLL不锁、FFT精度不足、浮点弱峰argmax、CORDIC保留字编译、WSL启动故障等失败仍保留，不以旧通过日志代替新验证。

## 证据边界

公开静态六星40dB-Hz场景中完成最低四星功能。未验证隐藏场景、低CNR、复杂动态、失锁重捕、12通道或ASIC后端。没有教师隐藏位置真值，因此不宣称水平/垂直/3D定位误差；四星方程残差很小不等于定位精度。Route A按原脚本自动优先采用Prompt恢复导航；RTL type2真实解码已另经独立全字核对。

源码实现阶段commit `fe9fbfb`已推送；最终验收报告/manifest由随后最终提交固化。STATUS为唯一当前状态，Goal完成后停止，不自动扩展下一milestone。
