global P

if {[info exists P(TUNE_DTCD_MOVEMENT_SWITCH_ON)] && $P(TUNE_DTCD_MOVEMENT_SWITCH_ON) == 1} {
    if {[file exists  $P(BASE_DIR)/rpts/DTCD_Blockage.tcl]} {
        source -e -v $P(BASE_DIR)/rpts/DTCD_Blockage.tcl
    }
}
