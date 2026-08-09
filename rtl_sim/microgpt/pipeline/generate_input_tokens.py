#! /usr/bin/env python3
"""Generate a deterministic MicroGPT input-token sequence for RTL replay."""

from argparse import ArgumentParser
from pathlib import Path


def load_vocabulary(input_file: Path) -> tuple[dict[str, int], int]:
    documents = [line.strip() for line in input_file.read_text(encoding="utf-8").splitlines()]
    documents = [document for document in documents if document]
    if not documents:
        raise ValueError(f"no documents found in {input_file}")

    uchars = sorted(set("".join(documents)))
    char_to_id = {char: index for index, char in enumerate(uchars)}
    bos = len(uchars)
    return char_to_id, bos


def write_tokens(path: Path, tokens: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(f"{token:x}" for token in tokens) + "\n",
        encoding="ascii",
    )


def main() -> None:
    parser = ArgumentParser(description="Generate fixed input tokens for RTL replay.")
    parser.add_argument(
        "--text",
        required=True,
        help="Text converted into character tokens after the BOS token.",
    )
    parser.add_argument(
        "--input-file",
        default="microgpt/input.txt",
        help="Dataset used to build the MicroGPT character vocabulary.",
    )
    parser.add_argument(
        "--num-tokens",
        type=int,
        default=5,
        help="Number of tokens to write, including BOS.",
    )
    parser.add_argument(
        "--outdir",
        default="generated/reference",
        help="Output directory.",
    )
    args = parser.parse_args()

    if args.num_tokens <= 0:
        raise ValueError("--num-tokens must be positive")

    input_file = Path(args.input_file)
    char_to_id, bos = load_vocabulary(input_file)

    unknown = sorted({char for char in args.text if char not in char_to_id})
    if unknown:
        raise ValueError(f"characters are not in the MicroGPT vocabulary: {unknown}")

    tokens = [bos] + [char_to_id[char] for char in args.text]
    if len(tokens) < args.num_tokens:
        raise ValueError(
            f"text produces {len(tokens)} tokens, but {args.num_tokens} were requested"
        )
    tokens = tokens[: args.num_tokens]

    outdir = Path(args.outdir)
    write_tokens(outdir / "input_tokens.mem", tokens)
    (outdir / "input_tokens.txt").write_text(
        "position input_token\n"
        + "\n".join(f"{position} {token}" for position, token in enumerate(tokens))
        + "\n",
        encoding="ascii",
    )

    print(f"vocabulary size: {bos + 1}")
    print(f"BOS token: {bos}")
    print(f"input tokens: {tokens}")
    print(f"wrote {outdir / 'input_tokens.mem'}")
    print(f"wrote {outdir / 'input_tokens.txt'}")


if __name__ == "__main__":
    main()
