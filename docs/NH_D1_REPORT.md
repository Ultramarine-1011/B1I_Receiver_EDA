# NH/位同步/D1实验结果（2026-10-25交付稿）

2026-10-13实际验证两级RTL：NH20相位搜索/20ms软位，及前导码候选/30bit字/BCH去交织解码。三种相位、正反极性、9字通过；另外当前闭环实际Prompt恢复了29个恒定位。**完整Prompt→位→字实验是合成Prompt模块测试；闭环IF实验仅到恒定位，没有真实D1帧或教师场景导航解调。** 没有生成伪造receiver_records。

## 输入、结构与算法

```mermaid
flowchart LR
    P[1ms Prompt I / ref] --> NH[20相位积分评分 / 400事件训练]
    NH --> BIT[NH擦除 / 20ms软位和符号]
    BIT --> POL[前导码搜索 / 正反极性]
    POL --> W[30bit候选字]
    W --> BCH[BCH15,11 / 两组去交织]
    BCH --> OUT[raw / information / corrected / ref]
```

`nh20_sync.sv`仅接收Prompt事件、signed28bit I和窗口ref。NH20时间顺序为00000100110101001110（ICD5.2.1），每个码1ms、导航位20ms。20个候选按各自NH位置擦除符号，在候选位边界完成20项和；训练400个实际事件，丢弃第一20事件的残缺窗，累积各相位完整位的绝对软和值。最高分大于两倍第二名且非零才锁定，否则重新训练，不能伪造同步。

锁定后仅从下一完整边界输出data_bit、signed34bit soft sum、首Prompt ref；不会将训练期半个位输出。Costas半周模糊保留到前导码极性确认。输入假设是连续真实1ms Prompt；本次空逻辑拍不会增加事件计数。当前无噪声门限标定、跟踪状态门控、参考缺样检测或失步重捕，不能用nh_locked宣称这些场景都正确。

`d1_word_sync.sv`只接收恢复的数据位/ref。搜索11bit前导码11100010010及其补码，确认后统一极性并凑齐30bit字。第1字前15bit不编码，后15bit做BCH(15,11)；其它字分离交错的两组15bit、分别解码后拼成22bit信息（输出26bit，高4bit为0）。记录word_number、raw_word、information、corrected_bits和首位ref；第10字后重新搜索前导码。

这是前导码候选与字边界，不是经过重复6s子帧/字段合理性确认的完整frame/time有效性。未解SOW、星历、页面、完整D1参数，不输出time_valid/measurement_valid或最终type2导航记录。

BCH综合除法 syndrome 与ICD/教师诊断器等价，零syndrome保留，非零在15个单比特syndrome中匹配并翻转。信息位为修正后前11位。每个(15,11)码字可纠正1位；不能检测所有双错，可能误纠正。测试中的2位错误分属两组BCH，各1位，并未声称纠正一个码字内2位错误。

## 数值与时序

- Prompt I signed28bit；20项和signed34bit，无截短/饱和；训练分数unsigned64bit。训练与RUN都只随prompt_valid事件推进。
- 位输出valid为单拍，bit_ref为20个Prompt中首事件的ref。下一级下一拍消费注册位。
- 原始字30bit，information26bit，纠错总数2bit；word_valid为单拍、word_ref首位参考，输出保持到下次字。
- 当前各事件ref间隔16368样本，位间隔327360样本。前导码发现时由最后位ref减10×327360定位字首；缺样/非恒定间隔不在验证范围。
- 模块测试无结果ready；每个输入Prompt间隔至少一个逻辑时钟，低速位/字事件可及时观察。本次未做多通道汇聚或记录背压。

## 实际可复现测试

根目录：`.\scripts\run_local_verilator.ps1 -Task nhd1`。独立Python用多项式x4+x+1长除法生成BCH，再按两组位交错形成字。40个零导航位为训练/等待前缀，随后3个非平凡字；它们仅构成合成Prompt激励，期望信息/纠错数只留TB评分，不进入DUT。每个Prompt幅值±100000，按真实NH与数据符号产生。无噪声，不是教师IF。

| 用例 | 起始NH相位 | 极性 | 恢复位 | 完整字 | 实际结果 |
|---|---:|---|---:|---:|---|
|0|0|正常|111|3|PASS|
|1|7|反相|110|3|PASS|
|2|19|正常|110|3|PASS|

实际`NH_D1_MODULE_PASS cases=3 words=9 phases=0,7,19 polarity=normal,inverted`，退出0，全部字/信息、0/1/2纠错数和时间戳逐事件匹配。例0三个原始字为0x3890b45a、0x1666677c、0x0fac034e；对应information为0x3890b45、0x00aaeab、0x01f0b21。正常/反相都恢复相同字。

证据：reports/local/tb_nh_d1.build.log、.run.log、nh_d1_words.csv；刺激/评分来源tb/vectors/nh_d1/manifest.json及model/nh_d1_vectors.py。

## 真实RTL Prompt连接证据与独立诊断

`.\scripts\run_local_verilator.ps1 -Task nhprompt`先从**当前**tracking_loop.csv的正向已通过用例导出999行，文件只含实际IP/window_ref，不含真实相位/数据字段或伪造记录。RTL重新搜索实际NH相位，实际`NH_ACTUAL_RTL_PROMPT_PASS windows=999 phase=1 bits=29 constant_data_polarity=0`，退出0。phase1来自前端首窗接近真实第二个主码周期，属于评分结果，没有灌入同步器。该IF激励只有NH和恒定导航符号，所以没有前导码或D1字，不能写成完整IF→D1成功。

独立诊断：bundled Python执行`model/nh_d1_validate.py`，调用未改教师prompt_d1.py的decode_word，核对9个实际RTL raw_word/information/corrected_bits，实际PASS/退出0。没有用软件结果替换RTL；未运行教师secondary_solution的完整载波/子帧恢复或定位。

## 未覆盖与交付边界

未验证教师40dB-Hz、全部20相位、多星、缺Prompt、噪声、错误前导码、重复6s帧确认、一个BCH码字多错、完整子帧/星历/SOW及导航记录输出。当前顶层只输出end，完整教师自检仍FAIL，未得到可定位观测。这些是明确缺口，当前9个字为实验模块证据，禁止把它们当作公开场景实收数据提交。

来源：本地ICD2.1第5.1.3、5.2.1、5.2.2节（PDF15–20页的编码/帧材料）；教师prompt_d1.py的独立解码契约；当前RTL与实际日志。本稿为可编辑Markdown，未生成Word/PDF。
