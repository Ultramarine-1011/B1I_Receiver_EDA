# 北斗 B1I 基带信号处理器总体技术方案与接口设计

本方案按《集成电路 EDA 实验指导书 V1.7》第二章、第三至第七章和附录 1 编写，码发生器的多项式和抽头按 B1I ICD。输入、总体结构和模块划分里的数值只取这两处已有的；指导书没有给出的位宽留空。码 NCO 和相关器已经有 RTL，端口和定点格式按现有代码记录。

报告排版：标题四号宋体，正文小四号宋体，行距固定 22 磅，首行缩进。表头五号、加粗。图题放在图下，五号、加粗。

整机仍按完整接收机描述，包含输入、控制、卫星管理、捕获、12 个跟踪通道、电文解调、测量和输出。当前只做其中一路的码跟踪和载波跟踪。载波混频、DLL、FLL/PLL 还没有 RTL。

## 0. 现有进展

2026 年 9 月 28 日核对过代码。

PRN 6–37 的发生器已有独立 RTL 和软件对照，VCS 日志为 `B1I_PRN_REGRESSION_PASS`。

码 NCO 和 E/P/L 相关器已有模型和 RTL。2026 年 9 月 21 日的日志为 `CODE_NCO_EPL_REGRESSION_PASS`，events=36451，windows=4。此后 `code_nco` 改了复位、init 与样点处在同一拍时的接纳规则，测试增加了 `run_reload_collision_test`。旧日志中没有 `RELOAD_COLLISION_PASS`，不能为这次改动作证。

载波 NCO、混频、DLL、FLL/PLL 和锁定标志都还没有代码，单通道闭环也未连接。PRN 或相关器单独通过，不能说明环路已经跟上。

SRAM 读口、捕获、两级管理、12 通道集成、电文解调、测量输出和后端留待后续。正式 SRAM 配置和系统 `clk` 目前没有。功能模型可以按每个 `sample_valid` 推进；吞吐和时序要等这两项有资料后再验。

## 1. 总体架构与模块划分

指导书中的整机为输入缓存、并行捕获、12 个跟踪通道、电文解调、测量输出，另加两级管理。捕获与已分配通道的跟踪可以并行。每颗卫星的码相位、载波环、电文状态和测量存在各自的通道里。图 1 为该结构。已有代码的范围见第 0 节。

```text
控制与事务：
Global Controller ── run/drain/control ──► 各受控模块
Satellite Manager ── search_req ────────► Acquisition
Satellite Manager ◄─ search_result ────── Acquisition
Satellite Manager ── channel_init ──────► Tracking Channel × 12
Satellite Manager ◄─ channel_status ───── Tracking Channel × 12

样本与结果：
SRAM ──► Input / Timebase / Buffer ── sample_stream ──► Tracking Core × 12
                    │                                      │
                    └── historical window ──► Acquisition  ├── Prompt ──► Sync & D1 Decoder × 12
                                                           │                  │ time/nav
                                                           ▼                  ▼
                                                 Channel Measurement × 12
                                                           │ obs/nav/status
                                                           ▼
                                                    Epoch & Output
                                                           │
                                                    RINEX adapter
                                                           │
                                                        OBS / NAV
```

**图 1  北斗 B1I 基带信号处理器总体架构**

捕获结果交给卫星管理，再由管理模块写入跟踪通道。捕获模块不修改跟踪通道的寄存器。

### 1.1 顶层模块

顶层分成 7 块。整机的跟踪通道为 12 个，结构相同；目前只验证 1 个，没有 12 通道顶层。更换捕获算法，或更换 DLL、PLL 的实现时，顶层信号的含义保持不变。捕获引擎可做成 P 个并行，也可分时共用。各通道的码相位、环路历史、电文状态和测量仍分开存放。

| 模块 | 个数 | 职责 | 不包含 |
| --- | ---: | --- | --- |
| `input_timebase` | 1 | 读 SRAM，拆 2 bit 样点，产生 `sample_valid` 与 `sample_count`，缓存捕获窗口 | 卫星与通道状态 |
| `global_ctrl` | 1 | reset、config、run、drain、end，整机故障与运行状态 | 选择 PRN，修改通道内的环路 |
| `sat_manager` | 1 | 候选 PRN、搜索队列、捕获调度、通道分配、重试、替换、`generation` | 相关运算 |
| `acquisition` | 1 个逻辑模块，内含 P 个搜索引擎 | 按 PRN、窗口、码相位范围和频率范围捕获，给出码相位与频偏初值 | 长期保存跟踪状态 |
| `tracking_channel` | 12 | 单星相关、DLL、FLL/PLL、锁定标志和连续状态 | 自行选择卫星 |
| `sync_decode` | 每通道 1 | NH、数据位、帧同步、D1 解码、广播参数和导航时间 | 用模拟器真值填接收结果 |
| `measurement/output` | 通道内测量，加全局汇集 | 把连续码状态换成同一历元上的观测，汇集 OBS/NAV | 在 RTL 中生成 RINEX 文本 |

### 1.2 `input_timebase`

`input_timebase` 读 SRAM，并产生各模块共用的接收时间。

```text
sram_addr
sram_rd_en
sram_rdata
sram_rvalid
```

`sram_addr`、`sram_rd_en` 由本模块发往 SRAM。`sram_rdata`、`sram_rvalid` 由 SRAM 返回。

地址宽度、数据宽度和读延迟等配套 SRAM 说明。指导书未给出，此处留空。样点为 2 bit，`00` 对应 −3，`01` 对应 −1，`10` 对应 +1，`11` 对应 +3。模块内部至少用 3 bit 有符号数存放。

V1.7 给出的输入为 `Fs = 16.368 MHz`，`IF = 4.092 MHz`，B1I 码速率 `Rc = 2.046 Mcps`，主码 2046 chip。按该速率，1 chip 有 8 个样点，1 个主码周期有 16368 个样点。`Fs` 是采样率，与芯片逻辑时钟 `clk` 分开。旧资料中的 16.384 MHz 和 4.096 MHz 与本指导书不符，本方案不采用。

若 1 字节内存放 4 个样点，时间上最早的位于 `[7:6]`，其后为 `[5:4]`、`[3:2]`、`[1:0]`。这只约定字节内的次序，不能推出 SRAM 数据宽度为 8 bit。

向后级给出：

```text
sample_data        重构后的有符号样点
sample_valid       本拍收下 1 个新样点
sample_count       已收样点的序号，即公共本地时间
input_eof          有效样点结束
input_error        SRAM 或输入出错

window_ref         捕获窗口的参考样点
window_data/...    捕获模块读取历史窗口
```

`sample_count` 每收下 1 个新样点加 1。捕获对同一段历史窗口反复读取时，重复读取不增加 `sample_count`。样点序号因此与公共时间对应。

## 2. 两级管理

### 2.1 `global_ctrl`

`global_ctrl` 保存整机运行状态：

```text
global_state
run_enable
drain_request
end_reason
global_error
```

```text
RESET
  ↓
CONFIG_CHECK
  ↓
RUN
  ↓
DRAIN
  ↓
DONE / ERROR
```

复位后检查配置。配置通过则进入 `RUN`。输入结束后进入 `DRAIN`，等已经收下的事务处理完，再进入 `DONE`。SRAM 故障等整机错误进入 `ERROR`，原因写入 `end_reason`。某颗卫星失锁只记在该通道上，不与输入结束、SRAM 故障使用同一种结束原因。

### 2.2 `sat_manager`

`sat_manager` 负责搜星和 12 个通道的分配，单独保存：

```text
candidate_prn[]
search_queue
channel_resource_state[12]
channel_prn[12]
generation[12]
retry_count[]
last_search_time[]
```

通道占用状态为 `IDLE`、`RESERVED`、`RUNNING`、`RECLAIM`。通道是否已分配，与观测量是否有效，使用不同标志。通道侧的有效标志为：

```text
tracking_valid
nh_sync_valid
bit_sync_valid
frame_sync_valid
time_valid
measurement_valid
```

管理模块依据这两组标志做分配、收回和重新捕获。

## 3. 捕获接口

捕获与外部之间为 `search_req` 和 `search_result`。内部用滑动相关或 FFT，两边信号的含义不变。

### 3.1 `search_req`

| 字段 | 含义 |
| --- | --- |
| `prn` | 待搜索的卫星号 |
| `task_id` | 本次搜索的编号 |
| `code_range` | 码相位搜索范围 |
| `doppler_min/max/step` | 频率搜索范围和步进 |
| `integration_cfg` | 相干积分与非相干积分 |
| `window_ref` | 被搜索窗口的本地参考样点 |
| `window_length` | 窗口长度 |
| `req_valid` | 请求有效 |
| `req_ready` | 捕获模块可以收下该请求 |

取消使用 `search_cancel` 和 `cancel_task_id`。

### 3.2 `search_result`

| 字段 | 含义 |
| --- | --- |
| `success` | 是否捕获到 |
| `prn` | 卫星号 |
| `task_id` | 对应的搜索编号 |
| `code_phase` | 码周期内的相位 |
| `doppler` | 捕获得到的频偏 |
| `ref_time/ref_sample` | 该估计对应的本地样点 |
| `peak_metric` | 峰值 |
| `noise_metric` | 噪声或背景 |
| `quality` | 质量 |
| `reason` | 失败、取消或异常的原因 |
| `result_valid` | 结果有效 |
| `result_ready` | 管理模块可以收下该结果 |

码相位和多普勒都附带 `ref_time` 或 `ref_sample`。捕获需要运算时间，结果返回管理模块时，估计所对应的样点已经过去，所以参考时刻要随结果一起交回。

## 4. 通道初始化

捕获完成后，用 `channel_init` 把初值交给跟踪通道。`acquisition` 不写通道内部寄存器。

```text
init_valid
init_ready

channel_id
generation
prn
code_phase_init
doppler_init
capture_ref_time
effective_time
quality
```

`capture_ref_time` 是估计对应的样点。`effective_time` 是通道改用这组初值的样点。后者更晚时，按样点差 ΔN 把码相位推到 `effective_time`，或使用等效的时间对齐。验证时确认对齐后的初值处于跟踪拉入范围以内。

这组握手还没有 RTL。`code_nco` 上的 `init_valid` 只是装载初相的脉冲，没有 `init_ready`，也没有通道号和捕获参考时刻。装入任意码相位时，PRN 发生器的预置必须已经结束。预置期间的逻辑时钟不消耗样点。预置结束后进入相关的第一个样点，应与初相的参考位置为同一个样点。公共输入连续到来时，预置与参考时刻的安排在通道集成时再验证。

## 5. `tracking_channel`

12 个跟踪通道的结构相同。当前只做一个。完整的 `tracking_channel` 顶层还没有，下面按功能分开：

```text
tracking_channel
│
├── channel_ctrl
├── carrier_nco_and_mixer
├── code_nco_and_prn
├── epl_correlator
├── dll
└── fll_pll
```

样点逐个进入载波混频和码 NCO，相关器对每个样点做乘加。DLL 和 FLL/PLL 在积分窗结束后才更新。

```text
逐样点：
sample ──► Carrier NCO/Mixer ── I/Q ──► E/P/L correlator
           Code NCO + PRN ── E/P/L 码 ──► E/P/L correlator

积分窗之后：
E/P/L correlator ── E/L、窗口参考 ──► DLL ── code feedback ──► Code NCO
E/P/L correlator ── Prompt、窗口参考 ──► FLL/PLL ── carrier feedback ──► Carrier NCO
```

**图 2  单通道跟踪数据流**

相关窗按 16368 个被接纳的样点计数。环路更新间隔，以及多星共用的观测历元长度，目前没有数值。1 ms 和 1 s 只是口头举例，不作为各模块的更新周期。模块之间用样点序号或历元号对应。

### 5.1 载波 NCO 与混频

载波 NCO 和混频还没有代码。控制字格式、相位表示、I/Q 符号和位宽等全精度模型做完再填，指导书未给出这些数。

输入为 `sample_data`、`sample_valid`、`carrier_ctrl_word`、`init_doppler`、`init_valid`。输出为 `i_sample`、`q_sample`、`iq_valid`。

本地载波相位仅在 `sample_valid` 表示新样点被收下时推进。捕获提供的是多普勒初值。初始化只装多普勒，载波相位在通道内部累加，外部不送入绝对相位。

写 RTL 时要确定：中频与多普勒如何组合、符号如何取、量化成多少位，以及新控制字从哪个样点生效。混频若插入流水线，同一逻辑时钟上的 I/Q、码、valid 和样点号可能属于不同样点。连线时按数据延迟的拍数对齐。

### 5.2 码 NCO 与 B1I PRN

码发生器 `b1i_prn_gen` 和 `code_nco` 已经实现。发生器通过 `load`、`prn_select`、`chip_enable` 按 chip 输出 PRN 6–37。G1、G2 的多项式和抽头取自 B1I ICD，模块内不存放 2046 长的码表。计满 2046 chip 回到初相。发生器本身不含 NCO。

`code_nco` 除 `clk`、`rst_n` 外的端口：

| 方向 | 端口 | 含义 |
| --- | --- | --- |
| 输入 | `init_valid`、`init_prn[5:0]` | 装载脉冲，PRN 取 6–37 |
| 输入 | `init_code_phase_q`、`init_code_period_count` | 码周期内的初相，以及单独给出的整周期计数 |
| 输入 | `sample_valid`、`code_step_q` | 样点有效，以及每个被接纳样点的 chip 增量 |
| 输出 | `code_valid`、`init_done` | 码状态可用；预置完成脉冲 |
| 输出 | `sample_accepted` | `rst_n && !init_valid && sample_valid && code_valid`。复位和 init 期间不收样点 |
| 输出 | `early_code`、`prompt_code`、`late_code` | 当前样点的三路码 |
| 输出 | `code_phase_q`、`code_period_count`、`code_epoch` | Prompt 相位、周期计数、绕回脉冲 |

`PHASE_FRAC = 32`。相位为无符号 Q11.32 chip，共 43 bit。步长为无符号 Q1.32，单位是 chip/每个被接纳的样点，共 33 bit。标称 `Rc/Fs = 0.125`，`code_step_q = 0x20000000`。运行中 `0 < code_step_q < 1` chip/样点。码速率微调在这个正步长上加减，NCO 不反向计数。相位对 2046 chip 取模，初相使用同一格式。装载时，整周期计数采用端口给出的值；初相折进 0 到 2046 时，周期计数不因此加 1。周期计数默认 32 bit，参数可改。它统计的是码周期，与电文中的卫星时间分开。

`CODE_LENGTH` 目前必须为 2046，与 PRN 子模块的固定长度一致。回归配置为小数 32 bit、单边间隔 1/4 chip、周期计数 32 bit。更换参数需要另做回归。步长是否合法由外部保证，模块内不限幅，也没有错误标志。PRN 号非法时 `code_valid` 保持 0，不会出现 `init_done`。封装若一直等待该脉冲，配置错误时会停住。

E、P、L 的相位为 `(q+delta) mod 2046`、`q`、`(q-delta) mod 2046`，用整数部分取码片。`delta` 是相对 Prompt 的单边间隔。这一版用 0.25 chip，E 与 L 相距 0.5 chip。该间隔来自模型对几种间隔的比较，指导书没有指定 0.25，参数仍可改。

每个被接纳的样点按这个次序处理，与指导书第 4.5 节一致：用当前 `q[n]` 取本地码，做完该样点的相关，再更新码 NCO；相位绕过 2046 时 `code_period_count` 加 1。

正常运行的空拍保持相位、码和周期计数。`code_epoch` 与 `init_done` 只维持 1 个逻辑时钟。复位、装载和预置不按空拍处理。

E/P/L 用三个串行的 PRN 发生器预置。装载后 `code_valid = 0`，最坏情况要等 2046 个逻辑时钟才能接收样点。这段时间只推进码发生器，不消耗样点。复位优先于 init，init 优先于预置和逐样点推进。运行中再次装载时，同一拍的样点取消，预置再做一遍。

测试 `run_reload_collision_test` 覆盖运行中 init 与样点同拍、预置期间 `sample_valid` 保持为 1，以及异步复位时不接纳样点。已有日志中没有 `RELOAD_COLLISION_PASS`。测试已经写好，结果还没有。通道取消、预置结束后第一个样点与参考时刻对齐、`channel_init` 的 ready/valid，都还没有做。

## 6. E/P/L 相关器

`epl_correlator` 已有 RTL。除 `clk`、`rst_n` 外，输入为：

```text
i_sample
q_sample
sample_valid
sample_ref
init_valid

early_code
prompt_code
late_code
```

输出为：

```text
ie qe
ip qp
il ql

window_done
window_ref
```

IE、QE、IP、QP、IL、QL 就是上述小写端口。整机的相关结果还要带 `channel_id`、`generation`、`prn`，独立模块里目前没有。`sample_ref` 默认 64 bit，可以改参数。`window_ref` 记本窗第一个被接纳的样点。计算结束的时刻另外计。

```text
E = IE + j QE
P = IP + j QP
L = IL + j QL
```

同一窗内的 E、P、L 使用同一批样点、同一个通道、同一段起止和同一个参考时刻。窗的最后一个样点计入本窗，下一个样点计入下一窗。

`WINDOW_SAMPLES = 16368`，只计被接纳的样点。样点均匀连续时，这段计数为 1 ms。仿真中的空拍多少，不改变这 1 ms。`code_epoch` 不负责截断窗口。码速率微调后，16368 个样点的窗口与本地码绕回会错开。测试把 NCO 的 `sample_accepted` 接到相关器的 `sample_valid`。空拍表示该拍没有新样点。若信号时间上缺少样点，缺样之后如何推进另定。空拍不表示样点丢失。

相关之前做符号扩展。码值 0 乘 +1，码值 1 乘 −1。W bit 有符号数、N 个样点时，乘积绝对值的上限为 `2^(W-1)`，和的最坏绝对值为 `N·2^(W-1)`，不溢出的有符号宽度为 `W + ceil(log2(N+1))`。N = 16368 时，`ACC_WIDTH = IQ_WIDTH + 14 + ACC_GUARD_BITS`，保护位默认 0。`IQ_WIDTH = 3` 的测试中，累加器为 17 bit，极值 `±65472`。混频器输出位宽未定，这组测试宽度只属于该测试。相关器保留完整的和，内部不舍入，也不饱和。

`window_done` 只维持 1 拍。六路和与 `window_ref` 保持到下一窗完成，或直到复位、init。结果侧没有 `ready`。环路来不及读取时，在通道封装里把结果寄存下来。后级忙时，本模块不停止计数。复位或 init 清除未完成的窗，半个窗不向外送出。

## 7. DLL

DLL 没有 RTL。鉴别器、滤波器、更新周期、位宽和锁定门限还没有数值，等全精度模型和定点对比。已有的归一化 E−L 功率曲线只用于比较 early-late 间隔，增益未定。

输入：

```text
E complex
L complex
window_done
window_ref
code_state

carrier_aid        可选
carrier_aid_valid
```

输出：

```text
code_error
code_error_valid

code_rate_correction
code_quality
code_lock
code_loss_event
```

测量还需要连续的 `code_phase` 和 `code_period_count`。

`code_rate_correction` 送回码 NCO。它是码速率修正量，符号、单位以及换算到 `code_step_q` 的方法要单独写出。换算成步长增量后，加到标称步长上。该端口的数值不等于 NCO 控制字。环路延迟、所用积分窗，以及修正生效的样点，模型和 RTL 使用同一套记录。

## 8. FLL / PLL

FLL/PLL 没有 RTL。鉴别器、阶数、带宽、更新周期、模式切换、定点格式和锁定门限都还空着。

输入为 Prompt I/Q、`window_done`、`window_ref`，以及 `prn`、`channel_id`、`generation`、`capture_doppler_init`、`init_effective_time`。输出为 `carrier_nco_ctrl`、`doppler_est`、`carrier_phase_diag`、`carrier_error`、`carrier_error_valid`、`carrier_lock`、`carrier_quality`、`carrier_loss_reason`。

`carrier_nco_ctrl` 送回载波 NCO。Prompt 的 I/Q 同时送给 NH 处理和位同步，软值保留。环路内部若得到 0/1 判决，该判决不提供给电文模块。

每次载波环更新都带 Prompt 的 `window_ref`。实现时写明频率误差和相位误差的单位、I/Q 符号、中频与多普勒的关系、反馈生效的样点，以及环路切换时相位是否连续。激励可以带上 NH 和数据符号的影响。被测环路的输入不接入符号起止的真值，也不接入载波相位真值。

## 9. 电文解调

电文解调、测量和 OBS/NAV 属于后续整机。当前的单通道跟踪不做这三部分。

每个通道自己保存电文状态，顺序为 NH 搜索、NH 对齐、位同步、帧同步、BCH 与去交织及解码，然后得到导航时间和广播参数。

输入为 `prompt_i`、`prompt_q`、`window_done`、`window_ref`、`code_phase`、`code_period_count`、`carrier_status`，以及 `prn`、`channel_id`、`generation`。接收机输入端不提供 NH 起点、数据位起止和发射时刻，这三项由电文处理恢复。

状态输出：

```text
nh_sync_valid
bit_sync_valid
frame_sync_valid
sync_quality
sync_loss_event
```

数据输出：

```text
data_bit
data_bit_valid
bit_time

d1_word/frame_data
decode_valid
decode_status
```

时间和星历输出：

```text
nav_time
nav_time_valid

nav_param
nav_param_valid

first_available_time
```

这些记录都带 `prn`、`channel_id`、`generation`、`source_time`。`first_available_time` 是该导航参数第一次能够从接收数据中确定的样点。计算 TTFF 时用这个时刻，避免把尚未解出的星历算成已经可用。

## 10. 通道测量

`channel_measurement` 在共同接收历元上，用码相位、整码周期和导航时间恢复发射时刻，形成观测量。

输入为 `code_phase`、`code_period_count`、`nav_time`、`nav_time_valid`、`doppler_est`、`tracking_status`、`common_epoch_request`。

伪距由精细码相位、整码周期和电文时间锚点计算。捕获给出的粗码相位只用于初始化。

每颗卫星输出 `measurement_record`，其中有 `prn`、`channel_id`、`generation`、`epoch_time` 或 `epoch_sample`、`code_phase`、`code_period_count`、`pseudorange` 及有效位、`doppler` 及有效位、`measurement_quality`。

课程要求中的 C2I 伪距必须输出。其他观测量在对应功能完成并验证之后再输出。尚未得到的数据保持无效。

## 11. 历元输出

`epoch_output` 按共同接收历元汇集 12 个通道。各通道可以在不同逻辑拍计算完成。`common_epoch` 相同的记录归入同一次观测。

输入为 `measurement_record[0:11]`、`nav_record[0:11]`、`channel_status[0:11]`。输出为 `obs_record`（带 `obs_valid`、`obs_ready`）和 `nav_record`（带 `nav_valid`、`nav_ready`）。

OBS 中有 `common_epoch`、PRN、C2I、`measurement_valid`、通道身份和 `availability_time`。NAV 中有 PRN、广播星历、钟差、时间等参数，以及 `parameter_valid` 和 `availability_time`。

RINEX 3.05 文本由 RTL 外的适配器生成。RTL 输出结构化的观测和星历。

## 12. 通道状态

载波、码、电文和测量各自有标志。单独一个 `locked` 不能概括这四项。本阶段只做 `carrier_lock`、`code_lock`、`tracking_valid`，以及质量和失锁事件。已有的 PRN、NCO 和相关器不产生这些标志。

```text
channel_id
generation
prn

resource_state

carrier_lock
code_lock
tracking_valid

nh_sync_valid
bit_sync_valid
frame_sync_valid

time_valid
measurement_valid

quality
loss_reason
event_time
status_valid
```

帧同步丢失而跟踪仍然有效时，清除依赖帧同步的有效标志，并重新做帧同步。码或载波失锁时，清除 `measurement_valid`，然后做短时重捕。连续重捕失败，则整星重搜，或释放通道。电文校验错误一次，只影响对应的电文状态，载波锁定保持原值。

`resource_state` 只有 `sat_manager` 可以写。汇总里可以读取，跟踪通道不能写。短时重捕、整星重搜和释放通道由管理模块发起。跟踪通道上报状态和事件。

## 13. 恢复与取消

恢复使用单独的一组信号，不放进 `channel_status`。

```text
recover_req
recover_valid
recover_ready

task_id
channel_id
generation
prn

last_code_phase
last_doppler
last_ref_time

retry_count
recover_reason
```

取消为 `cancel_valid`、`task_id`、`channel_id`、`generation`、`cancel_reason`。

短时遮挡后，用最近的码相位、多普勒和参考时刻恢复。长时间锁不住，则重新搜索或释放通道。

## 14. `task_id` 与 `generation`

`task_id` 标记一次搜索或一次恢复，例如 PRN 12 的第 7 次捕获。`generation` 标记某一硬件通道当前分配给哪颗卫星，每次重新分配加 1。CH3 从 `generation = 5` 的 PRN 12 换成 `generation = 6` 的 PRN 23 之后，PRN 12 迟到的旧结果对不上 `generation`，应丢弃。

收下异步结果时核对 PRN、`task_id`、`generation` 和参考时刻。同一拍里若同时出现异步结果和复位、取消或有效位撤销，按取消或撤销处理。

## 15. ready/valid

事务接口为 `xxx_valid`、`xxx_ready`、`xxx_payload`。仅当 `valid && ready` 时传送一次。`valid = 1` 且 `ready = 0` 时，payload、通道号和时间标签保持不变。

使用该握手的接口为 `search_req`、`search_result`、`channel_init`、`recover_req`、`obs_record`、`nav_record`。

样点流为 `sample_valid` 和 `sample_data`。正在跟踪的通道使用同一套样点序号。未分配、正在预置或已经失效的通道，不能把公共的 `sample_count` 停住。通道从 `effective_time` 起用这组初值。

`code_nco` 的 `code_valid` 和 `sample_accepted` 只表示该模块本拍是否收下样点。公共输入不因此暂停。通道级封装还没有。

`init_valid`、`init_done`、`window_done` 是单拍脉冲，没有 ready。需要排队时，在封装中保存数据和通道号，再按接收方的 ready 送出。

## 16. 时间字段

| 字段 | 含义 |
| --- | --- |
| `clk` | 芯片逻辑时钟 |
| `sample_valid` | 本拍是否收下 1 个新样点 |
| `sample_count` | 公共本地接收时间 |
| `window_ref` | 相关器：本窗第一个被接纳样点。捕获：请求或结果所绑定的窗口位置 |
| `code_phase` / `code_phase_q` | 2046 chip 以内的相位。现有 RTL 为 Q11.32 chip。码速率为标称值时，1 个码周期为 1 ms |
| `code_period_count` | 初值加上其后 Prompt 相位绕回的次数。与按样点数截断的积分窗分开计数 |
| `nav_time` | 由 D1 电文得到的卫星时间 |
| `common_epoch` | 多星观测共用的接收历元 |

模块计算完成的时刻与信号到达的时刻使用不同字段。12 个通道可以在不同拍给出结果。`source_time` 或 `common_epoch` 相同，即为同一次接收。

PRN 预置所用的逻辑时钟、`window_done`、`code_epoch`、环路更新和公共历元分开计数。公共历元的长度和触发方式尚未规定。

## 17. 顶层接口

按指导书表 2-2，顶层为八组：

| 接口 | 方向 | 主要信号 |
| --- | --- | --- |
| `sram_if` | 输入模块与 SRAM | 请求 addr、read；返回 data、rvalid |
| `sample_stream` | 输入模块到跟踪和捕获 | sample、valid、本地时间 |
| `search_req` | 卫星管理到捕获 | PRN、task_id、搜索范围、积分配置、window_ref |
| `search_result` | 捕获到卫星管理 | success、PRN、task_id、码相位、doppler、参考时间、quality |
| `channel_init` | 管理到通道 | channel_id、generation、PRN、跟踪初值、effective time |
| `correlator_result` | 相关器到环路和电文 | E/P/L、window_done、window_ref、通道号 |
| `channel_status` | 通道到控制和管理 | 各项有效位、质量、失锁原因、事件时间 |
| `obs_nav` | 汇集到适配器 | common epoch、观测与参数、valid、通道身份、可用时间 |

恢复和取消不放入 `channel_status`，使用 `recover` 与 `cancel`。

## 18. 参数与验证

### 18.1 已经采用的数

| 参数 | 取值 | 来源 |
| --- | --- | --- |
| Fs / IF | 16.368 MHz / 4.092 MHz；2 bit 为 −3/−1/+1/+3 | V1.7 |
| B1I PRN | MEO/IGSO 的 PRN 6–37，主码 2046 chip | B1I ICD；发生器 VCS 为 `B1I_PRN_REGRESSION_PASS` |
| 码 NCO | 相位 Q11.32 chip，步长 Q1.32 chip/样点，标称 0.125 | 本次模型与回归所用 |
| E/P/L | 单边 0.25 chip，E 与 L 相距 0.5 chip | 模型比较了间隔；指导书未指定该值 |
| 相关窗 | 16368 个被接纳样点，末样点计入本窗，`window_ref` 取窗内第一个样点 | 现有模型、RTL 和逐事件自检 |
| 累加器 | `IQ_WIDTH + ceil(log2(WINDOW_SAMPLES+1))`，可加保护位；和完整保留 | 按最坏幅度计算，并用极值自检。混频 I/Q 位宽未定 |

上表中 Q11.32、0.25 chip 等来自本次实现。指导书没有把它们规定成唯一取值。若以后修改，模型和 RTL 一起改。

### 18.2 还没有数值的部分

载波 NCO 和混频的相位、控制字、I/Q 位宽、符号、量化及流水拍数尚未填写。DLL 与 FLL/PLL 的鉴别器、阶数、带宽、更新周期、系数、模式切换和锁定门限也未填写。

六路结果由谁读取、反馈从哪个样点生效、混频输出与码及样点号如何对齐、初始化、取消和通道号如何连接，都还没有 RTL。reset/init 的仲裁已经写进 `code_nco`，这次改动还没有新的回归日志。环路中间量的位宽、除零、舍入和饱和未定。验收所用的频偏、码偏、初相、噪声、动态、时长和误差门限，也还没有列成表。

这些数值在全精度模型对比之后再定为定点。SRAM 和时钟没有正式资料时，功能验证继续按被接纳的样点进行。

### 18.3 等外部资料的部分

SRAM 端口、样点文件的 metadata、目标 `clk`、总吞吐和课程验收配置，等正式文件到达后再写入。捕获算法与并行度、12 个通道的低速运算是否共用、公共历元的格式、电文、测量、输出和后端，属于后续工作。

### 18.4 已有回归

现有两条回归，`prn-regression` 和 `code-nco-epl-regression`，经 Windows、SSH 到 Linux 上运行 VCS。2026 年 9 月 21 日的日志为 `B1I_PRN_REGRESSION_PASS`，以及 `CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4`。后者不含其后增加的 reload collision。`code_nco` 的仲裁改动要用改完的源重新运行，并保留退出状态和完整日志。环境中的计数器测试只说明 VCS 和 DC 能完成一次最小运行，其中没有 GNSS 综合、吞吐和闭环跟踪。

NCO/EPL 回归用 Python 的位精确向量对照 RTL 事件，包括初相、空拍、PRN 与码片切换、码周期绕回、正负码速率微调、连续窗口和累加器极值。全精度模型与定点相位的差值用于挑选参数。DLL、FLL/PLL 还没有全精度、定点和 RTL 放在一起的锁定结果。

单通道的后续工作是全精度环路模型、参数对比、定点和自检，并写明动态、扰动、误差门限和锁定判据。测试所用真值只产生激励和评分。RTL 修改后，对应的 Linux VCS 重新运行。9 月 21 日的通过记录不能代替新代码。单通道验收满足后停止，12 通道和其余整机随后再做。
