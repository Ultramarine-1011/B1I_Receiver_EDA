# G性能采集与因果评价设计

来源：本地指导书V1.7 §7.3–7.9（印刷pp64–69）、教师README/input_contract/RECORD_FORMAT。G完整授权见[归档](archive/G_AUTHORIZATION_2026-10-14.md)，当前状态只见[STATUS](../STATUS.md)。实际结果见reports/g_stage；框架自测不构成接收性能PASS。

## 数据与时间

`g_receiver_probe`仅以观测端口读取原receiver_multichannel状态、PCPS候选、精修、分配、公共样本消费；不写DUT，不改教师top/interface或公共文件。`g_receiver.cpp`只读IF、驱动公开32bit/16样本握手、写实际256bit小端BIN及逐握手sidecar。完整默认搜索与默认4保持F参数；narrow只用于标明范围的定向诊断。

BIN是唯一功能数据源。sidecar保留sequence、hardware_cycle及available_sample（握手当拍已接纳样本量，最多含16样本缓冲），身份/代次/有效性与源参考时刻按原始记录解码。type5公开格式没有generation，不能凭空补造；NAV/OBS/Prompt使用各自已发布代次字段。tracking源时刻指向NCO投影的最近码边界，可比接纳样本计数超前1点；这是已知状态的数值投影，因果性必须按输出握手核查，不能误当未来输入。

事件流分别记录共享捕获请求接纳、每PRN CODE_INIT计算起点、粗候选、精修请求、复核可用、分配与释放。候选在共享请求时进入逻辑搜索队列；CODE_INIT为该PRN计算接纳点，队列部分包含共享4ms窗及前序候选/精修等待。首次输出用实际type5握手绑定复核事件。全局type5 acquisition_cycles不作为各PRN开始/结束时间。排队、PCPS、精修/复核和输出等待分别报；共享窗等待不重复计入信号时间。

信号秒=已接纳新样本/Fs；硬件周期是实际eval时钟沿；假定clk处理秒=周期/假定clk；主机墙钟独立测量。Fs=16.368MHz，IF=4.092MHz，标称码速2.046Mcps，clk没有课程配置。可暂停文件模型的available_sample不能证明固定速率RF实时系统；paced测试另按假定clk生产输入、有限FIFO占用/溢出，并单独列范围。

## 因果导航

`online_navigation.py`按BIN/sidecar实际序号消费，仅使用RTL type2/type4。调用未修改的教师decode_word、decode_subframe、build_ephemerides、transmit_sow、broadcast_state、solve_position；不调用recover_navigation，不从Prompt重建NAV。

每个PRN/generation收集连续10字，独立BCH解码核对raw/information、头/字序/SOW/子帧。SF1/2/3须来自同一个30s帧（SOW−6×(sfid−1)模一周相同），健康/轨道参数通过教师校验后才标ephemeris_ready。记录全部30个原始NAV序号，SF3第10字握手才可发布完整星历。失锁清同代状态，新代次无法使用旧星历。

每条有效OBS到达时冻结当时完整同代星历和时间锚点，不缓存无星历OBS等待以后回填；至少4个不同PRN、同共同历元、所有测量有效标志成立才求解。保留used_obs、星历可用事件used_nav、全部原始字段/时间锚点used_raw_nav、最后依赖握手时间。逐历元最多一个解，之后的NAV不改早期结果。

软件有效性检查有限值、可解几何、迭代剩余更新<1mm及合理地心半径；1mm是求解数值收敛判据，不是位置真值误差门槛。无独立ECEF真值不报告P09精度。PDOP可以从当次已用卫星计算，不能替代正式场景的统一几何资格。

TTFF以连续3个有效1秒历元的第3个最后依赖握手available_sample为终点。缺解/间隔/代次/星历/未来依赖均拒绝。观察窗未确认时报告实际已观察时长下界，不补成180s。offline replay测量主机求解服务时间，但没有调度到持续硬件系统；最后RTL依赖时间和实际CPU完成时刻的边界必须明示。

## 定向诊断与缺口

G0登记正式公开开发输入、独立自生成B1I调制、合成Prompt、模块激励及历史诊断。所有真值只由生成器和离线评分器读取。量化前每星C/N0采用真实白噪声方差1、单边N0=2/Fs，实正弦幅值A满足A²Fs/4=10^(C/N0/10)；2bit门限−1/0/+1，码/载波先按连续物理轨迹生成再量化。

P01仅边界/代表性组合，P03少量独立种子/4ms观察链路均为PARTIAL；不运行16368×81×20=26516160组合笛卡尔积。全覆盖按单例实测成本估算，正式100+100/10s场景缺失不凑种子。成功必须独立核对PRN、lag及频偏，失败保留在分母。

D01–04分段常jerk，距离/速度/加速度连续；D03六循环30s累计60m，不能每圈清距离。短闭环只评价实际覆盖动态片段；单通道、任意BCH payload、合成Prompt均不能作为12颗有效D1星的完整P07。

RF中断向PRN6的模拟贡献置零2s，继续产生每个真实IF样本，PRN7持续；输入valid不暂停。导航payload为独立生成的BCH测试字，未提供可定位星历/几何。分别记录真实失锁、重搜/精修、重捕、NH/帧/时间/NAV/OBS及健康通道。BCH通过率不替代与发射information逐字一致的比例。

`g_bank_service`以1/4/12全部active数字槽测样本服务和串行记录仲裁，包含16→1拆包；没有12星IF/NAV负载资格。公开实际4通道的NAV排空周期、冷搜索/精修停顿另由wrapper状态计数测量。缓冲需求、最低平均clk和最大等待是实测/算术预算，宏/目标clk/物理时序仍缺，存储架构/PPA留H。
