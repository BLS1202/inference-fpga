#! /usr/bin/env python3
"""Generate Q12 RMSNorm input and reference output files."""

from argparse import ArgumentParser
from math import isqrt
from pathlib import Path
from random import Random


FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1
DEFAULT_EPS_Q24 = 168


def sat(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def trunc_divide(numerator: int, denominator: int) -> int:
    """Match SystemVerilog signed division, which truncates toward zero."""
    if numerator < 0:
        return -((-numerator) // denominator)
    return numerator // denominator


def hex_value(value: int, width: int) -> str:
    return f"{value & ((1 << width) - 1):0{(width + 3) // 4}x}"


def random_q12(rng: Random, max_abs: float) -> int:
    limit = min(INT16_MAX, int(round(max_abs * SCALE)))
    return rng.randint(-limit, limit)


def rmsnorm_q12(values: list[int], eps_q24: int) -> list[int]:
    sum_squares = sum(value * value for value in values)
    rad = (sum_squares // len(values)) + eps_q24
    root = isqrt(rad)
    if root == 0:
        return [0] * len(values)

    return [
        sat(trunc_divide(value << FRAC_BITS, root), INT16_MIN, INT16_MAX)
        for value in values
    ]


def write_mem(path: Path, values: list[int], width: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(hex_value(value, width) for value in values) + "\n",
        encoding="ascii",
    )


def format_matrix(values: list[int]) -> str:
    return "  " + " ".join(f"{value / SCALE: .6f}" for value in values)


def main() -> None:
    parser = ArgumentParser(description="Generate RMSNorm input/reference files.")
    parser.add_argument("--n-embd", type=int, default=16)
    parser.add_argument("--outdir", default="generated/rmsnorm")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--max-abs", type=float, default=2.0)
    parser.add_argument("--eps-q24", type=int, default=DEFAULT_EPS_Q24)
    args = parser.parse_args()

    if args.n_embd <= 0:
        raise ValueError("--n-embd must be positive")
    if args.max_abs < 0 or args.max_abs > 7.999:
        raise ValueError("--max-abs should be in range 0..7.999 for signed Q3.12")
    if args.eps_q24 < 0:
        raise ValueError("--eps-q24 must be non-negative")

    rng = Random(args.seed)
    outdir = Path(args.outdir)
    x = [random_q12(rng, args.max_abs) for _ in range(args.n_embd)]
    y = rmsnorm_q12(x, args.eps_q24)

    write_mem(outdir / "rmsnorm_input.mem", x, 16)
    write_mem(outdir / "rmsnorm_expected.mem", y, 16)

    report = [
        f"Q format: signed Q3.{FRAC_BITS} input and output",
        f"N_EMBD={args.n_embd} EPS_Q24={args.eps_q24}",
        "",
        "Input x (float):",
        format_matrix(x),
        "",
        "Expected RMSNorm output (float):",
        format_matrix(y),
        "",
    ]
    (outdir / "values_float.txt").write_text("\n".join(report), encoding="ascii")

    print(f"wrote {outdir / 'rmsnorm_input.mem'}")
    print(f"wrote {outdir / 'rmsnorm_expected.mem'}")
    print(f"wrote {outdir / 'values_float.txt'}")


if __name__ == "__main__":
    main()
