# Backward-compatible entry point for BRAM generation.
# The inference RTL now uses one flattened BRAM per matrix multiply.
source [file join [file dirname [info script]] create_microgpt_matrix_brams.tcl]
