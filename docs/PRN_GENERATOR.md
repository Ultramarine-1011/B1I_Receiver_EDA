# B1I PRN Generator 设计与验证说明

## 依据与范围

实现依据为 `EDA_CONTEXT_COMPRESSED/北斗_B1I_B2I_ICD_2.1版_中文版.pdf`：

- PDF 第 11 页（正文第 7 页），第 4.3 节及图 4-1：G1/G2 生成多项式、11 级寄存器、初相 `01010101010`、输出和移位方向。
- PDF 第 12–13 页（正文第 8–9 页），表 4-2：PRN 1–37 的 G2 相位抽头；本模块实现课程所需的 MEO/IGSO PRN 6–37。

G1 多项式：

```text
1 + X + X^7 + X^8 + X^9 + X^10 + X^11
```

G2 多项式：

```text
1 + X + X^2 + X^3 + X^4 + X^5 + X^8 + X^9 + X^11
```

模块输出从 ICD 初相开始的前 2046 个 Gold-code chip，并在周期边界跳过被截短的第 2047 个 chip，恢复初相。

## 接口

| 信号 | 方向 | 含义 |
|---|---|---|
| `clk` | input | PRN 模块逻辑时钟；频率不在本模块冻结 |
| `rst_n` | input | 异步低有效复位 |
| `load` | input | 装载 `prn_select` 并恢复 chip 0；优先于 advance |
| `chip_enable` | input | 为 1 时消费当前 chip，并在上升沿推进到下一 chip |
| `prn_select[5:0]` | input | MEO/IGSO PRN 6–37 |
| `chip` | output | 当前 chip，二进制 `0/1`；未配置时为 0 |
| `chip_index[10:0]` | output | 当前 chip 序号 0–2045 |
| `configured` | output | 最近一次 `load` 选择了合法 PRN |
| `epoch` | output | 消费 chip 2045 后拉高一个 `clk` 周期 |

`chip_enable=0` 时 LFSR 和 `chip_index` 保持。模块不包含采样率假设、NCO 相位、Early/Prompt/Late 偏移或相关累加器。

## 独立 golden model

`model/b1i_prn_golden.py` 使用 Python 列表按 ICD stage 1→11 表示寄存器，和 RTL 的 packed vector 表示不同。模型会：

1. 独立验证 G1、G2 都在 2047 次移位后首次回到初相。
2. 按表 4-2 生成 PRN 6–37 的组合向量，并为 PRN 6、12、23、37 另存独立 2046-chip 文件。
3. 检查四条代表序列互不相同，并记录 SHA-256 与前 32 chip。

## VCS 自检覆盖

`tb/tb_b1i_prn_gen.sv` 自动检查：

- reset 后未配置、index 0、chip/epoch 为 0；
- 非法 PRN 5 被拒绝；
- PRN 6–37 全部 32 个 MEO/IGSO 序列，各 2046 个 chip 与 golden model 逐 chip 一致；
- 每个 PRN 在 chip 2045 后 `epoch` 单周期有效并回到 chip 0；
- PRN 6、12、23、37 的六个两两组合均存在序列差异；
- 只有全部检查通过才打印 `B1I_PRN_REGRESSION_PASS`。

运行入口：

```text
source ~/eda_env.sh
cd ~/eda_project
make prn-regression
```
