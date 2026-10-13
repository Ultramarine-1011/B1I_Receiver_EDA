# GNSS 捕获方法卡

> 来源：Dovis & Ta, *High Sensitivity Techniques for GNSS Signal Acquisition*。用途：搜索空间、判决、积分和性能评价。文献主要以 GPS/Galileo 举例；B1I 的码/NH/数据结构需结合 ICD 和项目指导书。

## 1. 捕获的数学对象

捕获要在 `(PRN, code delay τ, Doppler fD)` 的不确定空间中找到最匹配的本地假设。每个 cell 生成本地 PRN 和本地载波，与输入相关；复相关输出可看成 Cross Ambiguity Function (CAF) 的一个采样。（PDF pp.3–4）

实现上不管采用串行、码相位并行还是 FFT，本质接口不变：

```text
input window + PRN + code-delay grid + Doppler grid + integration cfg
    ↓
complex correlation metric per cell
    ↓
peak search + detection threshold
    ↓
PRN, code_phase, doppler, metric, reference_time
```

## 2. 搜索栅格不是越粗越省事

码相位误差和频率残差都会造成相关损失。文献给出一个常见 BPSK 经验：码相位步长约 0.5 chip；Doppler 步长与相干积分时间 `Tint` 成反比，常见量级 `1/(2Tint)` 或 `2/(3Tint)`。（PDF pp.4–5）

这不是本项目的强制参数，但给出一个重要设计关系：

> 积分越长 → 频率 bin 必须越细 → 搜索 cell 数增加 → 计算量和捕获时间上升。

所以搜索范围、步长、积分时间、并行度必须一起做预算。

## 3. 判决必须同时考虑检测和虚警

每个搜索 cell 的相关能量在“目标不存在 H0”和“目标存在 H1”下都是随机量。门限提高会降低虚警但增加漏检；门限降低则相反。文献使用 Neyman–Pearson 框架，并把 `Pd`、`Pfa`、ROC、平均捕获时间作为核心性能量。（PDF pp.5–7）

因此测试不应只有“某一次波形抓到了”：

```text
固定搜索范围、积分、门限、C/N0、随机试验数
→ 统计 correct acquisition rate / Pd
→ 统计 full-search false alarm / Pfa
→ 统计 acquisition latency
```

这与课程要求的捕获率、全搜索虚警率、捕获耗时是同一个评价方向。

## 4. 相干积分的收益与限制

更长的 coherent integration 能提高解扩增益，但有几个限制：（PDF p.8）

- 未知数据/NH 符号翻转会使相干和抵消；
- 残余 Doppler 在长积分中累积相位旋转；
- 码 Doppler/动态会造成码失配；
- 本振不稳定会在长积分中更加明显；
- 更长积分要求更细的 Doppler grid，计算量增加。

对 B1I 尤其要记住：D1 上还有 NH20 次级码。若积分跨越未知 NH 翻转而没有处理其符号，不能简单假设“积得越久越灵敏”。

## 5. 三类后相关组合

无外部辅助时，文献讨论三种经典组合：（PDF pp.8–10）

### Coherent

直接把复相关值按相位相干相加，等价于延长相干积分。理论增益最好，但最怕数据/频率失配，并要求更细搜索。

### Non-coherent

累计 `|R_m|^2`。不需要保持跨块相位，但存在 squaring loss；硬件/控制比较直观。

### Differential

利用相邻复相关值与前一块共轭相乘后再组合。信号在相邻块间相关、噪声较不相关，因此在灵敏度与复杂度之间折中；仍可能受数据符号翻转影响。

项目第一版无需追求高灵敏度花活。更合理的路线是先完成短积分的正确基线，再把这些方法作为可测量的扩展方案。

## 6. 外部辅助与 channel combining

文献的高灵敏度框架还包括：（PDF pp.10–16）

- external aiding：提供粗码相位/频率/导航数据，从而允许 data wipe-off 和更长相干积分；
- data + pilot channel combining：利用现代 GNSS 的 pilot/data 双分量。

本课程 B1I D1 基础项目没有要求 pilot combining，也不能把模拟器真值作为接收机的“隐藏辅助”。除非课程明确允许辅助信息，否则捕获必须只使用接口允许的配置。

## 7. 方案评审时必须写清的 8 个量

```text
1. PRN 范围
2. Doppler min/max
3. Doppler step
4. code-phase step / 表示
5. coherent integration length
6. non-coherent/differential combining count（若有）
7. detection metric + threshold rule
8. 单任务 cell 数、每 cell 运算量、总最坏延迟
```

除此之外，捕获输出还必须绑定 `task_id/reference_sample`，否则异步结果无法安全移交给跟踪。
