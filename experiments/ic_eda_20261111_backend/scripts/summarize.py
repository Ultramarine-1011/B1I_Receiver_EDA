"""Summarize actual reports and verify the V6 reconstruction and timing profiles."""
import csv
import hashlib
import json
from pathlib import Path
import re

experiment = Path(__file__).resolve().parent.parent
repository = experiment.parents[1]
night = repository / "experiments/ic_eda_20261110/night_opt"


def value(text, pattern, convert=float):
    match = re.search(pattern, text)
    return convert(match[1]) if match else None


def critical_path(text):
    first = text.split("  Startpoint:", 1)[1].split("  slack (", 1)[0]
    blocks = {}
    pending = ""
    for line in first.splitlines():
        stripped = line.strip()
        if stripped and not re.match(r"^[-+\d.# ]", stripped):
            pending = stripped
        match = re.search(r"([-+]?\d+\.\d+)\s+([-+]?\d+\.\d+)\s*[rf]?\s*$", line)
        if not match:
            continue
        for name in ("pll_ratio", "dll_ratio", "fll_phase", "carrier_conversion", "feedback_aid", "code_conversion"):
            if name + "/" in pending:
                arrival = float(match[2])
                blocks.setdefault(name, []).append(arrival)
    return {"start": first.splitlines()[0].strip(),
            "end": re.search(r"Endpoint:\s+(.+)", first)[1].strip(),
            "arrival_ns": value(first, r"data arrival time\s+([-\d.]+)"),
            "blocks": {name: {"input_ns": min(times), "output_ns": max(times),
                              "delay_ns": max(times)-min(times)} for name, times in blocks.items()}}


records = {}
labels = ("clean_v6_parts_retry1", "clean_v6_channel", "fast_v6_parts", "fast_v6_channel", "core6_v6_isolated", "memory_ports")
for label in labels:
    run = experiment / "evidence" / label
    folder = run / "reports"
    if not folder.exists():
        continue
    record = {}
    if (folder / "result.json").exists():
        record["process"] = json.loads((folder / "result.json").read_text())
    log = (folder / "run.log").read_text(errors="replace")
    record["errors"] = re.findall(r"^Error:.*", log, re.M)
    if (run / "runner_exit.txt").exists():
        record["runner_exit"] = int((run / "runner_exit.txt").read_text())
    time = (folder / "time.txt").read_text() if (folder / "time.txt").exists() else ""
    record["peak_rss_kib"] = value(time, r"Maximum resident set size \(kbytes\):\s+(\d+)", int)
    record["cpu_percent"] = value(time, r"Percent of CPU this job got:\s+(\d+)%", int)
    if (folder / "resources.csv").exists():
        with (folder / "resources.csv").open() as stream:
            rows = list(csv.DictReader(stream))
        if rows:
            record["aggregate_peak_rss_kib"] = max(int(row["rss_kib"]) for row in rows)
            record["minimum_available_kib"] = min(int(row["mem_available_kib"]) for row in rows)
            record["maximum_swap_used_kib"] = max(int(row["swap_used_kib"]) for row in rows)
    record["mapped_files_present"] = all((folder / name).exists() for name in ("mapped.v", "mapped.ddc", "mapped.sdc"))
    if (folder / "qor.rpt").exists():
        qor = (folder / "qor.rpt").read_text()
        record.update(area_um2=value(qor, r"Cell Area:\s+([\d.]+)"),
                      leaf_cells=value(qor, r"Leaf Cell Count:\s+(\d+)", int),
                      sequential_cells=value(qor, r"Sequential Cell Count:\s+(\d+)", int),
                      logic_levels=value(qor, r"Levels of Logic:\s+([\d.]+)"),
                      hold_violating_endpoints=value(qor, r"No. of Hold Violations:\s+([\d.]+)", float))
        constraints = (folder / "constraints.rpt").read_text()
        section = constraints.split("max_delay/setup", 1)[1].split("min_delay/hold", 1)[0]
        slacks = [float(x) for x in re.findall(r"\s(-[\d.]+)\s+\(VIOLATED\)", section)]
        record.update(setup_wns_ns=min(slacks) if slacks else 0,
                      setup_tns_reported_endpoint_sum_ns=sum(slacks), setup_violating_endpoints=len(slacks))
        record["worst_hold_ns"] = value((folder / "timing_min.rpt").read_text(), r"slack \([^)]*\)\s+([-\d.]+)")
        record["critical_path"] = critical_path((folder / "timing_max.rpt").read_text())
        sdc = (folder / "mapped.sdc").read_text()
        clocks = re.findall(r"^create_clock.*", sdc, re.M)
        exceptions = re.findall(r"^set_(?:false|multicycle)_path.*", sdc, re.M)
        assert len(clocks) == 1 and "-period 10" in clocks[0]
        assert "module_clk" not in sdc
        assert len(exceptions) == 1 and "set_false_path" in exceptions[0]
        record["clock"] = clocks[0]
        record["exceptions"] = exceptions
    records[label] = record

def normalized(path):
    text = re.sub(r"//[^\n]*", "", path.read_text())
    modules = {}
    for name, header, body in re.findall(r"\bmodule\s+(\S+)\s*\((.*?)\);(.*?)\bendmodule", text, re.S):
        statements = []
        for statement in body.split(";"):
            statement = statement.strip()
            if not statement:
                continue
            declaration = re.match(r"^(wire|input|output|inout|tri)\s+(\[[^]]+\]\s*)?(.*)$", statement, re.S)
            if declaration:
                kind, width, names = declaration.groups()
                statement = kind + (width or "") + ",".join(sorted(names.split(",")))
            statements.append(re.sub(r"\s+", "", statement))
        modules[name] = (re.sub(r"\s+", "", header), sorted(statements))
    return modules

old = night / "evidence/full_v6_cached_10ns/mapped.v"
rebuilt = experiment / "evidence/clean_v6_channel/reports/mapped.v"
old_modules, new_modules = normalized(old), normalized(rebuilt)
assert old_modules.keys() == new_modules.keys()
different_modules = [name for name in old_modules if old_modules[name] != new_modules[name]]
assert different_modules == ["code_nco_PHASE_FRAC32_PERIOD_COUNT_WIDTH32_EPL_HALF_SPACING_NUMERATOR5_EPL_HALF_SPACING_DENOMINATOR16"]
for name in ("clean_v6_channel", "fast_v6_channel"):
    assert not records[name]["errors"]
    assert records[name]["process"]["return_code"] == 0
    assert records[name]["process"]["stop_reason"] is None
assert records["clean_v6_channel"]["area_um2"] == 486269.185663
assert records["clean_v6_channel"]["setup_wns_ns"] == -18.646854
result = {"runs": records, "fresh_v6_netlist_identical_modules": len(old_modules)-len(different_modules),
          "fresh_v6_netlist_different_modules": different_modules,
          "netlist_comparison": "Exact module headers and concurrent statements, allowing wire-declaration/instance ordering. Code NCO is checked by mapped cycle equivalence."}
before, after = records["clean_v6_channel"], records["fast_v6_channel"]
result["optimization"] = {"setup_wns_improvement_ns": after["setup_wns_ns"]-before["setup_wns_ns"],
                           "area_increase_percent": (after["area_um2"] / before["area_um2"] - 1)*100,
                           "rtl_sha256": hashlib.sha256((night / "rtl/tracking_channel_minimal.sv").read_bytes()).hexdigest()}
arrays = []
for name in ("acquisition_pcps.sv", "fft4096_serial.sv"):
    source = (repository / "student_release/student_release/rtl" / name).read_text()
    for width, declarations in re.findall(r"logic\s+(?:signed\s+)?\[(\d+):0\]\s+([^;]+);", source):
        for array, high in re.findall(r"(\w+)\[0:(\d+)\]", declarations):
            bits = (int(width)+1)*(int(high)+1)
            arrays.append({"module_file": name, "array": array, "width": int(width)+1,
                           "depth": int(high)+1, "bits": bits})
assert sum(item["bits"] for item in arrays) == 1768768
result["memory"] = {"arrays": arrays, "state_bits": 1768768, "constant_table_bits_across_two_modules": 524288}
(experiment / "metrics.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps({"optimization": result["optimization"], "fast_path": after["critical_path"],
                  "memory_bits": result["memory"]["state_bits"]}, indent=2))
