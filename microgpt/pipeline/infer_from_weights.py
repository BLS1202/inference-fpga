"""Run one MicroGPT inference step from exported Q4.12 weight files.

This script does not train the model. It loads the flat hex files exported by
microgpt.py and evaluates the same one-layer MicroGPT forward path in Python.
"""

from __future__ import annotations

import argparse
import math
import random
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


def load_vocab(path: Path) -> tuple[list[str], int]:
    docs = [line.strip() for line in path.read_text(encoding="ascii").splitlines()]
    chars = sorted(set("".join(doc for doc in docs if doc)))
    bos = len(chars)
    if bos + 1 != VOCAB_SIZE:
        raise ValueError(f"{path}: expected vocab size {VOCAB_SIZE}, got {bos + 1}")
    return chars, bos


def decode_token(token_id: int, chars: list[str], bos: int) -> str:
    if token_id == bos:
        return ""
    return chars[token_id]


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
    trace: dict[str, list[float]] | None = None,
) -> tuple[list[float], list[list[float]], list[list[float]]]:
    token_embedding = weights["wte"][token_id].copy()
    position_embedding = weights["wpe"][pos_id].copy()
    embedding = [a + b for a, b in zip(token_embedding, position_embedding)]
    x = rmsnorm(embedding)

    if trace is not None:
        trace["token_embedding"] = token_embedding
        trace["position_embedding"] = position_embedding
        trace["embedding"] = embedding
        trace["rms0"] = x.copy()

    attn_residual = x.copy()
    normalized = rmsnorm(x)
    if trace is not None:
        trace["attn_rmsnorm"] = normalized.copy()

    query = linear(normalized, weights["wq"])
    key = linear(normalized, weights["wk"])
    value = linear(normalized, weights["wv"])
    keys = keys + [key]
    values = values + [value]

    if trace is not None:
        trace["q"] = query.copy()
        trace["k"] = key.copy()
        trace["v"] = value.copy()
        trace["kv_keys"] = [element for saved_key in keys for element in saved_key]
        trace["kv_values"] = [element for saved_value in values for element in saved_value]

    context: list[float] = []
    all_scores: list[float] = []
    all_probabilities: list[float] = []
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
        all_scores.extend(scores)
        all_probabilities.extend(probabilities)
        context.extend(
            sum(probabilities[t] * values[t][begin + i] for t in range(len(values)))
            for i in range(HEAD_DIM)
        )

    wo = linear(context, weights["wo"])
    attn_output = [a + b for a, b in zip(wo, attn_residual)]

    if trace is not None:
        trace["attention_logits"] = all_scores
        trace["attention_probs"] = all_probabilities
        trace["attention_context"] = context.copy()
        trace["wo"] = wo.copy()
        trace["attention_residual"] = attn_output.copy()

    mlp_residual = attn_output.copy()
    mlp_norm = rmsnorm(attn_output)
    fc1 = linear(mlp_norm, weights["fc1"])
    fc1_relu = [max(0.0, value) for value in fc1]
    fc2 = linear(fc1_relu, weights["fc2"])
    mlp_output = [a + b for a, b in zip(fc2, mlp_residual)]

    if trace is not None:
        trace["mlp_rmsnorm"] = mlp_norm.copy()
        trace["fc1"] = fc1.copy()
        trace["fc1_relu"] = fc1_relu.copy()
        trace["fc2"] = fc2.copy()
        trace["mlp_residual"] = mlp_output.copy()

    logits = linear(mlp_output, weights["lm"])
    if trace is not None:
        trace["lm_logits"] = logits.copy()

    return logits, keys, values


def write_trace(trace_dir: Path, trace: dict[str, list[float]]) -> None:
    """Write every traced vector as readable text and Q4.12 memory data."""
    trace_dir.mkdir(parents=True, exist_ok=True)

    for name, vector in trace.items():
        (trace_dir / f"{name}.txt").write_text(
            " ".join(f"{value:.10f}" for value in vector) + "\n",
            encoding="ascii",
        )
        (trace_dir / f"{name}.mem").write_text(
            "\n".join(f"{q12_bits(value)[1]:04x}" for value in vector) + "\n",
            encoding="ascii",
        )


def print_trace(trace: dict[str, list[float]]) -> None:
    """Print compact Q4.12 values in pipeline order."""
    for name, vector in trace.items():
        values = " ".join(
            f"0x{q12_bits(value)[1]:04x}({q12_bits(value)[0]})" for value in vector
        )
        print(f"{name}:")
        print(f"  {values}")


def run_sample(
    weights: dict[str, list[list[float]]],
    chars: list[str],
    bos: int,
    generate: int,
    temperature: float,
) -> None:
    keys: list[list[float]] = []
    values: list[list[float]] = []
    generated_tokens: list[int] = []
    current_token = bos

    for pos_id in range(min(generate, BLOCK_SIZE)):
        logits, keys, values = run_step(
            weights, current_token, pos_id, keys, values
        )
        probabilities = softmax([logit / temperature for logit in logits])
        next_token = random.choices(range(VOCAB_SIZE), weights=probabilities)[0]
        if next_token == bos:
            break
        generated_tokens.append(next_token)
        current_token = next_token

    print(
        "".join(
        decode_token(token_id, chars, bos) for token_id in generated_tokens
        )
    )


def run_samples(
    weights: dict[str, list[list[float]]],
    chars: list[str],
    bos: int,
    samples: int,
    generate: int,
    temperature: float,
) -> None:
    print("--- inference (new, hallucinated names) ---")
    for sample_idx in range(samples):
        print(f"sample {sample_idx + 1:2d}: ", end="")
        run_sample(weights, chars, bos, generate, temperature)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run MicroGPT inference from Q4.12 weights")
    parser.add_argument("--token-id", type=int)
    parser.add_argument("--pos-id", type=int)
    parser.add_argument(
        "--sample",
        action="store_true",
        help="Generate names starting from the BOS token",
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=17,
        help="Number of names to generate in --sample mode",
    )
    parser.add_argument(
        "--generate",
        type=int,
        default=BLOCK_SIZE,
        help="Maximum number of inference steps in --sample mode",
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=0.5,
        help="Sampling temperature in --sample mode",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed used in --sample mode",
    )
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
    parser.add_argument(
        "--dump-dir",
        type=Path,
        default=Path("generated/reference/intermediates"),
        help="Directory for intermediate .txt and Q4.12 .mem files",
    )
    parser.add_argument(
        "--vocab-source",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "input.txt",
        help="Text file used to rebuild the character vocabulary",
    )
    args = parser.parse_args()

    weights = load_weights(args.weights)

    if args.sample:
        if args.token_id is not None or args.pos_id is not None or args.context_tokens:
            parser.error("--sample cannot be combined with --token-id, --pos-id, or --context-tokens")
        if args.generate < 0:
            parser.error("--generate must be non-negative")
        if args.samples < 0:
            parser.error("--samples must be non-negative")
        if args.temperature <= 0:
            parser.error("--temperature must be positive")
        try:
            chars, bos = load_vocab(args.vocab_source)
            random.seed(args.seed)
            run_samples(
                weights,
                chars,
                bos,
                args.samples,
                args.generate,
                args.temperature,
            )
        except ValueError as exc:
            parser.error(str(exc))
        return

    if args.token_id is None or args.pos_id is None:
        parser.error("provide either --sample or both --token-id and --pos-id")
    if not 0 <= args.token_id < VOCAB_SIZE:
        parser.error(f"token-id must be in [0, {VOCAB_SIZE - 1}]")
    if not 0 <= args.pos_id < BLOCK_SIZE:
        parser.error(f"pos-id must be in [0, {BLOCK_SIZE - 1}]")
    if args.context_tokens and len(args.context_tokens) != args.pos_id:
        parser.error("the number of context tokens must equal pos-id")

    keys: list[list[float]] = []
    values: list[list[float]] = []

    for position, context_token in enumerate(args.context_tokens):
        if not 0 <= context_token < VOCAB_SIZE:
            parser.error(f"context token {context_token} is outside [0, {VOCAB_SIZE - 1}]")
        _, keys, values = run_step(weights, context_token, position, keys, values)

    trace: dict[str, list[float]] = {}
    logits, _, _ = run_step(
        weights, args.token_id, args.pos_id, keys, values, trace=trace
    )
    next_token = max(range(VOCAB_SIZE), key=logits.__getitem__)

    write_trace(args.dump_dir, trace)

    print(f"input token : {args.token_id}")
    print(f"input pos   : {args.pos_id}")
    print(f"next token  : {next_token}")
    print(f"max logit   : {logits[next_token]:.8f}")
    print("logits:")
    print(" ".join(f"{value:.8f}" for value in logits))
    print("logits Q4.12:")
    print(" ".join(f"0x{q12_bits(value)[1]:04x}({q12_bits(value)[0]})" for value in logits))
    print(f"intermediates: {args.dump_dir}")
    print_trace(trace)


if __name__ == "__main__":
    main()
