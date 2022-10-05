
set ::env(DESIGN_NAME) customcells

# unused clock port, but definition is expected
 set ::env(CLOCK_PORT) ""
 set ::env(CLOCK_NET) $::env(CLOCK_PORT)
 set ::env(CLOCK_TREE_SYNTH) 0

# Verilog Source-Files
 set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

# Include Custom Standardcells
 set ::env(EXTRA_LEFS) [glob $::env(DESIGN_DIR)/src/*.lef]
 set ::env(EXTRA_LIBS) [glob $::env(DESIGN_DIR)/src/*.lib]
 set ::env(EXTRA_GDS_FILES) [glob $::env(DESIGN_DIR)/src/*.gds]
 set ::env(SYNTH_READ_BLACKBOX_LIB) 1

# Floorplanning
 set ::env(FP_SIZING) "absolute"
 set ::env(DIE_AREA) "0 0 150 100"
 set ::env(FP_CORE_UTIL) {65}
 set ::env(FP_PDN_HOFFSET) {11.6}
 set ::env(FP_PDN_VOFFSET) $::env(FP_PDN_HOFFSET)
 set ::env(FP_PDN_HPITCH) 29
 set ::env(FP_PDN_VPITCH) $::env(FP_PDN_HPITCH)
 set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

# PDN on Macro-Level. Hardening of a Macro, which is later placed in a Core
 set ::env(DESIGN_IS_CORE) 0
 set ::env(FP_PDN_CORE_RING) 0
 set ::env(RT_MAX_LAYER) {met4}
 set ::env(VDD_NETS) [list {VPWR} {VPB}]
 set ::env(GND_NETS) [list {VGND} {VNB}]

# Placement Settings
 set ::env(PL_BASIC_PLACEMENT) 1
 set ::env(PL_TARGET_DENSITY) {0.70}
 set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) {0}
 set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) {0}

# Router Settings
 set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) {0}



set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}


# OpenROAD reports unconnected nodes as a warning.
# OpenLane typically treats unconnected node warnings 
# as a critical issue, and simply quits.
#
# We'll be leaving it up to the designer's discretion to
# enable/disable this: if LVS passes you're probably fine
# with this option being turned off.
# set ::env(FP_PDN_CHECK_NODES) 0


