# 综合准备与架构风险

2026-11-02新增六通道核心`bds_bb_6ch_core`及独立配置/串行导航位接口，功能验证见[六通道报告](../reports/six_channel_20261102/FINAL_REPORT.md)，接口和采样预算见[SIX_CHANNEL_DESIGN](SIX_CHANNEL_DESIGN.md)。2026-11-06 M1 已在虚拟机核对 TSMC28 标准单元三角和 TPHN28 PAD，见[M1报告](../reports/m1_tsmc28_20261106/REPORT.md)。同日 M2 把旋转因子改成 function，并建立 `bds_bb_6ch_pad_top`，见[M2报告](../reports/m2_tsmc28_20261106/REPORT.md)。隔离捕获存储后的顶层能够 link；六通道映射在 1991 MB 虚拟机上被杀掉。下面的“工艺未定”只保留为更早阶段的历史措辞。

PRN 模块已完成 VCS 回归和 SAED90nm 的实验性 DC 综合，条件及结果见 [H0_VM_SMOKE](H0_VM_SMOKE.md)。完整接收机综合、ICC、DRC/LVS 和最终 STA 为 NOT_RUN；下表是源码风险分析。

实际周期、1/4/12数字槽服务、64word FIFO溢出与102400word有界通过，以及持续实时的缺项统一见 [G报告](../reports/g_stage/FINAL_REPORT.md)“吞吐与时间预算”。源码清单入口 `model/synthesis_inventory.py`；历史清单见 `reports/f_stage/synthesis/source_inventory.json`。

| 风险与直接代码对象 | 可能影响 | 后续DC阻塞性质 | 最低代价措施/本轮状态 |
|---|---|---|---|
| acquisition_pcps raw[65472]×3bit、base_r/i[16368]×16、code/signal四数组[4096]×32、cos/sin×32、acc_power×64；fft4096 re/im/cos/sin[4096]×32 | 明确声明数组合计2,293,056bit（约280KiB），未计小状态；若展开寄存器，面积/布线巨大，不能把C++内存当SRAM宏 | 功能可解析；正式存储映射/面积/时序收敛依赖宏及端口设计 | 确认工艺宏/同步读延迟；先拆只读ROM与捕获窗/频域工作存储，逐阶段补访存流水，不凭猜测blackbox |
| FFT同拍两地址异步读并写a/b，额外read_address异步读；PCPS外部replay raw异步读 | 单/双口SRAM不能直接表达所有同拍端口；综合成mux+FF或需bank；同步宏会改变load/read/EVALUATE拍数 | 宏接入前的真实结构阻塞，仿真不证明端口可实现 | 列模式端口需求；FFT两bank/分拍蝶形并更新事件延迟；后台捕获窗与refine共享只读一份、计算结束前不覆盖 |
| tracking_channel_minimal两路80bit动态除法、64bit常数换算，16级64bit组合CORDIC；framer/NAV动态64/33bit除法 | 12路复制宽除法/乘法/长组合加法，可能是关键路径与面积主因；窗结束条件门控不自动变成分时硬件 | DC是否支持展开须实跑；目标clk未定，不能称时序已满足 | 首轮DC统计真实关键路径，优先复用/迭代低速DLL/FLL/边界运算，每窗1ms有预算；先保留数值与ready时序 |
| 每通道NCO/Mixer/EPL/环路/NH/D1/测量完全独立；NAV10×256bit缓存、Prompt/OBS/lost/输出寄存 | 12通道复制资源/扇出；仅NAV字缓存12×2560=30720bit，另每槽数据pending约1024bit | 参数化RTL能展开，不代表面积/功耗合格 | 先12槽DC面积层次报告，保持高速相关独立；只对已证关键资源共享，不为理论PPA重写算法 |
| receiver_multichannel AND slot_ready、一字16→1；共同epoch使用64bit除/模；输入和record大扇出 | 暂停输入可保数值但不保证持续实时；同步窗结束或输出堵塞使全输入等待，有限缓存只能承担有界暂停 | 正式持续输入/时钟/输出服务预算缺失，实时验收未通过 | 写清最小服务率、最大停顿和外部存储模型；按正式clk驱动连续输入、缓存高水位/溢出、背压最长值；epoch可在证据需要时改倒计数 |
| 冷捕获/精搜时暂停公共输入，后台用独占4ms历史窗并与跟踪并行 | 冷启动计算等待需要可暂停数据源或足够缓冲；后台结果比参考信号晚，运动误差/年龄影响拉入 | 公开文件ready契约允许暂停；持续实时验收仍未证明 | 使用同一capture_ref→effective_ref传播；新增槽预置预约4096未来样本（最长2046逻辑拍），不足时全ready保护；随后按正式时钟评估捕获延迟/失效边界 |
| receiver_channel channel_reset_n由release生成、NAV由assign/locked产生异步reset；NH/D1旧逻辑同样依赖locked | 组合复位网络/恢复移除时序/扇出风险，仿真理想无门延迟；端口阻塞时撤销和承诺记录需同时保持 | 不一定阻止DC解析，但真实STA/reset实现必须审查 | 正式综合前评估改同步clear/flush事务，维持已承诺record stable与generation；不随意设false_path掩盖 |
| initial $readmemh ROM文件、initial参数$fatal、$countones与SV数组/变宽cast | ROM初始化综合依赖指定工具流程；旧DC语法/映射不能靠Verilator支持推定 | M2 已确认 VER-281。旋转因子改为 function 后，抽样常数进入映射网表。`$countones` 在 `satellite_manager` 上为 ELAB-939；该模块不在六通道 PAD 顶层层次里 | 旋转因子保持 function，不要改回 `$readmemh`。综合文件列表不要纳入 `satellite_manager`，除非先换成循环加法 |
| manager recovery_floor[64]×64、多槽失锁同拍更新时间戳、schema3只有6bit generation | 可能多写端口/大mux；第63代后槽明确退休，避免generation隐式回绕混旧记录 | DC映射/长期寿命是后续问题；当前不会静默wrap | 支持PRN6–37仅必要bank，逐条事件仲裁；如需要无限代次先按教师格式确认schema升级；本轮控制TB验证退休 |

## 存储与时序规划输入

Fs=16.368MHz；16→1拆包至少17逻辑拍/16样本，理想服务clk下界17.391MHz。E历史100s计2,009,844,711拍/1,636,800,000样本，平均下界20.09844711MHz；假定100MHz时换算20.098s。G当前周期及最大停顿采用上述报告，时钟、IO与宏共同决定持续服务能力。

默认完整PCPS全32PRN/41频点历史345,073,499拍；每候选精搜33×11×65472及预置/流水约2400万拍。新槽4096样本未来预置解决PRN加载时基；搜索计算延迟和运动误差仍需按正式场景评估。

下一正式DC的必需输入：工艺与合法库/宏功能/时序/物理视图、工艺角/电压温度、目标clk、IO延迟/transition/load、复位约束、运行模式/真实例外依据、宏/电源策略及经授权的工具环境。
