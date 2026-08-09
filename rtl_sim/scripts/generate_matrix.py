#! /usr/bin/env python3
"""Generate signed 16-bit Q4.12 matrix files for matmul_unit simulation."""

from argparse import ArgumentParser
from pathlib import Path
from random import Random


FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1


def sat16(value: int) -> int:
    return max(INT16_MIN, min(INT16_MAX, value))


def random_q12(rng: Random, max_abs: float) -> int:
    """Generate a random Q4.12 value with fractional precision."""
    max_fixed = min(INT16_MAX, int(round(max_abs * SCALE)))
    return rng.randint(-max_fixed, max_fixed)


def hex16(value: int) -> str:
    return f"{value & 0xFFFF:04x}"


def write_mem(path: Path, values: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(hex16(value) for value in values) + "\n", encoding="ascii")


def write_coe(path: Path, values: list[int], depth: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    coe_values = list(values)
    if depth is not None:
        if len(coe_values) > depth:
            raise ValueError("COE data contains more values than the requested depth")
        coe_values.extend([0] * (depth - len(coe_values)))

    entries = ",\n".join(f"{hex16(value)}" for value in coe_values)
    path.write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        f"{entries};\n",
        encoding="ascii",
    )


def format_matrix(values: list[int], rows: int, cols: int) -> str:
    lines = []
    for row in range(rows):
        elements = values[row * cols : (row + 1) * cols]
        lines.append("  " + " ".join(f"{value / SCALE: .6f}" for value in elements))
    return "\n".join(lines)


def write_float_report(
    path: Path,
    a: list[int],
    b: list[int],
    c: list[int],
    m: int,
    k: int,
    n: int,
) -> None:
    report = [
        f"Q format: Q4.{FRAC_BITS}",
        f"Dimensions: A={m}x{k}, B={k}x{n}, C={m}x{n}",
        "",
        "Matrix A (float):",
        format_matrix(a, m, k),
        "",
        "Matrix B (float):",
        format_matrix(b, k, n),
        "",
        "Expected Matrix C (float, fixed-point quantized):",
        format_matrix(c, m, n),
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(report), encoding="ascii")


def write_split_bram_files(
    outdir: Path,
    a: list[int],
    b: list[int],
    m: int,
    k: int,
    n: int,
    bram_depth: int,
) -> None:
    """Write one BRAM initialization file per A row and B column.

    A row BRAMs contain exactly K entries. B column BRAMs contain exactly K
    entries. No padding is added; the Vivado BRAM depth can match the
    generated file contents.
    """
    split_dir = outdir / "split_bram"

    for row in range(m):
        a_row = a[row * k : (row + 1) * k]
        write_mem(split_dir / f"a_row_{row}.mem", a_row)
        write_coe(split_dir / f"a_row_{row}.coe", a_row)

    for col in range(n):
        b_col = [b[row * n + col] for row in range(k)]
        write_mem(split_dir / f"b_col_{col}.mem", b_col)
        write_coe(split_dir / f"b_col_{col}.coe", b_col)

    manifest = [
        f"A BRAM files: {m} (one per A row), {k} values per file",
        f"B BRAM files: {n} (one per B column), {k} values per file",
        "Split BRAM files are not padded; configure each BRAM for its listed depth.",
        "",
        "A file mapping:",
        *[f"a_row_{row}: A[{row}][0:{k - 1}]" for row in range(m)],
        "",
        "B file mapping:",
        *[f"b_col_{col}: B[0:{k - 1}][{col}]" for col in range(n)],
        "",
    ]
    (split_dir / "README.txt").write_text("\n".join(manifest), encoding="ascii")


def matmul_q12(a: list[int], b: list[int], m: int, k: int, n: int) -> list[int]:
    c = []
    for row in range(m):
        for col in range(n):
            acc = 0
            for kk in range(k):
                acc += a[row * k + kk] * b[kk * n + col]
            c.append(sat16(acc >> FRAC_BITS))
    return c


def main() -> None:
    parser = ArgumentParser(description="Generate .mem files for matmul_unit_tb.")
    parser.add_argument("--m", type=int, default=2, help="Rows of matrix A / C.")
    parser.add_argument("--k", type=int, default=3, help="Columns of A / rows of B.")
    parser.add_argument("--n", type=int, default=2, help="Columns of matrix B / C.")
    parser.add_argument("--outdir", default="generated/matmul", help="Output directory.")
    parser.add_argument(
        "--bram-depth",
        type=int,
        default=32,
        help="Number of entries to initialize in the A/B COE files.",
    )
    parser.add_argument("--seed", type=int, default=1, help="Random seed.")
    parser.add_argument(
        "--max-abs",
        type=float,
        default=2,
        help="Maximum absolute floating-point value for generated inputs.",
    )
    args = parser.parse_args()

    if args.m <= 0 or args.k <= 0 or args.n <= 0:
        raise ValueError("matrix dimensions must be positive")
    if args.bram_depth <= 0:
        raise ValueError("--bram-depth must be positive")
    if args.max_abs < 0 or args.max_abs > 7.999:
        raise ValueError("--max-abs should be in range 0..7.999 for signed Q4.12")

    rng = Random(args.seed)
    outdir = Path(args.outdir)

    a = [random_q12(rng, args.max_abs) for _ in range(args.m * args.k)]
    b = [random_q12(rng, args.max_abs) for _ in range(args.k * args.n)]
    c = matmul_q12(a, b, args.m, args.k, args.n)
    if args.bram_depth < max(len(a), len(b)):
        raise ValueError("--bram-depth is smaller than matrix A or B")

    write_mem(outdir / "mat_a.mem", a)
    write_mem(outdir / "mat_b.mem", b)
    write_mem(outdir / "mat_c_expected.mem", c)
    write_coe(outdir / "mat_a.coe", a, args.bram_depth)
    write_coe(outdir / "mat_b.coe", b, args.bram_depth)
    write_coe(outdir / "mat_c_expected.coe", c)
    write_float_report(outdir / "matrices_float.txt", a, b, c, args.m, args.k, args.n)
    write_split_bram_files(outdir, a, b, args.m, args.k, args.n, args.bram_depth)

    print(f"wrote {outdir / 'mat_a.mem'}")
    print(f"wrote {outdir / 'mat_b.mem'}")
    print(f"wrote {outdir / 'mat_c_expected.mem'}")
    print(f"wrote {outdir / 'mat_a.coe'}")
    print(f"wrote {outdir / 'mat_b.coe'}")
    print(f"wrote {outdir / 'mat_c_expected.coe'}")
    print(f"wrote {outdir / 'matrices_float.txt'}")
    print(f"wrote {outdir / 'split_bram'}")
    print(f"M={args.m} K={args.k} N={args.n} DATA_WIDTH=16 FRAC_BITS={FRAC_BITS}")


if __name__ == "__main__":
    main()
