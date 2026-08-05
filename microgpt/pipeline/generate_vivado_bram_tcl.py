#!/usr/bin/env python3
"""Generate Vivado Tcl commands for the MicroGPT embedding and weight BRAMs."""

from __future__ import annotations

import argparse
from pathlib import Path


LAYER_PREFIXES = {
    "layer0_attn_wq": "q",
    "layer0_attn_wk": "k",
    "layer0_attn_wv": "v",
    "layer0_attn_wo": "wo",
    "layer0_mlp_fc1": "fc1",
    "layer0_mlp_fc2": "fc2",
    "lm_head": "lm",
}


def coe_depth(path: Path) -> int:
    values = []
    in_vector = False
    for line in path.read_text(encoding="ascii").splitlines():
        line = line.strip()
        if line.startswith("memory_initialization_vector"):
            in_vector = True
            continue
        if not in_vector or not line:
            continue
        values.extend(value.strip().rstrip(";") for value in line.split(","))
    values = [value for value in values if value]
    if not values:
        raise ValueError(f"no initialization values found in {path}")
    return len(values)


def tcl_path(path: Path) -> str:
    return path.resolve().as_posix()


def ip_tcl(module_name: str, coe: Path, depth: int, latency: int) -> str:
    if latency == 1:
        primitive_register = "true"
        core_register = "false"
    elif latency == 2:
        primitive_register = "true"
        core_register = "true"
    else:
        raise ValueError("this generator supports only one- or two-cycle latency")

    return f'''\n# {module_name}: {coe.name}\ncreate_ip -name blk_mem_gen \\
    -vendor xilinx.com -library ip -version 8.4 \\
    -module_name {module_name}\n\nset_property -dict [list \\
    CONFIG.Memory_Type {{Single_Port_RAM}} \\
    CONFIG.PRIM_type_to_Implement {{BRAM}} \\
    CONFIG.Write_Width_A {{16}} \\
    CONFIG.Read_Width_A {{16}} \\
    CONFIG.Write_Depth_A {{{depth}}} \\
    CONFIG.Enable_A {{Use_ENA_Pin}} \\
    CONFIG.Register_PortA_Output_of_Memory_Primitives {{{primitive_register}}} \\
    CONFIG.Register_PortA_Output_of_Memory_Core {{{core_register}}} \\
    CONFIG.Pipeline_Stages {{0}} \\
    CONFIG.Load_Init_File {{true}} \\
    CONFIG.Coe_File {{{tcl_path(coe)}}} \\
] [get_ips {module_name}]\n\ngenerate_target all [get_ips {module_name}]\n'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--generated-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "generated",
        help="MicroGPT generated directory",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("microgpt/pipeline/create_microgpt_brams.tcl"),
        help="output Vivado Tcl file",
    )
    parser.add_argument("--latency", type=int, default=2)
    args = parser.parse_args()

    if args.latency < 1:
        parser.error("--latency must be at least 1")

    generated = args.generated_dir.resolve()
    split_root = generated / "bram_split"
    flat_coe_root = generated / "coe"
    commands = [
        "# Generated MicroGPT BRAM configuration",
        "# Run this file from the Vivado project Tcl console.",
        "set_msg_config -id {IP_Flow 19-3656} -suppress",
    ]

    # The current embedding_bram_reader uses flat row-major embedding BRAMs.
    embeddings = [
        ("blk_mem_gen_0", flat_coe_root / "wte_q12.coe"),
        ("blk_mem_gen_1", flat_coe_root / "wpe_q12.coe"),
    ]
    for module_name, coe in embeddings:
        if not coe.is_file():
            raise FileNotFoundError(
                f"missing {coe}; convert wte_q12.hex and wpe_q12.hex to COE first"
            )
        commands.append(ip_tcl(module_name, coe, coe_depth(coe), args.latency))

    for directory_name, prefix in LAYER_PREFIXES.items():
        layer_dir = split_root / directory_name
        coes = sorted(layer_dir.glob("*.coe"))
        if not coes:
            raise FileNotFoundError(f"no split COE files found in {layer_dir}")

        for index, coe in enumerate(coes):
            module_name = f"blk_mem_gen_{prefix}_{index}"
            commands.append(ip_tcl(module_name, coe, coe_depth(coe), args.latency))

    commands.append("\nupdate_compile_order -fileset sources_1")
    commands.append('puts "MicroGPT BRAM IP generation complete."')

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(commands) + "\n", encoding="ascii")
    print(f"wrote {args.output} with Vivado commands for all BRAMs")


if __name__ == "__main__":
    main()
