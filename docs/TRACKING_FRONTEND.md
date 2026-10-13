# 单通道跟踪前端

`rtl/tracking_frontend.sv` 连接现有 Code NCO/PRN、Carrier NCO/Mixer 与 E/P/L，不包含 DLL、FLL/PLL、锁定判据、捕获或卫星管理。调用方仍提供两个 NCO 的控制字。

## 数据与时间

- 只有 `code_valid=1` 且非 reset/init 时接纳 `sample_valid`。同一个 `sample_accepted` 驱动两种 NCO；PRN 预置期间载波不推进，不消费信号样本。
- 每个接纳沿用当前码/载波相位处理当前样本。Mixer 注册 I/Q/ref，同拍寄存 E/P/L 码及是否属于积分窗口的标记。
- 后一级相关器在下一逻辑上升沿消费这些已对齐的数据。窗口完成时发布六路完整和、首样本参考和同窗口输入能量。
- 空拍停止 NCO 的样本推进，但在途样本仍可从 Mixer 流向相关器；这不是凭空消费新输入。不能要求所有流水级在 `sample_valid=0` 的同一拍立即保持。
- 最后一个样本计入当前窗口，下一样本开始下一窗口。`window_done` 相对于窗口最后一个输入接纳沿晚一拍；I/Q 与码值有相同延迟。

| 逻辑上升沿 | 输入级 | 积分级 |
|---|---|---|
| k | 接纳样本 n，寄存它的 I/Q、码、ref；推进两个 NCO | 消费已寄存的前一样本（若有效） |
| k+1 | 可接纳 n+1，也可空拍 | 消费样本 n，若为末样本则发布本窗口 |

## 首窗口与初始化

`ALIGN_FIRST_WINDOW=1` 为当前 baseline。初始 Prompt 相位为 0 时从首个接纳样本积分；否则先正常推进 NCO 到首次本地码回绕，回绕后的下一接纳样本开始第一个固定 N 样本窗口。启动只依据本地码状态，不读取真实 NH 或数据边界。此后窗口固定为 16368 个接纳样本，不随每个 `code_epoch` 重开。

PRN 预置逻辑时钟不推进样本时间；以上等待本地回绕的阶段则实际接纳样本、推进本地时间但不发布相关结果，二者不能混为一谈。输入 `sample_ref` 在等待期间同样前进，`window_ref` 为真正首个积分样本的参考。

reset/init 取消同周期输入、丢弃在途 I/Q 和不完整窗口，清除六路发布值及能量，不输出残缺窗口。新的初值仅用于新的样本序列，不自动推进捕获参考时刻；系统级时间对齐仍由封装负责。

## 端口与位宽

| 信息组 | 主要端口 |
|---|---|
| 初始化 | `init_valid/init_prn/init_code_phase_q/init_code_period_count/init_carrier_phase_word` |
| NCO 控制 | `code_step_q` 为 Q1.32 chip/sample；`carrier_step_word` 为总 IF+频偏的 32 bit 周增量 |
| 输入 | `sample_valid/sample_data/sample_ref`；当前 signed 3 bit，64 bit 参考 |
| 状态 | `sample_accepted/code_valid/init_done/code_epoch/code_phase_q/code_period_count/carrier_phase_word` |
| 窗口结果 | signed `ie/qe/ip/qp/il/ql`，`window_done/window_ref/window_energy` |

当前 Mixer 输出 14 bit，六路和为 28 bit；完整和不截断/饱和。结果没有 ready，后续环路封装必须及时保存。

`window_energy = sum(i_sample^2 + q_sample^2)`，与六路相关使用相同样本、边界和幅值标度；它不是已经归一化的 C/N0。功率鉴别使用的是相关和的平方，不能与此逐样本能量混淆。该输出供后续低能量有效性检查，不预先固定最终锁定阈值。

对 W bit I/Q 和 N 个样本，采用 unsigned `ENERGY_WIDTH=2*W+ceil(log2(N+1))` 的保守完整和：当前 W=14、N=16368，共 42 bit。乘法先保留完整平方位宽，两个平方扩位相加，再进入能量累加器。

## 验证

`model/frontend_golden.py` 用已有独立整数 NCO 与 Carrier golden 建模一个显式 pending 样本级，逐事件计算完整 I/Q、延迟码、六路和及能量；TB 检查实际寄存器级事件，不能只凭最终积分值判断对齐。

向量覆盖 PRN 6/12/23、零初相/2045.75 chip 跨回绕/任意非整数初相、正负码速微调、载波 ±10 kHz 控制更新、sample_valid 空拍、两窗口连续边界、重新初始化、-4 极值输入和最后样本流水线排空。

VCS 入口为 `make frontend-regression`。第一轮实际通过 `FRONTEND_REGRESSION_PASS events=90000 windows=4`。随后增加有在途样本时的 init/reset 与预置期间保持输入 valid 的定向测试；最终证据必须包含 `FRONTEND_RELOAD_RESET_PASS` 及总 PASS，见 `reports/frontend_vcs.log` 和后续回归清单。源码变更后不能以第一轮日志替代最终回归。

该回归证明逐样本数据路径与窗口语义，不证明 DLL/FLL/PLL 闭环收敛。后续还须落实 128 accepted-sample 反馈等待预算与实际算术延迟；窗口完成的一拍延迟必须计入，而不能从错误的样本位置重新计时。
