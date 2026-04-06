source  /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/proc_pnr.tcl
if { [regexp "vdci" [get_attribute [current_design] name]]} {
    if {[info exists P(POWER_NET_NAME)] == 1} {
        set vdd_main [lindex $P(POWER_NET_NAME) 0]
        puts "# Found main power in P(POWER_NET_NAME) $P(POWER_NET_NAME)"
        checkVdciPin $vdd_main
    } else {
        puts "ERROR: POWER_NET_NAME not defined to get the main power. e.g. POWER_NET_NAME  = VDD_075_UCIS VDD_075_UCIS VDDCR_SOC VDDCR_SOC"
    }
}
