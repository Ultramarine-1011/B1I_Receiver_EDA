# 教师流桥接与结束协议（A）

固定学生顶层端口不变。`stream_unpacker`缓冲一个32 bit字，每次输入握手接收16个样本；lane从0到15，`word_data[2*lane+:2]`直接取码，内部有符号3 bit按-3/-1/+1/+3重构，引用为`word_ref+lane`。教师player已经将文件每字节MSB-first转换成总线LSB-first，学生不再翻转。

缓冲有数据时对输入背压；后级`sample_ready=0`保持lane、数据和引用。最后字握手后禁止新字，只有最后lane被下游接纳才发`input_drained`。当前顶层A阶段为传输基线，后级直接接纳并计数，尚未接捕获或跟踪，不输出锁定/导航/观测记录。

顶层接收计数每次输入握手加16，处理计数每次单样本握手加1。输入引用与期望接收计数不一致则置错误。最后lane完成后进入DRAIN，保留两拍排空预算，再注册唯一type=6（样本数为处理计数；编号错误或接收/处理不等时置错误位）。record背压保持256 bit数据/valid，接收后进入DONE。下一运行须复位，符合教师player只启动一次的限制。后续接算法时必须以实际pending结果确认排空，不能只沿用固定延迟。

## 实际验证

根目录PowerShell：

```powershell
.\scripts\run_local_verilator.ps1 -Task bridge
.\scripts\run_local_verilator.ps1 -Task smoke
.\scripts\run_local_verilator.ps1 -Task frontend
```

- A3：3字48样本，各量化级/首末lane、输入空拍、持续valid等待、下游规律停顿、最后drain；STREAM_UNPACKER_PASS。
- 顶层：3字48样本，6拍record背压保持，唯一且最后end；STUDENT_TRANSPORT_PASS。
- 0.01s：自有wrapper实例化未改教师TB/player，独立$fgetc reader逐样本检查IF2文件MSB-first与解包输出。10230次握手、163680样本、唯一end，STUDENT_FILE_SMOKE_PASS；teacher TB PASS records=1。
- 教师check_records在A阶段明确指定minimum-acquisitions=0，只验证结构：PASS records=1 bytes=32 types={'end':1}。完整self_check仍保持4星/跟踪/导航/观测要求，实际FAIL detected PRNs []（退出1）。这不是接收机功能PASS，不是最终提交文件。
- C1：原9.28 frontend不改算法，当前Verilator回归90000事件/4窗和reload/reset PASS。只是前端，不含闭环。

所有build/run命令与退出码在reports/local/*.log。首次冒烟因自有runner的PowerShell自动变量args冲突导致MAX_BYTES丢失，自动断言失败；修正为plusArgs后实跑通过。失败日志保留tb_student_file_smoke.initial_fail.log。9.28五个关键源哈希与历史manifest一致，frontend来源为9.28 17:13本地文件；详见source_manifest/baseline_crosscheck。

## 限制

未覆盖0字节输入、非16整字尾包、重复start、100秒完整场景或故障输入（教师协议限定整字）。未接真实捕获/闭环/同步/导航；现有32字节end文件仅为冒烟证据。Verilator旧RTL宽度警告保留于build log，未为消警重写冻结RTL。自有入口直接使用WSL Python，避开本机WindowsApps Python占位命令；教师公共脚本不改。
