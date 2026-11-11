# 当前状态

2026-11-11，本地 ASIC 预演与实验室准备已完成并停止。实验分支 `codex/ic-eda-personal-local-smoke-20261110`，起点 `b8b887c`。交付和真实限制见 [本轮报告](experiments/ic_eda_20261111_backend/REPORT.md)。

V6 从源码重建成功，面积 486269.185663 µm²、setup WNS −18.646854 ns。4 ns 内部算术映射预算使 WNS 改善至 −10.948725 ns，面积 499790.599561 µm²，仍有 414 个 setup、1987 个 hold 违例端点。两次完整单通道映射均在 20 分钟内。20万拍 Code NCO 映射比较、20007 组算术映射比较通过。

隔离 PCPS 的唯一一次六通道核心预演完成解析、展开、链接和六路实例检查，映射在 30 分钟预算到期后停止，峰值 RSS 6.30 GiB，最终网表与 PPA 尚未生成。PCPS/FFT 可变数组 1768768 bit，另有逻辑常量表 524288 bit，存储实现仍是全量综合阻塞。

实验室携带包及分阶段入口已准备。TSMC90 八位移位寄存器的 MAX/MIN SDF、VCS、SAIF 与功耗入口实跑通过，活动覆盖100%。TSMC28 六通道正式结果仍待实验室库、匹配门级模型、存储实现及相应资源。原 TSMC90 条件弧模型的28条IOPATH不匹配作为实际缺口保存。

下一执行任务为在实验室按 [LAB_RUNBOOK](experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md) 执行 preflight 和八位探针，核对实际库、模型、许可证、内存与 swap。本轮停止状态及资源检查保存在实验目录，最终本地 commit ID 记录于 `experiments/ic_eda_20261111_backend/work/FINAL_COMMIT.txt`。
