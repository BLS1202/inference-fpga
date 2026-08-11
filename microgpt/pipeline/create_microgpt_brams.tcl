# Generated MicroGPT BRAM configuration
# Run this file from the Vivado project Tcl console.
set_msg_config -id {IP_Flow 19-3656} -suppress

# Remove old distributed BRAM instances from the previous design.
foreach old_ip [get_ips -quiet] {
    set old_name [get_property NAME $old_ip]
    if {[regexp {^blk_mem_gen_(q|k|v|wo|fc1|fc2|lm)_[0-9]+$} $old_name]} {
        delete_ip $old_ip
    }
}

# blk_mem_gen_0: wte_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_0]] != 0} {
    delete_ip [get_ips blk_mem_gen_0]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {432} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/wte_q12.coe} \
] [get_ips blk_mem_gen_0]

generate_target all [get_ips blk_mem_gen_0]


# blk_mem_gen_1: wpe_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_1]] != 0} {
    delete_ip [get_ips blk_mem_gen_1]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/wpe_q12.coe} \
] [get_ips blk_mem_gen_1]

generate_target all [get_ips blk_mem_gen_1]


# blk_mem_gen_q: layer0_attn_wq_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_q]] != 0} {
    delete_ip [get_ips blk_mem_gen_q]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_attn_wq_q12.coe} \
] [get_ips blk_mem_gen_q]

generate_target all [get_ips blk_mem_gen_q]


# blk_mem_gen_k: layer0_attn_wk_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_k]] != 0} {
    delete_ip [get_ips blk_mem_gen_k]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_attn_wk_q12.coe} \
] [get_ips blk_mem_gen_k]

generate_target all [get_ips blk_mem_gen_k]


# blk_mem_gen_v: layer0_attn_wv_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_v]] != 0} {
    delete_ip [get_ips blk_mem_gen_v]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_attn_wv_q12.coe} \
] [get_ips blk_mem_gen_v]

generate_target all [get_ips blk_mem_gen_v]


# blk_mem_gen_wo: layer0_attn_wo_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_wo]] != 0} {
    delete_ip [get_ips blk_mem_gen_wo]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_attn_wo_q12.coe} \
] [get_ips blk_mem_gen_wo]

generate_target all [get_ips blk_mem_gen_wo]


# blk_mem_gen_fc1: layer0_mlp_fc1_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_fc1]] != 0} {
    delete_ip [get_ips blk_mem_gen_fc1]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_mlp_fc1_q12.coe} \
] [get_ips blk_mem_gen_fc1]

generate_target all [get_ips blk_mem_gen_fc1]


# blk_mem_gen_fc2: layer0_mlp_fc2_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_fc2]] != 0} {
    delete_ip [get_ips blk_mem_gen_fc2]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/layer0_mlp_fc2_q12.coe} \
] [get_ips blk_mem_gen_fc2]

generate_target all [get_ips blk_mem_gen_fc2]


# blk_mem_gen_lm: lm_head_q12.coe
if {[llength [get_ips -quiet blk_mem_gen_lm]] != 0} {
    delete_ip [get_ips blk_mem_gen_lm]
}
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {432} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {false} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/lm_head_q12.coe} \
] [get_ips blk_mem_gen_lm]

generate_target all [get_ips blk_mem_gen_lm]


update_compile_order -fileset sources_1
puts "MicroGPT BRAM IP generation complete."
