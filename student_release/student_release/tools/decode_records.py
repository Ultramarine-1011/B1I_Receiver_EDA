"""Decode the receiver's fixed 32-byte little-endian records to JSON Lines."""
from __future__ import annotations

import argparse
import json
from pathlib import Path


NAMES = {
    1: "tracking",
    2: "navigation",
    3: "lost",
    4: "common_observation",
    5: "acquisition",
    6: "end",
}


def bits(value: int, lo: int, width: int) -> int:
    return (value >> lo) & ((1 << width) - 1)


def signed(value: int, width: int) -> int:
    return value - (1 << width) if value & (1 << (width - 1)) else value


def decode(raw: bytes) -> dict[str, int | bool | str]:
    value = int.from_bytes(raw, "little")
    kind = bits(value, 0, 8)
    result: dict[str, int | bool | str] = {
        "type": NAMES.get(kind, f"unknown_{kind}"),
        "type_id": kind,
        "prn": bits(value, 8, 6),
        "channel": bits(value, 14, 4),
        "sample_index": bits(value, 32, 64),
    }
    if kind == 1:
        tracking_schema = 3 if bits(value, 23, 1) and bits(value, 30, 2) == 3 else (
            2 if bits(value, 23, 1) else 1)
        generation = bits(value, 24, 6) if tracking_schema == 3 else bits(value, 24, 8)
        result.update(
            locked=bool(bits(value, 18, 1)),
            nh_valid=bool(bits(value, 19, 1)),
            frame_valid=bool(bits(value, 20, 1)),
            time_valid=bool(bits(value, 21, 1)),
            generation=generation,
            schema_version=tracking_schema,
        )
        if tracking_schema == 3:
            result.update(
                prompt_i=signed(bits(value, 96, 24), 24),
                prompt_q=signed(bits(value, 120, 24), 24),
                doppler_word=signed(bits(value, 144, 32), 32),
                carrier_phase=bits(value, 176, 32),
                code_fraction=bits(value, 208, 24) << 8,
                code_chip=bits(value, 232, 11),
                code_epoch=bits(value, 243, 13),
            )
        else:
            result.update(
                prompt_i=signed(bits(value, 96, 32), 32),
                prompt_q=signed(bits(value, 128, 32), 32),
                doppler_word=signed(bits(value, 160, 32), 32),
                code_chip=bits(value, 224, 11),
                code_epoch=bits(value, 235, 16),
            )
        if tracking_schema == 2:
            result["carrier_phase"] = bits(value, 192, 32)
        elif tracking_schema == 1:
            result["code_fraction"] = bits(value, 192, 32)
    elif kind == 2:
        result.update(
            locked=bool(bits(value, 18, 1)),
            nh_valid=bool(bits(value, 19, 1)),
            frame_valid=bool(bits(value, 20, 1)),
            time_valid=bool(bits(value, 21, 1)),
            bch_valid=bool(bits(value, 22, 1)),
            generation=bits(value, 24, 8),
            raw_word=bits(value, 96, 30),
            information=bits(value, 126, 26),
            word_number=bits(value, 152, 4),
            subframe_id=bits(value, 156, 3),
            sow=bits(value, 159, 20),
            corrected_bits=bits(value, 179, 2),
            code_epoch=bits(value, 181, 16),
            code_chip=bits(value, 197, 11),
            code_fraction=bits(value, 208, 32),
        )
    elif kind == 4:
        result.update(
            locked=bool(bits(value, 18, 1)),
            nh_valid=bool(bits(value, 19, 1)),
            frame_valid=bool(bits(value, 20, 1)),
            time_valid=bool(bits(value, 21, 1)),
            measurement_valid=bool(bits(value, 22, 1)),
            active=bool(bits(value, 23, 1)),
            schema_version=bits(value, 24, 8),
            common_epoch_id=bits(value, 96, 32),
            generation=bits(value, 128, 16),
            code_epoch=bits(value, 144, 16),
            code_chip=bits(value, 160, 11),
            code_fraction=bits(value, 171, 32),
            doppler_word=signed(bits(value, 203, 32), 32),
            sow=bits(value, 235, 20),
            bch_valid=bool(bits(value, 255, 1)),
        )
    elif kind == 5:
        result.update(
            detected=bool(bits(value, 18, 1)),
            incomplete=bool(bits(value, 23, 1)),
            lag_samples=bits(value, 96, 14),
            doppler_word=signed(bits(value, 128, 32), 32),
            peak_power=bits(value, 160, 64),
            acquisition_cycles=bits(value, 224, 32),
        )
    elif kind == 6:
        result.update(
            underrun=bool(bits(value, 18, 1)),
            overflow=bool(bits(value, 19, 1)),
            hardware_cycles=bits(value, 96, 64),
            missing_ticks=bits(value, 160, 64),
        )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    data = args.input.read_bytes()
    if len(data) % 32:
        raise SystemExit(f"record file length {len(data)} is not a multiple of 32")
    lines = [json.dumps(decode(data[n : n + 32]), ensure_ascii=False)
             for n in range(0, len(data), 32)]
    text = "\n".join(lines) + ("\n" if lines else "")
    if args.output:
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
