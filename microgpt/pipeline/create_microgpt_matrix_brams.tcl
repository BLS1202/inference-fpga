# Create one wide, single-port BRAM for each matrix multiply.
# Run from an open Vivado project Tcl console.

set ROOT [file normalize [file join [file dirname [info script]] .. ..]]
set COE_DIR [file join $ROOT microgpt generated coe]
set CLOCK_PERIOD_NS 12.000

proc create_matrix_bram {module_name width depth coe_file clock_period} {
    if {[llength [get_ips -quiet $module_name]] != 0} {
        delete_ip [get_ips $module_name]
    }

    create_ip -name blk_mem_gen \
        -vendor xilinx.com -library ip -version 8.4 \
        -module_name $module_name

    set_property -dict [list \
        CONFIG.Memory_Type {Single_Port_RAM} \
        CONFIG.PRIM_type_to_Implement {BRAM} \
        CONFIG.Write_Width_A $width \
        CONFIG.Read_Width_A $width \
        CONFIG.Write_Depth_A $depth \
        CONFIG.Enable_A {Use_ENA_Pin} \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
        CONFIG.Register_PortA_Output_of_Memory_Core {true} \
        CONFIG.Pipeline_Stages {0} \
        CONFIG.Load_Init_File {true} \
        CONFIG.Coe_File $coe_file \
    ] [get_ips $module_name]

    generate_target all [get_ips $module_name]

    foreach ooc_xdc [get_files -all -filter "FILE_NAME =~ *_ooc.xdc"] {
        set path [get_property FILE_NAME $ooc_xdc]
        if {[file exists $path]} {
            set fh [open $path r]
            set contents [read $fh]
            close $fh
            regsub -all {-period 20\.0} $contents "-period $clock_period" contents
            set fh [open $path w]
            puts -nonewline $fh $contents
            close $fh
        }
    }
}

create_matrix_bram blk_mem_gen_0 16 432 [file join $COE_DIR wte_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_1 16 256 [file join $COE_DIR wpe_q12.coe] $CLOCK_PERIOD_NS

# Each weight BRAM stores the flattened matrix in row-major order.
create_matrix_bram blk_mem_gen_q   16 256 [file join $COE_DIR layer0_attn_wq_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_k   16 256 [file join $COE_DIR layer0_attn_wk_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_v   16 256 [file join $COE_DIR layer0_attn_wv_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_wo  16 256 [file join $COE_DIR layer0_attn_wo_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_fc1 16 1024 [file join $COE_DIR layer0_mlp_fc1_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_fc2 16 1024 [file join $COE_DIR layer0_mlp_fc2_q12.coe] $CLOCK_PERIOD_NS
create_matrix_bram blk_mem_gen_lm  16 432 [file join $COE_DIR lm_head_q12.coe] $CLOCK_PERIOD_NS

update_compile_order -fileset sources_1
puts "Created 9 full-matrix BRAM IPs."
