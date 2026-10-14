# 综合准备与架构风险

G只新增实际周期/服务/FIFO预算，学生RTL及下列F源码风险基线未改。当前没有正式综合/物理结果，H仍须另行授权。G默认4/52s实测平均clk下界22.586541MHz、RUN17.403010MHz、最大冷阻塞269543639拍；假定100MHz约2.695s停顿，原文件调度算术积压约11016200字节。1/4/12数字槽稳态下界17.394/17.403/17.427MHz，不能作为真实12D1持续实时通过。64word有限FIFO实际溢出、102400word仅0.1s有界通过。完整时间域/输入输出服务边界见[G报告](../reports/g_stage/FINAL_REPORT.md)；clk/宏/端口/背压上界及物理时序仍缺。

本轮仅源码/本地Verilator检查，不运行DC/ICC/PT/DRC/LVS，也不把解析/仿真PASS称为ASIC验收。正式宏/工艺/角/clk/IO负载/约束未提供；GNSS尚无正式综合结果。代码证据由 `python3 model/synthesis_inventory.py` 保存文件SHA256和行号到reports/f_stage/synthesis/source_inventory.json。

| 风险与直接代码对象 | 可能影响 | 后续DC阻塞性质 | 最低代价措施/本轮状态 |
|---|---|---|---|
| acquisition_pcps raw[65472]×3bit、base_r/i[16368]×16、code/signal四数组[4096]×32、cos/sin×32、acc_power×64；fft4096 re/im/cos/sin[4096]×32 | 明确声明数组合计2,293,056bit（约280KiB），未计小状态；若展开寄存器，面积/布线巨大，不能把C++内存当SRAM宏 | 功能可解析；正式存储映射/面积/时序收敛依赖宏及端口设计 | 确认工艺宏/同步读延迟；先拆只读ROM与捕获窗/频域工作存储，逐阶段补访存流水，不凭猜测blackbox |
| FFT同拍两地址异步读并写a/b，额外read_address异步读；PCPS外部replay raw异步读 | 单/双口SRAM不能直接表达所有同拍端口；综合成mux+FF或需bank；同步宏会改变load/read/EVALUATE拍数 | 宏接入前的真实结构阻塞，仿真不证明端口可实现 | 列模式端口需求；FFT两bank/分拍蝶形并更新事件延迟；后台捕获窗与refine共享只读一份、计算结束前不覆盖 |
| tracking_channel_minimal两路80bit动态除法、64bit常数换算，16级64bit组合CORDIC；framer/NAV动态64/33bit除法 | 12路复制宽除法/乘法/长组合加法，可能是关键路径与面积主因；窗结束条件门控不自动变成分时硬件 | DC是否支持展开须实跑；目标clk未定，不能称时序已满足 | 首轮DC统计真实关键路径，优先复用/迭代低速DLL/FLL/边界运算，每窗1ms有预算；先保留数值与ready时序 |
| 每通道NCO/Mixer/EPL/环路/NH/D1/测量完全独立；NAV10×256bit缓存、Prompt/OBS/lost/输出寄存 | 12通道复制资源/扇出；仅NAV字缓存12×2560=30720bit，另每槽数据pending约1024bit | 参数化RTL能展开，不代表面积/功耗合格 | 先12槽DC面积层次报告，保持高速相关独立；只对已证关键资源共享，不为理论PPA重写算法 |
| receiver_multichannel AND slot_ready、一字16→1；共同epoch使用64bit除/模；输入和record大扇出 | 暂停输入可保数值但不保证持续实时；同步窗结束或输出堵塞使全输入等待，有限缓存只能承担有界暂停 | 正式持续输入/时钟/输出服务预算缺失，实时验收未通过 | 写清最小服务率、最大停顿和外部存储模型；按正式clk驱动连续输入、缓存高水位/溢出、背压最长值；epoch可在证据需要时改倒计数 |
| 冷捕获/精搜时暂停公共输入，后台用独占4ms历史窗并与跟踪并行 | 冷启动计算等待需要可暂停数据源或足够缓冲；后台结果比参考信号晚，运动误差/年龄影响拉入 | 公开文件ready契约允许暂停；持续实时验收仍未证明 | 使用同一capture_ref→effective_ref传播；新增槽预置预约4096未来样本（最长2046逻辑拍），不足时全ready保护；随后按正式时钟评估捕获延迟/失效边界 |
| receiver_channel channel_reset_n由release生成、NAV由assign/locked产生异步reset；NH/D1旧逻辑同样依赖locked | 组合复位网络/恢复移除时序/扇出风险，仿真理想无门延迟；端口阻塞时撤销和承诺记录需同时保持 | 不一定阻止DC解析，但真实STA/reset实现必须审查 | 正式综合前评估改同步clear/flush事务，维持已承诺record stable与generation；不随意设false_path掩盖 |
| initial $readmemh ROM文件、initial参数$fatal、$countones与SV数组/变宽cast | ROM初始化综合依赖指定工具流程；旧DC语法/映射不能靠Verilator支持推定 | 正式DC elaboration/link待验证 | ROM manifest/可综合常数或正式ROM宏；参数检查单列仿真；若实际不支持$countones则用固定循环加法；保留基线源不改工具配置 |
| manager recovery_floor[64]×64、多槽失锁同拍更新时间戳、schema3只有6bit generation | 可能多写端口/大mux；第63代后槽明确退休，避免generation隐式回绕混旧记录 | DC映射/长期寿命是后续问题；当前不会静默wrap | 支持PRN6–37仅必要bank，逐条事件仲裁；如需要无限代次先按教师格式确认schema升级；本轮控制TB验证退休 |

## 周期与吞吐边界

Fs=16.368MHz来自教师/指导书；clk未指定。拆包至少17逻辑拍/16样本，理想无其他等待时所需服务clk下界17.391MHz，不能把它当最终目标。短通道bank不含16→1接口，196416样本/206440拍只证明该TB节奏；合成12槽双星包含捕获/反压/重搜，实际数见run日志。

E历史100秒2,009,844,711拍/1,636,800,000样本，总平均clk下界20.09844711MHz；含冷搜索等待，不是F当前实测，也不是持续稳态最大暂停保证。假设100MHz时E总处理时间20.098s只是周期换算；正式clk/IO和宏未定，不宣称真实实时通过。F当前周期由对应run/type6读取，分别列信号秒、周期、假定clk处理秒、主机墙钟。

默认完整PCPS全32PRN/41频点历史345,073,499拍；每候选精搜33×11×65472及预置/流水约2400万拍。新槽4096样本未来预置仅解决PRN加载时基，不抹去搜索计算延迟或运动误差。缩网格测试只证明其范围；正式P01/P03/G仍需要全范围场景统计。

下一正式DC的必需输入：工艺与合法库/宏功能/时序/物理视图、工艺角/电压温度、目标clk、IO延迟/transition/load、复位约束、运行模式/真实例外依据、宏/电源策略及实际非VMware工具环境。资料未具备前保留风险，不虚构最终ASIC条件。
