"""Run the six-channel attempt and a bounded single-channel fallback. Python 2/3."""
from __future__ import print_function
import json
import os
import signal
import subprocess
import time


def now():
    with open("/proc/uptime") as stream:
        return float(stream.read().split()[0])


class BudgetExpired(Exception):
    pass


def stop(signum, frame):
    raise BudgetExpired("Outer synthesis budget expired")


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
root = os.path.abspath(os.environ["LAB_OUT"])
flow = os.path.join(os.environ["LAB_DIR"], "run_lab.sh")
window = min(5980, float(os.environ.get("LAB_SYNTH_WINDOW_S", "5980")))
if window <= 0:
    raise ValueError("LAB_SYNTH_WINDOW_S must be positive")
start = now()
summary = {"status": "FAILURE", "reason": "No completed mapping", "attempts": [],
           "synthesis_window_s": window, "reserved_until_120min_s": 7200 - window,
           "primary_scope": "six-channel real PAD, PCPS/FFT storage isolated",
           "fallback_scope": "single tracking channel, no PAD or acquisition"}


def run(stage, directory, budget, extra):
    environment = os.environ.copy()
    # A laboratory run always maps its own technology. External DDC reuse is
    # limited to the checkpoint produced by this invocation's primary attempt.
    environment.pop("CHANNEL_CHECKPOINT", None)
    environment.update(extra)
    environment["LAB_OUT"] = directory
    environment["SYNTH_BUDGET"] = str(max(1, int(budget)))
    environment["LAB_JOB_BUDGET_S"] = environment["SYNTH_BUDGET"]
    if not os.path.isdir(directory):
        os.makedirs(directory)
    with open(os.path.join(directory, "runner_stdout.log"), "a") as output:
        code = subprocess.call(["bash", flow, stage], env=environment,
                               stdout=output, stderr=subprocess.STDOUT)
    record = {"stage": stage, "directory": directory,
              "return_code": code, "elapsed_total_s": now() - start,
              "tool_budget_s": budget}
    tool_stage = "preflight" if stage == "preflight" else "synth"
    result_path = os.path.join(directory, "logs", tool_stage, "result.json")
    if os.path.isfile(result_path):
        with open(result_path) as source:
            record["tool_result"] = json.load(source)
    if code:
        with open(os.path.join(directory, "runner_stdout.log")) as source:
            record["failure_tail"] = source.read().splitlines()[-12:]
        tool_log = os.path.join(directory, "logs", tool_stage, "run.log")
        if os.path.isfile(tool_log):
            with open(tool_log) as source:
                record["tool_errors"] = [line.strip() for line in source
                                         if line.lstrip().startswith(("Error:", "Fatal:"))][-8:]
    summary["attempts"].append(record)
    return code


try:
    primary = os.path.join(root, "attempt6")
    fallback = os.path.join(root, "fallback_tracking")
    if os.path.exists(primary) or os.path.exists(fallback):
        raise ValueError("Use a fresh LAB_OUT to preserve previous results")
    primary_env = {"SYNTH_SCOPE": "six", "LOCAL_PROBE": "0"}
    preflight_code = run("preflight", primary, 120, primary_env)
    primary_code = preflight_code
    if preflight_code == 0:
        primary_budget = min(4500, max(1, window - (now() - start) - 1230))
        primary_code = run("synth-hier", primary, primary_budget, primary_env)
    if primary_code == 0:
        summary["status"] = "SUCCESS"
        summary["reason"] = "Six-channel isolated-storage mapping and structural checks completed"
        summary["result_directory"] = primary
    else:
        remaining = window - (now() - start) - 30
        if remaining <= 0:
            raise BudgetExpired("No time remains for the single-channel fallback")
        fallback_env = {"SYNTH_SCOPE": "channel", "LOCAL_PROBE": "0",
                        "TOP": "tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1"}
        checkpoint = os.path.join(primary, "output", "channel")
        if os.path.isfile(os.path.join(checkpoint, "checkpoint.sha256")):
            fallback_env["CHANNEL_CHECKPOINT"] = checkpoint
        fallback_code = run("synth-channel", fallback, min(2100, remaining), fallback_env)
        if fallback_code == 0:
            summary["status"] = "PARTIAL_SUCCESS"
            summary["reason"] = "Receiver-core attempt failed, tracking fallback and structural checks completed"
            summary["result_scope"] = "single_tracking_channel"
            summary["result_directory"] = fallback
        else:
            summary["reason"] = "Receiver-core attempt and tracking fallback failed, inspect their tool and runner logs"
except BudgetExpired as error:
    summary["reason"] = str(error)
finally:
    summary["elapsed_s"] = now() - start
    with open(os.path.join(root, "summary.json"), "w") as output:
        json.dump(summary, output, indent=2)
    print(json.dumps(summary, indent=2))
raise SystemExit(0 if summary["status"] in ("SUCCESS", "PARTIAL_SUCCESS") else 1)
