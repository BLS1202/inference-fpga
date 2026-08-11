#!/usr/bin/env python3
"""Generate Vivado Tcl commands for the MicroGPT embedding and weight BRAMs."""

from __future__ import annotations

import argparse
from pathlib import Path


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
        primitive_register = "false"
        core_register = "false"
    elif latency == 2:
        # The BRAM has a native synchronous read cycle.  Registering the
        # primitive output adds the second cycle.  Registering the core output
        # as well creates an additional cycle in the generated IP.
        primitive_register = "true"
        core_register = "false"
    else:
        raise ValueError("this generator supports only one- or two-cycle latency")

    return f'''\n# {module_name}: {coe.name}
if {{[llength [get_ips -quiet {module_name}]] != 0}} {{
    delete_ip [get_ips {module_name}]
}}
create_ip -name blk_mem_gen \\
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
    flat_coe_root = generated / "coe"
    commands = [
        "# Generated MicroGPT BRAM configuration",
        "# Run this file from the Vivado project Tcl console.",
        "set_msg_config -id {IP_Flow 19-3656} -suppress",
        "",
        "# Remove old distributed BRAM instances from the previous design.",
        "foreach old_ip [get_ips -quiet] {",
        "    set old_name [get_property NAME $old_ip]",
        "    if {[regexp {^blk_mem_gen_(q|k|v|wo|fc1|fc2|lm)_[0-9]+$} $old_name]} {",
        "        delete_ip $old_ip",
        "    }",
        "}",
    ]

    # The inference design uses one flat row-major BRAM per stored file.
    brams = [
        ("blk_mem_gen_0", flat_coe_root / "wte_q12.coe"),
        ("blk_mem_gen_1", flat_coe_root / "wpe_q12.coe"),
        ("blk_mem_gen_q", flat_coe_root / "layer0_attn_wq_q12.coe"),
        ("blk_mem_gen_k", flat_coe_root / "layer0_attn_wk_q12.coe"),
        ("blk_mem_gen_v", flat_coe_root / "layer0_attn_wv_q12.coe"),
        ("blk_mem_gen_wo", flat_coe_root / "layer0_attn_wo_q12.coe"),
        ("blk_mem_gen_fc1", flat_coe_root / "layer0_mlp_fc1_q12.coe"),
        ("blk_mem_gen_fc2", flat_coe_root / "layer0_mlp_fc2_q12.coe"),
        ("blk_mem_gen_lm", flat_coe_root / "lm_head_q12.coe"),
    ]
    for module_name, coe in brams:
        if not coe.is_file():
            raise FileNotFoundError(
                f"missing flat COE file: {coe}"
            )
        commands.append(ip_tcl(module_name, coe, coe_depth(coe), args.latency))

    commands.append("\nupdate_compile_order -fileset sources_1")
    commands.append('puts "MicroGPT BRAM IP generation complete."')

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(commands) + "\n", encoding="ascii")
    print(f"wrote {args.output} with Vivado commands for {len(brams)} flat BRAMs")


if __name__ == "__main__":
    main()
