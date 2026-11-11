# 实验室运行清单

2026-11-11。入口采用 V6 实验 RTL，从源码重新映射算术块。当前全量实现的前置条件为 PCPS/FFT 存储方案及匹配的门级模型。

## 携带与初始化

Windows 仓库内已验证的携带包及校验文件集中在 `deliverables/2026-11-11_backend_lab/`。包对应 `c3ba596`，包内清单保持原验证版本。包含所需 RTL、脚本和六星 IF/比特真值。工艺库与单元模型从实验室提供。

需要重新打包时，从 Git 仓库根目录在 PowerShell 执行以下命令，输出位于本实验的 `work/LAB_INPUTS.tar.gz` 及 `.sha256`。新包需另行核验，并保留已有携带包。

```powershell
wsl.exe -d Ubuntu -- python3 experiments/ic_eda_20261111_backend/scripts/prepare.py --lab-bundle
```

在 Linux 解包后执行以下命令。先加载实验室现有 EDA 环境。

```bash
sha256sum -c LAB_INPUTS.tar.gz.sha256
mkdir -p ~/b1i_backend_lab
tar -xzf LAB_INPUTS.tar.gz -C ~/b1i_backend_lab
cd ~/b1i_backend_lab
source ~/eda_env.sh
export FLOW="$PWD/experiments/ic_eda_20261111_backend/lab/run_lab.sh"
export LAB_OUT="$PWD/work/tsmc28_run01"
export STD_MODELS_F="$PWD/std_models.f"
# std_models.f 每行一个实际存在的标准单元/存储宏时序 Verilog 绝对路径。
bash "$FLOW" preflight
```

预期为 `LAB_PREFLIGHT_DC_PASS`、TT/SS/FF 标准单元与 PAD 库可加载。库路径默认 `/home/share/libs/tsmc28`，可用 `LAB_CONFIG=/绝对路径/config.sh` 覆盖。缺文件看 `logs/preflight/run.log`，工具缺失看 `logs/tool_paths.txt`。M1 历史环境缺标准单元 Verilog，需向实验室取得对应版本及必要 UDP、include 文件，并确认负时序检查支持。

查看 `reports/host_memory.txt`。本轮隔离 PCPS 的六通道预演峰值为 6.30 GiB，历史 2 GB 虚拟机资源不足。进入六通道综合前准备至少 8 GB 内存的主机，并核对可用内存与 swap。

模型到齐后，先用八位移位寄存器验证实际 TSMC28 标准单元、许可证、MAX/MIN 反标和功耗入口。

```bash
(
  export LOCAL_PROBE=1 TOP=backend_smoke LAB_OUT="$PWD/work/tsmc28_probe01"
  for step in preflight synth-isolated export gls-max gls-min power; do
    bash "$FLOW" "$step" || exit
  done
)
```

## 综合、时序与导出

```bash
bash "$FLOW" synth-isolated
# 隔离 PCPS 的含 PAD 预演，检查 reports/synth 与 output/final.*。
```

该结果包含一个明确的 PCPS 黑盒，捕获存储未综合。全量实现准备好后使用新的 `LAB_OUT`，提供已回归的 PCPS/FFT 源清单和宏库。

```bash
export LAB_OUT="$PWD/work/tsmc28_full01"
export PCPS_IMPL_F="$PWD/pcps_impl.f"
# 如使用 SRAM，设置匹配 PVT 的 MEMORY_MAX_DB、MEMORY_MIN_DB。
bash "$FLOW" synth-full
bash "$FLOW" export
```

检查六路跟踪、真实 PAD、未映射数与黑盒数，查看四类路径、setup/hold、复位恢复/移除、脉宽及设计规则。预期生成同版 `final.v/.ddc/.sdc`、`final_max.sdf`、`final_min.sdf` 和哈希清单。10 ns、IO 2.0/0.1 ns、转换 0.5 ns、负载 5 pF 为 M2 候选，板级规格发布后统一修改并重新综合。实验室 STA 传播 PAD/时钟单元弧，采用布局前估计。时序违例见 `reports/export/constraints.rpt`，覆盖见 `check_timing.rpt`。GLS 入口检查实际 STA 违例。

SS/FF 标准单元及 PAD 使用明确的 min-library 配对。两份 SDF 保留相同角落三元组，MAXIMUM 使用 SS 字段，MINIMUM 使用 FF 字段。核对 SDF 的 PROCESS、VOLTAGE、TEMPERATURE 及实际延迟差异。

## MAX/MIN 后仿与功耗

```bash
bash "$FLOW" gls-max
bash "$FLOW" gls-min
GLS_MODE=permuted bash "$FLOW" gls-max
GLS_MODE=recovery bash "$FLOW" gls-max
bash "$FLOW" power
```

预期为六路逐位自检 `LAB_GLS_SIX_PASS`，每路至少 35 位，恢复场景检查指定槽的失锁与重捕。测试平台在外部时钟上升沿采样上一拍 PAD 输出，与输出延迟预算对应。日志按角落和场景保存。先定位编译缺模型、`sdf.log` 的实例/IOPATH/时序检查匹配，再定位仿真的 X/Z、时序违例或首个比特错误。现有 TSMC90 非单调单元存在 28 条 IOPATH 模型不匹配，拦截日志已保存，实验室模型应重新核对。

默认记录 RF 样本 45,830,400–46,485,120 的稳定跟踪区间，区间内以 16.368 MHz 定速送 IF。其余功能检查采用加速握手。VCD 包含 DUT 全层次，转换前按实际记录边界平移时间戳，检查 SAIF 时长、`tb/dut`、时钟翻转和活动覆盖。功耗报告包含内部、开关、漏电及总功耗，条件取同版 DDC/SDC 和实际 SS 库。查看 `reports/power/activity.rpt`、`power.rpt`、`power_hierarchy.rpt`。

每次综合默认上限 30 分钟，单个 GLS 场景默认上限 1 小时。查看各阶段 `logs/*/result.json`、`time.txt` 和 `resources.csv`。结束后执行 `pgrep -af 'dc_shell|common_shell_exec|simv'` 确认本次进程退出。新运行使用新 `LAB_OUT` 保存已有证据。
