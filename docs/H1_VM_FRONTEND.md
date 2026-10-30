# H1：NH/字同步/D1 的 VCS 与增量综合

2026-10-30。源码基线是 GitHub `origin/main` `697ebaaa66b9e513b153a36870abd5f5653e4a10`，工作树为 `C:\Users\IC\Documents\Codex\2026-09-18\B1I_Receiver_EDA_H1`，分支 `h1-frontend`。虚拟机目录是新建的 `/home/7901_15/B1I_Receiver_EDA_H1`。原先的 `/home/7901_15/B1I_Receiver_EDA` 仍是 2026-10-16 15:20 的 H0 工程，本轮没有写入。

10 ns 时钟、1.0 ns 输入输出延迟、0.2 ns uncertainty、`INVX1` 驱动和 4×`INVX1/INP` 负载沿用 H0 的观察条件。`reset_n` 设了 `set_false_path`。这不是教师签核约束。

H1 是阶段性完成，存在明确未完成项，不是全 PASS。

| 项目 | 状态 |
|---|---|
| NH/D1 VCS | PASS |
| 双子帧导航 VCS | PASS |
| `d1_word_sync` DC | 映射完成。实验性 10 ns 下 slack +0.019 ns。`is_black_box` 计数为 2，对象 UNKNOWN |
| `nh20_sync` DC | INTERRUPTED。映射优化第 14 阶段被中止，不是设计 FAIL |
| `navigation_d1` DC | NOT_RUN |
| 完整接收机 DC / ICC | NOT_RUN |

## 实验室工作区备份

原工作区仍在 `h0-checkpoint` / `7ce233bab04517a997388068e806f5f004cbbbca`。已跟踪修改和未跟踪搬迁文件都还在，没有 `reset`、`clean`、`pull` 或覆盖。

仓库外备份：`C:\Users\IC\Documents\Codex\2026-09-18\B1I_lab_local_backup_20261030`。

| 项 | 结果 |
|---|---|
| 已跟踪补丁 | `tracked_vs_HEAD.patch`，29456 字节，SHA-256 `6fae37877645adca3df265826aa41587cb0f88c95c6b5695e549788ce7fb6086` |
| 补丁可恢复性 | 对干净 HEAD 的临时 index 做 `git apply --cached --check --binary`，退出码 0 |
| 未跟踪文件 | 116 个，逐文件 SHA-256 与原文件一致，失配 0 |
| 凭据 | 未跟踪树中没有私钥、证书、令牌或写成赋值的口令 |
| 机器路径 | `portable/origin.json` 记录了原机目录；`docs/VM_SSH.md` 记录 IP、用户和密钥路径，口令只有占位符 |

搬迁补丁没有并入 H1。`origin/main` 已经为了 BDI 收尾改过 `model/f_integrity_audit.py`、`model/g_delivery_audit.py` 以及部分 F/G 校验脚本，和本机路径适配不是同一处修改。H1 的 VCS/DC 使用虚拟机内的相对路径，不依赖那些 Windows 路径适配。

## 环境与传输

| 项目 | 实际值 |
|---|---|
| 主机 / 用户 | `IC` / `7901_15` |
| VCS | `/opt/Synopsys/VCS2014/bin/vcs`，I-2014.03 |
| Design Compiler | `/opt/Synopsys/Synplify2015/bin/dc_shell`，K-2015.06 |
| 库 | `/home/IC/Foundry_Library/Digital/saed90nm_typ.db`，2168211 字节，可读 |
| Git | 虚拟机没有 `git` |
| 初始化 | `source /home/7901_15/eda_env.sh` |

15 个源、向量和脚本的 Windows SHA-256 与虚拟机 `sha256sum` 一致。RTL 相对 `7ce233b` 没有变化，因此没有为旧 VCS 改测试或做兼容副本。

| 文件 | SHA-256 |
|---|---|
| `student_release/student_release/rtl/nh20_sync.sv` | `86809764aad883d10982b61d6a4b01b5647208009082674a07206896771021ea` |
| `student_release/student_release/rtl/d1_word_sync.sv` | `018be7893e2593b0d1e02d8f53c7ffedea2de8423a3dc676be50108e1b389556` |
| `student_release/student_release/rtl/navigation_d1.sv` | `641b382c753e4fbc64f1f29a1f4b8918c00d06244f87a39fa15874b2ac549174` |
| `tb/tb_nh_d1.sv` | `cec3edfdaa707f18342948d92b4eba56bc19dd29e203143b0b9599b102f35cdc` |
| `tb/tb_navigation_d1.sv` | `84c93d01bdfc275a98cd1220a13f654e49479b195cb99dcd4a4eb669270cb0b4` |
| `tb/vectors/nh_d1/nav_bits.mem` | `5c074c67cc69150fd1c40bc907c2cc732e68941a1fb509d91b1dd152fef0da62` |
| `tb/vectors/nh_d1/expected_words.mem` | `2a4203b5a260fab05c3c37045b4f3cacb48b467dd89ce2256f96208b6d9a0f12` |
| `work/navigation/bits.mem` | `504f6475db32f109fa6a1096ee4b4bb7e0ad40c01d13327c4cecbc2103702112` |
| `work/navigation/raw.mem` | `0abedd1e351089d739ab12c386d5d07b68b76c502f734534dc45a87a2053e8b0` |
| `work/navigation/info.mem` | `3e6e6216ad067cbefd4d775f6f29d2cd39488f45f6f0118bd38f48841970b4a4` |

双子帧向量由 Windows Python 3.12.14 执行 `model/navigation_vectors.py` 生成，打印 `NAVIGATION_VECTORS_PASS frames=2 words=20`。正式 RTL 未改。

## VCS

两次都用 `vcs -sverilog -R`，退出码 0。日志没有编译 Error，也没有断言 `$fatal`。

NH/位同步和 BCH 字恢复，工作目录 `work/h1_vcs_nh`：

- `NH_D1_CASE_PASS` 三条：相位 0 正常极性 111 位 3 字；相位 7 反极性 110 位 3 字；相位 19 正常极性 110 位 3 字。
- `NH_D1_MODULE_PASS cases=3 words=9 phases=0,7,19 polarity=normal,inverted`。
- `$finish` 在 80100000 ps，即 80.100 μs。CPU Time 0.070 s。
- `nh_d1_words.csv` 有 9 行。字 1 的 `word_ref` 在相位 0/7/19 分别是 13094400、12979824、12783408，符合测试里 `(40+30×字序)×20−相位` 再乘 16368 的时间检查。三字纠错数分别是 0、1、2。

双子帧导航，工作目录 `work/h1_vcs_nav`，向量是上面三个 mem：

- `NAVIGATION_D1_CASE_PASS` 两条，相位 7 与 19，各 10 条记录。
- `NAVIGATION_D1_PASS cases=2 two_frame_confirmation=1 backpressure=1 lost_reset=1`。背压和失锁清除是测试中的 `$fatal` 条件，通过后才打印这行。
- `$finish` 在 1540420000 ps，即 1.540420 ms。CPU Time 0.190 s。

日志：`reports/local/h1_vm/vcs_nh_d1.log`、`reports/local/h1_vm/vcs_navigation_d1.log`。

## Design Compiler

入口是 `scripts/h1_dc_d1_word_sync.tcl`、`scripts/h1_dc_nh20_sync.tcl`、`scripts/h1_dc_navigation_d1.tcl`，公共步骤在 `scripts/h1_dc_common.tcl`。`compile` 不是 `compile_ultra`。

### d1_word_sync：已映射

`dc_shell` 退出码 0。日志有 `H1_DC_ANALYZE_OK`、`H1_DC_ELABORATE_OK`、`H1_DC_LINK_OK`、`H1_DC_COMPILE_DONE`，没有 `Error:` 行。实际编译源是 `student_release/student_release/rtl/d1_word_sync.sv`，哈希与上表一致。脚本留下 `DC_COMPILE_WITH_ISSUES`，因为 `H1_BLACKBOX_COUNT` 为 2。

这两个 black-box 属性计数的对象是 UNKNOWN。保存的日志只打印了计数，没有单元名。随后的 `d1_word_sync_blackbox.rpt` 对同一查询结果做 `report_cell`，结果是 0 个单元。`report_area` 的宏/黑盒数和黑盒面积都是 0。`report_reference` 没有任何带 `b` 属性的参考单元；唯一的层次单元是 `d1_word_sync_DW01_sub_0`，属性是 `h`，内部是 SAED90nm 标准单元，资源报告里的实现是 `rpl`。`H1_UNMAPPED_COUNT` 和 `H1_LATCH_COUNT` 都是 0。`check_design` 点名的是 4 个不驱动网络的单元，不是 2 个黑盒。不能从这些证据把计数对应到具体对象，也没有为了追查而重新综合。

| 项目 | 数值 |
|---|---|
| 端口 / 网络 / 单元 | 391 / 1191 / 977 |
| 组合 / 时序 / buf-inv | 732 / 244 / 154 |
| 宏或黑盒 | 0 |
| 组合面积 | 7554.355210 |
| 非组合面积 | 7805.030525 |
| 单元面积 | 15359.385736 |
| 线网面积 | 897.032641 |
| 总面积 | 16256.418376 |
| 关键路径 | 输入 `bit_ref[7]` 到 `start_ref_reg[63]` |
| 数据到达 | 9.696 ns |
| QoR 路径长度 / slack | 8.70 ns / 0.02 ns |
| 详细 slack | 0.019 ns，MET |
| 建立违例 | 0 |
| 保持 WNS / TNS | 0.00 / 0.00 |

`check_design` 返回 1，有 LINT-1 和综合后 `DW01_sub` 的未连接高位端口警告。库是 `saed90nm_typ`。`INVX1/INP` 为 3.52132 fF，输出负载 14.08528 fF。最长路径来自 `bit_ref` 减常数后写入 `start_ref`，在 10 ns 实验时钟下只剩约 0.02 ns。

网表和约束：`reports/local/h1_vm/d1_word_sync_saed90nm.v`、`d1_word_sync_saed90nm.sdc`。面积、时序、资源和 check 报告在同一目录。

### nh20_sync：INTERRUPTED

综合进程跑了约 19 分钟，CPU 约 100%，驻留内存约 489 MB，日志停在 `Mapping Optimization (Phase 14)`，随后按本轮决定发送 SIGTERM。日志含 `Process terminated by kill.`。包装脚本写下 `DC_FAIL` 和退出码 1。该字符串只表示进程被中止，状态归类为 INTERRUPTED，不是设计 FAIL，也没有面积、时序或网表。

当时已经开始映射多个 `DW02_mult` 和 `DW01_add`。内存没有出现失控增长，但是优化阶段还没有结束。不把这次中断称作综合失败根因，也不把它当作可签收结果。

### navigation_d1：NOT_RUN

前两个模块里 `nh20_sync` 没有完成映射，所以没有启动 `navigation_d1`。该模块的组合逻辑里还有变除数的 64 位除法，预计也是长时间综合。本轮按长时间命令跳过，没有为了让它综合完而改算法。

## 下一步

还不能开始完整接收机综合或 H2。阻塞是 `nh20_sync` 综合 INTERRUPTED、`navigation_d1` 综合 NOT_RUN，以及 `d1_word_sync` 那两个 black-box 对象仍为 UNKNOWN。`d1_word_sync` 只在实验性 10 ns 时钟下有 +0.019 ns slack。捕获存储和通道复制仍然是更大的面积风险。ICC、PrimeTime、DRC/LVS 为 NOT_RUN。

本阶段只在 H1 分支保留脚本、本报告和 `reports/local/h1_vm/` 的轻量证据。原工作区的搬迁修改不进入这次提交，也不推送。
