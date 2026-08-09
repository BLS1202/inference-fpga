#! /usr/bin/env python3
"""Train MicroGPT and verify that its Q4.12 RTL weights were exported."""

from argparse import ArgumentParser
from pathlib import Path
import subprocess
import sys


REQUIRED_FILES = (
    "wte_q12.hex",
    "wpe_q12.hex",
    "layer0_attn_wq_q12.hex",
    "layer0_attn_wk_q12.hex",
    "layer0_attn_wv_q12.hex",
    "layer0_attn_wo_q12.hex",
    "layer0_mlp_fc1_q12.hex",
    "layer0_mlp_fc2_q12.hex",
    "lm_head_q12.hex",
)


def main() -> None:
    parser = ArgumentParser(description="Train MicroGPT and export RTL weights.")
    parser.add_argument(
        "--python",
        default=sys.executable,
        help="Python interpreter used to run microgpt.py.",
    )
    args = parser.parse_args()

    microgpt_dir = Path(__file__).resolve().parents[1]
    script = microgpt_dir / "microgpt.py"
    generated_dir = microgpt_dir / "generated"

    subprocess.run(
        [args.python, str(script)],
        cwd=microgpt_dir,
        check=True,
    )

    missing = [name for name in REQUIRED_FILES if not (generated_dir / name).is_file()]
    if missing:
        raise RuntimeError(
            "MicroGPT finished, but these RTL weight files are missing: "
            + ", ".join(missing)
        )

    print(f"verified {len(REQUIRED_FILES)} RTL weight files in {generated_dir}")


if __name__ == "__main__":
    main()
