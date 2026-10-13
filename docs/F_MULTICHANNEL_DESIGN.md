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

## 当前实施细化

CH1/2/4/12统一PCPS多槽路径，USE_PCPS=0仍保留原单星串行回归。冷捕获按既有默认全PRN网格、成功数达槽数或扫描结束后统一RUN；RUN独立后台FSM捕4ms窗并顺序计算/精搜。重复PRN直接跳过，无空闲槽则延后新搜索，不抢健康星；部分满载扫描会丢弃多余候选。PCPS FINISHED可由新request重启，refine保留默认±16sample/±250Hz；仅自生成短TB缩网格。

后台新槽预约effective_ref=processed_samples+4096，码/载波按capture_ref→effective_ref推进；最长2046拍预置期间健康槽继续处理，待预约样本前忽略新槽ready。slot_available要求已排空且根输出没有该槽已承诺记录。分配只接受当前search_task、合法PRN、当前窗及该PRN失锁之后的新窗。generation从1递增；schema3只有6bit，63代后明确退休，避免隐式wrap。

失锁在曾锁定后撤销时或初次拉入2秒仍未锁时触发；2秒为本工程恢复基线而非课程门限。超时仅由processed_samples差分计量，不能组合依赖sample_ready（首次长TB已暴露并修复反馈）。release清tracker/NH/D1、未承诺Prompt/OBS及SOW，保留valid&&!ready已承诺记录，之后发type3并释放。输入索引错误撤销所有槽有效性、禁止新分配，继续排空并在end置underrun，不产生伪有效。

EOF取消PCPS（未完成精搜不再分配），公共最后16lane和至少4拍流水、每槽/根pending全部排空后唯一end；EOF本身不产生失锁。只有实际epoch且槽已到effective_ref才形成OBS；完整合法NAV条件仍是measurement_valid的必要条件。

## 真实证据范围

F3当前channel_bank 196416样本/206440拍：1/2/4/12同PRN逐窗一致、47个人工控制epoch/槽、每个公共样本被各运行槽接受；不是一秒真实OBS。channel_reuse：保持旧承诺记录、type3、排空、代次2、未来样本前NCO保持、reset。manager控制注入12满载/重复/旧任务窗/失锁/重分配/退休/背压已PASS。

f3_recovery自生成主码/NH双星，12槽，3.2s/52377600样本/57456502拍、主机182.724s：新星加入、后台抓窗/计算与持续跟踪、PRN6自然失锁、候选错误拉入超时释放、再次搜索后末段两星≥100锁定窗，end计数/flags正确。它不是12星同时实收、不是40dB-Hz/D1场景或正式P08。首0.8s测试只查重分配曾PASS；强化锁定检查FAIL及组合反馈FAIL保留，不能引用早版PASS为完整恢复。

公开IF默认4已实跑2s输入停顿/输出反压和20s完整NAV/OBS：40NAV/4有效共同OBS，原检查及Route A19历元PASS；20s输出非end80100条与E前缀逐bit一致（仅cycle字段排除）。原100s交付/哈希保留，F未重复100s。十二NAV分层Prompt120字隔离和原E0三例/尾部回归亦PASS。持续实时吞吐和12星完整D1/PVT尚未验证，见SYNTHESIS_READINESS与PERFORMANCE_EVALUATION。
