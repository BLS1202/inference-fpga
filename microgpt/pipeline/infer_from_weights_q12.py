"""Run one MicroGPT inference step with RTL-style Q4.12 fixed point.

This is a verification companion for infer_from_weights.py.  It keeps values
as signed Q4.12 integers and mirrors the current RTL arithmetic closely:
wide integer MACs, arithmetic right shifts, saturation, integer RMSNorm, and
the exported exponential LUT.
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

FRAC_BITS = 12
SCALE = 1 << FRAC_BITS
INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1

VOCAB_SIZE = 27
BLOCK_SIZE = 16
N_EMBD = 16
N_HEAD = 4
HEAD_DIM = 4
MLP_HIDDEN = 4 * N_EMBD
EPS_Q24 = 168
EXP_ADDR_WIDTH = 12
EXP_LUT_SIZE = 1 << EXP_ADDR_WIDTH
EXP_MIN_INPUT = -((1 << 3) << FRAC_BITS)


def sat16(value: int) -> int:
    return max(INT16_MIN, min(INT16_MAX, value))


def sat_add16(a: int, b: int) -> int:
    return sat16(a + b)


def signed_i16(word: str) -> int:
    value = int(word.strip(), 16)
    if value & 0x8000:
        value -= 1 << 16
    return value


def unsigned_i16(word: str) -> int:
    return int(word.strip(), 16) & 0xFFFF


def hex16(value: int) -> str:
    return f"{value & 0xFFFF:04x}"


def q12_float(value: int) -> float:
    return value / SCALE


def load_matrix(path: Path, rows: int, cols: int) -> list[list[int]]:
    words = [line.strip() for line in path.read_text(encoding="ascii").splitlines()]
    expected = rows * cols
    if len(words) != expected:
        raise ValueError(f"{path}: expected {expected} values, found {len(words)}")
    return [
        [signed_i16(words[row * cols + col]) for col in range(cols)]
        for row in range(rows)
    ]


def load_exp_lut(path: Path) -> list[int]:
    words = [line.strip() for line in path.read_text(encoding="ascii").splitlines()]
    if len(words) != EXP_LUT_SIZE:
        raise ValueError(f"{path}: expected {EXP_LUT_SIZE} values, found {len(words)}")
    return [unsigned_i16(word) for word in words]


def load_weights(directory: Path) -> dict[str, list[list[int]]]:
    specs = {
        "wte": ("wte_q12.hex", VOCAB_SIZE, N_EMBD),
        "wpe": ("wpe_q12.hex", BLOCK_SIZE, N_EMBD),
        "wq": ("layer0_attn_wq_q12.hex", N_EMBD, N_EMBD),
        "wk": ("layer0_attn_wk_q12.hex", N_EMBD, N_EMBD),
        "wv": ("layer0_attn_wv_q12.hex", N_EMBD, N_EMBD),
        "wo": ("layer0_attn_wo_q12.hex", N_EMBD, N_EMBD),
        "fc1": ("layer0_mlp_fc1_q12.hex", MLP_HIDDEN, N_EMBD),
        "fc2": ("layer0_mlp_fc2_q12.hex", N_EMBD, MLP_HIDDEN),
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
        raise ValueError(
            f"{path}: expected vocab size {VOCAB_SIZE}, got {bos + 1}"
        )
    return chars, bos


def encode_prompt(prompt: str, chars: list[str]) -> list[int]:
    token_ids: list[int] = []
    for char in prompt:
        if char not in chars:
            raise ValueError(f"prompt character {char!r} is not in the vocabulary")
        token_ids.append(chars.index(char))
    return token_ids


def decode_token(token_id: int, chars: list[str], bos: int) -> str:
    if token_id == bos:
        return ""
    return chars[token_id]


def linear_q12(vector: list[int], matrix: list[list[int]]) -> list[int]:
    output: list[int] = []
    for row in matrix:
        acc = 0
        for weight, value in zip(row, vector):
            acc += weight * value
        output.append(sat16(acc >> FRAC_BITS))
    return output


def fc2_q12_current_rtl(vector: list[int], matrix: list[list[int]]) -> list[int]:
    """Mirror the current shared FC2 path: four shifted 16-wide partial sums."""
    output: list[int] = []
    for row in matrix:
        partial_sum = 0
        for col_base in range(0, MLP_HIDDEN, N_EMBD):
            acc = 0
            for i in range(N_EMBD):
                acc += row[col_base + i] * vector[col_base + i]
            partial_sum += sat16(acc >> FRAC_BITS)
        output.append(sat16(partial_sum))
    return output


def rmsnorm_q12(vector: list[int]) -> list[int]:
    fin_sum = sum(value * value for value in vector)
    rad = (fin_sum >> int(math.log2(N_EMBD))) + EPS_Q24
    root = math.isqrt(rad)
    if root == 0:
        scale_q12 = 0
    else:
        scale_q12 = sat16((1 << (2 * FRAC_BITS)) // root)
    return [sat16((value * scale_q12) >> FRAC_BITS) for value in vector]


def exp_addr(delta: int) -> int:
    if delta >= 0:
        clipped = 0
    elif delta < EXP_MIN_INPUT:
        clipped = EXP_MIN_INPUT
    else:
        clipped = delta
    magnitude = -clipped
    return (magnitude * (EXP_LUT_SIZE - 1)) >> (FRAC_BITS + 3)


def categorical_weights_q12(logits: list[int], exp_lut: list[int]) -> list[int]:
    max_logit = max(logits)
    return [exp_lut[exp_addr(logit - max_logit)] for logit in logits]


def div_trunc_toward_zero(numerator: int, denominator: int) -> int:
    if denominator == 0:
        denominator = 1
    quotient = abs(numerator) // abs(denominator)
    if (numerator < 0) ^ (denominator < 0):
        quotient = -quotient
    return quotient


def attention_context_q12(
    query: list[int],
    keys: list[list[int]],
    values: list[list[int]],
    pos_id: int,
    exp_lut: list[int],
) -> tuple[list[int], list[int], list[int]]:
    all_logits: list[int] = []
    all_weights: list[int] = []
    context = [0 for _ in range(N_EMBD)]

    for head in range(N_HEAD):
        begin = head * HEAD_DIM
        logits: list[int] = []
        for pos in range(BLOCK_SIZE):
            if pos <= pos_id and pos < len(keys):
                acc = 0
                for dim in range(HEAD_DIM):
                    acc += keys[pos][begin + dim] * query[begin + dim]
                score = sat16(acc >> FRAC_BITS)
                logits.append(score >> 1)
            else:
                logits.append(INT16_MIN)

        max_logit = max(logits)
        exp_values: list[int] = []
        exp_sum = 0
        for pos, logit in enumerate(logits):
            if pos <= pos_id:
                exp_value = exp_lut[exp_addr(logit - max_logit)]
                exp_sum += exp_value
            else:
                exp_value = 0
            exp_values.append(exp_value)

        for dim in range(HEAD_DIM):
            value_acc = 0
            for pos in range(pos_id + 1):
                product = exp_values[pos] * values[pos][begin + dim]
                value_acc += product >> FRAC_BITS
            context[begin + dim] = sat16(div_trunc_toward_zero(value_acc, exp_sum))

        all_logits.extend(logits)
        all_weights.extend(exp_values)

    return context, all_logits, all_weights


def run_step(
    weights: dict[str, list[list[int]]],
    exp_lut: list[int],
    token_id: int,
    pos_id: int,
    keys: list[list[int]],
    values: list[list[int]],
    trace: dict[str, list[int]] | None = None,
) -> tuple[list[int], list[list[int]], list[list[int]]]:
    token_embedding = weights["wte"][token_id].copy()
    position_embedding = weights["wpe"][pos_id].copy()
    embedding = [
        sat_add16(token_value, pos_value)
        for token_value, pos_value in zip(token_embedding, position_embedding)
    ]

    rms0 = rmsnorm_q12(embedding)
    query = linear_q12(rms0, weights["wq"])
    key = linear_q12(rms0, weights["wk"])
    value = linear_q12(rms0, weights["wv"])

    keys = [saved_key.copy() for saved_key in keys]
    values = [saved_value.copy() for saved_value in values]
    keys[pos_id] = key
    values[pos_id] = value

    context, attention_logits, attention_weights = attention_context_q12(
        query, keys, values, pos_id, exp_lut
    )
    wo = linear_q12(context, weights["wo"])
    attention_residual = [sat_add16(a, b) for a, b in zip(rms0, wo)]

    mlp_rmsnorm = rmsnorm_q12(attention_residual)
    fc1 = linear_q12(mlp_rmsnorm, weights["fc1"])
    fc1_relu = [max(0, value) for value in fc1]
    fc2 = fc2_q12_current_rtl(fc1_relu, weights["fc2"])
    mlp_residual = [sat_add16(a, b) for a, b in zip(attention_residual, fc2)]

    logits = linear_q12(mlp_residual, weights["lm"])
    final_weights = categorical_weights_q12(logits, exp_lut)

    if trace is not None:
        trace["token_embedding"] = token_embedding
        trace["position_embedding"] = position_embedding
        trace["embedding"] = embedding
        trace["rms0"] = rms0
        trace["attn_rmsnorm"] = rms0.copy()
        trace["q"] = query
        trace["k"] = key
        trace["v"] = value
        trace["kv_keys"] = [element for saved_key in keys for element in saved_key]
        trace["kv_values"] = [element for saved_value in values for element in saved_value]
        trace["attention_logits"] = attention_logits
        trace["attention_probs"] = attention_weights
        trace["attention_context"] = context
        trace["wo"] = wo
        trace["attention_residual"] = attention_residual
        trace["mlp_rmsnorm"] = mlp_rmsnorm
        trace["fc1"] = fc1
        trace["fc1_relu"] = fc1_relu
        trace["fc2"] = fc2
        trace["mlp_residual"] = mlp_residual
        trace["lm_logits"] = logits
        trace["final_weights"] = final_weights

    return logits, keys, values


def write_trace(trace_dir: Path, trace: dict[str, list[int]]) -> None:
    trace_dir.mkdir(parents=True, exist_ok=True)
    for name, vector in trace.items():
        (trace_dir / f"{name}.txt").write_text(
            " ".join(f"{q12_float(value):.10f}" for value in vector) + "\n",
            encoding="ascii",
        )
        (trace_dir / f"{name}.mem").write_text(
            "\n".join(hex16(value) for value in vector) + "\n",
            encoding="ascii",
        )


def print_trace(trace: dict[str, list[int]]) -> None:
    for name, vector in trace.items():
        values = " ".join(f"0x{hex16(value)}({value})" for value in vector)
        print(f"{name}:")
        print(f"  {values}")


def run_prompt(
    weights: dict[str, list[list[int]]],
    exp_lut: list[int],
    chars: list[str],
    bos: int,
    prompt: str,
    generate: int,
    dump_dir: Path,
) -> None:
    prompt_tokens = encode_prompt(prompt, chars)
    input_tokens = [bos] + prompt_tokens
    if len(input_tokens) > BLOCK_SIZE:
        raise ValueError(f"prompt is too long for block size {BLOCK_SIZE}")

    keys: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]
    values: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]
    generated_tokens: list[int] = []
    trace: dict[str, list[int]] = {}
    next_token = bos
    last_logits: list[int] = []

    max_steps = min(generate, BLOCK_SIZE - len(prompt_tokens))
    for pos_id, token_id in enumerate(input_tokens):
        step_trace = trace if pos_id == len(input_tokens) - 1 else None
        last_logits, keys, values = run_step(
            weights, exp_lut, token_id, pos_id, keys, values, trace=step_trace
        )
        if step_trace is not None:
            next_token = max(range(VOCAB_SIZE), key=step_trace["final_weights"].__getitem__)

    if max_steps > 0 and next_token != bos:
        generated_tokens.append(next_token)

    current_token = next_token
    for step in range(1, max_steps):
        if current_token == bos:
            break
        pos_id = len(prompt_tokens) + step
        trace = {}
        last_logits, keys, values = run_step(
            weights, exp_lut, current_token, pos_id, keys, values, trace=trace
        )
        final_weights = trace["final_weights"]
        next_token = max(range(VOCAB_SIZE), key=final_weights.__getitem__)
        if next_token == bos:
            break
        generated_tokens.append(next_token)
        current_token = next_token

    generated_text = "".join(decode_token(token_id, chars, bos) for token_id in generated_tokens)
    output_text = prompt + generated_text
    write_trace(dump_dir, trace)

    print(f"prompt      : {prompt}")
    print(f"prompt ids  : {' '.join(str(token_id) for token_id in prompt_tokens)}")
    print(f"generated   : {generated_text}")
    print(f"output      : {output_text}")
    print(f"output ids  : {' '.join(str(token_id) for token_id in prompt_tokens + generated_tokens)}")
    print(f"next token  : {next_token}")
    if last_logits:
        print(f"max logit   : {q12_float(last_logits[next_token]):.8f}")
    print(f"intermediates: {dump_dir}")
    print_trace(trace)


def run_sample(
    weights: dict[str, list[list[int]]],
    exp_lut: list[int],
    chars: list[str],
    bos: int,
    generate: int,
) -> str:
    keys: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]
    values: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]
    current_token = bos
    generated_tokens: list[int] = []

    for pos_id in range(min(generate, BLOCK_SIZE)):
        trace: dict[str, list[int]] = {}
        _, keys, values = run_step(
            weights, exp_lut, current_token, pos_id, keys, values, trace=trace
        )
        final_weights = trace["final_weights"]
        next_token = random.choices(range(VOCAB_SIZE), weights=final_weights)[0]
        if next_token == bos:
            break
        generated_tokens.append(next_token)
        current_token = next_token

    return "".join(decode_token(token_id, chars, bos) for token_id in generated_tokens)


def run_samples(
    weights: dict[str, list[list[int]]],
    exp_lut: list[int],
    chars: list[str],
    bos: int,
    samples: int,
    generate: int,
) -> None:
    print("--- inference (new, hallucinated names) ---")
    for sample_idx in range(samples):
        sample = run_sample(weights, exp_lut, chars, bos, generate)
        print(f"sample {sample_idx + 1:2d}: {sample}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run one MicroGPT step with RTL-style Q4.12 arithmetic"
    )
    parser.add_argument("--token-id", type=int)
    parser.add_argument("--pos-id", type=int)
    parser.add_argument(
        "--prompt",
        help="Character prompt to continue, for example: anna",
    )
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
        default=8,
        help="Number of additional characters to generate in prompt mode",
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
        "--exp-lut",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "generated" / "exp_q12.hex",
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
        default=Path("generated/reference/intermediates_q12"),
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
    exp_lut = load_exp_lut(args.exp_lut)

    if args.sample:
        if args.prompt is not None or args.token_id is not None or args.pos_id is not None or args.context_tokens:
            parser.error("--sample cannot be combined with --prompt, --token-id, --pos-id, or --context-tokens")
        if args.generate < 0:
            parser.error("--generate must be non-negative")
        if args.samples < 0:
            parser.error("--samples must be non-negative")
        try:
            chars, bos = load_vocab(args.vocab_source)
            random.seed(args.seed)
            run_samples(
                weights,
                exp_lut,
                chars,
                bos,
                args.samples,
                args.generate,
            )
        except ValueError as exc:
            parser.error(str(exc))
        return

    if args.prompt is not None:
        if args.context_tokens:
            parser.error("--context-tokens is only used with --token-id/--pos-id mode")
        if args.generate < 0:
            parser.error("--generate must be non-negative")
        try:
            chars, bos = load_vocab(args.vocab_source)
            run_prompt(
                weights,
                exp_lut,
                chars,
                bos,
                args.prompt,
                args.generate,
                args.dump_dir,
            )
        except ValueError as exc:
            parser.error(str(exc))
        return

    if args.token_id is None or args.pos_id is None:
        parser.error("provide --sample, --prompt, or both --token-id and --pos-id")
    if not 0 <= args.token_id < VOCAB_SIZE:
        parser.error(f"token-id must be in [0, {VOCAB_SIZE - 1}]")
    if not 0 <= args.pos_id < BLOCK_SIZE:
        parser.error(f"pos-id must be in [0, {BLOCK_SIZE - 1}]")
    if args.context_tokens and len(args.context_tokens) != args.pos_id:
        parser.error("the number of context tokens must equal pos-id")

    keys: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]
    values: list[list[int]] = [[0 for _ in range(N_EMBD)] for _ in range(BLOCK_SIZE)]

    for position, context_token in enumerate(args.context_tokens):
        if not 0 <= context_token < VOCAB_SIZE:
            parser.error(f"context token {context_token} is outside [0, {VOCAB_SIZE - 1}]")
        _, keys, values = run_step(
            weights, exp_lut, context_token, position, keys, values
        )

    trace: dict[str, list[int]] = {}
    logits, _, _ = run_step(
        weights, exp_lut, args.token_id, args.pos_id, keys, values, trace=trace
    )
    final_weights = trace["final_weights"]
    next_token = max(range(VOCAB_SIZE), key=final_weights.__getitem__)

    write_trace(args.dump_dir, trace)

    print(f"input token : {args.token_id}")
    print(f"input pos   : {args.pos_id}")
    print(f"next token  : {next_token}")
    print(f"max logit   : {q12_float(logits[next_token]):.8f}")
    print("logits:")
    print(" ".join(f"{q12_float(value):.8f}" for value in logits))
    print("logits Q4.12:")
    print(" ".join(f"0x{hex16(value)}({value})" for value in logits))
    print(f"intermediates: {args.dump_dir}")
    print_trace(trace)


if __name__ == "__main__":
    main()
