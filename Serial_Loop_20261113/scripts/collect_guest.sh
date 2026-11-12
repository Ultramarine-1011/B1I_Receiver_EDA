#!/bin/bash
source /home/ICer/.bashrc
set -euo pipefail
export LC_ALL=C
ROOT=/home/ICer/six_tile_asic_v2_20261113
cd "$ROOT"
mkdir -p collection
{
    hostname
    uname -a
    getconf _NPROCESSORS_ONLN
    free -m
    df -h /home
    if /home/synopsys/syn/O-2018.06-SP1/bin/dc_shell -version;then
        echo DC_VERSION_COMMAND_EXIT=0
    else
        echo DC_VERSION_COMMAND_EXIT=$?
    fi
    ls /home/ic_libs
    if test -d /home/share/libs/tsmc28;then echo TSMC28_KNOWN_ROOT_EXISTS;else echo TSMC28_KNOWN_ROOT_ABSENT;fi
} > collection/environment.txt
sha256sum /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db \
    /home/ic_libs/TSMC.90/aci/sc-x/verilog/tsmc090.v \
    /home/synopsys/syn/O-2018.06-SP1/linux64/syn/bin/common_shell_exec \
    /home/synopsys/syn/O-2018.06-SP1/libraries/syn/dw_foundation.sldb \
    /home/ICer/ic_eda_resume_tree_20261112/final_core/reports/mapped.ddc \
    channel_retry1/reports/mapped.ddc bank_retry1/reports/mapped.ddc core_retry1/reports/mapped.ddc \
    > collection/mapping_identity.sha256
sha256sum rtl/*.sv rtl/*.svh scripts/*.tcl scripts/*.sh tb/*.sv tb/*.mem tb/*.if2 \
    teacher/*.sv > collection/tested_inputs.sha256
tar -czf /tmp/six_tile_v2_results.tar.gz \
    channel_retry1/reports bank_retry1/reports core_retry1/reports teacher_capture/reports collection
paths=(unit_normalize/simulation unit_aid/simulation if_fifo/simulation \
    tracking_equivalence/simulation tracking_minimal/simulation tracking_legacy/simulation \
    tracking_minimal_counter/simulation tracking_legacy_counter/simulation \
    six_paced/simulation six_nominal/simulation six_recovery/simulation \
    mapped_normalize/simulation mapped_aid/simulation mapped_normalize/sources.sha256 mapped_aid/sources.sha256 \
    mapped_normalize/tb_normalize.sv mapped_aid/tb_aid.sv \
    channel/reports bank/reports)
for directory in unit_normalize unit_aid if_fifo tracking_equivalence tracking_minimal tracking_legacy tracking_minimal_counter tracking_legacy_counter \
    six_paced six_nominal six_recovery mapped_normalize mapped_aid;do
    paths+=("$directory/compile.log")
done
tar -czf /tmp/six_tile_v2_tests.tar.gz "${paths[@]}"
cd /home/ICer/six_tile_asic_20261113
tar --exclude=mapped.v --exclude=mapped.ddc -czf /tmp/six_tile_v1_evidence.tar.gz \
    channel/reports core/reports bank/reports bank_retry1/reports \
    unit/simulation tracking_equivalence/simulation tracking_minimal/simulation \
    six_paced/simulation six_nominal/simulation six_recovery/simulation
echo ITERATIVE_COLLECTION_PASS
