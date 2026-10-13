# Carrier NCO / Mixer：第一版实现与依据

2026-09-28。依据 V1.7 第 5.1、5.6、5.7 节和当前定稿 `plan.md`。本模块只完成逐样本载波产生和混频，不包含 FLL/PLL。课程输入为 Fs=16.368 MHz、IF=4.092 MHz、signed 3 bit 重构值 -3/-1/+1/+3；绝对载波初相不是捕获模块必需输出。

## 数学、单位与时间

```text
theta[n]       = 2*pi * phase_word[n] / 2^P
step_word[n]   = round((IF + estimated_offset_hz[n]) / Fs * 2^P)
I[n]          = x[n] * cos(theta[n])
Q[n]          = -x[n] * sin(theta[n])
phase_word[n+1] = (phase_word[n] + step_word[n]) mod 2^P
```

`step_word` 表示总 IF 频率，不是单独的 Doppler 修正字；IF 只能加入一次。正频偏意味着接收信号相位比本地推进更快，去码后的 Prompt 正向旋转，环路应增加本地频率。更新频率控制字不清零相位。

当前样本用当前相位混频，然后推进相位。新的 step 在接纳沿用于推进到下一样本，不追溯改变当前样本的正余弦。`sample_accepted = rst_n && !init_valid && carrier_valid && sample_valid`。reset/init 优先，不消费同周期样本；空拍保持相位、I/Q 与参考数据，`iq_valid` 是事件有效标记而非保持数据。

I/Q、`iq_ref` 在接纳沿注册，供下一级在后一上升沿接收。未来通道封装必须把 Code NCO 的当前 E/P/L 码同样延迟一拍；不能将注册 I/Q 接到已经推进后的实时码值。`init_valid` 清空在途输出；系统级取消/代次仍由后续封装处理。

## 扫描与第一版选择

`model/carrier_model.py` 在选择前规定工程误差预算：频率舍入误差 ≤0.01 Hz；单位复本振幅度的峰值误差 ≤0.0035、RMS ≤0.0025。这些是内部实现预算，不是课程给出的环路验收门限。

| 相位 P | 频率 LSB (Hz) | 半 LSB 舍入界 (Hz) | 1 ms 相位误差界 (度) |
|---:|---:|---:|---:|
| 24 | 0.975609 | 0.487804 | 0.175610 |
| 28 | 0.060976 | 0.030488 | 0.010976 |
| 32 | 0.003811 | 0.001905 | 0.000686 |
| 36 | 0.000238 | 0.000119 | 0.000043 |

选择 P=32，是候选中满足频率预算的最小值。32 bit 在 30 s 完全开环下可积累 20.58° 的最坏量化漂移，不能把该位宽本身当作闭环锁定证据。

正弦扫描地址宽度 A=8/10/12、幅值宽度 B=8/10/12/14，共 12 组。全周扫描 262144 个相位点，并以解析界保护有限扫描网格的边界漏检：

```text
peak_bound <= 2*sin(pi/(2*2^A)) + sqrt(2)/(2*(2^(B-1)-1))
```

第一项来自最近地址量化，第二项来自两个分量各半幅值 LSB。按通过预算者中最小四分之一表存储位数选择 A=10、B=12：

- 最近地址舍入，半格处向增大方向取整，最后一格按整周回绕。
- 对称整数幅值 ±2047，归一化除数为 **2047，不是 2048**；不宣称是隐含 Q1.11 的 /2048 增益。
- 全周 1024 点；RTL 四分之一表含两个端点，共 257×12=3084 bit 表值。该数字不是综合面积或实际 ROM 宏面积。
- 实测单位复本振峰值误差 0.00339820、RMS 0.00178261；解析峰值界 0.00341340。
- A=10/B=10 的解析峰值界 0.00445173，不满足预算；A=12/B=10 满足但表值为 10250 bit。

报告为 `reports/carrier/frequency_scan.csv`、`lut_scan.csv`、`analysis.json`。改变查表精度须重建表、独立 golden 和回归，当前表常量不伪装成任意 A/B 均支持。

## Mixer 与相关器位宽

输入宽度 W 参数化，正弦整数范围 `[-2047,+2047]`，因此全部 W bit 二补码输入的乘积满足：

```text
abs(product) <= 2^(W-1) * 2047 < 2^(W+10)
IQ_WIDTH = W + 11
```

当前 W=3：I/Q 为 signed 14 bit。课程输入最大乘积为 3×2047=6141；对额外测试的 -4 极值，最大绝对值为 8188。RTL 先形成完整乘积再移除冗余符号位，不截小数、不舍入、不饱和。

接已有相关器时配置 `IQ_WIDTH=14`，N=16368 得 `ACC_WIDTH=14+14=28`，仍保存完整和。原 3 bit I/Q、17 bit 累加器是旧独立测试配置，不再用于描述新 Mixer 的输出。

## 接口

| 信号 | 含义 |
|---|---|
| `clk/rst_n` | 逻辑时钟 / 异步低有效复位 |
| `init_valid/init_phase_word` | 初始化相位，unsigned 周内相位字；正常捕获移交可使用确定的零初相，不要求真值 |
| `carrier_step_word` | P bit 总 IF+频偏控制字；在每个接纳沿推进相位 |
| `sample_valid/sample_data/sample_ref` | 重构后的 signed 输入及样本参考 |
| `carrier_valid/sample_accepted` | 已配置状态和组合接纳标志，不对公共流施加反压 |
| `carrier_phase_word` | 当前本地相位状态，unsigned fraction-of-turn |
| `iq_valid/i_sample/q_sample/iq_ref` | 同拍注册的有效标记、完整整数 I/Q 和原样本参考 |

参数：`PHASE_WIDTH=32`、`INPUT_WIDTH=3`、`SAMPLE_REF_WIDTH=64`。当前回归使用这些默认值；不因参数可修改就宣称其他配置已验证。

## 独立模型与 VCS 证据

全精度参考直接使用 `cos/sin`；整数 golden 直接生成全周 sin/cos 两表。RTL 则使用四分之一表、象限镜像及 cos 相移，避免只比对同一查表地址实现。

模型自动核对全部向量的数学相位推进、I/Q 全精度误差及有符号边界，输出 `CARRIER_MODEL_PASS`。29,775 事件中 22,043 个样本被接纳，包括所有 1024 查表地址、每格舍入边界两侧、四象限、整周回绕、标称 IF、±10 kHz、±125 Hz、频率变化不重置相位、空拍、reset/init 冲突及 -4 极值。

2026-09-28 Linux VCS I-2014.03 实际运行：

```text
make prn-regression code-nco-epl-regression carrier-regression
B1I_PRN_REGRESSION_PASS
RELOAD_COLLISION_PASS: init priority, busy sample and asynchronous reset
CODE_NCO_EPL_REGRESSION_PASS events=36451 windows=4
CARRIER_REGRESSION_PASS events=29775 accepted=22043
```

整体命令退出状态为 0。TB 对 X/不匹配计为失败，检查每个事件的接纳、相位、配置状态、注册 I/Q/valid/ref，并设超时；仅全部通过才打印最终 PASS。日志回收到 `reports/carrier_vcs.log`，依赖日志为 `reports/b1i_prn_vcs.log`、`reports/code_nco_epl_vcs.log`。

## 限制与后续

- 本模块 PASS 不代表 FLL/PLL、DLL 或单通道闭环已经完成。
- `model/tracking_reference.py` 正在研究全精度闭环、窗口启动对齐、反馈延迟及锁定迟滞；环路参数尚未冻结到 RTL。
- 输入实信号的实际 ADC 阈值、前端滤波、正式课程文件仍未取得。模型激励的量化阈值是明确记录的工程选择。
- 尚未做 GNSS 正式 DC/PPA 或目标系统吞吐/时序验收。
