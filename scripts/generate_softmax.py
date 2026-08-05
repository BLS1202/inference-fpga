#! /usr/bin/env python3
"""Generate quantized softmax inputs, LUT, and reference output files."""

from argparse import ArgumentParser
from math import exp
from pathlib import Path
from random import Random


FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
DATA_WIDTH = 16
INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1
EXP_ADDR_WIDTH = 12
EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH


def hex16(value: int) -> str:
    return f"{value & 0xFFFF:04x}"


def random_q12(rng: Random, max_abs: float) -> int:
    limit = min(INT16_MAX, int(round(max_abs * SCALE)))
    return rng.randint(-limit, limit)


def write_mem(path: Path, values: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(hex16(value) for value in values) + "\n", encoding="ascii")


def make_exp_lut() -> list[int]:
    return [
        min(INT16_MAX, int(round(exp(-8.0 * address / (EXP_LUT_SIZE - 1)) * SCALE)))
        for address in range(EXP_LUT_SIZE)
    ]


def exp_address(shifted_value: int) -> int:
    exp_min_input = -(8 * SCALE)
    clipped = max(exp_min_input, min(0, shifted_value))
    magnitude = -clipped
    return (magnitude * (EXP_LUT_SIZE - 1)) >> (FRAC_BITS + 3)


def softmax_q12(logits: list[int], exp_lut: list[int]) -> list[int]:
    max_value = max(logits)
    exp_values = [exp_lut[exp_address(value - max_value)] for value in logits]
    exp_sum = sum(exp_values)
    if exp_sum == 0:
        return [0] * len(logits)
    return [((value << FRAC_BITS) // exp_sum) for value in exp_values]


def format_values(values: list[int]) -> str:
    return "  " + " ".join(f"{value / SCALE: .6f}" for value in values)


def main() -> None:
    parser = ArgumentParser(description="Generate softmax input/reference files.")
    parser.add_argument("--vector-size", type=int, default=16)
    parser.add_argument("--outdir", default="generated/softmax")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--max-abs", type=float, default=2.0)
    args = parser.parse_args()

    if args.vector_size <= 0:
        raise ValueError("--vector-size must be positive")
    if args.max_abs < 0 or args.max_abs > 7.999:
        raise ValueError("--max-abs should be in range 0..7.999")

    rng = Random(args.seed)
    outdir = Path(args.outdir)
    exp_lut = make_exp_lut()
    logits = [random_q12(rng, args.max_abs) for _ in range(args.vector_size)]
    probs = softmax_q12(logits, exp_lut)

    write_mem(outdir / "softmax_logits.mem", logits)
    write_mem(outdir / "softmax_expected.mem", probs)
    write_mem(outdir / "exp_lut.mem", exp_lut)

    report = [
        f"Q format: Q4.{FRAC_BITS}",
        f"VECTOR_SIZE={args.vector_size} EXP_LUT_SIZE={EXP_LUT_SIZE}",
        "",
        "Logits (float):",
        format_values(logits),
        "",
        "Expected probabilities (float, quantized):",
        format_values(probs),
        "",
    ]
    (outdir / "values_float.txt").write_text("\n".join(report), encoding="ascii")

    print(f"wrote {outdir / 'softmax_logits.mem'}")
    print(f"wrote {outdir / 'softmax_expected.mem'}")
    print(f"wrote {outdir / 'exp_lut.mem'}")
    print(f"wrote {outdir / 'values_float.txt'}")


if __name__ == "__main__":
    main()
