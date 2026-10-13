# GNSS 基带硬件设计方法卡

> 来源：Shivaramaiah & Dempster, *Baseband Hardware Designs in Modernised GNSS Receivers*。该章讨论通用 GPS/Galileo 基带；用于硬件组织和资源权衡，**不提供北斗 B1I 的规范参数**。

## 1. 通用单通道硬件骨架

文献把基带分成两部分：（1）核心相关器硬件；（2）处理相关结果、做捕获判决和跟踪反馈的控制部分。（PDF pp.2–3）

核心相关路径可以压缩成：

```text
IF sample
  ↓
Carrier NCO → local I/Q carrier
  ↓
carrier mixer
  ↓
local reference (code, optional subcarrier)
  ↓
E/P/L × I/Q reference mixing
  ↓
accumulators over integration window
  ↓
tracking/discriminator/controller
  ↘ feedback to carrier/code NCO
```

对典型三臂 E/P/L 相关器，I/Q 两路一共形成 6 路积累结果。

## 2. 为什么要把“相关计算”和“本地信号生成”分开

文献建议把核心相关器再拆成：

- correlation computation；
- local signal generation/control。

这样更容易扩展不同 PRN、不同码率、不同调制，同时让相关数据通路保持相对稳定。（PDF p.3）

对本项目的直接启发：`carrier_nco`、`code_nco/prn`、`epl_correlator/accumulator` 应有清晰边界；不要把 PRN 生成、NCO、环路滤波全部糊在一个大 always block。

## 3. 位宽设计：逐级按“可能取值 + 后续算术”推导

文献用 `Nif, Ncar, N1, Nref, N2, Nacc` 表示各级位宽，并强调位宽决定资源和功耗。（PDF pp.4–5）

值得直接借鉴的思路：

- ADC/IF 低位宽是常见选择；文献示例使用 2 bit、四电平 `{±1,±3}`；
- 本地载波量化越细，杂散/量化噪声越低，但后级乘法/查表/累加全部变宽；
- 即使某一级只有有限个离散值，如果下一步要做补码算术，也要考虑可直接加减的表示宽度；
- `Nacc` 由“单样本最大幅度 × 一个积分窗口最多累加多少点”给出保守上界，再结合真实信号/量化做优化。

对本项目：不要凭经验直接写 `integer` 或统一 32 bit；为 Carrier mixer、E/P/L sample product、积分器、环路误差、NCO 控制字分别记录范围/精度/溢出策略。

## 4. 逐样本组合逻辑与时钟约束

在经典相关器里，carrier mixer 和 reference mixer 可以是组合逻辑，NCO/输入寄存/累加器是时序逻辑。组合传播延迟必须小于采样/处理周期预算。（PDF p.6）

但本项目的 `clk` 不一定等于采样率，因此真正的约束应写成：

```text
每个 sample_valid 到来后，必须在下一次需要该结果之前完成对应运算；
吞吐率 ≥ 配套输入的有效采样吞吐率。
```

可以多周期/流水化，但不能靠“仿真最终算对”掩盖吞吐不足。

## 5. 资源的主要膨胀源

文献对现代 GNSS 的分析表明，资源通常被以下因素推高：（PDF pp.7–14）

- 更长/更复杂的码生成或码存储；
- 更高采样率/工作频率；
- 多级/复数调制带来的更宽 reference mixer；
- 更多信号分量导致更多相关臂和累加器；
- 较长积分导致更宽累加器。

虽然 B1I 比 Galileo E5 简单得多，但 12 路复制仍使“每通道 6 个积分器 + NCO + PRN + 环路状态”的小浪费乘 12。优先优化高复制率的模块。

## 6. 推荐的硬件优化顺序

文献给出的通用建议是模块化、控制资源/功耗，并谨慎做性能换资源。（PDF pp.15–19）

对本项目更实际的顺序：

1. 先做**功能清楚、位宽有依据**的单通道；
2. 确认持续吞吐与积分边界；
3. 再复制到 12 通道并查共享机会；
4. 优化重复的 LUT/码生成/控制，不要先牺牲观测语义；
5. 若考虑降采样/资源复用，先证明不会破坏捕获/跟踪所需带宽和时间关系。

文献还指出降低工作频率通常能降功耗，但若为了降频增加滤波、复用或多周期结构，会带来额外资源和控制复杂度。（PDF p.17）

## 7. 对当前 B1I 项目的边界

可以直接借鉴：

- 核心相关器/控制器分离；
- NCO → mixer → E/P/L → accumulator → loop feedback 的组织；
- 位宽与累加器上界推导；
- 模块化和资源复制分析。

不要直接搬：

- GPS L1 C/A 的码发生器参数；
- Galileo BOC/AltBOC 的 subcarrier 结构；
- 文献中某个 FPGA 的具体功耗/资源数字作为本 ASIC 验收目标。
