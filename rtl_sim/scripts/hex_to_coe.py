#!/usr/bin/env python3
"""Convert one-word-per-line hexadecimal files to Vivado COE files."""

from __future__ import annotations

import argparse
from pathlib import Path


def read_hex_words(path: Path, width: int) -> list[str]:
    words: list[str] = []

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        value = line.split("#", 1)[0].strip()
        if not value:
            continue

        value = value.rstrip(",;").strip()
        if value.lower().startswith("0x"):
            value = value[2:]

        try:
            number = int(value, 16)
        except ValueError as exc:
            raise ValueError(f"{path}:{line_number}: invalid hex value: {value!r}") from exc

        if number < 0 or number >= (1 << width):
            raise ValueError(
                f"{path}:{line_number}: value {value!r} does not fit in {width} bits"
            )

        words.append(f"{number:0{(width + 3) // 4}X}")

    if not words:
        raise ValueError(f"{path}: no hexadecimal values found")

    return words


def write_coe(path: Path, words: list[str], width: int, pad_to: int | None) -> None:
    if pad_to is not None:
        if pad_to < len(words):
            raise ValueError(
                f"cannot pad {path.name}: {len(words)} values exceed depth {pad_to}"
            )
        words = words + ["0" * ((width + 3) // 4)] * (pad_to - len(words))

    path.write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        + ",\n".join(words)
        + ";\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--input", type=Path, help="single input .hex file")
    source.add_argument("--indir", type=Path, help="directory containing .hex files")
    parser.add_argument("--output", type=Path, help="single output .coe file")
    parser.add_argument("--outdir", type=Path, help="directory for converted .coe files")
    parser.add_argument("--width", type=int, default=16, help="word width in bits (default: 16)")
    parser.add_argument(
        "--pad-to",
        type=int,
        help="optional BRAM depth; append zero words until this depth",
    )
    args = parser.parse_args()

    if args.width <= 0 or args.width % 4 != 0:
        parser.error("--width must be a positive multiple of 4")

    if args.input is not None:
        if args.output is None:
            parser.error("--output is required with --input")
        jobs = [(args.input, args.output)]
    else:
        if args.output is not None:
            parser.error("--output cannot be used with --indir")
        if args.outdir is None:
            parser.error("--outdir is required with --indir")
        jobs = [
            (path, args.outdir / f"{path.stem}.coe")
            for path in sorted(args.indir.glob("*.hex"))
        ]
        if not jobs:
            parser.error(f"no .hex files found in {args.indir}")

    for input_path, output_path in jobs:
        words = read_hex_words(input_path, args.width)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        write_coe(output_path, words, args.width, args.pad_to)
        print(f"wrote {output_path} ({len(words)} words before padding)")


if __name__ == "__main__":
    main()
