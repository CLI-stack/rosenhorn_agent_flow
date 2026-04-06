source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/proc_pnr.tcl
if { [regexp "vdci" [get_attribute [current_design] name]]} {
    placeVdciPins
}

