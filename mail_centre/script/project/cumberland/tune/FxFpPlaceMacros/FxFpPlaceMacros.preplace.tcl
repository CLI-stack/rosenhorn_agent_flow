# check unplace pin
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/check_and_fix_unplaced_ports.tcl
# check offtrack pin
if {[info exists P(PD_AGENT_FIX_OFFTRACK)]} {
    if {$P(PD_AGENT_FIX_OFFTRACK) == 1} {
        source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/check_fix_offtrack.tcl
    }
}
# check vdci pin
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_vdci_pin.tcl
# fix dtcd spacing issue
# source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/add_dtcd_blockage.tcl
# fix macro to boudary spacing
source /tool/aticad/1.0/src/zoo/PD_agent/tile/project/cumberland/fix_macro_boundary_spacing.tcl
# unfix mem
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/unfix_mem.tcl
# unfix macro
set macros {FTO_FIP_TSMCN3E_PERFROH143_B0 N03_DTCD_ALL_M11_220327 mapsmro_tsmc3ne17m}
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/unfix_macro.tcl
# check clock port distance far from center gravity of regs
source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/check_clock_port_distance.tcl 
# check if port on the opposite side of macro pins
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_port_edge.tcl
