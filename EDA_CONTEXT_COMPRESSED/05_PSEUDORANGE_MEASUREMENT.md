# 码相位 → 伪距：实现方法卡

> 来源：Pini, Falco & Lo Presti, *Estimation of Satellite-User Ranges Through GNSS Code Phase Measurements*。该文用 GPS/Galileo 举例；本项目要把同样的时间逻辑映射到北斗 B1I/D1。

## 1. 为什么叫伪距

卫星钟属于统一 GNSS 时间尺度，而接收机本地钟有未知偏差。传播时间乘光速得到的观测因此包含一个所有卫星共有的接收机钟差项。三维位置 `(x,y,z)` 加接收机钟差一共 4 个未知量，所以通常至少需要 4 颗卫星。（PDF pp.2–3）

对 RTL 来说最重要的不是直接解位置，而是给导航软件提供**同一接收历元、身份明确、时间关系正确**的多星观测。

## 2. acquisition / tracking / demodulation 为什么都和测距有关

文献把链路写得很清楚：（PDF pp.4–8）

- acquisition 给出粗 code delay 与 Doppler；
- DLL/PLL 持续把本地码/载波与输入对齐；
- 接收机持续计数 chip、完整码周期、导航 bit 和 frame；
- 帧/电文同步提供绝对或较粗的卫星时间锚点；
- 这些计数器之间的相对偏移最终形成各卫星传播时间差。

所以“测量模块”不能在最后凭空计算伪距；上游从第一天起就必须保存可追溯的样本/码周期/位/帧时间关系。

## 3. 首组伪距的两个思路

文献给出两类常用构造。（PDF pp.10–14）

### Common transmission time

比较“同一个卫星发送时刻对应的标记”在不同通道何时被接收。因为各卫星距离不同，接收时刻有差异。选一个最早到达的参考通道，其余通道测相对延迟。

优点：概念直观。缺点：若要求所有通道都到达同一电文位置，实时更新不够方便。

### Common reception time

固定一个接收机公共时刻 `t_u^R`，对每个通道回看对应卫星信号的发送时间，再比较各通道的相对传播时间。文献指出这种方式更适合实时接收机，因为不必等待所有通道解到同一个数据位位置。（PDF pp.13–14）

本课程已经要求“共同接收历元”，因此总体架构更自然地落在 common-reception-time 思路上。

## 4. 本项目的测量状态应该怎么保留

每个通道至少持续维护：

```text
prn / channel_id / generation
sample/source time reference
fractional code phase
integer code-period count
navigation-bit/frame alignment
nav time anchor + valid
tracking/time validity
```

到达共同观测历元时，测量单元利用这些状态把“当前本地接收时刻”与“该卫星信号对应的发射时刻”关联起来。

不要用以下捷径：

- 把捕获阶段的 `code_phase` 直接当伪距；
- 只有 0–1 ms 分数码相位，没有整码周期计数；
- 用通道计算完成的 clk 周期当作接收时刻；
- 从模拟器真值读取发射时间/几何距离补齐缺失状态。

## 5. 为什么共同历元需要输出汇聚层

12 路通道的内部计算可能先后完成，但导航软件需要同一接收时刻的一组多星观测。共同历元由输入公共时基定义，与各通道“什么时候算完”是两件事。

因此建议：

```text
channel measurement state
     ↓ at common_epoch
per-channel snapshot + valid
     ↓
epoch/output aggregator
     ↓
OBS records for same epoch
```

通道失锁/时间信息不足时，必须撤销该星当历元的 measurement valid，而不是输出一个看似完整的数。

## 6. 首次测量与后续测量

文献区分“第一组伪距”和后续连续伪距：首组需要建立时间锚和相对关系；第一次 PVT 后，参考距离/时间关系可以进一步精化；后续只需持续推进统一接收时刻和通道计数状态。（PDF p.14）

对工程状态机的启发：

```text
tracking_valid
→ sync_valid
→ nav_time_valid
→ measurement_time_initialized
→ periodic measurement_valid
```

不要在 `code_lock=1` 的同一时刻就宣称伪距有效。

## 7. 这篇文献中不能直接搬到 B1I 的部分

文献示例使用 GPS C/A 的 1 ms 码、20 ms 数据位、GPS TOW/HOW 等术语。B1I 的主码虽同样是 1 ms，但 D1 的 NH20、帧格式、SOW/时间字段必须按北斗 ICD 实现。可迁移的是“时间锚 + 码相位 + 整周期 + 公共接收历元”的方法，而不是 GPS 电文字段本身。
