"""Portable Python 2.7/3 stdlib checks for the lab flow and its local smoke."""
from __future__ import print_function
import decimal
import glob
import hashlib
import json
import os
import re
import sys


def read(path):
    with open(path, "r") as stream:
        return stream.read()


def files(paths):
    for path in paths:
        if os.path.isdir(path):
            for directory, _, names in os.walk(path):
                for name in names:
                    yield os.path.join(directory, name)
        else:
            yield path


def model_paths():
    listing = os.environ.get("STD_MODELS_F", "")
    if not listing or not os.path.isfile(listing):
        raise ValueError("Set STD_MODELS_F to a list of the matching standard-cell timing Verilog files")
    paths = [line.strip() for line in read(listing).splitlines() if line.strip() and not line.lstrip().startswith("#")]
    if os.environ["LOCAL_PROBE"] == "0":
        paths.append(os.environ["PAD_MODEL"])
    for path in paths:
        if not os.path.isabs(path) or not os.path.isfile(path):
            raise ValueError("Model file must be an existing absolute path: " + path)
    return paths


stage = sys.argv[1]
if stage == "logs":
    issues = []
    for path in files(sys.argv[2:]):
        if not path.endswith((".log", ".rpt", ".txt")):
            continue
        for number, line in enumerate(read(path).splitlines(), 1):
            if re.search(r"^\s*(Error:|Fatal:|Error-\[|Fatal-\[)|Warning-\[SDF|Timing violation|timing violation|\$[a-z]*(?:setup|hold|recovery|removal|width|period)\(", line):
                issues.append([path, number, line])
    if issues:
        raise ValueError(json.dumps(issues, indent=2))
    print("LOG_CHECK_PASS")
elif stage == "config":
    names = "STD_TT STD_SS STD_FF PAD_TT PAD_SS PAD_FF TOP LOCAL_PROBE CLOCK_NS IO_MAX_NS IO_MIN_NS INPUT_TRANSITION_NS OUTPUT_LOAD_PF UNCERTAINTY_NS STD_MODELS_F PAD_MODEL GLS_MODE DUMP_BEGIN_SAMPLE DUMP_END_SAMPLE".split()
    result = dict((name, os.environ.get(name, "")) for name in names)
    for name in "CLOCK_NS IO_MAX_NS IO_MIN_NS INPUT_TRANSITION_NS OUTPUT_LOAD_PF UNCERTAINTY_NS".split():
        value = decimal.Decimal(result[name])
        if not value.is_finite() or value < 0 or (name == "CLOCK_NS" and value == 0):
            raise ValueError("Invalid numeric constraint: " + name)
    if decimal.Decimal(result["IO_MIN_NS"]) > decimal.Decimal(result["IO_MAX_NS"]):
        raise ValueError("IO_MIN_NS exceeds IO_MAX_NS")
    print(json.dumps(result, indent=2))
elif stage == "inputs":
    repo = os.environ["REPO_ROOT"]
    experiment = os.environ["EXPERIMENT_ROOT"]
    paths = list(files([os.environ["LAB_DIR"]]))
    paths.append(os.path.join(experiment, "scripts/reports.tcl"))
    paths.append(os.environ["MONITOR_SCRIPT"])
    if os.environ["LOCAL_PROBE"] == "0":
        paths.extend(glob.glob(os.path.join(repo, "student_release/student_release/rtl/*")))
        paths.extend([os.path.join(repo, "rtl/bds_bb_6ch_pad_top.sv"),
                      os.path.join(repo, "synth/m2_isolate/acquisition_pcps_blackbox.sv"),
                      os.path.join(experiment, "work/stage/rtl/tracking_channel_minimal.sv")])
        if os.environ["SYNTH_MODE"] == "full":
            listing = os.environ["PCPS_IMPL_F"]
            paths.append(listing)
            paths.extend(line.strip() for line in read(listing).splitlines() if line.strip() and not line.lstrip().startswith("#"))
    for path in sorted(set(paths)):
        if os.path.isfile(path):
            with open(path, "rb") as stream:
                print(hashlib.sha256(stream.read()).hexdigest() + "  " + path)
elif stage == "environment":
    original = json.loads(read("output/config.json"))
    numeric = set("CLOCK_NS IO_MAX_NS IO_MIN_NS INPUT_TRANSITION_NS OUTPUT_LOAD_PF UNCERTAINTY_NS".split())
    for name in "STD_TT STD_SS STD_FF PAD_TT PAD_SS PAD_FF TOP LOCAL_PROBE CLOCK_NS IO_MAX_NS IO_MIN_NS INPUT_TRANSITION_NS OUTPUT_LOAD_PF UNCERTAINTY_NS".split():
        expected, actual = original[name], os.environ.get(name, "")
        if name in numeric:
            expected, actual = decimal.Decimal(expected), decimal.Decimal(actual)
        if expected != actual:
            raise ValueError("Configuration differs from synthesis: " + name)
    print("SYNTHESIS_CONFIGURATION_MATCH")
elif stage == "synthesis":
    log = read("logs/synth/run.log")
    if "LAB_SYNTH_EXPORTED" not in log:
        raise ValueError("Synthesis did not finish exporting")
    for name in ("final.v", "final.ddc", "final.sdc"):
        if os.path.getsize("output/" + name) == 0:
            raise ValueError("Empty design output: " + name)
    if re.search(r"UNMAPPED [1-9]", log):
        raise ValueError("Unmapped leaf cells remain")
    boxes = re.findall(r"^BACKEND_BLACKBOX (\S+) (\S+)", log, re.M)
    isolated = read("output/synthesis_mode.txt").strip() == "isolated" and os.environ["LOCAL_PROBE"] == "0"
    if isolated:
        if len(boxes) != 1 or not boxes[0][1].startswith("acquisition_pcps"):
            raise ValueError("Isolation must contain exactly the intended PCPS black box")
    elif boxes:
        raise ValueError("Unexpected black boxes: " + repr(boxes))
    print("SYNTHESIS_STRUCTURE_PASS isolated=" + str(isolated))
elif stage == "sdf":
    data = read("output/final_max.sdf")
    if "IOPATH" not in data or "TIMINGCHECK" not in data:
        raise ValueError("SDF lacks propagation delays or timing checks")
    values = re.findall(r"\(([-+\d.eE]+):([-+\d.eE]*):([-+\d.eE]+)\)", data)
    distinct = sum(1 for low, _, high in values if float(low) != float(high))
    if not distinct:
        raise ValueError("No distinct MIN/MAX delay values. Inspect the actual min-library pairing")
    print("SDF_TRIPLETS_PASS distinct_min_max=" + str(distinct))
elif stage == "timing":
    constraints = read("reports/export/constraints.rpt")
    if "(VIOLATED)" in constraints:
        raise ValueError("STA violations remain. Inspect reports/export/constraints.rpt before formal GLS")
    qor = read("reports/export/qor.rpt")
    slacks = re.findall(r"Critical Path Slack:\s+([-\d.]+)", qor)
    if not slacks or any(float(value) < 0 for value in slacks):
        raise ValueError("STA setup slack is negative or unavailable")
    timing = read("reports/export/check_timing.rpt")
    for section in ("loops", "unconstrained_endpoints"):
        match = re.search(r"Checking " + section + r"\.\.\.(.*?)(?:Information:|\Z)", timing, re.S)
        if match and re.search(r"Warning:|Error:", match.group(1)):
            raise ValueError("STA coverage issue in " + section)
    print("STA_VIOLATIONS_COVERAGE_PASS")
elif stage == "models":
    paths = model_paths()
    data = read("output/final.v")
    definitions = set(re.findall(r"\bmodule\s+([^\s(]+)", data))
    references = set(re.findall(r"^\s*([^\s()]+)\s+[^\s()]+\s*\(", data, re.M)) - set(["module"])
    available = set()
    for path in paths:
        available.update(re.findall(r"\bmodule\s+([^\s(]+)", read(path)))
    missing = references - definitions - available
    if missing:
        raise ValueError("Missing gate models: " + ", ".join(sorted(missing)))
    with open("sim/models.f", "w") as stream:
        stream.write("\n".join(paths) + "\n")
    match = re.search(r"\bmodule\s+" + re.escape(os.environ["TOP"]) + r"\s*\((.*?)\);", data, re.S)
    if not match:
        raise ValueError("Top module header missing")
    with open("sim/dut_pg.svh", "w") as stream:
        for name in ("VDD", "VSS", "VDDPST", "VSSPST"):
            if re.search(r"\b" + name + r"\b", match.group(1)):
                stream.write(", ." + name + "(" + name + ")\n")
    print("GATE_MODEL_COVERAGE_PASS external_cell_types=" + str(len(references - definitions)))
elif stage == "annotation":
    folder = sys.argv[2]
    data = "\n".join(read(path) for path in files([folder]) if path.endswith(".log"))
    if not re.search(r"SDF", data, re.I) or re.search(r"[1-9]\d*\s+(?:annotation\s+)?errors", data, re.I):
        raise ValueError("Review SDF annotation logs")
    print("SDF_ANNOTATION_LOG_CHECK_PASS")
elif stage == "clip-vcd":
    source, target, interval = sys.argv[2:]
    bounds = [decimal.Decimal(value) for value in read(interval).split()]
    if len(bounds) != 2 or bounds[1] <= bounds[0]:
        raise ValueError("Activity interval is incomplete")
    # The TB reports ns. Convert to the actual VCD tick unit before clipping.
    # Stream the potentially large DUT hierarchy instead of holding it in RAM.
    timescale = []
    in_timescale = False
    header_complete = False
    with open(source) as stream, open(target, "w") as output:
        for line in stream:
            output.write(line)
            if "$timescale" in line:
                in_timescale = True
            if in_timescale:
                timescale.append(line)
                if "$end" in line:
                    in_timescale = False
            if "$enddefinitions" in line:
                header_complete = True
                break
        match = re.search(r"\$timescale\s+(\d+)\s*(fs|ps|ns|us|ms|s)\s+\$end", "".join(timescale))
        factors = dict(fs=decimal.Decimal("0.000001"), ps=decimal.Decimal("0.001"), ns=decimal.Decimal(1),
                       us=decimal.Decimal(1000), ms=decimal.Decimal(1000000), s=decimal.Decimal(1000000000))
        if not match or not header_complete:
            raise ValueError("Unsupported VCD timescale")
        unit = decimal.Decimal(match.group(1)) * factors[match.group(2)]
        first, last = [int(value / unit) for value in bounds]
        for line in stream:
            if line.startswith("#"):
                tick = int(line[1:].strip())
                if tick > last:
                    break
                if tick < first:
                    raise ValueError("Unexpected activity before selected window")
                output.write("#" + str(tick - first) + "\n")
            elif "$dumpoff" in line:
                break
            else:
                output.write(line)
        output.write("#" + str(last - first) + "\n")
    print("VCD_WINDOW_NS", str(bounds[1] - bounds[0]))
elif stage == "saif":
    data = read("activity/run.saif")
    duration = re.search(r"\(DURATION\s+([\d.]+)\)", data)
    if not duration or float(duration.group(1)) <= 0 or not re.search(r"\(INSTANCE\s+tb\s", data) or not re.search(r"\(INSTANCE\s+dut\s", data):
        raise ValueError("SAIF duration or tb/dut hierarchy is missing")
    clock = re.search(r"\((?:pad_clk|clk)\s+.*?\(TC\s+(\d+)\)", data, re.S)
    if not clock or int(clock.group(1)) < 2:
        raise ValueError("SAIF clock activity is missing")
    if os.environ["LOCAL_PROBE"] == "0":
        interval = "activity/interval_max_" + os.environ["GLS_MODE"] + ".txt"
        bounds = [decimal.Decimal(value) for value in read(interval).split()]
        scale = re.search(r"\(TIMESCALE\s+([\d.]+)\s+(fs|ps|ns|us|ms|s)\)", data)
        factors = dict(fs=decimal.Decimal("0.000001"), ps=decimal.Decimal("0.001"), ns=decimal.Decimal(1),
                       us=decimal.Decimal(1000), ms=decimal.Decimal(1000000), s=decimal.Decimal(1000000000))
        if not scale or len(bounds) != 2:
            raise ValueError("SAIF activity interval or timescale is missing")
        actual_ns = decimal.Decimal(duration.group(1)) * decimal.Decimal(scale.group(1)) * factors[scale.group(2)]
        if abs(actual_ns - (bounds[1] - bounds[0])) > decimal.Decimal("0.001"):
            raise ValueError("SAIF duration differs from the recorded power interval")
    print("SAIF_DURATION_HIERARCHY_PASS", duration.group(1))
elif stage == "power":
    data = read("reports/power/power.rpt")
    for field in ("Cell Internal Power", "Net Switching Power", "Cell Leakage Power", "Total Dynamic Power"):
        if field not in data:
            raise ValueError("Missing power component: " + field)
    if re.search(r"SAIF.*(?:not annotated|not found|failed)", read("logs/power/run.log"), re.I):
        raise ValueError("Activity annotation failed")
    activity = read("reports/power/activity.rpt")
    annotated = re.search(r"Nets\s+(\d+)\(([\d.]+)%\)", activity)
    if not annotated or int(annotated.group(1)) == 0:
        raise ValueError("No nets annotated from SAIF")
    print("SAIF_NET_ANNOTATION_PERCENT", annotated.group(2))
    print("POWER_COMPONENTS_PASS")
else:
    raise ValueError("Unknown check: " + stage)
