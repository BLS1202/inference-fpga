# Generated MicroGPT BRAM configuration
# Run this file from the Vivado project Tcl console.
set_msg_config -id {IP_Flow 19-3656} -suppress

# blk_mem_gen_0: wte_q12.coe
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
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/wte_q12.coe} \
] [get_ips blk_mem_gen_0]

generate_target all [get_ips blk_mem_gen_0]


# blk_mem_gen_1: wpe_q12.coe
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
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/coe/wpe_q12.coe} \
] [get_ips blk_mem_gen_1]

generate_target all [get_ips blk_mem_gen_1]


# blk_mem_gen_q_0: layer0_attn_wq_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_00.coe} \
] [get_ips blk_mem_gen_q_0]

generate_target all [get_ips blk_mem_gen_q_0]


# blk_mem_gen_q_1: layer0_attn_wq_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_01.coe} \
] [get_ips blk_mem_gen_q_1]

generate_target all [get_ips blk_mem_gen_q_1]


# blk_mem_gen_q_2: layer0_attn_wq_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_02.coe} \
] [get_ips blk_mem_gen_q_2]

generate_target all [get_ips blk_mem_gen_q_2]


# blk_mem_gen_q_3: layer0_attn_wq_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_03.coe} \
] [get_ips blk_mem_gen_q_3]

generate_target all [get_ips blk_mem_gen_q_3]


# blk_mem_gen_q_4: layer0_attn_wq_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_04.coe} \
] [get_ips blk_mem_gen_q_4]

generate_target all [get_ips blk_mem_gen_q_4]


# blk_mem_gen_q_5: layer0_attn_wq_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_05.coe} \
] [get_ips blk_mem_gen_q_5]

generate_target all [get_ips blk_mem_gen_q_5]


# blk_mem_gen_q_6: layer0_attn_wq_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_06.coe} \
] [get_ips blk_mem_gen_q_6]

generate_target all [get_ips blk_mem_gen_q_6]


# blk_mem_gen_q_7: layer0_attn_wq_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_07.coe} \
] [get_ips blk_mem_gen_q_7]

generate_target all [get_ips blk_mem_gen_q_7]


# blk_mem_gen_q_8: layer0_attn_wq_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_08.coe} \
] [get_ips blk_mem_gen_q_8]

generate_target all [get_ips blk_mem_gen_q_8]


# blk_mem_gen_q_9: layer0_attn_wq_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_09.coe} \
] [get_ips blk_mem_gen_q_9]

generate_target all [get_ips blk_mem_gen_q_9]


# blk_mem_gen_q_10: layer0_attn_wq_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_10.coe} \
] [get_ips blk_mem_gen_q_10]

generate_target all [get_ips blk_mem_gen_q_10]


# blk_mem_gen_q_11: layer0_attn_wq_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_11.coe} \
] [get_ips blk_mem_gen_q_11]

generate_target all [get_ips blk_mem_gen_q_11]


# blk_mem_gen_q_12: layer0_attn_wq_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_12.coe} \
] [get_ips blk_mem_gen_q_12]

generate_target all [get_ips blk_mem_gen_q_12]


# blk_mem_gen_q_13: layer0_attn_wq_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_13.coe} \
] [get_ips blk_mem_gen_q_13]

generate_target all [get_ips blk_mem_gen_q_13]


# blk_mem_gen_q_14: layer0_attn_wq_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_14.coe} \
] [get_ips blk_mem_gen_q_14]

generate_target all [get_ips blk_mem_gen_q_14]


# blk_mem_gen_q_15: layer0_attn_wq_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_q_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wq/layer0_attn_wq_15.coe} \
] [get_ips blk_mem_gen_q_15]

generate_target all [get_ips blk_mem_gen_q_15]


# blk_mem_gen_k_0: layer0_attn_wk_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_00.coe} \
] [get_ips blk_mem_gen_k_0]

generate_target all [get_ips blk_mem_gen_k_0]


# blk_mem_gen_k_1: layer0_attn_wk_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_01.coe} \
] [get_ips blk_mem_gen_k_1]

generate_target all [get_ips blk_mem_gen_k_1]


# blk_mem_gen_k_2: layer0_attn_wk_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_02.coe} \
] [get_ips blk_mem_gen_k_2]

generate_target all [get_ips blk_mem_gen_k_2]


# blk_mem_gen_k_3: layer0_attn_wk_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_03.coe} \
] [get_ips blk_mem_gen_k_3]

generate_target all [get_ips blk_mem_gen_k_3]


# blk_mem_gen_k_4: layer0_attn_wk_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_04.coe} \
] [get_ips blk_mem_gen_k_4]

generate_target all [get_ips blk_mem_gen_k_4]


# blk_mem_gen_k_5: layer0_attn_wk_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_05.coe} \
] [get_ips blk_mem_gen_k_5]

generate_target all [get_ips blk_mem_gen_k_5]


# blk_mem_gen_k_6: layer0_attn_wk_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_06.coe} \
] [get_ips blk_mem_gen_k_6]

generate_target all [get_ips blk_mem_gen_k_6]


# blk_mem_gen_k_7: layer0_attn_wk_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_07.coe} \
] [get_ips blk_mem_gen_k_7]

generate_target all [get_ips blk_mem_gen_k_7]


# blk_mem_gen_k_8: layer0_attn_wk_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_08.coe} \
] [get_ips blk_mem_gen_k_8]

generate_target all [get_ips blk_mem_gen_k_8]


# blk_mem_gen_k_9: layer0_attn_wk_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_09.coe} \
] [get_ips blk_mem_gen_k_9]

generate_target all [get_ips blk_mem_gen_k_9]


# blk_mem_gen_k_10: layer0_attn_wk_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_10.coe} \
] [get_ips blk_mem_gen_k_10]

generate_target all [get_ips blk_mem_gen_k_10]


# blk_mem_gen_k_11: layer0_attn_wk_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_11.coe} \
] [get_ips blk_mem_gen_k_11]

generate_target all [get_ips blk_mem_gen_k_11]


# blk_mem_gen_k_12: layer0_attn_wk_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_12.coe} \
] [get_ips blk_mem_gen_k_12]

generate_target all [get_ips blk_mem_gen_k_12]


# blk_mem_gen_k_13: layer0_attn_wk_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_13.coe} \
] [get_ips blk_mem_gen_k_13]

generate_target all [get_ips blk_mem_gen_k_13]


# blk_mem_gen_k_14: layer0_attn_wk_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_14.coe} \
] [get_ips blk_mem_gen_k_14]

generate_target all [get_ips blk_mem_gen_k_14]


# blk_mem_gen_k_15: layer0_attn_wk_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_k_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wk/layer0_attn_wk_15.coe} \
] [get_ips blk_mem_gen_k_15]

generate_target all [get_ips blk_mem_gen_k_15]


# blk_mem_gen_v_0: layer0_attn_wv_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_00.coe} \
] [get_ips blk_mem_gen_v_0]

generate_target all [get_ips blk_mem_gen_v_0]


# blk_mem_gen_v_1: layer0_attn_wv_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_01.coe} \
] [get_ips blk_mem_gen_v_1]

generate_target all [get_ips blk_mem_gen_v_1]


# blk_mem_gen_v_2: layer0_attn_wv_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_02.coe} \
] [get_ips blk_mem_gen_v_2]

generate_target all [get_ips blk_mem_gen_v_2]


# blk_mem_gen_v_3: layer0_attn_wv_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_03.coe} \
] [get_ips blk_mem_gen_v_3]

generate_target all [get_ips blk_mem_gen_v_3]


# blk_mem_gen_v_4: layer0_attn_wv_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_04.coe} \
] [get_ips blk_mem_gen_v_4]

generate_target all [get_ips blk_mem_gen_v_4]


# blk_mem_gen_v_5: layer0_attn_wv_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_05.coe} \
] [get_ips blk_mem_gen_v_5]

generate_target all [get_ips blk_mem_gen_v_5]


# blk_mem_gen_v_6: layer0_attn_wv_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_06.coe} \
] [get_ips blk_mem_gen_v_6]

generate_target all [get_ips blk_mem_gen_v_6]


# blk_mem_gen_v_7: layer0_attn_wv_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_07.coe} \
] [get_ips blk_mem_gen_v_7]

generate_target all [get_ips blk_mem_gen_v_7]


# blk_mem_gen_v_8: layer0_attn_wv_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_08.coe} \
] [get_ips blk_mem_gen_v_8]

generate_target all [get_ips blk_mem_gen_v_8]


# blk_mem_gen_v_9: layer0_attn_wv_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_09.coe} \
] [get_ips blk_mem_gen_v_9]

generate_target all [get_ips blk_mem_gen_v_9]


# blk_mem_gen_v_10: layer0_attn_wv_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_10.coe} \
] [get_ips blk_mem_gen_v_10]

generate_target all [get_ips blk_mem_gen_v_10]


# blk_mem_gen_v_11: layer0_attn_wv_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_11.coe} \
] [get_ips blk_mem_gen_v_11]

generate_target all [get_ips blk_mem_gen_v_11]


# blk_mem_gen_v_12: layer0_attn_wv_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_12.coe} \
] [get_ips blk_mem_gen_v_12]

generate_target all [get_ips blk_mem_gen_v_12]


# blk_mem_gen_v_13: layer0_attn_wv_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_13.coe} \
] [get_ips blk_mem_gen_v_13]

generate_target all [get_ips blk_mem_gen_v_13]


# blk_mem_gen_v_14: layer0_attn_wv_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_14.coe} \
] [get_ips blk_mem_gen_v_14]

generate_target all [get_ips blk_mem_gen_v_14]


# blk_mem_gen_v_15: layer0_attn_wv_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_v_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wv/layer0_attn_wv_15.coe} \
] [get_ips blk_mem_gen_v_15]

generate_target all [get_ips blk_mem_gen_v_15]


# blk_mem_gen_wo_0: layer0_attn_wo_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_00.coe} \
] [get_ips blk_mem_gen_wo_0]

generate_target all [get_ips blk_mem_gen_wo_0]


# blk_mem_gen_wo_1: layer0_attn_wo_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_01.coe} \
] [get_ips blk_mem_gen_wo_1]

generate_target all [get_ips blk_mem_gen_wo_1]


# blk_mem_gen_wo_2: layer0_attn_wo_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_02.coe} \
] [get_ips blk_mem_gen_wo_2]

generate_target all [get_ips blk_mem_gen_wo_2]


# blk_mem_gen_wo_3: layer0_attn_wo_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_03.coe} \
] [get_ips blk_mem_gen_wo_3]

generate_target all [get_ips blk_mem_gen_wo_3]


# blk_mem_gen_wo_4: layer0_attn_wo_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_04.coe} \
] [get_ips blk_mem_gen_wo_4]

generate_target all [get_ips blk_mem_gen_wo_4]


# blk_mem_gen_wo_5: layer0_attn_wo_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_05.coe} \
] [get_ips blk_mem_gen_wo_5]

generate_target all [get_ips blk_mem_gen_wo_5]


# blk_mem_gen_wo_6: layer0_attn_wo_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_06.coe} \
] [get_ips blk_mem_gen_wo_6]

generate_target all [get_ips blk_mem_gen_wo_6]


# blk_mem_gen_wo_7: layer0_attn_wo_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_07.coe} \
] [get_ips blk_mem_gen_wo_7]

generate_target all [get_ips blk_mem_gen_wo_7]


# blk_mem_gen_wo_8: layer0_attn_wo_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_08.coe} \
] [get_ips blk_mem_gen_wo_8]

generate_target all [get_ips blk_mem_gen_wo_8]


# blk_mem_gen_wo_9: layer0_attn_wo_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_09.coe} \
] [get_ips blk_mem_gen_wo_9]

generate_target all [get_ips blk_mem_gen_wo_9]


# blk_mem_gen_wo_10: layer0_attn_wo_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_10.coe} \
] [get_ips blk_mem_gen_wo_10]

generate_target all [get_ips blk_mem_gen_wo_10]


# blk_mem_gen_wo_11: layer0_attn_wo_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_11.coe} \
] [get_ips blk_mem_gen_wo_11]

generate_target all [get_ips blk_mem_gen_wo_11]


# blk_mem_gen_wo_12: layer0_attn_wo_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_12.coe} \
] [get_ips blk_mem_gen_wo_12]

generate_target all [get_ips blk_mem_gen_wo_12]


# blk_mem_gen_wo_13: layer0_attn_wo_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_13.coe} \
] [get_ips blk_mem_gen_wo_13]

generate_target all [get_ips blk_mem_gen_wo_13]


# blk_mem_gen_wo_14: layer0_attn_wo_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_14.coe} \
] [get_ips blk_mem_gen_wo_14]

generate_target all [get_ips blk_mem_gen_wo_14]


# blk_mem_gen_wo_15: layer0_attn_wo_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_wo_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_attn_wo/layer0_attn_wo_15.coe} \
] [get_ips blk_mem_gen_wo_15]

generate_target all [get_ips blk_mem_gen_wo_15]


# blk_mem_gen_fc1_0: layer0_mlp_fc1_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_00.coe} \
] [get_ips blk_mem_gen_fc1_0]

generate_target all [get_ips blk_mem_gen_fc1_0]


# blk_mem_gen_fc1_1: layer0_mlp_fc1_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_01.coe} \
] [get_ips blk_mem_gen_fc1_1]

generate_target all [get_ips blk_mem_gen_fc1_1]


# blk_mem_gen_fc1_2: layer0_mlp_fc1_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_02.coe} \
] [get_ips blk_mem_gen_fc1_2]

generate_target all [get_ips blk_mem_gen_fc1_2]


# blk_mem_gen_fc1_3: layer0_mlp_fc1_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_03.coe} \
] [get_ips blk_mem_gen_fc1_3]

generate_target all [get_ips blk_mem_gen_fc1_3]


# blk_mem_gen_fc1_4: layer0_mlp_fc1_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_04.coe} \
] [get_ips blk_mem_gen_fc1_4]

generate_target all [get_ips blk_mem_gen_fc1_4]


# blk_mem_gen_fc1_5: layer0_mlp_fc1_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_05.coe} \
] [get_ips blk_mem_gen_fc1_5]

generate_target all [get_ips blk_mem_gen_fc1_5]


# blk_mem_gen_fc1_6: layer0_mlp_fc1_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_06.coe} \
] [get_ips blk_mem_gen_fc1_6]

generate_target all [get_ips blk_mem_gen_fc1_6]


# blk_mem_gen_fc1_7: layer0_mlp_fc1_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_07.coe} \
] [get_ips blk_mem_gen_fc1_7]

generate_target all [get_ips blk_mem_gen_fc1_7]


# blk_mem_gen_fc1_8: layer0_mlp_fc1_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_08.coe} \
] [get_ips blk_mem_gen_fc1_8]

generate_target all [get_ips blk_mem_gen_fc1_8]


# blk_mem_gen_fc1_9: layer0_mlp_fc1_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_09.coe} \
] [get_ips blk_mem_gen_fc1_9]

generate_target all [get_ips blk_mem_gen_fc1_9]


# blk_mem_gen_fc1_10: layer0_mlp_fc1_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_10.coe} \
] [get_ips blk_mem_gen_fc1_10]

generate_target all [get_ips blk_mem_gen_fc1_10]


# blk_mem_gen_fc1_11: layer0_mlp_fc1_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_11.coe} \
] [get_ips blk_mem_gen_fc1_11]

generate_target all [get_ips blk_mem_gen_fc1_11]


# blk_mem_gen_fc1_12: layer0_mlp_fc1_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_12.coe} \
] [get_ips blk_mem_gen_fc1_12]

generate_target all [get_ips blk_mem_gen_fc1_12]


# blk_mem_gen_fc1_13: layer0_mlp_fc1_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_13.coe} \
] [get_ips blk_mem_gen_fc1_13]

generate_target all [get_ips blk_mem_gen_fc1_13]


# blk_mem_gen_fc1_14: layer0_mlp_fc1_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_14.coe} \
] [get_ips blk_mem_gen_fc1_14]

generate_target all [get_ips blk_mem_gen_fc1_14]


# blk_mem_gen_fc1_15: layer0_mlp_fc1_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_15.coe} \
] [get_ips blk_mem_gen_fc1_15]

generate_target all [get_ips blk_mem_gen_fc1_15]


# blk_mem_gen_fc1_16: layer0_mlp_fc1_16.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_16

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_16.coe} \
] [get_ips blk_mem_gen_fc1_16]

generate_target all [get_ips blk_mem_gen_fc1_16]


# blk_mem_gen_fc1_17: layer0_mlp_fc1_17.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_17

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_17.coe} \
] [get_ips blk_mem_gen_fc1_17]

generate_target all [get_ips blk_mem_gen_fc1_17]


# blk_mem_gen_fc1_18: layer0_mlp_fc1_18.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_18

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_18.coe} \
] [get_ips blk_mem_gen_fc1_18]

generate_target all [get_ips blk_mem_gen_fc1_18]


# blk_mem_gen_fc1_19: layer0_mlp_fc1_19.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_19

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_19.coe} \
] [get_ips blk_mem_gen_fc1_19]

generate_target all [get_ips blk_mem_gen_fc1_19]


# blk_mem_gen_fc1_20: layer0_mlp_fc1_20.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_20

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_20.coe} \
] [get_ips blk_mem_gen_fc1_20]

generate_target all [get_ips blk_mem_gen_fc1_20]


# blk_mem_gen_fc1_21: layer0_mlp_fc1_21.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_21

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_21.coe} \
] [get_ips blk_mem_gen_fc1_21]

generate_target all [get_ips blk_mem_gen_fc1_21]


# blk_mem_gen_fc1_22: layer0_mlp_fc1_22.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_22

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_22.coe} \
] [get_ips blk_mem_gen_fc1_22]

generate_target all [get_ips blk_mem_gen_fc1_22]


# blk_mem_gen_fc1_23: layer0_mlp_fc1_23.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_23

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_23.coe} \
] [get_ips blk_mem_gen_fc1_23]

generate_target all [get_ips blk_mem_gen_fc1_23]


# blk_mem_gen_fc1_24: layer0_mlp_fc1_24.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_24

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_24.coe} \
] [get_ips blk_mem_gen_fc1_24]

generate_target all [get_ips blk_mem_gen_fc1_24]


# blk_mem_gen_fc1_25: layer0_mlp_fc1_25.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_25

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_25.coe} \
] [get_ips blk_mem_gen_fc1_25]

generate_target all [get_ips blk_mem_gen_fc1_25]


# blk_mem_gen_fc1_26: layer0_mlp_fc1_26.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_26

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_26.coe} \
] [get_ips blk_mem_gen_fc1_26]

generate_target all [get_ips blk_mem_gen_fc1_26]


# blk_mem_gen_fc1_27: layer0_mlp_fc1_27.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_27

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_27.coe} \
] [get_ips blk_mem_gen_fc1_27]

generate_target all [get_ips blk_mem_gen_fc1_27]


# blk_mem_gen_fc1_28: layer0_mlp_fc1_28.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_28

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_28.coe} \
] [get_ips blk_mem_gen_fc1_28]

generate_target all [get_ips blk_mem_gen_fc1_28]


# blk_mem_gen_fc1_29: layer0_mlp_fc1_29.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_29

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_29.coe} \
] [get_ips blk_mem_gen_fc1_29]

generate_target all [get_ips blk_mem_gen_fc1_29]


# blk_mem_gen_fc1_30: layer0_mlp_fc1_30.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_30

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_30.coe} \
] [get_ips blk_mem_gen_fc1_30]

generate_target all [get_ips blk_mem_gen_fc1_30]


# blk_mem_gen_fc1_31: layer0_mlp_fc1_31.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_31

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_31.coe} \
] [get_ips blk_mem_gen_fc1_31]

generate_target all [get_ips blk_mem_gen_fc1_31]


# blk_mem_gen_fc1_32: layer0_mlp_fc1_32.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_32

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_32.coe} \
] [get_ips blk_mem_gen_fc1_32]

generate_target all [get_ips blk_mem_gen_fc1_32]


# blk_mem_gen_fc1_33: layer0_mlp_fc1_33.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_33

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_33.coe} \
] [get_ips blk_mem_gen_fc1_33]

generate_target all [get_ips blk_mem_gen_fc1_33]


# blk_mem_gen_fc1_34: layer0_mlp_fc1_34.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_34

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_34.coe} \
] [get_ips blk_mem_gen_fc1_34]

generate_target all [get_ips blk_mem_gen_fc1_34]


# blk_mem_gen_fc1_35: layer0_mlp_fc1_35.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_35

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_35.coe} \
] [get_ips blk_mem_gen_fc1_35]

generate_target all [get_ips blk_mem_gen_fc1_35]


# blk_mem_gen_fc1_36: layer0_mlp_fc1_36.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_36

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_36.coe} \
] [get_ips blk_mem_gen_fc1_36]

generate_target all [get_ips blk_mem_gen_fc1_36]


# blk_mem_gen_fc1_37: layer0_mlp_fc1_37.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_37

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_37.coe} \
] [get_ips blk_mem_gen_fc1_37]

generate_target all [get_ips blk_mem_gen_fc1_37]


# blk_mem_gen_fc1_38: layer0_mlp_fc1_38.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_38

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_38.coe} \
] [get_ips blk_mem_gen_fc1_38]

generate_target all [get_ips blk_mem_gen_fc1_38]


# blk_mem_gen_fc1_39: layer0_mlp_fc1_39.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_39

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_39.coe} \
] [get_ips blk_mem_gen_fc1_39]

generate_target all [get_ips blk_mem_gen_fc1_39]


# blk_mem_gen_fc1_40: layer0_mlp_fc1_40.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_40

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_40.coe} \
] [get_ips blk_mem_gen_fc1_40]

generate_target all [get_ips blk_mem_gen_fc1_40]


# blk_mem_gen_fc1_41: layer0_mlp_fc1_41.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_41

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_41.coe} \
] [get_ips blk_mem_gen_fc1_41]

generate_target all [get_ips blk_mem_gen_fc1_41]


# blk_mem_gen_fc1_42: layer0_mlp_fc1_42.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_42

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_42.coe} \
] [get_ips blk_mem_gen_fc1_42]

generate_target all [get_ips blk_mem_gen_fc1_42]


# blk_mem_gen_fc1_43: layer0_mlp_fc1_43.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_43

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_43.coe} \
] [get_ips blk_mem_gen_fc1_43]

generate_target all [get_ips blk_mem_gen_fc1_43]


# blk_mem_gen_fc1_44: layer0_mlp_fc1_44.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_44

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_44.coe} \
] [get_ips blk_mem_gen_fc1_44]

generate_target all [get_ips blk_mem_gen_fc1_44]


# blk_mem_gen_fc1_45: layer0_mlp_fc1_45.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_45

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_45.coe} \
] [get_ips blk_mem_gen_fc1_45]

generate_target all [get_ips blk_mem_gen_fc1_45]


# blk_mem_gen_fc1_46: layer0_mlp_fc1_46.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_46

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_46.coe} \
] [get_ips blk_mem_gen_fc1_46]

generate_target all [get_ips blk_mem_gen_fc1_46]


# blk_mem_gen_fc1_47: layer0_mlp_fc1_47.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_47

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_47.coe} \
] [get_ips blk_mem_gen_fc1_47]

generate_target all [get_ips blk_mem_gen_fc1_47]


# blk_mem_gen_fc1_48: layer0_mlp_fc1_48.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_48

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_48.coe} \
] [get_ips blk_mem_gen_fc1_48]

generate_target all [get_ips blk_mem_gen_fc1_48]


# blk_mem_gen_fc1_49: layer0_mlp_fc1_49.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_49

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_49.coe} \
] [get_ips blk_mem_gen_fc1_49]

generate_target all [get_ips blk_mem_gen_fc1_49]


# blk_mem_gen_fc1_50: layer0_mlp_fc1_50.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_50

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_50.coe} \
] [get_ips blk_mem_gen_fc1_50]

generate_target all [get_ips blk_mem_gen_fc1_50]


# blk_mem_gen_fc1_51: layer0_mlp_fc1_51.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_51

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_51.coe} \
] [get_ips blk_mem_gen_fc1_51]

generate_target all [get_ips blk_mem_gen_fc1_51]


# blk_mem_gen_fc1_52: layer0_mlp_fc1_52.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_52

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_52.coe} \
] [get_ips blk_mem_gen_fc1_52]

generate_target all [get_ips blk_mem_gen_fc1_52]


# blk_mem_gen_fc1_53: layer0_mlp_fc1_53.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_53

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_53.coe} \
] [get_ips blk_mem_gen_fc1_53]

generate_target all [get_ips blk_mem_gen_fc1_53]


# blk_mem_gen_fc1_54: layer0_mlp_fc1_54.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_54

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_54.coe} \
] [get_ips blk_mem_gen_fc1_54]

generate_target all [get_ips blk_mem_gen_fc1_54]


# blk_mem_gen_fc1_55: layer0_mlp_fc1_55.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_55

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_55.coe} \
] [get_ips blk_mem_gen_fc1_55]

generate_target all [get_ips blk_mem_gen_fc1_55]


# blk_mem_gen_fc1_56: layer0_mlp_fc1_56.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_56

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_56.coe} \
] [get_ips blk_mem_gen_fc1_56]

generate_target all [get_ips blk_mem_gen_fc1_56]


# blk_mem_gen_fc1_57: layer0_mlp_fc1_57.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_57

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_57.coe} \
] [get_ips blk_mem_gen_fc1_57]

generate_target all [get_ips blk_mem_gen_fc1_57]


# blk_mem_gen_fc1_58: layer0_mlp_fc1_58.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_58

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_58.coe} \
] [get_ips blk_mem_gen_fc1_58]

generate_target all [get_ips blk_mem_gen_fc1_58]


# blk_mem_gen_fc1_59: layer0_mlp_fc1_59.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_59

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_59.coe} \
] [get_ips blk_mem_gen_fc1_59]

generate_target all [get_ips blk_mem_gen_fc1_59]


# blk_mem_gen_fc1_60: layer0_mlp_fc1_60.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_60

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_60.coe} \
] [get_ips blk_mem_gen_fc1_60]

generate_target all [get_ips blk_mem_gen_fc1_60]


# blk_mem_gen_fc1_61: layer0_mlp_fc1_61.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_61

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_61.coe} \
] [get_ips blk_mem_gen_fc1_61]

generate_target all [get_ips blk_mem_gen_fc1_61]


# blk_mem_gen_fc1_62: layer0_mlp_fc1_62.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_62

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_62.coe} \
] [get_ips blk_mem_gen_fc1_62]

generate_target all [get_ips blk_mem_gen_fc1_62]


# blk_mem_gen_fc1_63: layer0_mlp_fc1_63.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc1_63

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc1/layer0_mlp_fc1_63.coe} \
] [get_ips blk_mem_gen_fc1_63]

generate_target all [get_ips blk_mem_gen_fc1_63]


# blk_mem_gen_fc2_0: layer0_mlp_fc2_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_00.coe} \
] [get_ips blk_mem_gen_fc2_0]

generate_target all [get_ips blk_mem_gen_fc2_0]


# blk_mem_gen_fc2_1: layer0_mlp_fc2_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_01.coe} \
] [get_ips blk_mem_gen_fc2_1]

generate_target all [get_ips blk_mem_gen_fc2_1]


# blk_mem_gen_fc2_2: layer0_mlp_fc2_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_02.coe} \
] [get_ips blk_mem_gen_fc2_2]

generate_target all [get_ips blk_mem_gen_fc2_2]


# blk_mem_gen_fc2_3: layer0_mlp_fc2_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_03.coe} \
] [get_ips blk_mem_gen_fc2_3]

generate_target all [get_ips blk_mem_gen_fc2_3]


# blk_mem_gen_fc2_4: layer0_mlp_fc2_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_04.coe} \
] [get_ips blk_mem_gen_fc2_4]

generate_target all [get_ips blk_mem_gen_fc2_4]


# blk_mem_gen_fc2_5: layer0_mlp_fc2_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_05.coe} \
] [get_ips blk_mem_gen_fc2_5]

generate_target all [get_ips blk_mem_gen_fc2_5]


# blk_mem_gen_fc2_6: layer0_mlp_fc2_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_06.coe} \
] [get_ips blk_mem_gen_fc2_6]

generate_target all [get_ips blk_mem_gen_fc2_6]


# blk_mem_gen_fc2_7: layer0_mlp_fc2_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_07.coe} \
] [get_ips blk_mem_gen_fc2_7]

generate_target all [get_ips blk_mem_gen_fc2_7]


# blk_mem_gen_fc2_8: layer0_mlp_fc2_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_08.coe} \
] [get_ips blk_mem_gen_fc2_8]

generate_target all [get_ips blk_mem_gen_fc2_8]


# blk_mem_gen_fc2_9: layer0_mlp_fc2_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_09.coe} \
] [get_ips blk_mem_gen_fc2_9]

generate_target all [get_ips blk_mem_gen_fc2_9]


# blk_mem_gen_fc2_10: layer0_mlp_fc2_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_10.coe} \
] [get_ips blk_mem_gen_fc2_10]

generate_target all [get_ips blk_mem_gen_fc2_10]


# blk_mem_gen_fc2_11: layer0_mlp_fc2_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_11.coe} \
] [get_ips blk_mem_gen_fc2_11]

generate_target all [get_ips blk_mem_gen_fc2_11]


# blk_mem_gen_fc2_12: layer0_mlp_fc2_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_12.coe} \
] [get_ips blk_mem_gen_fc2_12]

generate_target all [get_ips blk_mem_gen_fc2_12]


# blk_mem_gen_fc2_13: layer0_mlp_fc2_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_13.coe} \
] [get_ips blk_mem_gen_fc2_13]

generate_target all [get_ips blk_mem_gen_fc2_13]


# blk_mem_gen_fc2_14: layer0_mlp_fc2_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_14.coe} \
] [get_ips blk_mem_gen_fc2_14]

generate_target all [get_ips blk_mem_gen_fc2_14]


# blk_mem_gen_fc2_15: layer0_mlp_fc2_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_fc2_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/layer0_mlp_fc2/layer0_mlp_fc2_15.coe} \
] [get_ips blk_mem_gen_fc2_15]

generate_target all [get_ips blk_mem_gen_fc2_15]


# blk_mem_gen_lm_0: lm_head_00.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_0

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_00.coe} \
] [get_ips blk_mem_gen_lm_0]

generate_target all [get_ips blk_mem_gen_lm_0]


# blk_mem_gen_lm_1: lm_head_01.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_1

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_01.coe} \
] [get_ips blk_mem_gen_lm_1]

generate_target all [get_ips blk_mem_gen_lm_1]


# blk_mem_gen_lm_2: lm_head_02.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_2

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_02.coe} \
] [get_ips blk_mem_gen_lm_2]

generate_target all [get_ips blk_mem_gen_lm_2]


# blk_mem_gen_lm_3: lm_head_03.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_3

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_03.coe} \
] [get_ips blk_mem_gen_lm_3]

generate_target all [get_ips blk_mem_gen_lm_3]


# blk_mem_gen_lm_4: lm_head_04.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_4

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_04.coe} \
] [get_ips blk_mem_gen_lm_4]

generate_target all [get_ips blk_mem_gen_lm_4]


# blk_mem_gen_lm_5: lm_head_05.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_5

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_05.coe} \
] [get_ips blk_mem_gen_lm_5]

generate_target all [get_ips blk_mem_gen_lm_5]


# blk_mem_gen_lm_6: lm_head_06.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_6

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_06.coe} \
] [get_ips blk_mem_gen_lm_6]

generate_target all [get_ips blk_mem_gen_lm_6]


# blk_mem_gen_lm_7: lm_head_07.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_7

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_07.coe} \
] [get_ips blk_mem_gen_lm_7]

generate_target all [get_ips blk_mem_gen_lm_7]


# blk_mem_gen_lm_8: lm_head_08.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_8

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_08.coe} \
] [get_ips blk_mem_gen_lm_8]

generate_target all [get_ips blk_mem_gen_lm_8]


# blk_mem_gen_lm_9: lm_head_09.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_9

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_09.coe} \
] [get_ips blk_mem_gen_lm_9]

generate_target all [get_ips blk_mem_gen_lm_9]


# blk_mem_gen_lm_10: lm_head_10.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_10

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_10.coe} \
] [get_ips blk_mem_gen_lm_10]

generate_target all [get_ips blk_mem_gen_lm_10]


# blk_mem_gen_lm_11: lm_head_11.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_11

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_11.coe} \
] [get_ips blk_mem_gen_lm_11]

generate_target all [get_ips blk_mem_gen_lm_11]


# blk_mem_gen_lm_12: lm_head_12.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_12

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_12.coe} \
] [get_ips blk_mem_gen_lm_12]

generate_target all [get_ips blk_mem_gen_lm_12]


# blk_mem_gen_lm_13: lm_head_13.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_13

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_13.coe} \
] [get_ips blk_mem_gen_lm_13]

generate_target all [get_ips blk_mem_gen_lm_13]


# blk_mem_gen_lm_14: lm_head_14.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_14

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_14.coe} \
] [get_ips blk_mem_gen_lm_14]

generate_target all [get_ips blk_mem_gen_lm_14]


# blk_mem_gen_lm_15: lm_head_15.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_15

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_15.coe} \
] [get_ips blk_mem_gen_lm_15]

generate_target all [get_ips blk_mem_gen_lm_15]


# blk_mem_gen_lm_16: lm_head_16.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_16

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_16.coe} \
] [get_ips blk_mem_gen_lm_16]

generate_target all [get_ips blk_mem_gen_lm_16]


# blk_mem_gen_lm_17: lm_head_17.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_17

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_17.coe} \
] [get_ips blk_mem_gen_lm_17]

generate_target all [get_ips blk_mem_gen_lm_17]


# blk_mem_gen_lm_18: lm_head_18.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_18

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_18.coe} \
] [get_ips blk_mem_gen_lm_18]

generate_target all [get_ips blk_mem_gen_lm_18]


# blk_mem_gen_lm_19: lm_head_19.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_19

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_19.coe} \
] [get_ips blk_mem_gen_lm_19]

generate_target all [get_ips blk_mem_gen_lm_19]


# blk_mem_gen_lm_20: lm_head_20.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_20

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_20.coe} \
] [get_ips blk_mem_gen_lm_20]

generate_target all [get_ips blk_mem_gen_lm_20]


# blk_mem_gen_lm_21: lm_head_21.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_21

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_21.coe} \
] [get_ips blk_mem_gen_lm_21]

generate_target all [get_ips blk_mem_gen_lm_21]


# blk_mem_gen_lm_22: lm_head_22.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_22

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_22.coe} \
] [get_ips blk_mem_gen_lm_22]

generate_target all [get_ips blk_mem_gen_lm_22]


# blk_mem_gen_lm_23: lm_head_23.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_23

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_23.coe} \
] [get_ips blk_mem_gen_lm_23]

generate_target all [get_ips blk_mem_gen_lm_23]


# blk_mem_gen_lm_24: lm_head_24.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_24

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_24.coe} \
] [get_ips blk_mem_gen_lm_24]

generate_target all [get_ips blk_mem_gen_lm_24]


# blk_mem_gen_lm_25: lm_head_25.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_25

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_25.coe} \
] [get_ips blk_mem_gen_lm_25]

generate_target all [get_ips blk_mem_gen_lm_25]


# blk_mem_gen_lm_26: lm_head_26.coe
create_ip -name blk_mem_gen \
    -vendor xilinx.com -library ip -version 8.4 \
    -module_name blk_mem_gen_lm_26

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {BRAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Enable_A {Use_ENA_Pin} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Register_PortA_Output_of_Memory_Core {true} \
    CONFIG.Pipeline_Stages {0} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File {C:/Users/bertl/Desktop/project/inference-fpga/microgpt/generated/bram_split/lm_head/lm_head_26.coe} \
] [get_ips blk_mem_gen_lm_26]

generate_target all [get_ips blk_mem_gen_lm_26]


update_compile_order -fileset sources_1
puts "MicroGPT BRAM IP generation complete."
