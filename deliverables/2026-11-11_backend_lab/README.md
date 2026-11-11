# 2026-11-11 实验室携带包

- 本机已备齐 `LAB_INPUTS.tar.gz` 与 `LAB_INPUTS.tar.gz.sha256`，两文件一同携带。
- 包对应本地提交 `c3ba596902c71b4ea0fe1ff780a01f08037c3cef`，669824 字节，SHA256 为 `8922bd51f757df2905a2499de645a043006419c2ab89a3415bedffad295072a0`。
- [LAB_RUNBOOK](../../experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md) 给出解包、preflight、八位探针和分阶段执行命令。
- [结果与实际限制](../../experiments/ic_eda_20261111_backend/REPORT.md) 记录 TSMC90 预演、六通道超时和模型缺口。
- [Git 中的同版证据包](../../experiments/ic_eda_20261111_backend/evidence/LAB_INPUTS.tar.gz) 可用于恢复本机携带包。校验文件已随本目录保存。

Linux 在本目录运行 `sha256sum -c LAB_INPUTS.tar.gz.sha256`，然后按运行清单解包。包内运行清单保留原验证版本，外层导航与打包命令在本次整理中更新。重建会输出到后端实验的 `work/`。

该包包含源码、脚本、六星 IF 和独立比特真值。工艺库与门级模型由实验室提供。TSMC28 六通道正式综合、SDF 与功耗等待实际实验室条件。
