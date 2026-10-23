# 简化 BDI 单星串行捕获实验

仅以 `work/teacher_bdi_capture/README.md` 和《简化BDI信号发生器和捕获判断说明.docx》为规范。正式验收源为原样的 `bdi_signal_source.sv`、`bdi_prn_code_pkg.sv`，默认 **MEO-6 / PRN 6、发送起始相位10、零多普勒**。

本次实际结果：相位0开始，每失败一窗推进1码片；第11窗在相位10捕获，`I=0, Q=-57288, energy=57288`。后两窗保持相位10，`Q=+57288/-57288`，能量均为57288；首次命中只发一拍 `hit`。连续输入每16368拍一个 `dump`。完整搜索及两窗复核共212784个有效样点。

## 运行与交付入口

先将老师提供的 ZIP 解压到工程根目录的 `work/teacher_bdi_capture/`，避免多套一层目录。复现必需文件为：

```text
work/teacher_bdi_capture/
  bdi_signal_source.sv
  bdi_prn_code_pkg.sv
  README.md
  简化BDI信号发生器和捕获判断说明.docx
```

前两份是仿真直接编译的教师源，后两份是参数及捕获判据的原始规范；资料包的 `reference/` 保留为参考。根目录 `.gitignore` 忽略整个 `work/`，GitHub 不分发教师 ZIP、Word、PDF 或源文件。从 GitHub 克隆后，用户须自行提供这份教师资料；复核检查直接编译的两份教师源；缺失时报告 `BLOCKED_INPUT`，退出码2。README/Word用于查阅规范。

在工程根目录执行，使用已有 WSL Ubuntu / Verilator / g++ / Python，不安装或配置系统环境：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\experiments\bdi_capture\run.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\experiments\bdi_capture\plot.ps1
```

第一条编译并串行运行全部6项自检，生成完整VCD；第二条用已有项目 `work/plotdeps` 中的 Matplotlib 生成五组PNG/SVG。每次运行创建新的 `runs/时间戳/`，不覆盖旧结果。WSL只在独立 `/tmp/bdi_capture_*` 编译目录镜像五个实际SV源文件，并核对SHA256；`run_summary.json` 保存全部命令数组、cwd、耗时、退出码及源哈希。脚本遇到编译失败、断言、超时、缺少PASS标志或评分失败返回非零。

当前验收证据为 **[runs/20261019_164411](runs/20261019_164411)**，`runs/LATEST.txt` 指向最近一次完整通过的运行。

| 内容 | 文件 |
|---|---|
| 独立RTL / 自检TB | [bdi_sliding_capture.sv](rtl/bdi_sliding_capture.sv)、[tb_bdi_capture.sv](tb/tb_bdi_capture.sv) |
| 独立ICD列表模型 | [reference.py](model/reference.py) |
| 完整波形，约161 MB | `runs/20261019_164411/main/capture.vcd` 仅保留在本机，未提交；SHA256 见 [run_summary.json](runs/20261019_164411/run_summary.json) |
| 逐窗结果 / 全样点观测CSV | [windows.csv](runs/20261019_164411/main/windows.csv) 已提交；约15 MB的 `samples.csv` 仅保留在本机，未提交 |
| 编译与仿真命令、退出码、评分 | [run_summary.json](runs/20261019_164411/run_summary.json)、[主用例日志](runs/20261019_164411/main/simulation.log)、[build.log](runs/20261019_164411/build.log) |
| 历史运行时的完整性证明 | [baseline.json](evidence/baseline.json)、[delivery_audit.json](runs/20261019_164411/delivery_audit.json)，保留当时HEAD及原结果 |

### 已有运行复核

复核仅检查五份实际编译源/镜像、六组命令退出码、TB结果及逐窗CSV与摘要的对应关系。历史完整性记录见上表；复核不依赖固定Git提交、其他阶段文件或完整VCD。

```powershell
python -X utf8 experiments/bdi_capture/scripts/audit_delivery.py --run experiments/bdi_capture/runs/20261019_164411
```

默认输出新的 `work/bdi_delivery_audit_时间戳.json`，可用 `--output 新路径.json` 指定。退出码0表示已有证据复核通过，1表示检查失败，2表示教师编译源缺失；不启动仿真。已有输出文件保留，另选新路径。

## RTL及时序

原样实例化工程 `rtl/b1i_prn_gen.sv`，固定选择PRN 6。启动时逐码片建立2046位本地循环表，`ready` 拉高后TB才使能教师源。生成器本身不改动；码表按 `(候选相位+窗内码片序号) mod 2046` 循环，避免2047状态LFSR跨越2046码片边界造成偏差。原捕获前端使用不同的IF2输入映射和±2047本振缩放，本实验另设直接补码入口及教师规定的±7四相本振。

`if_valid && ready` 时接受一个有符号2位样点。每8个有效样点推进一码片；每16368点完成一窗。本地载波按有效样点推进，初相为π/2，`cos=[0,-7,0,7]`、`sin=[7,0,-7,0]`；因此主峰在Q路。无效拍保持码、载波、窗计数和积分状态。

相关定义为 `I += if_sample*cos*c`、`Q += if_sample*sin*c`，二进制本地码0→+1、1→−1。相关乘积6位有符号，累加器与最终I/Q各24位有符号；先扩为25位求绝对值，再以26位无符号相加。默认判据严格为 **完整窗口 `M=abs(I)+abs(Q) >= 8192`**。

末样点沿以 `i_acc+i_product`、`q_acc+q_product` 同时锁存最终I/Q、名为 `energy` 的寄存器和 `result_phase`，产生单拍 `dump`，再清零运行累加器。失败后 `candidate_phase` 加1；首次命中同时产生单拍 `hit`、锁存 `captured_phase` 并置 `acquired`，之后保持候选相位逐窗复核。`acquired` 表示历史捕获成功，保持至复位。

DUT输入只有 `clk/rst_n/if_sample/if_valid`。发送相位、NH/导航位、教师 `dbg_*`、参考向量均未进入DUT；本地表由原PRN硬件独立生成。

## 波形读法

VCD顶层为 `tb_bdi_capture`。教师调试码是组合输出，而IF经过一级寄存器；TB先延迟调试码一拍，再保存“刚被相关器接受”的事务快照。下列 `consumed_*` 与沿后累加器/结果属于同一个样点，应优先使用这些信号对齐观察。

| 观察项目 | VCD信号 |
|---|---|
| 输入时序、接收IF | `clk, rst_n, ready, if_valid, consumed_valid, consumed_if` |
| 接收码 / 本地码 | `consumed_rx_code, consumed_local_code, consumed_local_index` |
| 本地载波 / I/Q相关乘积 | `consumed_cos, consumed_sin, consumed_i_product, consumed_q_product` |
| 累加 / 完整积分结果 | `i_acc, q_acc, i_result, q_result` |
| 能量 / 门限 / 有效脉冲 | `energy, threshold, dump` |
| 本次样点相位 / 下一候选 / 结果 / 命中 | `consumed_phase, candidate_phase, result_phase, captured_phase, hit, acquired` |

仿真使用教师允许的2 ns压缩时钟，VCD中一窗为32.736 μs；物理意义仍为16.368 MHz下1 ms。图片横轴由实际接受样点数换算，初始化不计入搜索时间。不要把VCD时间直接读成物理时间。

- [总览](runs/20261019_164411/figures/01_search_overview.png)：完整相位0→10及后两窗复核；11 ms处能量跨过8192门限，只有首次结果产生hit。
- [错误相位码与乘积](runs/20261019_164411/figures/02_wrong_phase_code_products.png)：相位0码片不重合，Q乘积正负抵消，整窗能量1624。
- [正确相位码与乘积](runs/20261019_164411/figures/03_aligned_phase_code_products.png)：相位10码片重合、Q乘积持续同号；自检另逐点验证三整窗共49104点一致。
- [完整积分比较](runs/20261019_164411/figures/04_full_window_comparison.png)：错误相位低幅波动，正确相位持续积累至−57288；dump后运行累加器清零，独立结果保持。
- [dump/hit逐拍放大](runs/20261019_164411/figures/05_dump_hit_detail.png)：第11窗末样点与结果同时提交，`result_phase` 从9变10，候选保持10，dump/hit宽度各1拍。

窗口中途的 `energy` 是上一完整窗口结果；正确相位初段图中的56属于相位9，直到本窗dump才更新为57288。原始组合乘积在上升沿之后可能已指向下一样点，不能混用其时间基准。

## 自动验收与实测

所有6项自检、编译与独立评分均退出0。正式判据由默认源 `main` 用例验收，其余是同一PRN 6设计的接口/边界补充验证。

| 用例 | 通过内容 |
|---|---|
| main，13窗 | 所有2046本地码片对照独立模型；逐样点IF/码/载波/乘积/累加；13个结果；dump间隔16368拍；第11窗相位10单拍hit；再复核两窗 |
| gaps，13窗 | 插入9165个额外无效拍（另有1拍启动空隙）；积分及dump按有效样点计数；相位和结果与main一致 |
| phase3，6窗 | 仅将同一教师PRN 6源参数改为相位3作为补充；实际在第4窗捕获3并复核两窗，排除把10写死为结果 |
| terminal，2窗 | 首/末点非零，包含2位补码−2；末样点单独贡献非零I；完整结果为(−7,−14)/(−14,−7)，M均21，漏末点即断言失败 |
| zero，13窗 | 零输入逐窗M=0，不产生hit，候选顺序推进 |
| restart，两轮各13窗 | 捕获并复核后，在下一部分窗口异步复位；全部状态归零，再从0搜索并在10重新命中 |

TB在下降沿驱动、上升沿读取被消费值，并在NBA更新后检查；任何不符均 `$fatal` 非零退出。完成末窗后另观察下一拍，验证脉冲清除，日志 `trailing_samples` 单列该尾部样点，不冒充额外完整窗口。

**说明表中的低相关数值差异：** 当前教师循环表、独立ICD模型与真实RTL三者一致；说明书示例低值表有六处略异，未改教师源或降低门限。

| 候选相位 | 说明表M | 当前源/独立模型/RTL M |
|---:|---:|---:|
| 0 | 1736 | 1624 |
| 1 | 0 | 56 |
| 2 | 56 | 56 |
| 3 | 1736 | 1736 |
| 4 | 1792 | 1848 |
| 5 | 56 | 56 |
| 6 | 1792 | 1848 |
| 7 | 1848 | 1848 |
| 8 | 0 | 56 |
| 9 | 0 | 56 |
| 10，三窗 | 57288 | 57288 / 57288 / 57288 |

最大错误相位值1848仍小于8192；捕获相位、主峰及NH变号与教师判据一致。差异细项见 [reference.json](runs/20261019_164411/reference/reference.json)。首次将示例低值当作逐项断言的检查退出1，证据保留于 `runs/20261019_164044/`；并非RTL失败。随后按当前实际源逐点核对，最终验证绑定当前源哈希。`build.log` 保留15条来自未修改教师文件的位宽警告，当前新增RTL/TB无编译警告。

本实验条件为教师默认无噪声、零多普勒、从首个有效样点开始的窗口；噪声、任意NH起点和2046全相位虚警尚未测试。新捕获电路的DC/ICC为 NOT_RUN；原PRN的独立H0 VCS/DC结果见 [H0报告](../../docs/H0_VM_SMOKE.md)。提交和合并经过见 [WORKLOG](../../WORKLOG.md)。
