# E阶段最小集成

E0复用已验证stream_unpacker、acquisition_serial和tracking_channel_minimal，固定教师顶层端口不变。SEARCH_*参数只是可配置搜索范围；合成TB用受限网格缩短验证，IF真值只在生成器与独立评分中使用。默认全网格尚未实跑。

## 样本和移交

每个32bit握手接收16个真实样本，processed_samples仅在单样本接纳时+1；捕获重放与PRN预置不推进输入时间。采满16368点后对输入反压，但解包器可预存下一字。串行搜索完成后用 `delta=processed_samples-result_ref`，`q0=((delta+(16368-lag)%16368)%16368)<<29`，周期计数为同一分子的商。参考载波零相位按`delta*(0x40000000+Doppler)`推进，低32bit自然回绕；捕获不提供真实绝对相位，Costas负责相位拉入。样本在PRN预置完成前保持，首跟踪样本编号不受搜索墙钟/逻辑周期影响。

## 记录

type5来自RTL捕获result，ref为捕获首样本，lag单位IF sample，Doppler单位2^32/Fs的FCW，功率保留原64bit单位，cycles为逻辑周期。

type1使用教师decoder schema3：bit23=1、bits31:30=3、generation=1。signed28bit Prompt算术右移4至24bit，负数向负无穷取整；解码后的Prompt单位为原Mixer相关和的1/16，不饱和。记录sample_index=window_ref，码相位/周期/载波为该相关窗口首样本计算前快照，通过Mixer同拍延迟和窗口开始锁存关联。Doppler为当前窗口控制字；上一窗反馈在后续接纳样本生效。此处定义的首样本时间语义已独立评分。教师prompt_d1的导航锚点推断含末样本约定，E2接入时须单独核对其时间偏移，不能直接把软件诊断锚点当RTL真时间。

两级输出槽覆盖Mixer/相关器流水，记录积压时暂停样本；valid且!ready保持全部256bit。EOF先处理最后lane，停止新样本，等待两级流水至少4拍及window事件、两槽全空，再输出唯一type6。少于捕获窗的完整输入只发end；恰好捕获窗仍等真正搜索完成与type5排空；未检出时完整消费尾输入但不伪造tracking。

## E0实证与E1性能决策

合成三例PRN6/12，lag0/+16/−8sample，频偏0/+1k/−1kHz，各250ms。输入空拍、内部计算停顿、长突发record反压、真实样本逐点核对、decoder回读和独立浮点评分。248–249个连续Prompt，每例55–56个锁定窗，唯一end=4092000。最大码误差0.07609chip，尾频差最大0.00858Hz，尾相位最大0.01094turn，首窗浮点Prompt相对误差最大0.00001451。最终命令/日志见WORKLOG及reports/e_stage；当前通过范围不能外推真实教师信号。

旧串行捕获4用例31格点，仿真实测0.194s/约664k逻辑周期。按同一吞吐估算全0.5chip×41频率每PRN约15分钟，32PRN约8小时；这是成本估计而非全网格实测。E1需要有收益的搜索改进。

独立软件PCPS设计诊断只读公开IF前4ms：Fs/4正交解调、4092点/毫秒、4096点零补FFT、4窗非相干，全PRN6–37/±10kHz/500Hz。运行0.406s，多个候选峰均比>8；结果见reports/e_stage/pcps_float_diagnostic.json，仅是算法诊断，不是RTL捕获。4096与4092的补零差异使码延迟候选需原始周期精搜。后续先位精确FFT/RTL评分，再由RTL全PRN搜索产生候选，禁止读取此JSON初始化DUT。
