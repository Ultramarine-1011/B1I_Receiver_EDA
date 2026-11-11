#!/bin/bash
export LC_ALL=C
exec > /tmp/backend_launch.txt 2>&1
set -e
source /home/ICer/.bashrc
set -euo pipefail
ROOT=/home/ICer/ic_eda_backend_20261111
mkdir -p "$ROOT"
tar -xzf /tmp/backend_input.tar.gz -C "$ROOT"
nohup bash "$ROOT/scripts/run.sh" partitions clean_v6_parts_retry1 1500 > "$ROOT/clean_v6_parts_retry1.launcher.log" 2>&1 < /dev/null &
echo "LAUNCHED $!"
