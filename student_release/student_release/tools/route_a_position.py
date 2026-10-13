"""Route-A post-processing: receiver BIN -> D1 ephemeris -> common-epoch PVT.

The script uses only records emitted by the receiver.  It does not read the
signal-source truth directory or a RINEX observation file.  Type-2 records
provide D1 words/time anchors and type-4 records provide simultaneous code
states for all tracking channels.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import asdict, dataclass
import json
import math
from pathlib import Path
import sys
from typing import Iterable

import numpy as np

from decode_records import decode
from prompt_d1 import recover_navigation


FS = 16_368_000.0
CHIP_RATE = 2_046_000.0
CODE_PERIOD = 0.001
CODE_EPOCH_WRAP = 65.536
WEEK_SECONDS = 604_800.0
C = 299_792_458.0
MU = 3.986004418e14
OMEGA_E = 7.2921150e-5
B1I_RF = 1_561_098_000.0
EARTH_A = 6_378_137.0
EARTH_F = 1.0 / 298.257222101
PREAMBLE = 0b11100010010


@dataclass(frozen=True)
class Ephemeris:
    prn: int
    week: int
    toc: float
    a0: float
    a1: float
    a2: float
    aode: int
    crs: float
    delta_n: float
    m0: float
    cuc: float
    e: float
    cus: float
    sqrt_a: float
    toe: float
    cic: float
    omega0: float
    cis: float
    i0: float
    crc: float
    omega: float
    omega_dot: float
    idot: float
    health: int
    tgd1: float
    tgd2: float
    aodc: int


@dataclass(frozen=True)
class TimeModel:
    """Robust affine mapping from receiver samples to D1 transmit time."""

    prn: int
    generation: int
    reference_sample: float
    reference_sow: float
    transmit_scale: float
    anchor_count: int
    inlier_count: int
    residual_rms_m: float
    residual_max_m: float


def read_records(path: Path) -> list[dict]:
    data = path.read_bytes()
    if not data or len(data) % 32:
        raise ValueError("receiver BIN is empty or not aligned to 32-byte records")
    return [decode(data[offset:offset + 32]) for offset in range(0, len(data), 32)]


def _int_bits(value: int, width: int) -> list[int]:
    return [(value >> shift) & 1 for shift in range(width - 1, -1, -1)]


def _take(bits: list[int], cursor: list[int], width: int) -> int:
    value = 0
    for bit in bits[cursor[0]:cursor[0] + width]:
        value = (value << 1) | bit
    cursor[0] += width
    return value


def _signed(value: int, width: int) -> int:
    return value - (1 << width) if value & (1 << (width - 1)) else value


def decode_subframe(words: list[int]) -> dict[str, int]:
    if len(words) != 10:
        raise ValueError("a D1 subframe needs exactly ten words")
    bits = _int_bits(words[0], 26)
    for word in words[1:]:
        bits.extend(_int_bits(word & ((1 << 22) - 1), 22))
    if len(bits) != 224:
        raise AssertionError("D1 information length changed")

    cursor = [0]
    result: dict[str, int] = {
        "preamble": _take(bits, cursor, 11),
        "reserved": _take(bits, cursor, 4),
        "subframe_id": _take(bits, cursor, 3),
        "sow": _take(bits, cursor, 20),
    }
    sfid = result["subframe_id"]
    if sfid == 1:
        fields = (
            ("health", 1), ("aodc", 5), ("urai", 4), ("week", 13),
            ("toc", 17), ("tgd1", 10), ("tgd2", 10),
            ("alpha0", 8), ("alpha1", 8), ("alpha2", 8), ("alpha3", 8),
            ("beta0", 8), ("beta1", 8), ("beta2", 8), ("beta3", 8),
            ("a2", 11), ("a0", 24), ("a1", 22), ("aode", 5),
        )
    elif sfid == 2:
        fields = (
            ("delta_n", 16), ("cuc", 18), ("m0", 32), ("e", 32),
            ("cus", 18), ("crc", 18), ("crs", 18), ("sqrt_a", 32),
            ("toe_msb", 2),
        )
    elif sfid == 3:
        fields = (
            ("toe_middle", 10), ("toe_lsb", 5), ("i0", 32), ("cic", 18),
            ("omega_dot", 24), ("cis", 18), ("idot", 14),
            ("omega0", 32), ("omega", 32), ("reserved_tail", 1),
        )
    elif sfid in (4, 5):
        fields = (("reserved_aux", 1), ("page", 7), ("aux_payload", 178))
    else:
        raise ValueError(f"invalid D1 subframe id {sfid}")
    for name, width in fields:
        result[name] = _take(bits, cursor, width)
    if cursor[0] != 224 or result["preamble"] != PREAMBLE:
        raise ValueError("invalid D1 information header")
    return result


def collect_subframes(records: Iterable[dict]) -> dict[int, list[dict[str, int]]]:
    current: dict[tuple[int, int], dict] = {}
    complete: dict[int, list[dict[str, int]]] = defaultdict(list)
    for record in records:
        if record["type"] != "navigation" or not record.get("bch_valid"):
            continue
        key = (int(record["prn"]), int(record["generation"]))
        number = int(record["word_number"])
        if number == 1:
            current[key] = {
                "sfid": int(record["subframe_id"]),
                "words": [int(record["information"])],
            }
            continue
        state = current.get(key)
        if state is None or number != len(state["words"]) + 1:
            current.pop(key, None)
            continue
        if int(record["subframe_id"]) != state["sfid"]:
            current.pop(key, None)
            continue
        state["words"].append(int(record["information"]))
        if number == 10:
            try:
                decoded = decode_subframe(state["words"])
            except ValueError:
                current.pop(key, None)
                continue
            decoded["last_sample_index"] = int(record["sample_index"])
            decoded["generation"] = key[1]
            complete[key[0]].append(decoded)
            current.pop(key, None)
    return complete


def build_ephemerides(subframes: dict[int, list[dict[str, int]]]) -> dict[int, Ephemeris]:
    result: dict[int, Ephemeris] = {}
    for prn, frames in subframes.items():
        by_generation: dict[int, dict[int, dict[str, int]]] = defaultdict(dict)
        for frame in frames:
            if frame["subframe_id"] in (1, 2, 3):
                by_generation[frame["generation"]][frame["subframe_id"]] = frame
        candidates = [
            group for group in by_generation.values()
            if all(number in group for number in (1, 2, 3))
        ]
        if not candidates:
            continue
        latest = max(
            candidates,
            key=lambda group: max(group[number]["last_sample_index"] for number in (1, 2, 3)),
        )
        sf1, sf2, sf3 = latest[1], latest[2], latest[3]
        toe_raw = (sf2["toe_msb"] << 15) | (sf3["toe_middle"] << 5) | sf3["toe_lsb"]
        pi = math.pi
        eph = Ephemeris(
            prn=prn,
            week=sf1["week"],
            toc=sf1["toc"] * 2.0**3,
            a0=_signed(sf1["a0"], 24) * 2.0**-33,
            a1=_signed(sf1["a1"], 22) * 2.0**-50,
            a2=_signed(sf1["a2"], 11) * 2.0**-66,
            aode=sf1["aode"],
            crs=_signed(sf2["crs"], 18) * 2.0**-6,
            delta_n=_signed(sf2["delta_n"], 16) * pi * 2.0**-43,
            m0=_signed(sf2["m0"], 32) * pi * 2.0**-31,
            cuc=_signed(sf2["cuc"], 18) * 2.0**-31,
            e=sf2["e"] * 2.0**-33,
            cus=_signed(sf2["cus"], 18) * 2.0**-31,
            sqrt_a=sf2["sqrt_a"] * 2.0**-19,
            toe=toe_raw * 2.0**3,
            cic=_signed(sf3["cic"], 18) * 2.0**-31,
            omega0=_signed(sf3["omega0"], 32) * pi * 2.0**-31,
            cis=_signed(sf3["cis"], 18) * 2.0**-31,
            i0=_signed(sf3["i0"], 32) * pi * 2.0**-31,
            crc=_signed(sf2["crc"], 18) * 2.0**-6,
            omega=_signed(sf3["omega"], 32) * pi * 2.0**-31,
            omega_dot=_signed(sf3["omega_dot"], 24) * pi * 2.0**-43,
            idot=_signed(sf3["idot"], 14) * pi * 2.0**-43,
            health=sf1["health"],
            tgd1=_signed(sf1["tgd1"], 10) * 1e-10,
            tgd2=_signed(sf1["tgd2"], 10) * 1e-10,
            aodc=sf1["aodc"],
        )
        if eph.health == 0 and 0.0 <= eph.e < 1.0 and eph.sqrt_a > 0.0:
            result[prn] = eph
    return result


def _week_delta(seconds: float) -> float:
    if seconds > WEEK_SECONDS / 2:
        return seconds - WEEK_SECONDS
    if seconds < -WEEK_SECONDS / 2:
        return seconds + WEEK_SECONDS
    return seconds


def broadcast_state(eph: Ephemeris, sow: float) -> tuple[np.ndarray, float]:
    tk = _week_delta(sow - eph.toe)
    semi_major = eph.sqrt_a * eph.sqrt_a
    mean = eph.m0 + (math.sqrt(MU / semi_major**3) + eph.delta_n) * tk
    eccentric = mean
    for _ in range(20):
        step = (eccentric - eph.e * math.sin(eccentric) - mean) / (1.0 - eph.e * math.cos(eccentric))
        eccentric -= step
        if abs(step) < 1e-14:
            break
    sin_e, cos_e = math.sin(eccentric), math.cos(eccentric)
    true_anomaly = math.atan2(math.sqrt(1.0 - eph.e**2) * sin_e, cos_e - eph.e)
    phi = true_anomaly + eph.omega
    du = eph.cus * math.sin(2.0 * phi) + eph.cuc * math.cos(2.0 * phi)
    dr = eph.crs * math.sin(2.0 * phi) + eph.crc * math.cos(2.0 * phi)
    di = eph.cis * math.sin(2.0 * phi) + eph.cic * math.cos(2.0 * phi)
    u = phi + du
    radius = semi_major * (1.0 - eph.e * cos_e) + dr
    inclination = eph.i0 + eph.idot * tk + di
    xo, yo = radius * math.cos(u), radius * math.sin(u)
    node = eph.omega0 + (eph.omega_dot - OMEGA_E) * tk - OMEGA_E * eph.toe
    cn, sn = math.cos(node), math.sin(node)
    ci, si = math.cos(inclination), math.sin(inclination)
    xyz = np.array((xo * cn - yo * ci * sn, xo * sn + yo * ci * cn, yo * si))
    dt = _week_delta(sow - eph.toc)
    relativity = -2.0 * math.sqrt(MU) * eph.e * eph.sqrt_a * sin_e / C**2
    clock = eph.a0 + eph.a1 * dt + eph.a2 * dt * dt + relativity
    return xyz, clock


def rotate_earth(xyz: np.ndarray, travel_seconds: float) -> np.ndarray:
    angle = OMEGA_E * travel_seconds
    ca, sa = math.cos(angle), math.sin(angle)
    x, y, z = xyz
    return np.array((ca * x + sa * y, -sa * x + ca * y, z))


def code_time(record: dict) -> float:
    phase = (int(record["code_chip"]) + int(record["code_fraction"]) / 2.0**32) / CHIP_RATE
    return int(record["code_epoch"]) * CODE_PERIOD + phase


def build_time_models(anchors: Iterable[dict]) -> dict[tuple[int, int], TimeModel]:
    """Fit one sample-to-D1-time line per tracked satellite generation.

    A single recovered word boundary has about one correlator-sample of timing
    noise.  Fitting all BCH-valid boundaries greatly reduces that noise and
    also estimates the actual code-time scale instead of relying on one
    carrier-Doppler estimate.  A small 3-MAD rejection pass removes isolated
    boundary decisions; no signal-source truth is used.
    """
    grouped: dict[tuple[int, int], list[dict]] = defaultdict(list)
    for item in anchors:
        if (item.get("type") == "navigation"
                and item.get("software_recovered")
                and item.get("bch_valid") and item.get("time_valid")
                and int(item.get("word_number", 0)) >= 2):
            grouped[(int(item["prn"]), int(item["generation"]))].append(item)

    result: dict[tuple[int, int], TimeModel] = {}
    for (prn, generation), items in grouped.items():
        if len(items) < 3:
            continue
        items.sort(key=lambda item: int(item["sample_index"]))
        samples = np.asarray([
            int(item["sample_index"]) + float(item.get("sample_fraction", 0.0))
            for item in items
        ], dtype=np.float64)
        wrapped = np.asarray([
            int(item["sow"]) + 0.6 * int(item["word_number"])
            for item in items
        ], dtype=np.float64)
        first_sow = float(wrapped[0])
        times = np.asarray([
            first_sow + _week_delta(float(value) - first_sow)
            for value in wrapped
        ], dtype=np.float64)
        reference_sample = float(np.mean(samples))
        x = (samples - reference_sample) / FS
        design = np.column_stack((np.ones(len(x)), x))
        inliers = np.ones(len(x), dtype=bool)
        coefficients, *_ = np.linalg.lstsq(design, times, rcond=None)
        for _ in range(4):
            residual = times - design @ coefficients
            center = float(np.median(residual[inliers]))
            mad = float(np.median(np.abs(residual[inliers] - center)))
            sigma = max(1e-12, 1.4826 * mad)
            proposed = np.abs(residual - center) <= 3.0 * sigma
            if (int(np.count_nonzero(proposed)) < max(3, len(items) // 2)
                    or np.array_equal(proposed, inliers)):
                break
            inliers = proposed
            coefficients, *_ = np.linalg.lstsq(
                design[inliers], times[inliers], rcond=None)
        residual_m = (times - design @ coefficients) * C
        selected = residual_m[inliers]
        result[(prn, generation)] = TimeModel(
            prn=prn,
            generation=generation,
            reference_sample=reference_sample,
            reference_sow=float(coefficients[0]),
            transmit_scale=float(coefficients[1]),
            anchor_count=len(items),
            inlier_count=int(np.count_nonzero(inliers)),
            residual_rms_m=float(math.sqrt(np.mean(selected * selected))),
            residual_max_m=float(np.max(np.abs(selected))),
        )
    return result


def transmit_sow(snapshot: dict, anchors: list[dict],
                 time_models: dict[tuple[int, int], TimeModel] | None = None,
                 ) -> tuple[float, dict, TimeModel | None]:
    candidates = [
        item for item in anchors
        if item["type"] == "navigation"
        and item.get("bch_valid") and item.get("time_valid")
        and int(item.get("word_number", 0)) >= 2
        and int(item["prn"]) == int(snapshot["prn"])
        and int(item["generation"]) == int(snapshot["generation"])
    ]
    if not candidates:
        raise ValueError("no valid D1 time anchor")
    anchor = min(candidates, key=lambda item: abs(int(item["sample_index"]) - int(snapshot["sample_index"])))
    model = None if time_models is None else time_models.get(
        (int(snapshot["prn"]), int(snapshot["generation"])))
    if model is not None:
        elapsed = (int(snapshot["sample_index"]) - model.reference_sample) / FS
        return ((model.reference_sow + elapsed * model.transmit_scale) % WEEK_SECONDS,
                anchor, model)
    anchor_sample = int(anchor["sample_index"]) + float(anchor.get("sample_fraction", 0.0))
    expected_delta = (int(snapshot["sample_index"]) - anchor_sample) / FS
    anchor_end = int(anchor["sow"]) + 0.6 * int(anchor["word_number"])
    if anchor.get("software_recovered"):
        # The recovered D1 bit boundary supplies an absolute transmit time at
        # an exact receive sample.  Carrier Doppler gives the transmitter-code
        # time scale used by the generated static signal, avoiding DLL code-
        # phase noise of several chips in a quantized multi-star mixture.
        scale = 1.0 + float(anchor.get("carrier_doppler_hz", 0.0)) / B1I_RF
        return (anchor_end + expected_delta * scale) % WEEK_SECONDS, anchor, None
    raw_delta = code_time(snapshot) - code_time(anchor)
    delta = raw_delta + round((expected_delta - raw_delta) / CODE_EPOCH_WRAP) * CODE_EPOCH_WRAP
    return (anchor_end + delta) % WEEK_SECONDS, anchor, None


def solve_position(
    measurements: list[tuple[int, float, Ephemeris]],
) -> tuple[np.ndarray, float, np.ndarray, float, list[dict]]:
    if len(measurements) < 4:
        raise ValueError("at least four satellites are required")
    tx_values = np.array([item[1] for item in measurements])
    reference_sow = float(tx_values.max() + 0.12) % WEEK_SECONDS
    raw_rho = np.array([(_week_delta(reference_sow - tx_sow)) * C for _, tx_sow, _ in measurements])
    states = [broadcast_state(eph, tx_sow) for _, tx_sow, eph in measurements]
    corrected = np.array([
        rho + C * clock - C * eph.tgd1
        for rho, (_, clock), (_, _, eph) in zip(raw_rho, states, measurements)
    ])
    observation_details = [
        {
            "prn": f"C{prn:02d}",
            "transmit_sow": tx_sow,
            "raw_pseudorange_m": float(rho),
            "satellite_clock_s": float(clock),
            "tgd1_s": float(eph.tgd1),
            "corrected_pseudorange_m": float(corrected_rho),
        }
        for (prn, tx_sow, eph), rho, (_, clock), corrected_rho
        in zip(measurements, raw_rho, states, corrected)
    ]

    receiver = np.zeros(3)
    clock_bias = float(np.median([
        rho - np.linalg.norm(state[0]) for rho, state in zip(corrected, states)
    ]))
    residual = np.zeros(len(measurements))
    for _ in range(12):
        design = []
        predicted = []
        for (satellite, _), rho in zip(states, corrected):
            travel = min(0.15, max(0.05, (rho - clock_bias) / C))
            sat_rx = rotate_earth(satellite, travel)
            vector = receiver - sat_rx
            distance = float(np.linalg.norm(vector))
            design.append([*(vector / distance), 1.0])
            predicted.append(distance + clock_bias)
        residual = corrected - np.asarray(predicted)
        update, *_ = np.linalg.lstsq(np.asarray(design), residual, rcond=None)
        receiver += update[:3]
        clock_bias += float(update[3])
        if float(np.linalg.norm(update[:3])) < 1e-4 and abs(float(update[3])) < 1e-4:
            break
    return receiver, clock_bias, residual, reference_sow, observation_details


def ecef_to_geodetic(xyz: np.ndarray) -> tuple[float, float, float]:
    x, y, z = map(float, xyz)
    eccentricity2 = EARTH_F * (2.0 - EARTH_F)
    longitude = math.atan2(y, x)
    p = math.hypot(x, y)
    latitude = math.atan2(z, p * (1.0 - eccentricity2))
    height = 0.0
    for _ in range(12):
        sin_lat = math.sin(latitude)
        prime = EARTH_A / math.sqrt(1.0 - eccentricity2 * sin_lat * sin_lat)
        height = p / max(math.cos(latitude), 1e-15) - prime
        next_lat = math.atan2(z, p * (1.0 - eccentricity2 * prime / (prime + height)))
        if abs(next_lat - latitude) < 1e-13:
            latitude = next_lat
            break
        latitude = next_lat
    return math.degrees(latitude), math.degrees(longitude), height


def position_epochs(records: list[dict], ephemerides: dict[int, Ephemeris]) -> list[dict]:
    anchors = [item for item in records if item["type"] == "navigation"]
    time_models = build_time_models(anchors)
    software_prns = {int(item["prn"]) for item in anchors if item.get("software_recovered")}
    epochs: dict[tuple[int, int], list[dict]] = defaultdict(list)
    for item in records:
        software_valid = (item["type"] == "common_observation"
                          and int(item["prn"]) in software_prns
                          and item.get("active") and item.get("locked"))
        if item["type"] == "common_observation" and (item.get("measurement_valid") or software_valid):
            epochs[(int(item["common_epoch_id"]), int(item["sample_index"]))].append(item)

    positions: list[dict] = []
    for (epoch_id, sample_index), snapshots in sorted(epochs.items()):
        measurements: list[tuple[int, float, Ephemeris]] = []
        anchor_details = []
        for snapshot in snapshots:
            prn = int(snapshot["prn"])
            eph = ephemerides.get(prn)
            if eph is None:
                continue
            try:
                tx_sow, anchor, time_model = transmit_sow(snapshot, anchors, time_models)
            except ValueError:
                continue
            measurements.append((prn, tx_sow, eph))
            anchor_detail = {
                "prn": f"C{prn:02d}",
                "transmit_sow": tx_sow,
                "anchor_sample_index": int(anchor["sample_index"]),
                "anchor_sow": int(anchor["sow"]),
                "anchor_word_number": int(anchor["word_number"]),
            }
            if time_model is not None:
                anchor_detail["time_model"] = {
                    "anchor_count": time_model.anchor_count,
                    "inlier_count": time_model.inlier_count,
                    "transmit_scale": time_model.transmit_scale,
                    "residual_rms_m": time_model.residual_rms_m,
                    "residual_max_m": time_model.residual_max_m,
                }
            anchor_details.append(anchor_detail)
        if len(measurements) < 4:
            continue
        receiver, clock_bias, residual, reference_sow, observation_details = solve_position(measurements)
        latitude, longitude, height = ecef_to_geodetic(receiver)
        positions.append({
            "schema_version": 1,
            "type": "route_a_position",
            "common_epoch_id": epoch_id,
            "sample_index": sample_index,
            "satellites": [f"C{item[0]:02d}" for item in measurements],
            "satellite_count": len(measurements),
            "reference_receive_sow": reference_sow,
            "ecef_m": {"x": float(receiver[0]), "y": float(receiver[1]), "z": float(receiver[2])},
            "geodetic": {"latitude_deg": latitude, "longitude_deg": longitude, "height_m": height},
            "receiver_clock_bias_m": clock_bias,
            "residual_rms_m": float(math.sqrt(np.mean(residual * residual))),
            "residuals_m": {
                f"C{measurement[0]:02d}": float(value)
                for measurement, value in zip(measurements, residual)
            },
            "observations": observation_details,
            "time_anchors": anchor_details,
        })
    return positions


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="receiver_records.bin")
    parser.add_argument("-o", "--output", type=Path, required=True, help="position JSONL")
    parser.add_argument("--ephemeris-json", type=Path, help="optional decoded ephemeris report")
    args = parser.parse_args()

    try:
        records = read_records(args.input)
        software_navigation, software_reports = recover_navigation(records)
        software_keys = {(int(item["prn"]), int(item["generation"]))
                         for item in software_navigation}
        if software_keys:
            records = [item for item in records
                       if not (item.get("type") == "navigation"
                               and (int(item["prn"]), int(item["generation"])) in software_keys)]
        records.extend(software_navigation)
        records.sort(key=lambda item: int(item.get("sample_index", 0)))
        subframes = collect_subframes(records)
        ephemerides = build_ephemerides(subframes)
        positions = position_epochs(records, ephemerides)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"FAIL: {exc}") from exc

    if args.ephemeris_json:
        args.ephemeris_json.parent.mkdir(parents=True, exist_ok=True)
        report = {
            "schema_version": 1,
            "source": str(args.input),
            "complete_subframes": {f"C{prn:02d}": len(items) for prn, items in subframes.items()},
            "ephemerides": {f"C{prn:02d}": asdict(eph) for prn, eph in ephemerides.items()},
            "prompt_d1": software_reports,
        }
        args.ephemeris_json.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "".join(json.dumps(item, ensure_ascii=False) + "\n" for item in positions),
        encoding="utf-8",
    )
    print(
        f"Route A: subframes={sum(map(len, subframes.values()))} "
        f"ephemerides={len(ephemerides)} positions={len(positions)} output={args.output}"
    )
    if not ephemerides:
        raise SystemExit("INCOMPLETE: no complete D1 subframes 1/2/3 were decoded")
    if not positions:
        raise SystemExit("INCOMPLETE: no epoch had at least four valid observations")


if __name__ == "__main__":
    main()
