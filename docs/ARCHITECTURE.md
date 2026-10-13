# GNSS 基带接收机架构基线

> 2026-10-13：以下为9.28历史系统架构，当前状态只见根目录STATUS.md。近期采用教师student_release顶层/输入/输出契约，纯仿真无需SRAM；不开展12通道/后端。旧RTL算法保持，新增接口桥接见STREAM_BRIDGE.md。

本文整理 `plan.md` 已确定的系统架构，并链接后续有模型与回归证据的实现 baseline，方便 Codex/Cursor 继续工作。系统职责、接口、时间语义与状态所有权以 `plan.md` 为准；其中早期保留的算法/定点 TBD 以本文链接的后续设计决策和 [TBD.md](TBD.md) 的 resolved 记录了解当前状态，不应反复撤回已经验证的选择。当前开发范围与执行状态见根目录 [GOAL.md](../GOAL.md)，不能把完整系统框图视为本 milestone 的全部实现范围。

2026-09-28 一致性审查后 `plan.md` 已定稿，实施状态是当时快照；后续进展在本文和模块文档更新。以下系统级职责与身份/事务接口仍包含后续目标。当前独立 `b1i_prn_gen`、`code_nco`、`epl_correlator` 以及新增 `carrier_nco_mixer` 已通过 VCS，DLL/FLL/PLL RTL 和完整单通道封装尚未实现。

## 1. 系统结构与职责

系统由一个公共输入/时基、两级管理、一个逻辑捕获模块、12 个独立跟踪通道以及输出汇聚组成。捕获与持续跟踪并行；计算资源可以共享，但每颗星/每通道的码相位、环路历史、同步和测量状态必须独立。

| 模块 | 数量 | 已冻结职责 | 不负责 |
|---|---:|---|---|
| `input_timebase` | 1 | SRAM 访问、2 bit 样本解包、`sample_valid`、`sample_count`、窗口缓存和参考位置 | 卫星判断、通道状态 |
| `global_ctrl` | 1 | reset/config/run/drain/end、系统异常仲裁和整机状态 | PRN 选择、直接修改通道环路 |
| `sat_manager` | 1 | 候选 PRN、搜索队列、捕获调度、通道分配/重试/替换、`generation` | 相关计算 |
| `acquisition` | 1 个逻辑模块 | 按请求搜索 PRN、码相位和频偏并返回带参考时刻的结果 | 长期卫星状态 |
| `tracking_channel` | 12 | 单星相关、DLL、FLL/PLL、锁定判断及所有持续状态 | 自主决定跟踪对象 |
| `sync_decode` | 每通道 1 个 | NH/bit/frame 同步、BCH/D1 解码、导航时间与参数恢复 | 接收模拟器真值 |
| `channel_measurement` + `epoch_output` | 通道内 + 全局 | 连续码状态形成共同历元观测，汇聚结构化 OBS/NAV 记录 | 在 RTL 中生成 RINEX 文本 |

共享状态只有一个写入者。`global_ctrl` 独占整机状态；`sat_manager` 独占搜索队列、12 个通道的资源归属、PRN 映射、`generation`、重试次数和搜索时间。

## 2. 核心接口

顶层冻结以下信息组；字段位宽和部分算法配置尚未冻结。

| 接口 | 方向 | 核心语义 |
|---|---|---|
| `sram_if` | `input_timebase` ↔ SRAM | 发出 `addr/rd_en`，接收 `rdata/rvalid` |
| `sample_stream` | 输入 → 捕获/跟踪 | 重构后的有符号样本、`sample_valid`、本地样本参考 |
| `search_req` | `sat_manager` → `acquisition` | PRN、`task_id`、搜索范围、积分配置、`window_ref`/长度 |
| `search_result` | `acquisition` → `sat_manager` | 成败、PRN、`task_id`、码相位、doppler、参考时刻、质量/原因 |
| `channel_init` | 管理 → 跟踪通道 | `channel_id`、`generation`、PRN、初值、捕获参考时刻和生效时刻 |
| `correlator_result` | 相关器 → 环路/同步 | IE/QE、IP/QP、IL/QL、窗口完成/参考和身份 |
| `channel_status` | 通道 → 控制/管理 | 资源以外的分层有效性、质量、丢锁原因、事件时间 |
| `obs_nav` | 测量/汇聚 → 配套软件 | 共同历元、观测/导航参数、有效性、身份、首次可用时间 |
| `recover` / `cancel` | 控制事务 | 任务、通道、代次、PRN、最后状态、原因和重试信息 |

### 捕获到跟踪初始化

捕获模块不得直接写跟踪寄存器。独立的 `channel_init` 事务至少携带：

```text
channel_id, generation, prn
code_phase_init, doppler_init
capture_ref_time, effective_time, quality
```

`capture_ref_time` 是捕获估计对应的信号位置，`effective_time` 是通道真正应用初值的位置。两者相差的样本数必须通过明确的相位推进/对齐处理，旧码相位不能原样写入。

### 单个跟踪通道

每个 `tracking_channel` 包含 `channel_ctrl`、Carrier NCO/mixer、Code NCO + B1I PRN、E/P/L 相关器、DLL 和 FLL/PLL。逐样本高速路径与积分窗口/环路更新低速路径在语义上分离。

Carrier NCO 每接纳一个有效样本推进一次相位；捕获只提供频偏初值，不提供绝对载波相位。Code NCO 对每个有效样本依次执行：用当前 `q[n]` 取码、完成相关、更新 NCO、回绕时增加 `code_period_count`。

E/P/L 在同一积分窗口必须使用相同输入样本、通道身份、起止边界和参考时刻；窗口末样本计入当前窗口，下一样本开启新窗口。Prompt I/Q 在供载波环使用的同时，必须保留未硬判决的软信息给 NH/位同步。

## 3. 时间语义

| 名称 | 含义 |
|---|---|
| `clk` | ASIC 数字逻辑时钟 |
| `sample_valid` | 本周期接纳一个新的输入样本 |
| `sample_count` | 公共本地接收样本位置，只随新有效样本推进 |
| `window_ref` | 捕获/相关窗口对应的参考样本位置 |
| `code_phase` / `code_phase_q` | 当前 2046 chip 主码周期内位置，标称码速下周期为 1 ms |
| `code_period_count` | 已跨过的 PRN 周期数 |
| `nav_time` | 从 D1 电文恢复的卫星时间 |
| `common_epoch` | 多星观测的共同接收历元 |

模块计算完成时刻不等于信号对应的接收时刻。12 路结果可在不同电路周期完成，但 `source_time/common_epoch` 相同就属于同一接收历元。捕获反复读取历史窗口不得推进 `sample_count`。

整机状态抽象为 `RESET → CONFIG_CHECK → RUN → DRAIN → DONE/ERROR`。输入结束后先排空已接纳处理；正常结束、SRAM 故障和卫星失锁保留不同原因。

### 已冻结的输入物理参数

当前 V1.7 指导书冻结输入为 2 bit 实中频：`Fs=16.368 MHz`、`IF=4.092 MHz`，量化映射为 `00→-3`、`01→-1`、`10→+1`、`11→+3`，内部重构至少使用 signed 3 bit。B1I 码率为 2.046 Mcps，标称每 chip 8 个样本、每 1 ms 码周期 16368 个样本。系统逻辑 `clk` 仍由尚未提供的发布配置决定，不能与 `Fs` 自动等同。

### B1I PRN 子模块边界

独立 `b1i_prn_gen` 只负责按 chip 顺序产生 MEO/IGSO PRN 6–37，不包含 Code NCO。依据 BDS-SIS-ICD-2.1 第 4.3 节：G1/G2 均为 11 级 LFSR，初相均为 `01010101010`；G1/G2 生成多项式和各 PRN 的 G2 两抽头按图 4-1、表 4-2 实现。每周期输出 2046 chip，回绕后恢复 ICD 初相。现有 `code_nco` 通过三个 PRN 实例分别生成 E/P/L，采用 `load/chip_enable` 控制；NCO 位宽不进入 PRN 子模块接口。

### Code NCO 与 E/P/L 第一版基线

Code NCO 使用 unsigned Q11.32 chip 相位和 unsigned Q1.32 chip/accepted-sample 步长；标称步长为 `Rc/Fs=0.125`。正常运行的空拍保持逐样本数据状态，reset/init 和 PRN 预置有独立更新条件；`init_done/code_epoch` 为事件脉冲。每个接纳样本先用当前相位产生并相关 Early/Prompt/Late，再推进相位；Prompt 跨越 2046 chip 时增加 `code_period_count`。

`delta` 是 E/P 或 P/L 的单边间隔，第一版为 0.25 chip，因此 E-L 总间隔为 0.5 chip。相关器第一版按固定 16368 个 accepted samples 形成六路完整和；末样本计入当前窗口，下一有效样本开始下一窗口，`window_ref` 指向窗口首样本。相关器使用参数 `IQ_WIDTH`；最小累加器位宽为 `IQ_WIDTH+14`。新增 Mixer baseline 为 14 bit I/Q，连接时应配 28 bit 累加器，原 3 bit/17 bit 仍是独立模块测试配置。数学、扫描和接口细节见 [CODE_NCO_EPL.md](CODE_NCO_EPL.md)。

现有相关器没有 `channel_id/generation/prn` 或结果 `ready`，以 `window_done` 脉冲发布保持的六路结果。身份绑定、结果接纳和反馈生效由后续通道封装明确。固定样本窗口独立于本地 `code_epoch`；初始化预置最长 2046 个逻辑时钟，完成后需按实际首样本参考对齐。当前 NCO 已使用 `rst_n && !init_valid && sample_valid && code_valid` 屏蔽 reset/init 同周期接纳；2026-09-28 新回归包含 `RELOAD_COLLISION_PASS`，已闭合模块级仲裁验证。

### Carrier NCO/Mixer 第一版基线

相位采用 unsigned 32 bit 周内相位，控制字表示总 IF+频偏，每接纳样本先混频后推进。最近地址量化为 10 bit，12 bit 对称整数本振幅值为 ±2047；使用四分之一正弦表，`I=x*cos(theta)`、`Q=-x*sin(theta)`。对 3 bit 输入保留 signed 14 bit 完整 I/Q，不缩小数、不饱和。I/Q/valid/ref 注册一拍，接入相关器时必须同拍延迟码值。全精度、定点扫描及 29775 事件 VCS 自检见 [CARRIER_NCO_MIXER.md](CARRIER_NCO_MIXER.md)。该模块 PASS 不代表环路闭环已完成。

## 4. ready/valid 规则

事务接口统一使用 `valid`、`ready` 和 payload：

- 仅 `valid && ready` 同周期为 1 时发生一次传输。
- `valid=1 && ready=0` 时，全部数据、身份和时间标签保持不变。
- reset、cancel 或有效性撤销与结果同周期出现时，取消/撤销优先。
- `search_req`、`search_result`、`channel_init`、`recover_req`、`obs_record`、`nav_record` 使用该规则。
- 公共逐样本流使用 `sample_valid/sample_data`，已启用通道按同一样本参考处理；不允许各通道分别对公共输入施加反压。局部 `code_valid/sample_accepted` 不等同于公共流 ready/valid；未启用或预置中通道不停止公共时基。

## 5. 12 通道、身份和有效性

12 个物理通道结构相同，资源状态至少为 `IDLE/RESERVED/RUNNING/RECLAIM`。资源是否占用与当前是否产生有效观测是两个维度。

`task_id` 标识一次异步任务；`generation` 标识物理通道的当前使用代次。异步结果接纳至少核对 PRN、`task_id`、`generation` 和参考时刻，以拒绝通道复用后迟到的旧结果。

通道状态分层表达：`carrier_lock`、`code_lock`、`tracking_valid`、`nh_sync_valid`、`bit_sync_valid`、`frame_sync_valid`、`time_valid`、`measurement_valid`，并携带质量、丢失原因、事件时间、PRN、通道号和代次。帧同步丢失不等同于跟踪失锁；真正跟踪失锁时立即撤销测量有效性，再进入快速重捕/完整搜索/释放流程。

## 6. 同步、测量与输出

每通道独立完成 `NH search → NH aligned → bit sync → frame sync → BCH/D1 decode → navigation time/parameters`。输入不得包含真实 NH 起点、真实数据位边界或真实发射时刻。所有恢复的数据绑定 PRN、通道号、代次和源时间；导航参数记录首次可用样本时刻。

测量模块把精细码相位、整码周期和电文时间锚点组合到共同接收历元；捕获码相位不能直接当作伪距。基础输出要求包含有效的 C2I 伪距，其他观测量只在实现并验证后声明有效。`epoch_output` 汇聚结构化 OBS/NAV 数据，RINEX 文本由配套软件生成。
