# F 多通道最小修改设计

起点f8e8de7；plan.md保留9.28冻结方案，教师接口优先；当前状态见STATUS/GOAL。

## F0审查

receiver_multichannel固定4槽、2bit轮询/3bit分配计数；前4ms冷捕获，成功4星即取消搜索，搜索/预置暂停公共输入。student_receiver_core仅准1/4且1绕到旧单星。receiver_channel已经独立NCO/环路/NH/D1/缓存及8bit generation，但没有释放接口，重新分配未显式清pending/导航，失锁无type3管理。RUN共同样本/每秒epoch与pending反压已有基础。acquisition_pcps独占raw/base/FFT历史4ms，计算不需要新输入；refine只读其raw，适合后台计算，无需改跟踪算法。

## 最小实施与验收

1. 参数化CHANNELS=1/2/4/12（2作逐级并发验证），数组/generate/轮询按参数，默认4。短TB可独立注入初始化测数字隔离，不宣称真实IF捕获。
2. 管理占用/候选去重/任务与generation。失锁撤销有效性、type3、排空已承诺记录、释放重捕；重新分配清NCO/同步/时间/未承诺缓存。满载不抢健康星，延后候选，失锁槽优先回收。
3. RUN将同一接纳样本给健康槽及PCPS CAPTURE；PCPS计算读独占历史窗，跟踪继续。EOF取消未完成捕获并排空合法输出，不伪造失锁。
4. 新槽预置用未来effective_sample，按capture_ref推进相位；预置/等待忽略其ready，不停止现有槽；从目标真实样本起接纳。若时刻错过须显式失败/重约，禁止旧相位用于当前。
5. valid&&!ready保持；撤销不丢已承诺事务，禁止旧NAV/OBS混入新generation。共同epoch由每秒真实sample_ref触发、NCO更新前快照；异常不置measurement_valid。
6. 分报信号样本/Fs、硬件周期、明确假定clk处理时间与墙钟；暂停式仿真PASS不等于持续实时通过，正式clk/有限外部缓存未定。

F1–F3证据将在实际回归后追加。F0不重构FFT/环路。
