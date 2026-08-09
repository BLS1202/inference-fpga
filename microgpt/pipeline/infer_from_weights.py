"""Run one MicroGPT inference step from exported Q4.12 weight files.

This script does not train the model. It loads the flat hex files exported by
microgpt.py and evaluates the same one-layer MicroGPT forward path in Python.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
VOCAB_SIZE = 27
BLOCK_SIZE = 16
N_EMBD = 16
N_HEAD = 4
HEAD_DIM = 4


def signed_q12(word: str) -> float:
    value = int(word, 16)
    if value & 0x8000:
        value -= 1 << 16
    return value / SCALE


def q12_bits(value: float) -> tuple[int, int]:
    """Return saturated signed integer and 16-bit representation."""
    fixed = max(-32768, min(32767, int(round(value * SCALE))))
    return fixed, fixed & 0xFFFF


def load_matrix(path: Path, rows: int, cols: int) -> list[list[float]]:
    words = [line.strip() for line in path.read_text(encoding="ascii").splitlines()]
    expected = rows * cols
    if len(words) != expected:
        raise ValueError(f"{path}: expected {expected} values, found {len(words)}")
    return [
        [signed_q12(words[row * cols + col]) for col in range(cols)]
        for row in range(rows)
    ]


def load_weights(directory: Path) -> dict[str, list[list[float]]]:
    specs = {
        "wte": ("wte_q12.hex", VOCAB_SIZE, N_EMBD),
        "wpe": ("wpe_q12.hex", BLOCK_SIZE, N_EMBD),
        "wq": ("layer0_attn_wq_q12.hex", N_EMBD, N_EMBD),
        "wk": ("layer0_attn_wk_q12.hex", N_EMBD, N_EMBD),
        "wv": ("layer0_attn_wv_q12.hex", N_EMBD, N_EMBD),
        "wo": ("layer0_attn_wo_q12.hex", N_EMBD, N_EMBD),
        "fc1": ("layer0_mlp_fc1_q12.hex", 4 * N_EMBD, N_EMBD),
        "fc2": ("layer0_mlp_fc2_q12.hex", N_EMBD, 4 * N_EMBD),
        "lm": ("lm_head_q12.hex", VOCAB_SIZE, N_EMBD),
    }
    return {
        name: load_matrix(directory / filename, rows, cols)
        for name, (filename, rows, cols) in specs.items()
    }


def linear(vector: list[float], matrix: list[list[float]]) -> list[float]:
    return [sum(weight * value for weight, value in zip(row, vector)) for row in matrix]


def rmsnorm(vector: list[float]) -> list[float]:
    scale = 1.0 / math.sqrt(sum(value * value for value in vector) / len(vector) + 1e-5)
    return [value * scale for value in vector]


def softmax(values: list[float]) -> list[float]:
    maximum = max(values)
    exponentials = [math.exp(value - maximum) for value in values]
    total = sum(exponentials)
    return [value / total for value in exponentials]


def run_step(
    weights: dict[str, list[list[float]]],
    token_id: int,
    pos_id: int,
    keys: list[list[float]],
    values: list[list[float]],
) -> tuple[list[float], list[list[float]], list[list[float]]]:
    x = [a + b for a, b in zip(weights["wte"][token_id], weights["wpe"][pos_id])]
    x = rmsnorm(x)

    residual = x
    normalized = rmsnorm(x)
    query = linear(normalized, weights["wq"])
    key = linear(normalized, weights["wk"])
    value = linear(normalized, weights["wv"])
    keys = keys + [key]
    values = values + [value]

    context: list[float] = []
    for head in range(N_HEAD):
        begin = head * HEAD_DIM
        end = begin + HEAD_DIM
        query_head = query[begin:end]
        scores = [
            sum(query_head[i] * saved_key[begin + i] for i in range(HEAD_DIM))
            / math.sqrt(HEAD_DIM)
            for saved_key in keys
        ]
        probabilities = softmax(scores)
        context.extend(
            sum(probabilities[t] * values[t][begin + i] for t in range(len(values)))
            for i in range(HEAD_DIM)
        )

    x = linear(context, weights["wo"])
    x = [a + b for a, b in zip(x, residual)]

    residual = x
    x = rmsnorm(x)
    x = [max(0.0, value) for value in linear(x, weights["fc1"])]
    x = linear(x, weights["fc2"])
    x = [a + b for a, b in zip(x, residual)]

    return linear(x, weights["lm"]), keys, values


def main() -> None:
    parser = argparse.ArgumentParser(description="Run one MicroGPT step from Q4.12 weights")
    parser.add_argument("--token-id", type=int, required=True)
    parser.add_argument("--pos-id", type=int, required=True)
    parser.add_argument(
        "--weights",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "generated",
    )
    parser.add_argument(
        "--context-tokens",
        type=int,
        nargs="*",
        default=[],
        help="Earlier tokens used to build the KV cache before the requested step",
    )
    args = parser.parse_args()

    if not 0 <= args.token_id < VOCAB_SIZE:
        parser.error(f"token-id must be in [0, {VOCAB_SIZE - 1}]")
    if not 0 <= args.pos_id < BLOCK_SIZE:
        parser.error(f"pos-id must be in [0, {BLOCK_SIZE - 1}]")
    if args.context_tokens and len(args.context_tokens) != args.pos_id:
        parser.error("the number of context tokens must equal pos-id")

    weights = load_weights(args.weights)
    keys: list[list[float]] = []
    values: list[list[float]] = []

    for position, context_token in enumerate(args.context_tokens):
        if not 0 <= context_token < VOCAB_SIZE:
            parser.error(f"context token {context_token} is outside [0, {VOCAB_SIZE - 1}]")
        _, keys, values = run_step(weights, context_token, position, keys, values)

    logits, _, _ = run_step(weights, args.token_id, args.pos_id, keys, values)
    next_token = max(range(VOCAB_SIZE), key=logits.__getitem__)

    print(f"input token : {args.token_id}")
    print(f"input pos   : {args.pos_id}")
    print(f"next token  : {next_token}")
    print(f"max logit   : {logits[next_token]:.8f}")
    print("logits:")
    print(" ".join(f"{value:.8f}" for value in logits))
    print("logits Q4.12:")
    print(" ".join(f"0x{q12_bits(value)[1]:04x}({q12_bits(value)[0]})" for value in logits))


if __name__ == "__main__":
    main()
