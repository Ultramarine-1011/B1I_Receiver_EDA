# Code NCO 与 E/P/L 相关器基线

本文记录第一版 Code NCO、Early/Prompt/Late 取码和六路相关积分的数学定义、定点选择、RTL 接口及验证证据。依据为 `plan.md`、《集成电路 EDA 实验指导书 V1.7》第 4 章和已验证的 B1I PRN 子模块；本文不定义 DLL、载波环、捕获器或完整跟踪通道。

## 1. 逐样本数学与时序

正常运行且没有 reset/init 时，在 `sample_valid && code_valid` 时接纳样本。令接纳第 `n` 个样本之前的 Prompt 码相位为 `q[n]`，单位为 chip，主码长度 `L=2046`，Code NCO 每接纳样本的步长为 `d[n]`，则：

```text
E phase = (q[n] + delta) mod L
P phase =  q[n]
L phase = (q[n] - delta) mod L

E/P/L code = PRN[floor(E/P/L phase)]
q[n+1] = (q[n] + d[n]) mod L
```

一个有效样本周期严格按以下顺序解释：

1. 以当前 `q[n]` 读取 E/P/L 码片；
2. 当前 I/Q 样本乘以当前 E/P/L 码并累加；
3. 再用 `d[n]` 推进相位；
4. Prompt 相位跨过 2046 chip 时，`code_period_count` 加一，并脉冲输出 `code_epoch`。

正常运行的 `sample_valid=0` 空拍保持相位、PRN 状态、周期计数、积分器和窗口样本计数。reset/init 和初始化预置有独立状态更新条件；`code_epoch/init_done/window_done` 是单逻辑周期事件脉冲，不按数据保持规则延长。`code_valid=0` 的初始化预置阶段不接纳样本，但会推进 PRN 到目标 chip。

当前 RTL 的 `sample_accepted` 为 `rst_n && !init_valid && sample_valid && code_valid`，reset/init 会屏蔽同周期接纳；时序优先级为 reset → init → 预置 → 接纳样本。TB 的 `run_reload_collision_test` 检查 init 冲突、预置期间有效样本及异步 reset。2026-09-28 当前源文件已实际通过 Linux VCS，日志含 `RELOAD_COLLISION_PASS` 与原总 PASS；原“实现已改但验证待补”已经关闭，系统级首样本对齐和反馈仍待集成。

## 2. Code NCO 定点选择

### 2.1 表示与控制字

- `code_phase_q`：unsigned Q11.32，单位 chip，43 bit，范围按 2046 chip 取模；整数位能够表示 `0..2045`。
- `code_step_q`：unsigned Q1.32，单位 chip/accepted-sample，33 bit。
- 标称增量为 `Rc/Fs = 2.046 MHz / 16.368 MHz = 0.125 chip/sample`，因此标称控制字为 `0x20000000`。
- `init_code_phase_q` 与相位状态使用同一 Q11.32 表示。装载时规约到 `[0,2046)`；装载不会自行增加 `code_period_count`，后续真实相位回绕才增加。
- 当前接口限制 `0 < code_step_q < 1 chip/sample`，与本工程每有效样本约 1/8 chip 的用途一致。
- `CODE_LENGTH` 当前必须为 2046，与被复用的 PRN 固定周期一致。参数扫描不等于所有参数组合已经过 RTL 回归；现有 VCS 配置为 F=32、delta=1/4、周期计数 32 bit。非法 PRN 不产生成功 `init_done`；步长无运行时限幅/错误输出，调用方须保证合法配置。

为了覆盖尚未冻结的实际码速范围，扫描采用保守包络：把指导书载波总频偏覆盖 `±10 kHz` 全部按 `Rc/fB1I` 比例映射到码速，得到 `±13.1061599 chip/s`。这是定点覆盖边界，不表示振荡器造成的全部载波偏差必然等比例进入实际码速；DLL 设计时仍需区分多普勒与本振误差。

| 小数位 F | 相位总位数 | 码速 LSB (chip/s) | 最坏舍入误差 (chip/s) | 最坏 1 ms 漂移 (chip) | 最坏 180 s 开环漂移 (chip) |
|---:|---:|---:|---:|---:|---:|
| 16 | 27 | 249.755859 | 124.877930 | 0.124878 | 22478.0273 |
| 20 | 31 | 15.609741 | 7.804871 | 0.007805 | 1404.8767 |
| 24 | 35 | 0.975609 | 0.487804 | 0.000488 | 87.8048 |
| 28 | 39 | 0.060976 | 0.030488 | 0.0000305 | 5.4878 |
| **32** | **43** | **0.003811** | **0.001905** | **0.00000191** | **0.34299** |
| 36 | 47 | 0.000238 | 0.000119 | 0.000000119 | 0.02144 |

第一版选择 **F=32**。F=28 的最坏 180 s 开环量化漂移仍为 5.49 chip；F=32 将每个 1 ms 更新周期的最坏量化漂移压到约 `1.91e-6 chip`，而 F=36 还需增加 4 bit。180 s 数字只是没有 DLL 校正时的误差放大检查，不是闭环误差指标。在保守正/负端点处，F=32 的实际舍入误差为约 `0.000227 chip/s`。

详细扫描见 `reports/code_nco_width_scan.csv` 和 `reports/code_nco_epl_analysis.json`。

### 2.2 任意初始相位

`code_nco` 复用三个顺序型 `b1i_prn_gen` 实例，并在 `init_valid` 后把它们推进到 E/P/L 对应的整数 chip。预置期间 `code_valid=0`；最坏可能需要 2046 个逻辑时钟，但不会消耗输入样本。该方案先保证 ICD 序列唯一来源和位精确正确性；若后续吞吐/切换延迟要求不允许这一等待，可在不改变外部相位语义的前提下增加 LFSR jump-ahead 初始化。

## 3. E/P/L 间隔

本文把 `delta` 明确定义为 **Early 或 Late 相对 Prompt 的单边偏移**：`E=q+delta`、`L=q-delta`，所以 E-L 总间隔为 `2*delta`。不得把 `delta=0.25 chip` 写成 E-L 总间隔 0.25 chip。

扫描比较理想 BPSK 三角相关函数和 PRN 6 在 8 sample/chip 下的整周期离散相关。鉴别器用于比较的形式为归一化功率 Early-minus-Late：

```text
D = (E^2 - L^2) / (E^2 + L^2)
```

| 单边 `delta` (chip) | E-L 总间隔 (chip) | 标称采样偏移 | 理想零点斜率 (/chip) | 离散零点斜率 (/chip) | E/L 同时非零半范围 (chip) | 正确符号拉入半范围 (chip) |
|---:|---:|---:|---:|---:|---:|---:|
| 0.125 | 0.25 | 1 sample | -2.286 | -2.242 | 0.875 | 1.125 |
| **0.25** | **0.5** | **2 samples** | **-2.667** | **-2.598** | **0.75** | **1.25** |
| 0.5 | 1.0 | 4 samples | -4.000 | -3.771 | 0.50 | 1.50 |

第一版选择 **`delta=0.25 chip`，E-L 总间隔 0.5 chip**。它在标称采样率下恰好对应 2 个样本，零点斜率强于 0.125，同时保留比 0.5 更宽的 E/L 双臂有效区。8 sample/chip 的相位量化半 LSB 为 0.0625 chip。实际前端滤波、多径和噪声会改变最优间隔，因此 RTL 仍以有理数参数保留可修改性。

完整 E/P/L 曲线和 S-curve 数据见 `reports/epl_spacing_scan.csv`。

## 4. 相关窗口与累加器

第一版使用固定的 **16368 个 accepted samples** 窗口，对应标称 1 ms。它只依赖 `sample_valid`，不假设系统 `clk=Fs`：空拍不计数，窗口首样本的 `sample_ref` 记为 `window_ref`，第 16368 个有效样本先参与六路求和，再使 `window_done` 脉冲；紧接着的下一个有效样本开启下一窗口。因此连续窗口不重样、不漏样。

固定窗口不由 `code_epoch` 触发，码速微调时窗口边界与本地码历元可以不同。这里的空拍表示逻辑处理暂停且没有新样本进入，不代表输入信号时间中已丢失样本；实际样本缺口的时间推进与异常策略尚未定义。当前输出没有结果 ready 或身份端口，需要在后续通道封装中处理结果接纳、身份标签和反馈延迟。

相关器输入是 Carrier mixer 之后的 signed I/Q，`IQ_WIDTH` 保持参数化。2026-09-28 新增 Mixer 第一版为 signed 14 bit，因此连接时配置 28 bit 累加器，依据见 [CARRIER_NCO_MIXER.md](CARRIER_NCO_MIXER.md)；原 3 bit 测试仍独立保留。码值映射为 `0 -> +1`、`1 -> -1`。对 W bit 二补码输入，最大乘积绝对值为 `2^(W-1)`；窗口长度为 N 时，不溢出的最小 signed 累加器位宽为：

```text
ACC_WIDTH_min = W + ceil(log2(N + 1))
```

这里 `N=16368`，所以 `ceil(log2(N+1))=14`，即 `ACC_WIDTH_min=IQ_WIDTH+14`。

| `IQ_WIDTH` | 单样本最大乘积绝对值 | 16368 点最坏和绝对值 | 最小 `ACC_WIDTH` |
|---:|---:|---:|---:|
| 3 | 4 | 65472 | 17 |
| 4 | 8 | 130944 | 18 |
| 8 | 128 | 2095104 | 22 |
| 12 | 2048 | 33521664 | 26 |
| 16 | 32768 | 536346624 | 30 |

固定窗口并保留完整和时不需要额外 guard bit，第一版 `ACC_GUARD_BITS=0`；参数仍保留。相关器内部和输出均不舍入、不饱和。后续功率、鉴别器或跨窗口运算若需要缩位，必须在相应模块中明确舍入/饱和规则，不能隐式截断。

## 5. RTL 接口

### `rtl/code_nco.sv`

| 信号 | 语义 |
|---|---|
| `init_valid` | 重装 PRN、Q11.32 码相位和周期计数；优先于样本处理 |
| `init_prn` | B1I MEO/IGSO PRN 6–37 |
| `init_code_phase_q` | Q11.32 chip，按 2046 取模 |
| `init_code_period_count` | 初始整码周期计数 |
| `sample_valid` | 有新样本可处理；初始化完成前不会被接纳 |
| `code_step_q` | Q1.32 chip/accepted-sample |
| `code_valid` / `init_done` | E/P/L 已对准初相，可开始接纳样本 |
| `sample_accepted` | `rst_n && !init_valid && sample_valid && code_valid`；当前版本验证状态见第 1 节 |
| `early_code/prompt_code/late_code` | 当前样本使用的三个 B1I 码片 |
| `code_phase_q` | 当前 Prompt Q11.32 相位 |
| `code_period_count` / `code_epoch` | 整码周期计数及本次样本后发生回绕的脉冲 |

### `rtl/epl_correlator.sv`

| 信号 | 语义 |
|---|---|
| `init_valid` | 清除未完成窗口和已发布输出 |
| `sample_valid` | 与 Code NCO 的 `sample_accepted` 相连 |
| `i_sample/q_sample` | 参数化 `IQ_WIDTH` 的 signed mixer 输出 |
| `early/prompt/late_code` | 与当前样本对应的码片 |
| `sample_ref` | 当前接纳样本的公共参考位置 |
| `ie/qe/ip/qp/il/ql` | 完整窗口六路 signed 累加和 |
| `window_done` | 结果有效单周期脉冲 |
| `window_ref` | 本窗口第一个 accepted sample 的参考位置 |

## 6. 参考模型和验证证据

`model/code_nco_epl_model.py` 包含 exact-rational 全精度 Code NCO、独立 Q11.32 模型、六路相关器、位宽/间隔扫描和 golden vector 生成。`tb/tb_code_nco_epl.sv` 逐事件比较当前相位、E/P/L 码片、更新后相位、周期计数、回绕、六路积分、`window_done` 和 `window_ref`。

2026-09-21 Linux VCS I-2014.03 历史回归覆盖（不包含之后加入的 reset/init 仲裁修改与冲突测试）：

- PRN 6 标称 8 sample/chip，两个完整 16368 点窗口加边界余量；
- PRN 12 正码速微调并从 2045.75 chip 跨越周期边界；
- PRN 23 负码速微调；
- PRN 37 中途重新初始化到非整数相位和非零周期计数；
- 四个场景均插入 `sample_valid=0` 空拍；
- chip 边界、2045→0 回绕、E/P/L 模 2046 相位关系；
- 连续窗口的首末样本、无重样/漏样和 `window_ref`；
- 3 bit I/Q、16368 点窗口的正/负极值 `±65472`，17 bit 累加器无溢出。

最终自动标记为：

```text
CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4
```

当前日志 `reports/code_nco_epl_vcs.log` 已更新为 2026-09-28 实际运行；向量在 `tb/vectors/code_nco_epl/`。原向量和极值测试再次通过，并新增 `RELOAD_COLLISION_PASS`。整体回归进程退出状态 0，Windows/Linux 源文件哈希记录在 `reports/carrier/regression_manifest.json`。2026-09-21 原日志保留于 `reports/archive/2026-09-21/`。

## 7. 尚未冻结

- 模块 reset/init 接纳屏蔽及冲突验证已 resolved；系统级取消/身份、首样本参考对齐尚未完成。
- Mixer 流水线加入后的 I/Q/码值/样本参考对齐、窗口结果接纳和环路反馈生效点。
- Carrier mixer 第一版 14 bit 完整乘积已验证；28 bit E/P/L 的实际连接与依赖回归仍须在通道集成阶段完成。
- DLL 鉴别器、环路阶数/带宽、更新周期、滤波系数、锁定门限和载波辅助。
- 真实前端滤波/多径/噪声下是否需要调整 `delta`；第一版 0.25 chip 是可修改 baseline。
- 是否在 DLL/数据同步阶段继续采用固定 16368 点窗口，或增加按本地码历元、NH 边界聚合的上层窗口。
- 系统 `clk`、12 通道吞吐和资源复用方案；它们不改变逐 `sample_valid` 算法语义，但会决定微架构。
- 任意码相位初始化的 0–2046 周期预置延迟是否需要 jump-ahead 优化。
