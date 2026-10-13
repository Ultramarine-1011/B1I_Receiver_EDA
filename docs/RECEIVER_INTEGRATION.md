# E阶段最小接收机集成

唯一状态见[STATUS](../STATUS.md)，范围/验收见[GOAL](../GOAL.md)，命令与失败证据见[WORKLOG](../WORKLOG.md)。A–D设计报告是当时模块证据，不覆盖后续集成。

## 当前结构

学生公共顶层student_receiver_core保持教师端口，默认四通道receiver_multichannel；USE_PCPS=0或CHANNELS=1选择保留的receiver_single用于最小单星回归。stream_unpacker仍为单字16→1、LSB最早、样本引用+0..15；所有在用通道对同一接纳事件消费同一个真实样本。搜索/预置/记录反压不推进信号时间。

捕获：公开IF前4ms → quarter-IF正交解调和/4抽取 → 4096点定点FFT/相关/IFFT → 四窗非相干功率 → PRN6..37顺序、±10kHz/500Hz全粗网格。峰均比门限8为本工程baseline。4092有效点补零到4096有循环码失配，因此RTL候选再用原始65472个IF样本、精确16368点码周期做±16sample/1sample和±250Hz/50Hz局部精搜，四窗非相干峰/能量门限4。两级判决后分配首四个成功PRN；没有场景ID/频率/位置真值输入。

FFT每级/2归一化、Q30 sin/cos常数、signed64乘法、32bit存储；每次24576蝶形拍。信号抽取值×2048，参考码±65536，频域乘积在验证范围内不溢出32bit；功率64bit。128缩放初版低精度造成噪声底偏置，已保存并修正。独立整数golden逐点核对4096首格功率和32个全局候选，浮点峰均比误差最大1.424%<3%；未改变门限。弱噪声峰浮点argmax不稳定，采用全网格整数golden核对候选身份/频偏/功率/均值/判决，失败日志保留。

## 移交与跟踪

分配期间暂停公共输入；各槽的PRN/代次/初值独立锁存，已预置槽不消费样本。全部所需槽预置好后统一RUN。delta=实际首跟踪样本−捕获ref，码初值为 ((16368−lag)%16368)<<29 + delta*(0x20000000+signed Doppler/763)，按2046<<32取商/余数作为周期/相位；载波参考零相位推进delta*(0x40000000+Doppler)，低32bit回绕。计算耗时不进入delta。

复用9.28 PRN/NCO/Mixer/EPL；E/L单边5/16chip。小误差Costas/DLL PI与原质量迟滞保持；真实首星500Hz初频与记录独立估频581Hz相差81Hz，原PLL实跑0锁定后增加启动128窗FLL。FLL只用相邻有效Prompt的dot/cross，折叠BPSK反相，16次vectoring CORDIC，turn Q16×1000为Hz Q16，0.05增益进载波积分；gap/无效窗拒绝相邻差分。载波辅助码步长加总Doppler FCW/763，763=B1I RF/码率的比例。无教师真值/软件捕获答案反馈。

## type1时间、定点与协议

schema3由bit23=1且bits31:30=3识别；generation占低6bit。signed28 Prompt算术右移4至24bit，负数向负无穷取整，单位为原Mixer积分和的1/16。

教师prompt_d1/Route A会按主码周期结束边界解释Prompt记录，且Route A自动优先软件恢复的导航。因此最终type1标记相关窗口结束附近的本地码边界，不能标记窗口首时刻。前端将最后积分样本更新后的码相位/周期/步长与载波相位一起延迟，绑定真实窗口end_ref。framer用最近主码wrap估计边界，sample_index取该边界后的第一个整数样本，code_chip=0、code_fraction为该点的真实NCO分数余量（高24bit），code_epoch为对应周期；carrier_phase按同一整数样本用最后控制字推进/回退。全部是实际NCO状态推导，不是信号真值。原始积分仍严格16368个连续接纳样本，边界记录相邻引用因码速/取整可差±2sample；这不构成丢窗。教师负分数修正可恢复亚样本边界。

导航type2采用同一最近码wrap/分数余量的字结束时间，16bit周期。内部nh20_sync输入仍用真实积分窗口ref，不改回路/位序；通过Prompt→bit元数据寄存保持最后20ms位与码状态关联。type2首次输出要求两个完整连续子帧、合法SFID、SOW及+6s/6*Fs关系，10字缓存使word1 SOW可由word2填充。失锁清NH/帧/时间及待发导航。首个20s实收10个字的raw/information/word_number/SFID/SOW与原始prompt_d1独立恢复逐条一致；当时为旧type1首时刻版本，最终边界版本另见最新回归。

## 共同历元与输出

每个真实sample_ref=n*16368000（n>0）被公共流接纳时，各槽同拍保存计算前的实际码周期/码片/32bit分数、Doppler与身份，输出type4。epoch与PRN唯一；generation只在分配时递增，当前最低四槽不复用。只有locked/NH/frame/time/BCH/active全满足才置measurement_valid。初期仍可发active但无效的观测，不伪造导航时间。

每槽独立Prompt与观测pending槽，导航缓存ready/valid；公共输入在任何槽有积压时反压，Root轮询仲裁寄存输出，valid&&!ready保持256bit。EOF等最后lane、至少4拍相关/NH/D1流水和所有槽/根记录排空，再发唯一type6；部分未完成积分/子帧不会被伪装为有效结果。

## 仿真成本与入口

串行31格点0.194s推估旧全32PRN约8小时，未盲跑。PCPS模块全32PRN345073499拍/102.305s。四星真实2s教师player/writer入口实跑433s，g++ -O3版本1s333s。直接C++时钟入口仅负责公开IF2握手/2bit重排和原样32字节LE记录，全部捕获/环路/导航/观测在同一RTL；1s与未改教师player/writer3984个非end记录非cycle字段逐bit一致，实跑228s。新type1 framer的合成数值回归PASS。长场景用scripts/run_fast_verilator.ps1，source/ROM/SVH/driver SHA256随运行保存；SkipBuild必须匹配已编译源码manifest。原始教师文件保持不变。实际100s结果只以最终日志为准，正在运行不构成PASS。
