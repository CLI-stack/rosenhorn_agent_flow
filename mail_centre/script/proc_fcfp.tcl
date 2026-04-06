source /tool/aticad/1.0/src/zoo/PD_agent/tile/proc_pinAssign_icc2.tcl 
proc placeListTiles {spec} {
set f [open $spec r]
set o [open placeListTiles.tcl w]
while {[gets $f line] >= 0} {
    set tile [lindex $line 0]
    set ori [lindex $line 1]
    set x [lindex $line 2]
    set y [lindex $line 3]
    if {[sizeof_collection [get_cells -quiet $tile]] == 0} {
        puts "$tile does not exist"
        continue
    }
    puts $o "set_cell_location -orientation $ori -coordinates {$x $y} $tile"
}
close $o
close $f
source  placeListTiles.tcl
}

proc writeBlockDef {block_def} {
set blocks [get_cells * -filter "hierarchy_type == block || design_type == macro" ]
write_def -objects $blocks $block_def
}

proc st {tiles} {
change_selection [get_cells $tiles]
}

proc sat {} {
change_selection [get_cells  * -filter "hierarchy_type == block"]
}

proc sam {} {
change_selection [ get_cells  -hierarchical  -filter "design_type == macro || is_physical_only == true"]
}


proc sut {} {
set_editability -from_level 0 -value true
change_selection [get_cells  * -filter "hierarchy_type == block && physical_status == unplaced"]
}

proc do {side spacing} {
distribute_objects -side $side -spacing $spacing [get_selection]
}

proc getSelectedArea {} {
set tot_area 0
foreach_in_collection inst [get_selection] {
    if {[sizeof_collection [get_cell -quiet $inst]] == 0} {
        puts "[get_object_name $inst] is not inst"
        continue
    }
    if {[get_attribute $inst design_type] == "lib_cell"} {
        puts "[get_object_name $inst] is not block"
        continue
    }
    set area [expr [get_attribute -quiet [get_cells $inst] area] / 1000000]
    if {[llength $area] == 0} {
        puts "# [get_object_name $inst] 0"
        continue
    }
    set tot_area [expr $tot_area + $area]
    set ref [get_attribute $inst ref_name]
    #puts "# [get_object_name $inst] $ref $area"
}
puts "# total area: $tot_area"
}

proc getArea {cells} {
set tot_area 0
foreach_in_collection inst [get_cells $cells] {
    set area [expr [get_attribute -quiet [get_cells $inst] area] / 1000000]
    if {[llength $area] == 0} {
        puts "# [get_object_name $inst] 0"
        continue
    }
    set tot_area [expr $tot_area + $area]
}
puts "# total area: $tot_area"
}



proc dumpTileCon {tile_list} {
source /home/simchen/vega20/pinAssign/proc_pinAssign_icc2.tcl 
set f [open $tile_list r]
while {[gets $f line] >= 0} {
    set tile [lindex $line 0]
    set all_pins [get_pins $tile/*]
    foreach_in_collection pin $all_pins {
        pin2Pin $pin
    }        
}
}

proc pin2Pin {pin} {
foreach_in_collection net [all_connected $pin] {
    if {[sizeof_collection  [all_connected $net]] > 2} {continue}
    puts "[get_object_name [all_connected $net]]"
}
}

proc saveCells {} {
set o [open saveCells.tcl w]
foreach_in_collection cell [get_selection] {
    set bbox [get_attribute $cell boundary_bbox]
    set x [lindex [lindex $bbox 0] 0]
    set y [lindex [lindex $bbox 0] 1]
    set cell_name [get_object_name $cell]
    set ori [get_attribute [get_cells $cell] orientation]

    puts $o "set_cell_location \[get_cells $cell_name\]  -coordinates {$x $y} -ignore_fixed -orientation $ori"
}
close $o
}

proc getPinBlockageArea {} {
set tot_area 0
foreach_in_collection bkg [get_pin_blockages -design [current_design ]] {
    set bbox [get_attribute $bkg bbox]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set urx [lindex [lindex $bbox 1] 0]
    set ury [lindex [lindex $bbox 1] 1]
    puts "$llx $lly $urx $ury"
    set area [expr ($urx - $llx)*($ury - $lly)/1000000]
    set tot_area  [expr $tot_area + $area]
}
puts "# total area: $tot_area"
}


proc rtf {factor} {
set area [get_attribute [get_selection] area]
gui_set_object_shape -shape rect -lengths {1.0000 1.1463} -area [expr $area*$factor]
}

proc resizeTilebyArea {dir area} {
if {$area < 100} {
    set area [expr $area * 1000000]
}
set width  [get_attribute [get_selection] width]
set height  [get_attribute [get_selection] height]

if {$dir == 0} {
    set ratio [expr $area / ($width*$width)]
    puts "gui_set_object_shape -shape rect -lengths {1.00 $ratio} -area $area"
    eval "gui_set_object_shape -shape rect -lengths {1.0 $ratio}   -area $area"
} else {
    set ratio [expr $area / ($height*$height)]
    puts "gui_set_object_shape -shape rect -lengths {1.00 $ratio} -area $area"
    eval "gui_set_object_shape -shape rect -lengths {$ratio 1.0}   -area $area"
}
}


proc createSignTSV {x_offset y_offset} {
set pitch_x 15
set pitch_y 17.28
set size 5
set col 23
set f [open createSignTSV.tcl w]
set llx [lindex [lindex [get_attribute [current_design] bbox] 0] 0]
set lly [lindex [lindex [get_attribute [current_design] bbox] 0] 1]
set urx [lindex [lindex [get_attribute [current_design] bbox] 1] 0]
set ury [lindex [lindex [get_attribute [current_design] bbox] 1] 1]
set row [expr round(($ury - $lly) / $pitch_y)]
set x [expr $llx + $x_offset]
set y [expr $lly + $y_offset]
puts "$llx $lly $urx $ury $row"
for { set i 0 } { $i < $row } {incr i} {
    for { set j 0 } { $j < $col } {incr j} { 
        set x [expr $x +  $pitch_x]
        set llx_tsv [expr $x - $size / 2]
        set urx_tsv [expr $x + $size / 2]
        set lly_tsv [expr $y - $size / 2]
        set ury_tsv [expr $y + $size / 2]
        puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
    }
    set y [expr $y +  $pitch_y]
    set x [expr $llx + $x_offset]
}
close $f
source createSignTSV.tcl
} 



proc createVDDMEMTSV {x_offset y_offset} {
set pitch_x 9
set pitch_y 17.28
set pitch_n 260
set size 5
set col 2
set f [open createVDDMEMTSV.tcl w]
set llx [lindex [lindex [get_attribute [current_design] bbox] 0] 0]
set lly [lindex [lindex [get_attribute [current_design] bbox] 0] 1]
set urx [lindex [lindex [get_attribute [current_design] bbox] 1] 0]
set ury [lindex [lindex [get_attribute [current_design] bbox] 1] 1]
set row [expr round(($ury - $lly) / $pitch_y)]
set group [expr round(($urx - ($llx + $x_offset))/$pitch_n)]
set x [expr $llx + $x_offset]
set y [expr $lly + $y_offset]
puts "$llx $lly $urx $ury $row"
for { set n 0 } { $n <= $group } {incr n} {
    for { set i 0 } { $i < $row } {incr i} {
        for { set j 0 } { $j < $col } {incr j} {
            set x [expr $x +  $pitch_x]
            set llx_tsv [expr $x - $size / 2]
            set urx_tsv [expr $x + $size / 2]
            set lly_tsv [expr $y - $size / 2]
            set ury_tsv [expr $y + $size / 2]
            puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
        }
        set y [expr $y +  $pitch_y]
        set x [expr $llx + $x_offset + $pitch_n * $n]
    }
    set y [expr $lly + $y_offset]
    set x [expr $llx + $x_offset + $pitch_n * $n]

}
close $f
source createVDDMEMTSV.tcl
}

proc createVDDMTSV {x_offset y_offset col} {
set pitch_x 9
set pitch_y 17.28
set size 5
set f [open createVDDMTSV.tcl w]
set llx [lindex [lindex [get_attribute [current_design] bbox] 0] 0]
set lly [lindex [lindex [get_attribute [current_design] bbox] 0] 1]
set urx [lindex [lindex [get_attribute [current_design] bbox] 1] 0]
set ury [lindex [lindex [get_attribute [current_design] bbox] 1] 1]
set row [expr round(($ury - $lly) / $pitch_y)]
set x [expr $llx + $x_offset]
set y [expr $lly + $y_offset]
puts "$llx $lly $urx $ury $row"
for { set i 0 } { $i < $row } {incr i} {
    for { set j 0 } { $j < $col } {incr j} {
        set x [expr $x +  $pitch_x]
        set llx_tsv [expr $x - $size / 2]
        set urx_tsv [expr $x + $size / 2]
        set lly_tsv [expr $y - $size / 2]
        set ury_tsv [expr $y + $size / 2]
        puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
    }
    set y [expr $y +  $pitch_y]
    set x [expr $llx + $x_offset]
}
close $f
source createVDDMTSV.tcl
}



proc drawX3DTSV {x_orig y_orig} {
set pitch_x 9
set pitch_y 17.28
set pitch_n 260
set size 5
set col 2

set f [open drawX3DTSV.tcl w]
set x_offset 0
set y_offset 0
set x [expr $x_orig + $x_offset]
set y [expr $y_orig + $y_offset]

set row [expr round(6600 / $pitch_y)]
set group [expr round(1040/$pitch_n)]
for { set n 0 } { $n <= $group } {incr n} {
    for { set i 0 } { $i < $row } {incr i} {
        for { set j 0 } { $j < $col } {incr j} {
            set x [expr $x +  $pitch_x]
            set llx_tsv [expr $x - $size / 2]
            set urx_tsv [expr $x + $size / 2]
            set lly_tsv [expr $y - $size / 2]
            set ury_tsv [expr $y + $size / 2]
            puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
        }
        set y [expr $y +  $pitch_y]
        set x [expr $x_orig + $x_offset + $pitch_n * $n]
    }
    set y [expr $y_orig + $y_offset]
    set x [expr $x_orig + $x_offset + $pitch_n * $n]

}

set x_offset 1620
set y_offset 0

set x [expr $x_orig + $x_offset]
set y [expr $y_orig + $y_offset]

for { set n 0 } { $n <= $group } {incr n} {
    for { set i 0 } { $i < $row } {incr i} {
        for { set j 0 } { $j < $col } {incr j} {
            set x [expr $x +  $pitch_x]
            set llx_tsv [expr $x - $size / 2]
            set urx_tsv [expr $x + $size / 2]
            set lly_tsv [expr $y - $size / 2]
            set ury_tsv [expr $y + $size / 2]
            puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
        }
        set y [expr $y +  $pitch_y]
        set x [expr $x_orig + $x_offset + $pitch_n * $n]
    }
    set y [expr $y_orig + $y_offset]
    set x [expr $x_orig + $x_offset + $pitch_n * $n]

}

set x_offset 2900
set y_offset 0

set x [expr $x_orig + $x_offset]
set y [expr $y_orig + $y_offset]
for { set n 0 } { $n <= $group } {incr n} {
    for { set i 0 } { $i < $row } {incr i} {
        for { set j 0 } { $j < $col } {incr j} {
            set x [expr $x +  $pitch_x]
            set llx_tsv [expr $x - $size / 2]
            set urx_tsv [expr $x + $size / 2]
            set lly_tsv [expr $y - $size / 2]
            set ury_tsv [expr $y + $size / 2]
            puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
        }
        set y [expr $y +  $pitch_y]
        set x [expr $x_orig + $x_offset + $pitch_n * $n]
    }
    set y [expr $y_orig + $y_offset]
    set x [expr $x_orig + $x_offset + $pitch_n * $n]

}


set x_offset [expr 2900 + 1620]
set y_offset 0
for { set n 0 } { $n <= $group } {incr n} {
    for { set i 0 } { $i < $row } {incr i} {
        for { set j 0 } { $j < $col } {incr j} {
            set x [expr $x +  $pitch_x]
            set llx_tsv [expr $x - $size / 2]
            set urx_tsv [expr $x + $size / 2]
            set lly_tsv [expr $y - $size / 2]
            set ury_tsv [expr $y + $size / 2]
            puts $f "create_placement_blockage -boundary {{$llx_tsv $lly_tsv} {$urx_tsv $ury_tsv}} -type hard"
        }
        set y [expr $y +  $pitch_y]
        set x [expr $x_orig + $x_offset + $pitch_n * $n]
    }
    set y [expr $y_orig + $y_offset]
    set x [expr $x_orig + $x_offset + $pitch_n * $n]

}

close $f
source drawX3DTSV.tcl

}

proc addPma {} {
create_cell pma0 [get_lib_cells */dwc_pcie4esm_pma_x4_ns]
create_cell pma1 [get_lib_cells */dwc_pcie4esm_pma_x4_ns]
create_cell pma2 [get_lib_cells */dwc_pcie4esm_pma_x4_ns]
create_cell pma3 [get_lib_cells */dwc_pcie4esm_pma_x4_ns]
}

proc addHbm {} {
create_cell hbm [get_lib_cells */dwc_hbmphy_top]
}
 
proc dumpMacroPowerPin {} {
set all_macros [get_cells * -hier -filter "design_type == macro"]
foreach_in_collection macro $all_macros {
    set bbox [get_attribute $macro bbox]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set macro_name [get_object_name $macro]
    set pins [get_pins -quiet $macro_name/* -filter "port_type == power"]
    if {[sizeof_collection $pins] == 0} { continue}
    set pin_list ""
    foreach_in_collection pin $pins {
        set pin_list "$pin_list [get_attribute $pin name]"
    }
    puts "[get_object_name $macro] $llx $lly $pin_list"
}
}

proc checkXmlClk {xml} {
set f [open $xml r ]
set top [get_attribute [current_design] name]
set valid 0
while {[gets $f line] >= 0} {
    if {[regexp {tile_flavor\s+tile=\"(\S+)\"\s+flavor=\"(\S+)\"} $line match tile flavor] && $valid == 0} {
        puts "$tile $flavor $top"
        if {[regexp "$top" $tile]} {
            set valid 1
            set o [open $top.checkXml.rpt w]
            set os [open $top.checkScan.rpt w]
        } 
    }
    if {$valid == 0} {
        continue
    }
    if {[regexp {<scan_rep_info sdc_clk=\"(\S+)\"\s+pwrdomain=\"(\S+)\"\s+scan_instpin=\"(\S+)\"\s+core_scan_enable=\"(\S+)\"\s+output_scan_enable=\"(.*)\"\s+input_scan_enable=\"(.*)\"\s+limit=\"(\S+)\"\s+/>} $line match sdc_clk domain scan_instpin core_scan_enable output_scan_enable  input_scan_enable limit] && $valid ==1} {
        puts "$sdc_clk $domain $scan_instpin $core_scan_enable $output_scan_enable $input_scan_enable  $limit"
        if {[sizeof_collection [get_pins -quiet $scan_instpin]] ==0 && [llength $scan_instpin] > 0} {
            puts $os "$top $scan_instpin"
        }
        if {[sizeof_collection [get_pins -quiet $core_scan_enable]] ==0  && [llength $core_scan_enable] > 0} {
            puts $os "$top $core_scan_enable"
        }
        if {[sizeof_collection [get_pins -quiet $output_scan_enable]] ==0  && [llength $output_scan_enable] > 0} {
            puts $os "$top $output_scan_enable"
        }
        if {[sizeof_collection [get_pins -quiet $input_scan_enable]] ==0  && [llength $input_scan_enable] > 0} {
            puts $os "$top $input_scan_enable"
        }

    }
    if {[regexp {clock\s+sdc_clk=\"(\S+)\"\s+domain=\"(\S+)\"\s+root=\"(\S+)\"} $line match sdc_clk domain root] && $valid ==1} {
        puts "$sdc_clk $domain $root"
        if {[sizeof_collection [get_pins -quiet $root]] ==0 && [sizeof_collection [get_ports -quiet $root]] == 0} {
            puts $o "$top $root"
        }

    }

    if {[regexp {\<\/tile_flavor\>} $line]} {
        set valid 0
    }
}
close $f
close $o
close $os
}

proc checkPdXml {xml} {
set ir [open /home/simchen/mi100/fcfp/inst_ref.list r]
while {[gets $ir line] >= 0} {
    set inst [lindex $line 0]
    set ref [lindex $line 1]
    set inst_ref($inst) $ref
}
set f [open $xml r ]
set top [get_attribute [current_design] name]
set valid 0
set oi [open $top.checkPdRepXml.rpt w]
set rpt_flag 0
while {[gets $f line] >= 0} {
    if {[regexp {<repInstance\s+id=\"(\S+)\"\s+instName=\"(\S+)\"\s+order=\"(\S+)\"\s+parentInstance=\"(\S+)\"\s+scan_enable_type=\"(\S+)\"\s+usageCount=\"(\S+)\"} $line match id instName order parentInstance scan_enable_type usageCount]} {
        if {[info exists inst_ref($parentInstance)]} {
    
            if {$top == "$inst_ref($parentInstance)"} {
                set instName_h($instName) 1
                if {[sizeof_collection [get_cells -quiet $instName]] ==0} {
                    puts $oi "$instName in xml missing in netlist"
                }
            }
        }
    }
    if {[regexp {<clkGateInst\s+id=\"(\S+)\"\s+instName=\"(\S+)\"\s+order=\"(\S+)\"\s+parentInstance=\"(\S+)\"\s+scan_enable_type=\"(\S+)\"\s+usageCount=\"(\S+)\"} $line match id instName order parentInstance scan_enable_type usageCount]} {
        if {[info exists inst_ref($parentInstance)]} {

            if {$top == "$inst_ref($parentInstance)"} {
                set instName_h($instName) 1
                if {[sizeof_collection [get_cells -quiet $instName]] ==0} {
                    puts $oi "$instName in xml missing in netlist"
                }
            }
        }
    }

    if {[regexp {tile_flavor\s+flavor=\"(\S+)\"\s+tile=\"(\S+)\"} $line match tile flavor] && $valid == 0} {
        puts "$tile $flavor $top"
        if {[regexp "$top" $tile]} {
            set valid 1
            #set o [open $top.checkPdXml.rpt w]
            set rpt_flag  1
            #set os [open $top.checkPdScan.rpt w]
        }
    }
    if {$valid == 0} {
        continue
    }
    if {[regexp {<scan_rep_info sdc_clk=\"(\S+)\"\s+pwrdomain=\"(\S+)\"\s+scan_instpin=\"(\S+)\"\s+core_scan_enable=\"(\S+)\"\s+output_scan_enable=\"(.*)\"\s+input_scan_enable=\"(.*)\"\s+limit=\"(\S+)\"\s+/>} $line match sdc_clk domain scan_instpin core_scan_enable output_scan_enable  input_scan_enable limit] && $valid ==1} {
        puts "$sdc_clk $domain $scan_instpin $core_scan_enable $output_scan_enable $input_scan_enable  $limit"
        if {[sizeof_collection [get_pins -quiet $scan_instpin]] ==0 && [llength $scan_instpin] > 0} {
            #puts $os "$top $scan_instpin"
        }
        if {[sizeof_collection [get_pins -quiet $core_scan_enable]] ==0  && [llength $core_scan_enable] > 0} {
            #puts $os "$top $core_scan_enable"
        }
        if {[sizeof_collection [get_pins -quiet $output_scan_enable]] ==0  && [llength $output_scan_enable] > 0} {
            #puts $os "$top $output_scan_enable"
        }
        if {[sizeof_collection [get_pins -quiet $input_scan_enable]] ==0  && [llength $input_scan_enable] > 0} {
            #puts $os "$top $input_scan_enable"
        }

    }
    if {[regexp {clock\s+sdc_clk=\"(\S+)\"\s+domain=\"(\S+)\"\s+root=\"(\S+)\"} $line match sdc_clk domain root] && $valid ==1} {
        puts "$sdc_clk $domain $root"
        if {[sizeof_collection [get_pins -quiet $root]] ==0 && [sizeof_collection [get_ports -quiet $root]] == 0} {
            #puts $o "$top $root"
        }

    }

    if {[regexp {\<\/tile_flavor\>} $line]} {
        set valid 0
    }
}
foreach_in_collection inst [get_cells FCFPRep* -filter "is_sequential == true"] {
    set instName [get_object_name $inst]
    #puts "$instName"
    if {[info exists instName_h($instName)]} {
        
    } else {
        #puts "$instName"
        set drv [filter_collection [all_connected [all_connected $instName/D] -leaf] "direction == out"]
        if {[sizeof_collection $drv] > 0} {
            set drv_cell [get_cells -of_objects $drv]
            set drv_cell_ref [get_attribute $drv_cell ref_name]
            if {[regexp {TIE} $drv_cell_ref]} {
                continue
            }
            puts $oi "$instName in netlist missing in xml"
       } 
    }
}
close $f
close $oi
if {$rpt_flag == 1} {
    #close $o
    #close $os
}
}



proc checkXmlNet {xml} {
set f [open $xml r ]
set o [open $xml.fix w]
set rpt [open checkXml.net.rpt w]
while {[gets $f line] >= 0} {
    puts $line
    if {[regexp {net\s+name=\"(\S+)\"\s+bundle=\"(\S+)\"\s+orig_bundle=\"(\S+)\"\s+rep_type=\"(\S+)\"\s+fgcg_ctrl=\"(\S+)\"\s+sig_type=\"(\S+)\"} $line match net_name bundle_name orig_bundle_name rep_type fgcg_crtl sig_type] == 1} {
        if {[sizeof_collection [get_nets -quiet $net_name]] ==0} {
            puts $rpt "$net_name"
            continue
        }
    }   
    puts $o "$line"
}
close $f
close $rpt
close $o
}
   
proc hackfeedthruxml {topXml feedXml} {
set f [open $topxml r ]
set ff [open feedXml r]
#set top [get_attribute [current_design] name]
set valid 0
while {[gets $f line] >= 0} {
    if {[regexp {tile_flavor\s+tile=\"(\S+)\"\s+flavor=\"(\S+)\"} $line match tile flavor] && $valid == 0} {
        puts "$tile $flavor $top"
        if {[regexp "$top" $tile]} {
            set valid 1
        }
    }
    if {$valid == 0} {
        continue
    }
    if {[regexp {clock\s+sdc_clk=\"(\S+)\"\s+domain=\"(\S+)\"\s+root=\"(\S+)\"} $line match sdc_clk domain root] && $valid ==1} {
        puts "$sdc_clk $domain $root"
        if {[sizeof_collection [get_pins -quiet $root]] ==0} {
            puts $o "$top $root"
        }
        set clock_root_name [get_object_name $root]
        set clock_pin_domian($clock_root_name) $domain

    }
    if {[regexp {\<\/tile_flavor\>} $line]} {
        set valid 0
    }
}
close $f


close $o
}

 
proc snapTiles {tiles} {
foreach_in_collection tile [get_cells $tiles -filter "hierarchy_type == block"] {
    set ref_name [get_attribute $tile ref_name]
    set tile_name [get_object_name $tile]
     fixInstShape $tile_name 0
    #set ref_h($ref_name) $tile_name
}

check_tile_overlaps
}


proc sst {} {
foreach_in_collection tile [get_selection] {
    fixInstShape [get_object_name $tile] 0
}
}


proc calWhiteSpace {} {
set tot_area 0
foreach_in_collection shape [get_placement_blockages] {
    set area [get_attribute $shape area]
    set tot_area [expr $tot_area + $area]
    puts "[get_object_name $shape] $area"
}
puts "# White space: $tot_area"
}

proc genDie {w h} {
puts "# Check grid [expr $w / 5.472] [expr $h/4.8]"
# w should be (2n + 1) * 5.472
set w [expr (round(round($w / 5.472)/2)*2 + 1)*5.472 + 1.881]
#set w [expr round(($w / 5.472) )*5.472 + 1.824]
set h [expr round(($h / 4.8))*4.8]
puts "# Snap $w $h"
set p0  "[expr $w/2*(-1)] [expr $h/2*(-1)]"
set p1 "[expr $w/2*(-1)] [expr $h/2]"
set p2 "[expr $w/2] [expr $h/2]"
set p3 "[expr $w/2] [expr $h/2*(-1)]"
puts "initialize_floorplan -boundary \{\{$p0\} \{$p1\} \{$p2\} \{$p3\}\} -site_def TS06_DST -pin_snap wire_track"

}

proc initializeFP {} {
initialize_floorplan -keep_boundary -keep_placement all -site_def TS06_DST -pin_snap wire_track
}

proc setCenterCoor {} {
set bbox [get_attribute [current_design] boundary_bbox]
set lx [lindex [lindex $bbox 0] 0]
set ly [lindex [lindex $bbox 0] 1]
set hx [lindex [lindex $bbox 1] 0]
set hy [lindex [lindex $bbox 1] 1]
move_block_origin -to "[expr ($lx + $hx)/2] [expr ($ly + $hy)/2]" 
}

proc calAreaDelta { x y} {
set x_orig 21303
set y_orig 26883
set x_new [expr $x_orig + $x]
set y_new [expr $y_orig + $y]
set area [expr ($x_new * $y_new - $x_orig * $y_orig) / 1000000]
puts "$area"
}


proc reportUtil {} {
set macro_area 0
foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro && ref_name !~ *ovl*" ] {
    set macro_area [expr $macro_area+[get_attribute $macro area]]
}
set cell_area 0
foreach_in_collection cell [get_cells -hierarchical * -filter "design_type == lib_cell" ] {
    set cell_area [expr $cell_area+[get_attribute $cell area]]
}
set core_area [get_attribute [current_design] core_area_area]
set util [expr $cell_area / ($core_area - $macro_area)]
puts "# cell_area macro_area core_area util"
puts "util: $cell_area $macro_area $core_area $util"
}

proc moveTile {dir dis} {
foreach_in_collection tile [get_selection] {
    set bbox [get_attribute [get_cells $tile] boundary_bbox]
    set lx [lindex [lindex $bbox 0] 0]
    set ly [lindex [lindex $bbox 0] 1]
    if {$dir ==0} {
        set dis [expr round($dis / 10.944) * 10.944]
        set lx [expr $lx + $dis]
        puts "set_cell_location -coordinates {$lx $ly} [get_object_name $tile]"
        eval "set_cell_location -coordinates {$lx $ly} [get_cells $tile]"
    } else {
        set dis [expr round($dis / 2.4 * 2.4]
        set ly [expr $ly + $dis]
        eval "set_cell_location -coordinates {$lx $ly} [get_cells $tile]"
    }
}
}

proc moveTileCustom {dir dis}  {
foreach_in_collection tile [get_selection] {
    set bbox [get_attribute [get_cells $tile] boundary_bbox]
    set lx [lindex [lindex $bbox 0] 0]
    set ly [lindex [lindex $bbox 0] 1]
    if {$dir ==0} {
        set lx [expr $lx + $dis]
        puts "set_cell_location -coordinates {$lx $ly} [get_object_name $tile]"
        eval "set_cell_location -coordinates {$lx $ly} [get_cells $tile]"
    } else {
        set ly [expr $ly + $dis]
        eval "set_cell_location -coordinates {$lx $ly} [get_cells $tile]"
    }
}
}

proc mergePackage {pkg} {
set f [open $pkg r]
set o [open mergePackage.tcl w]
set l [open macros.list w]
set rpt [open movement.rpt w]
puts $o "set_cell_location -coordinates {0 0} \[get_cells * -hierarchical -filter \"full_name =~ io_t/*\"\]"
while {[gets $f line] >= 0} {
    set valid 0
    if {[regexp {\-\s+(\S+)\s+(\S+)\s+\+\s+(\S+)\s+\(\s+(\S+)\s+(\S+)\s+\)\s+(\S+)\s+} $line match inst ref status x y ori] == 1} {
        set x [expr $x / 2000.0]
        set y [expr $y / 2000.0]
        set x_h($inst) $x
        set y_h($inst) $y
        if {[sizeof_collection [get_cells -quiet $inst]] == 0} {
            puts "$line"
            continue
        }
        set valid 1
    }
    if {[regexp {\-\s+(\S+)\s+(\S+)\s+\+\s+SOURCE\s+DIST\s+\+\s+(\S+)\s+\(\s+(\S+)\s+(\S+)\s+\)\s+(\S+)\s+} $line match inst ref status x y ori] == 1} {
        set x [expr $x / 2000.0]
        set y [expr $y / 2000.0]
        set x_h($inst) $x
        set y_h($inst) $y
        if {[sizeof_collection [get_cells -quiet $inst]] == 0} {
            puts "$line"
            continue
        }
        set valid 1
    } 
    if {$valid == 1} {
        #puts "$inst $valid"
        set tile_inst [lindex [regsub {/} $inst { }] 0]
        set tile_ref [get_attribute $tile_inst ref_name]
        set tile_ref_inst [regsub "$tile_inst" $inst "$tile_ref"]
        set macro [regsub "$tile_inst/" $inst ""]
        set macros_h($macro)  1
        set ref_orig [get_attribute $inst ref_name]
        if {[regexp "$ref" $ref_orig] == 0} {
            set inst_ref($inst) $ref
            set inst_ref_orig($inst) $ref_orig
        }
        set bbox [get_attribute [get_cells $inst] boundary_bbox]
        set ori_new [get_attribute [get_cells $inst] orientation ]
        if {$ori_new == "R0"} {
            set ori_new "N"
        } elseif  {$ori_new == "MY"} {
            set ori_new "FN"
        }  elseif  {$ori_new == "MX"} {
             set ori_new "FS"
        }  elseif  {$ori_new == "R180"} {
             set ori_new "S"
        }

        set x_new [lindex [lindex $bbox 0] 0]
        set y_new [lindex [lindex $bbox 0] 1]
        set x_new_h($inst) $x_new
        set y_new_h($inst) $y_new
        set x_d [expr $x_new - $x]
        set y_d [expr $y_new - $y]
        set dis [expr abs($x_d) + abs($y_d)]
        #puts  "$inst $ori $ori_new $x_new_h($inst) $x_h($inst) $y_new_h($inst) $y_h($inst) $x_d $y_d"
        if {$dis > 0 || $ori != $ori_new} {
            puts $rpt "$inst $ori $ori_new $x_new_h($inst) $x_h($inst) $y_new_h($inst) $y_h($inst) $x_d $y_d"
            #puts "$inst $ori $ori_new $x_new_h($inst) $x_h($inst) $y_new_h($inst) $y_h($inst) $x_d $y_d"
        }
        if {[regexp {\bio_t} $tile_ref] == 0} {
            if {[info exists tile_ref_h($tile_ref_inst)] || [regexp {smu_clk|hbm|xgmi_cphy|pcie_cphy|tmon|thm|walf} $inst] == 1} {
                puts $o "set_cell_location -coordinates {$x $y} \[get_cells $inst\] -orientation $ori -ignore_fixed"
            } else {
                set  tile_ref_h($tile_ref_inst) 1
                puts $o "set_cell_location -coordinates {$x $y} \[get_cells $inst\] -orientation $ori -ignore_fixed"
            }
        }
    }
}
foreach inst [array names inst_ref] {
    puts "$inst $inst_ref_orig($inst) $inst_ref($inst)"
}
foreach macro [array names macros_h] {
    puts $l "$macro"
}
close $rpt
close $f
close $o
close $l
}
    
proc genPushDownTileList {} {
set tiles [get_cells  * -filter "hierarchy_type == block"]
set tiles [add_to_collection $tiles [get_cells  compute_array*/* -filter "hierarchy_type == block"]]
set tiles [filter_collection $tiles "orientation == R0"]
foreach_in_collection tile $tiles {
    set ref [get_attribute $tile ref_name]
    set tile_name [get_attribute $tile full_name]
    if {[info exists ref_h($ref)]} {
        #puts "$ref:$tile_name"
        continue
    } else {
        set ref_h($ref) $tile_name
    }
}
foreach ref [array names ref_h] {
    puts "$ref:$ref_h($ref)"
}
}

proc getRtlRepOrder {} {
set all_nets [get_nets  *BufRls*]
foreach_in_collection net $all_nets {
    set pins [filter_collection [all_connected $net -leaf] "full_name !~ *SI" ]

    set input [get_object_name [filter_collection $pins "direction == in"]]
    set output [get_object_name [filter_collection $pins "direction == out"]]
    if {[sizeof_collection  [filter_collection $pins "direction == in"]] == 0} {
        set output_port [filter_collection $pins "object_class == port"] 
        set output_pin [filter_collection $pins "object_class == pin"]
        set cell [get_object_name [get_cells -of_objects $output_pin]]
        set cell_out($cell) [get_object_name $output_pin] 
        set cell_outport($cell) [get_object_name $output_port]
        set output_port [get_object_name $output_port]
        set output_port_h($output_port) $cell
        continue
    }
    if {[sizeof_collection  [filter_collection $pins "direction == out"]] == 0} {
        set input_port [filter_collection $pins "object_class == port"]
        set input_pin [filter_collection $pins "object_class == pin"]
        set pin_name [get_attribute $input_pin name]
        set i [regsub {[A-Z]} $pin_name {}]
        set cell "[get_object_name [get_cells -of_objects $input_pin]] $i"
        set cell_in($cell) [get_object_name $input_pin] 
        set cell_inport($cell) [get_object_name $input_port]
        set input_port [get_object_name $input_port]
        set input_port_h($input_port) $cell
        continue
    }
    set input_pin [get_object_name [filter_collection $pins "direction == in"]]
    set pin_name [get_attribute $input_pin name]
    set i [regsub {[A-Z]} $pin_name {}]
    set output_pin  [get_object_name [filter_collection $pins "direction == out"]]
    set in_cell "[get_object_name [get_cells -of_objects $input_pin]] $i"
    set cell_in($in_cell) [get_object_name $input_pin]
    set pin_name [get_attribute $output_pin name]
    set i [regsub {[A-Z]} $pin_name {}]
    set out_cell "[get_object_name [get_cells -of_objects $output_pin]] $i"
    set cell_out($out_cell) [get_object_name $output_pin]
    set cell_h($out_cell) $in_cell
    #puts "# [get_object_name $net] $out_cell $in_cell"

}
set n 0
foreach port [array names input_port_h] {
    set n 0
    set stop 0
    set chain ""
    if {[info exists input_port_h($port)]} {
        set current_cell $input_port_h($port)
        set chain_h($port) "[lindex $current_cell 0]"
        #puts "$port $input_port_h($port)"
    } else {
        continue
    }
    while {$stop == 0} {
        incr n
        if {[info exists cell_h($current_cell)]} {
            #puts "$current_cell  $cell_h($current_cell)"
            set current_cell $cell_h($current_cell)
            set chain_h($port) "$chain_h($port) [lindex $current_cell 0]"
        } else {
            set stop 1
        }
        if {$n > 100} {
            break
        }
    }
        
}
foreach port [array names chain_h] {
    puts "## $port $chain_h($port)"
}
}

proc fixMacroLoc {insts} {
set o [open fixMacroLoc.tcl w]
set f [open fixMacroLoc.rpt w]
foreach_in_collection inst [get_cells $insts] {
    set bbox [get_attribute [get_cells $inst] boundary_bbox]
    set ori [get_attribute [get_cells $inst] orientation ]
    set x [lindex [lindex $bbox 0] 0]
    set y [lindex [lindex $bbox 0] 1]
    set x_orig $x
    set y_orig $y
    set x [expr round(($x / 0.114))*0.114 + 0.038 - 0.0095]
    set y [expr round(($y / 0.24))*0.24]
    set inst [get_object_name $inst]
    if {$x != $x_orig || $y != $y_orig} {
        puts $f "## $inst $x $y                                     [expr $x_orig/0.114]           [expr $y_orig/0.24]"
    }
    set tile_inst [lindex [regsub {/} $inst { }] 0]
    set tile_ref [get_attribute $tile_inst ref_name]
    set tile_ref_inst [regsub "$tile_inst" $inst "$tile_ref"]
    set ref_orig [get_attribute $inst ref_name]
    if {[info exists tile_ref_h($tile_ref_inst)]} {
        puts $o "set_cell_location -coordinates {$x $y} \[get_cells $inst\] -orientation $ori -ignore_fixed -fixed"
    } else {
        set  tile_ref_h($tile_ref_inst) 1
        puts $o "set_cell_location -coordinates {$x $y} \[get_cells $inst\] -orientation $ori -ignore_fixed -fixed"
    }
}
close $f
close $o
}

proc genGuideBuffer {pins} {
set o [open genGuideBuffer.tcl w]
foreach_in_collection pin [get_pins $pins] {
    set pin_name [get_object_name $pin]
    set net_orig [get_object_name [get_nets -of_objects $pin]]
    set inst_name [regsub -all {\[|\]} $net_orig {_}]
    set inst_name "${inst_name}_guideBuff"
    set net_new "${inst_name}_net"
    puts $o "create_net $net_new"
    puts $o "create_cell $inst_name \[get_lib_cells */$ck_buf\]"
    if {[get_attribute [get_pins $pin] direction] == "in"} {
        puts $o "disconnect_net \[get_pins $pin_name\]"
        puts $o "connect_net -net $net_new \[get_pins $inst_name/X\]"
        puts $o "connect_net -net $net_new \[get_pins $pin_name\]"
        puts $o "connect_net -net $net_orig \[get_pins $inst_name/A\]"
    } else {
        puts $o "disconnect_net \[get_pins $pin_name\]"
        puts $o "connect_net -net $net_new \[get_pins $inst_name/A\]"
        puts $o "connect_net -net $net_new \[get_pins $pin_name\]"
        puts $o "connect_net -net $net_orig \[get_pins $inst_name/X\]"
    }

}   
close $o
}

proc dumpTileMacroLoc {} {
# cat packagedef.mi200 | grep FIX | grep -v io_t | awk '{print $2}' | sed 's/\// /' | awk '{print $2}' | sort -u >  /home/simchen/navi31/fcfp/macros.list
set f [open /home/simchen/navi31/fcfp/macros.list r]
set tile [get_attribute [current_design] name]
puts "# dumpTileMacroLoc for $tile"
set o [open /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$tile.tcl w]
set ol [open /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$tile.list w]
while {[gets $f line] >= 0} {
    set inst [lindex $line 0]
    if {[sizeof_collection [get_cells -quiet $inst]] > 0} {
        set bbox [get_attribute [get_cells $inst] boundary_bbox]
        set ori [get_attribute [get_cells $inst] orientation ]
        set x [lindex [lindex $bbox 0] 0]
        set y [lindex [lindex $bbox 0] 1]
        puts $o "set_cell_location -coordinates {$x $y} \[get_cells $inst\] -orientation $ori -ignore_fixed -fixed"
        puts $ol "$inst"
    }
}
close $f
close $o
close $ol
}


proc getAllTileMacro {} {
set o [open getAllTileMacro.tcl w]
set tile_list [get_cells {umc_phy_t00 umc_phy_t10 io_cit_refclkio_mcd_t io_cldo_el3_t smu_fuse_thm_pwr_mcd_t df_el3_t0_0 io_gpio18_analog_mcd_t smu_clkc6_t smu_tmon_t0p cit_usr_mcd_dp_cp_phy_t umc_channel_t cit_usr_rep_t1 cit_usr_rep_t3}]
puts $o "set_working_design -push \[get_cells dfx_dft_mcd_t\]"
foreach_in_collection tile $tile_list {
    puts [get_object_name $tile]
    set tile_name [get_object_name $tile]
    puts $o "set_working_design -pop"
    puts $o "set_working_design -push \[get_cells $tile_name\]"
    puts $o "dumpTileMacroLoc"
}
puts $o "set_working_design -pop"
close $o
}


proc updateSSBXml {src_file} {
set f [open $src_file r]
set o [open ${src_file}.hack w]
while {[gets $f line] >= 0} {
    if {[regexp {FCFP_SSB} $line]} {
        puts $o "$line"
        continue
    }
    if {[regexp {\<datapin\s+load=\"(.*)\"\s+net=\"(.*)\"\s+\/\>} $line match loads ports]} {
        regsub -all {\,} $ports { } ports_new
        regsub -all {\,} $loads { } loads_new
        puts "$loads $ports"
        for { set i 0 } { $i < [llength $ports_new] } {incr i} { 
            set ports_h($i) [lindex $ports_new $i]
            if {[sizeof_collection [get_nets -quiet $ports_h($i)]] > 0} {
                puts "$i $ports_h($i)"
                foreach_in_collection pin [all_connected [get_nets $ports_h($i)] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set loads_h($i) [get_object_name $pin]
                        puts "$i $ports_h($i) $loads_h($i)"
                        break
                    }
                }
                if {$i ==0} {
                    set loads_updated $loads_h($i)
                    set ports_updated $ports_h($i)
                    #puts "$ports_h($i) $loads_updated"
                
                } else {
                    set loads_updated "$loads_updated,$loads_h($i)"
                    set ports_updated "$ports_updated,$ports_h($i)"
                    #puts "$ports_h($i) $loads_updated"
                }
             } else {
                set loads_h($i) [lindex $loads_new $i]
                puts "$i $loads_h($i)"
                foreach_in_collection pin [all_connected [get_nets $loads_h($i)] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set ports_h($i) [get_object_name $pin]
                        break
                    }
                }
                if {$i ==0} {
                    set ports_updated $ports_h($i)
                    set loads_updated $loads_h($i)
                } else {
                    set ports_updated "$ports_updated,$ports_h($i)"
                    set loads_updated "$loads_updated,$loads_h($i)"
                }
            }
            

        }
        puts $o "      \<datapin load=\"$loads_updated\" net=\"$ports_updated\" \/\>"
        puts "# end #"
        continue
    }
    if {[regexp {\<clockpin\s+load=\"(.*)\"\s+net=\"(.*)\"\s+\/\>} $line match loads ports]} {
        regsub -all {\,} $ports { } ports_new
        regsub -all {\,} $loads { } loads_new
        #puts "$loads $ports | $loads_new $ports_new"
        for { set i 0 } { $i < [llength $ports_new] } {incr i} {
            set ports_h($i) [lindex $ports_new $i]
            puts "$ports_h($i) $i "
            if {[sizeof_collection [get_nets -quiet $ports_h($i)]] > 0} {
                foreach_in_collection pin [all_connected [get_nets $ports_h($i)] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set loads_h($i) [get_object_name $pin]
                        puts "$ports_h($i) $loads_h($i)" 
                        break
                    }   
                }   
                if {$i ==0} {
                    set loads_updated $loads_h($i)
                    set ports_updated $ports_h($i)
                    #puts "$ports_h($i) $loads_updated"
                    
                } else {
                    set loads_updated "$loads_updated,$loads_h($i)"
                    set ports_updated "$ports_updated,$ports_h($i)"
                    #puts "$ports_h($i) $loads_updated"
                }   
             } else {
                set loads_h($i) [lindex $loads_new $i]
                foreach_in_collection pin [all_connected [get_nets $loads_h($i)] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set ports_h($i) [get_object_name $pin]
                        break
                    }
                }
                if {$i ==0} {
                    set ports_updated $ports_h($i)
                    set loads_updated $loads_h($i)
                } else {
                    set ports_updated "$ports_updated,$ports_h($i)"
                    set loads_updated "$loads_updated,$loads_h($i)"
                }
            }
        }
        puts $o "      \<clockpin load=\"$loads_updated\" net=\"$ports_updated\" \/\>"
        puts "# end #"
        continue
    }

    puts $o "$line"
}
close $f
close $o
exec /bin/cp -rf ${src_file}.hack $src_file 
}

proc dumpPGPin {} {
set top [get_attribute [current_design] name]
set port_list "VDDCI_CH VDDCR_BACO VDDCR_GFX VDDCR_SOC VSS"
set all_shapes ""
foreach port $port_list {
    if {[sizeof_collection [get_ports -quiet $port]] > 0} {
        set shapes [get_shapes -of_objects [get_ports $port]]
        set all_shapes [add_to_collection $all_shapes $shapes]
        puts "$port [sizeof_collection $all_shapes]"
    }
}
#write_def  -objects $all_shapes extractPG/$top.pg.pin.def.gz
write_def  -objects [get_ports $port_list] extractPG/$top.pg.pin.def.gz
}


proc genTileRef {} {
set tiles [get_cells  {* */*} -filter "hierarchy_type == block"]
foreach_in_collection tile $tiles {
    puts "[get_object_name $tile] [get_attribute $tile ref_name]"
}
}

proc genRemoveTieFeeds {ref} {
set f [open $ref.removeFeeds.list w]
set tiles [get_cells * -filter "ref_name == $ref"]
set all_pins ""
foreach_in_collection tile $tiles {
    set all_pins [add_to_collection $all_pins [get_pins [get_object_name $tile]/FE_FEED*]]
}
foreach_in_collection pin [get_pins $all_pins] {
    set net_name [get_object_name [all_connected $pin]]
    set pin_name [get_object_name $pin]
    set ref_pin_name [get_attribute $pin lib_pin_name]
    if {[regexp {Logic} $net_name]} {
        puts "$pin_name $net_name"
    } elseif {[sizeof_collection [all_connected $pin]] == 0} {
        puts "$pin_name NA"
    } else {
        set pin_is_tied($ref_pin_name) $pin_name
    }
}
foreach_in_collection pin [get_pins $all_pins] {
    set pin_name [get_object_name $pin]
    set ref_pin_name [get_attribute $pin lib_pin_name]
    if {[info exists pin_is_tied($ref_pin_name)]} {
    } else {
        puts $f "[get_object_name $pin] [get_attribute $pin direction]"
    } 
}
    
close $f
}

proc addAXIFlopToScan {scandef} {
set f [open $scandef r]
set o [open $scandef.expanded w]
while {[gets $f line] >= 0} {
    if {[regexp {FCFP_AXI_wrapper_inst(\S+)\s+\(\s+IN\s+si\s+\)\s+\(\s+OUT\s+so\s+\)} $line match inst]} {
        puts $line
        puts "FCFP_AXI_wrapper_inst$inst/si"
        set in_flop [get_cells -of_objects [get_pins [filter_collection [all_connected FCFP_AXI_wrapper_inst$inst/si] "name == SI"]]]
        set out_flop [get_cells -of_objects [get_pins [filter_collection [all_connected FCFP_AXI_wrapper_inst$inst/so] "name == Q || name == QN"]]]
        set out [get_attribute [filter_collection [all_connected FCFP_AXI_wrapper_inst$inst/so] "name == Q || name == QN"] name]
        puts $o "       [get_object_name $in_flop] ( IN SI ) ( OUT $out ) # FCFP_AXI_wrapper_inst$inst/si"
        puts $o "       [get_object_name $out_flop] ( IN SI ) ( OUT $out ) # FCFP_AXI_wrapper_inst$inst/so"
    } else {
        puts $o $line
    }
}
close $f
close $o
}


proc getRepScan {} {
set o [open getRepScan.rpt w]
set all_regs [get_cells * -hierarchical -filter "is_sequential == true && full_name =~ FCFPRep*"]
set all_regs [add_to_collection $all_regs [get_cells  FCFP_AXI_wrapper_*/FCFPAxi*]]
set all_regs [remove_from_collection $all_regs [get_cells FCFPRep*_Shift_*]]
set all_si ""
foreach_in_collection reg $all_regs {
    if {[regexp TARG_Shift [get_object_name $reg]]} {
        continue
    }
    if {[regexp {Axi} [get_object_name $reg]]} {
        set si "[get_object_name $reg]/si"
        puts "$si"
    } else {
        set si "[get_object_name $reg]/SI"
    }
    set all_si [add_to_collection $all_si [get_pins $si]]
}
foreach_in_collection rep_si [get_pins $all_si] {
    set name [get_object_name [get_cells -of_objects [get_pins $rep_si]]]
    puts "$name"
    if  {[regexp {Axi} $name]} {
        set next_SI [get_object_name [filter_collection [all_fanout -from $name/so -flat] "name == si || name == SI"]]
    } elseif {[sizeof_collection [get_pins -quiet $name/Q]] >0 } {
        set next_SI [get_object_name [filter_collection [all_fanout -from $name/Q -flat] "name == SI"]]
    } elseif {[sizeof_collection [get_pins -quiet $name/QN]] >0 } {
        set next_SI [get_object_name [filter_collection [all_fanout -from $name/QN -flat] "name == SI"]]
    }
    if  {[regexp {Axi} $next_SI]} {
        set next_SI [regsub -all  {\/} $next_SI " "]
        set hier0 [lindex $next_SI 0]
        set hier1 [lindex $next_SI 1]
        set next_SI "$hier0/$hier1/si"
    }

    set next_rep [get_object_name [get_cells  -of_objects [get_pins $next_SI]]]
    if  {[regexp {Axi} $name]} {
        set prev_Q [get_object_name [filter_collection [all_fanin -to $name/si -flat] "name =~ Q || name =~ so"]]
        
    } else {
        set prev_Q [get_object_name [filter_collection [all_fanin -to $name/SI -flat] "name =~ Q || name =~ so"]]
    }
    if  {[regexp {Axi} $prev_Q]} {
        set prev_Q [regsub -all  {\/} $prev_Q " "]
        set hier0 [lindex $prev_Q 0]
        set hier1 [lindex $prev_Q 1]
        set prev_Q "$hier0/$hier1/so"
    }
    set prev_rep [get_object_name [get_cells -of_objects [get_pins $prev_Q]]]
    puts "# $prev_rep $name $next_rep"
    set rep_si_h($name) $prev_rep
    set rep_so_h($name) $next_rep
    set rep_h($name) 1
    if {[regexp {SCAN_EN} $prev_Q]} {
        set rep_start_h($name) $prev_rep
    }
    if {[regexp {SCAN_EN} $next_SI]} {
        set rep_end_h($name) $next_rep
    }
}
puts "# build chain"
foreach name [array names rep_start_h] {
    set n 0
    set current_rep $name
    set start $rep_start_h($name)
    set chain_h($start) "$start"
    set chain_h($start) "$chain_h($start) $current_rep"
    puts "$start"
    while {$n < 1000} {
        puts "# $current_rep"
        if {[info exists rep_so_h($current_rep) ]} {
            set current_rep $rep_so_h($current_rep)
            set chain_h($start) "$chain_h($start) $current_rep"
            if  {[regexp {SCAN_EN} $current_rep]} {
                break
            }
        } else {
            break
        }
        incr n
    }
}
puts "# write chain"
foreach start [array names chain_h] {
    puts $o "[llength $chain_h($start)] $chain_h($start)"
}
close $o
}

proc findNonSIPin {pin} {
set input [filter_collection [all_fanout -from [get_pins $pin] -levels 1 -flat ] "direction == in"]
if {[sizeof_collection $input] == 2} {
    if {[sizeof_collection [filter_collection $input "name == SI"]] == 1} {
        set nonSI [remove_from_collection $input [filter_collection $input "name == SI"]]
        return $nonSI
    }
    if {[sizeof_collection [filter_collection $input "name == D"]] == 1} {
        set nonSI [filter_collection $input "name == D"]
        return $nonSI
    }
    if {[sizeof_collection [filter_collection $input "name == SI"]] == 0} {
        foreach_in_collection input_pin $input {
            set input_cells [get_object_name [get_cells -of_objects [get_pins $input_pin]]]
            set output [filter_collection [get_pins $input_cells/*] "direction == out"]
            set d [filter_collection [all_fanout -from $output -flat] "name == D"]
            if {[sizof_collection $d] == 1} {
                return $nonSI
            }
        }
    }
            
}
}


proc bypassSIRep {reps} {
set o [open bypassSIRep.tcl w]
puts $o "source /home/simchen/mi100/fcfp/proc_fcfp.tcl"

foreach_in_collection rep [get_cells $reps] {
    set rep [get_object_name $rep]
    puts $o "puts $rep"

    if {[sizeof_collection [get_pins -quiet $rep/D]] > 0} {
        puts $o "set new_buf \"${rep}_tied_buf\""
        puts $o "set new_tie \"${rep}_tied\""
        puts $o "set new_tie_net \"${rep}_tied_net\""
        puts $o "set new_buf_net \"${rep}_buf_net\""
        puts $o "create_net \$new_buf_net"
        puts $o "create_net \$new_tie_net"
        puts $o "create_cell \$new_tie \[get_lib_cells */HDBSVT08_TIE0_1\]"
        puts $o "create_cell \$new_buf \[get_lib_cells */HDBLVT08_BUF_4\]"
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $rep/D\] bbox\] 0\]"
        puts $o "set d_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/D\]\]\]"
        puts $o "set_cell_location \$new_tie -coordinates \$tie_cell_loc"
        puts $o "set_cell_location \$new_buf -coordinates \$tie_cell_loc"
        puts $o "connect_net -net \[get_nets \$new_tie_net\] \[get_pins \$new_tie/X\]"
        puts $o "disconnect_net -net \[get_nets \$d_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$new_tie_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$d_net\] \[get_pins \$new_buf/A\]"
    } else {
        puts "D is floating for $rep"
    }
    if {[sizeof_collection [get_pins -quiet $rep/Q]] > 0} {
        puts $o "set q \"$rep/Q\""
        puts $o "set si \[filter_collection \[all_fanout -from \[get_pins $rep/Q\]\] \"name == SI || name =~ test_si* || name == si\"]"
        set si [filter_collection [all_fanout -from [get_pins $rep/Q]] "name == SI || name =~ test_si* || name == si"]
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/Q\]\]\]"
    } elseif {[sizeof_collection [get_pins -quiet $rep/QN]] > 0} {
        puts $o "set si \[filter_collection \[all_fanout -from \[get_pins $rep/QN\]\] \"name == SI || name =~ test_si* || name == si\"]"
        set si [filter_collection [all_fanout -from [get_pins $rep/QN]] "name == SI || name =~ test_si* || name == si"]
        puts $o "set q \"$rep/QN\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins $rep/QN\]\]\]"
    } else {
        puts "Q or QN is floating for $rep"
        continue
    }
    puts $o "set si_net \[all_connected \$si\]"
    puts $o "disconnect_net -net \[get_nets \$si_net\] \[get_pins \$si]"
    puts $o "disconnect_net -net \[get_nets \$q_net\] \[get_pins \$q]"
    puts $o "connect_net -net \[get_nets \$new_buf_net\] \[get_pins \$q\]"
    if {[sizeof_collection $si] != 1} {
        puts "ERROR: SI pin for $rep not exists."
    }
    puts $o "connect_net -net \[get_nets \$new_buf_net\] \[get_pins \$si\]"
    puts $o "connect_net -net \[get_nets \$q_net\] \[get_pins \$new_buf/X\]"
}   
close $o
}

proc tieNonSIRep {reps} {
set o [open tieNonSIRep.tcl w]
puts $o "source /home/simchen/mi100/fcfp/findNonSIPin.tcl"
foreach_in_collection rep [get_cells $reps] {
    set rep [get_object_name $rep]
    puts $o "# $rep"
    if {[sizeof_collection [get_pins -quiet $rep/D]] > 0} {
        puts $o "set new_buf \"${rep}_tied_buf\""
        puts $o "set new_tie \"${rep}_tied\""
        puts $o "set new_tie_net \"${rep}_tied_net\""
        puts $o "create_net \$new_tie_net"
        puts $o "create_cell \$new_tie \[get_lib_cells */HDBSVT08_TIE0_1\]"
        puts $o "create_cell \$new_buf \[get_lib_cells */HDN6BLVT08_BUF_8\]"
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $rep/D\] bbox\] 0\]"
        puts $o "set d_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/D\]\]\]"
        puts $o "set_cell_location \$new_tie -coordinates \$tie_cell_loc"
        puts $o "set_cell_location \$new_buf -coordinates \$tie_cell_loc"
        puts $o "connect_net -net \[get_nets \$new_tie_net\] \[get_pins \$new_tie/X\]"
        puts $o "disconnect_net -net \[get_nets \$d_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$new_tie_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$d_net\] \[get_pins \$new_buf/A\]"
    } else {
        puts "D is floating for $rep"
    }
    if {[sizeof_collection [get_pins -quiet $rep/Q]] > 0} {
        puts $o "set q \"$rep/Q\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/Q\]\]\]"
    } elseif {[sizeof_collection [get_pins -quiet $rep/QN]] > 0} {
        puts $o "set q \"$rep/QN\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/QN\]\]\]"
    } else {
        puts "Q or QN is floating for $rep"
        continue
    }
 
    puts $o "disconnect_net -net \[get_nets \$q_net\] \[get_pins \$q\]"
    puts $o "connect_net -net \[get_nets \$q_net\] \[get_pins \$new_buf/X\]"
}
close $o
}


proc removeNonSIRep {reps} {
set o [open removeNonSIRep.tcl w]
foreach_in_collection rep [get_cells $reps] {
    set rep [get_object_name $rep]
    puts $o "# $rep"
    set new_buf "${rep}_tied_buf"
    if {[sizeof_collection [get_pins -quiet $rep/D]] > 0} {
        puts $o "create_cell $new_buf \[get_lib_cells */HDN6BLVT08_BUF_8\]"
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $rep/D\] bbox\] 0\]"
        puts $o "set d_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/D\]\]\]"
        puts $o "set_cell_location $new_buf -coordinates \$tie_cell_loc"
        puts $o "disconnect_net -net \[get_nets \$d_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$d_net\] \[get_pins $new_buf/A\]"
    } else {
        puts "D is floating for $rep"
    }
    if {[sizeof_collection [get_pins -quiet $rep/Q]] > 0} {
        puts $o "set q \"$rep/Q\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/Q\]\]\]"
    } elseif {[sizeof_collection [get_pins -quiet $rep/QN]] > 0} {
        puts $o "set q \"$rep/QN\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/QN\]\]\]"
    } else {
        puts "Q or QN is floating for $rep"
        continue
    }
    puts $o "disconnect_net -net \[get_nets \$q_net\] \[get_pins \$q\]"
    puts $o "connect_net -net \[get_nets \$q_net\] \[get_pins $new_buf/X\]"
    puts $o "remove_cell $rep"
}
close $o
}

proc removeSIRep {reps} {
set o [open removeSIRep.tcl w]
foreach_in_collection rep [get_cells $reps] {
    set rep [get_object_name $rep]
    puts $o "# $rep"
    set new_d_buf "${rep}_d_buf"
    if {[sizeof_collection [get_pins -quiet $rep/D]] > 0} {
        puts $o "create_cell $new_d_buf \[get_lib_cells */HDBLVT08_BUF_4\]"
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $rep/D\] bbox\] 0\]"
        puts $o "set d_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/D\]\]\]"
        puts $o "set_cell_location $new_d_buf -coordinates \$tie_cell_loc"
        puts $o "disconnect_net -net \[get_nets \$d_net\] \[get_pins $rep/D\]"
        puts $o "connect_net -net \[get_nets \$d_net\] \[get_pins $new_d_buf/A\]"
        puts $o "set si_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/SI\]\]\]"

    } else {
        puts "D is floating for $rep"
    }
    if {[sizeof_collection [get_pins -quiet $rep/Q]] > 0} {
        puts $o "set q \"$rep/Q\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/Q\]\]\]"
        puts $o "set si \[filter_collection \[all_fanout -from \[get_pins $rep/Q\]\] \"name == SI || name =~ test_si* || name == si\"]"
    } elseif {[sizeof_collection [get_pins -quiet $rep/QN]] > 0} {
        puts $o "set q \"$rep/QN\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/QN\]\]\]"
        puts $o "set si \[filter_collection \[all_fanout -from \[get_pins $rep/QN\]\] \"name == SI || name =~ test_si* || name == si\"]"
    } else {
        puts "Q or QN is floating for $rep"
        continue
    }
    puts $o "disconnect_net -net \[get_nets \$q_net\] \[get_pins \$q\]"
    puts $o "connect_net -net \[get_nets \$q_net\] \[get_pins $new_d_buf/X\]"
    puts $o "set si_post_net \[all_connected \$si\]"
    puts $o "disconnect_net -net \[get_nets \$si_post_net\] \[get_pins \$si]"
    puts $o "connect_net -net \[get_nets \$si_net\] \[get_pins \$si\]"
    puts $o "remove_cell $rep"
}
close $o
}


proc removeFloatSIRep {reps} {
set o [open removeFloatSIRep.tcl w]
foreach_in_collection rep [get_cells $reps] {
    set rep [get_object_name $rep]
    puts $o "# $rep"
    set new_buf "${rep}_SI_buf"
    if {[sizeof_collection [get_pins -quiet $rep/SI]] > 0} {
        puts $o "create_cell $new_buf \[get_lib_cells */HDBLVT08_BUF_4\]"
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $rep/D\] bbox\] 0\]"
        puts $o "set SI_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/SI\]\]\]"
        puts $o "set_cell_location $new_buf -coordinates \$tie_cell_loc"
        puts $o "disconnect_net -net \[get_nets \$SI_net\] \[get_pins $rep/SI\]"
        puts $o "connect_net -net \[get_nets \$SI_net\] \[get_pins $new_buf/A\]"
    } else {
        puts "D is floating for $rep"
    }
    if {[sizeof_collection [get_pins -quiet $rep/Q]] > 0} {
        puts $o "set q \"$rep/Q\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/Q\]\]\]"
    } elseif {[sizeof_collection [get_pins -quiet $rep/QN]] > 0} {
        puts $o "set q \"$rep/QN\""
        puts $o "set q_net \[get_object_name \[get_nets -of_objects \[get_pins  $rep/QN\]\]\]"
    } else {
        puts "Q or QN is floating for $rep"
        continue
    }
    puts $o "disconnect_net -net \[get_nets \$q_net\] \[get_pins \$q\]"
    puts $o "connect_net -net \[get_nets \$q_net\] \[get_pins $new_buf/X\]"
    puts $o "remove_cell $rep"
}
close $o
}


proc tieListPin {pin_list} {
set o [open tieListPin.tcl w]
foreach full_pin $pin_list {
    if {[regexp {(\S+)\/(\S+)} $full_pin match tile ref_pin]} {
        set i 0
        set tie_net "${tile}_${ref_pin}_tied_$i"
        while {[sizeof_collection [get_nets -quiet ${tile}_${ref_pin}_tied_$i]]} {
            incr i
            set  tie_net "${tile}_${ref_pin}_tied_$i"
        }

        puts $tie_net
        if {[sizeof_collection [get_nets -quiet -of_objects [get_pins -quiet $full_pin]]] > 0} {
            puts $o "disconnect_net -net \[get_nets -quiet -of_objects \[get_pins -quiet $full_pin\]\] \[get_pins $full_pin\]"
            puts $o "create_net $tie_net"
            puts $o "connect_net -net \[get_nets $tie_net\] \[get_pins $full_pin\]"
            puts "$full_pin $tie_net"
        } else {
            puts $o "create_net $tie_net"
            puts $o "connect_net -net \[get_nets $tie_net\] \[get_pins $full_pin\]"
        }
        set tie_cell ${tie_net}_inst_$i
        set i 0
        while {[sizeof_collection [get_cells -quiet $${tie_net}_inst_$i]]} {
            incr i
            set  tie_cell ${tie_net}_inst_$i
        }

        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $full_pin\] bbox\] 0\]"
        puts $o "# Tie $full_pin"
        puts $o "create_cell $tie_cell \[get_lib_cells */HDN6BLVT08_TIE0_V1_2\]"
        puts $o "set_cell_location $tie_cell -coordinates \"\$tie_cell_loc\""
        puts $o "connect_net -net \[get_nets $tie_net\] \[get_pins $tie_cell/X\]"
        puts $o ""
    }

}
close $o
}

proc tieInstPin {pinList} {
set o [open tieinstPin.tcl w]
set f [open $pinList r]
while {[gets $f line] >= 0} {
    set pin [lindex $line 0]
    set inst_name [get_object_name [get_cells -of_object [get_pins $pin]]]
    puts $pin
    set inst_pin [get_attribute [get_pins $pin] name]
    set tieCell [lindex $line 1]
    set suffix simchen_0430
    set pin_loc [getObjLoc [get_pins $pin]]
    set tie_name "${inst_name}_${inst_pin}_tie_$suffix"
    set tie_name [regsub {\[} $tie_name {_}]
    set tie_name [regsub {\]} $tie_name {_}]
    
    puts $o "create_cell $tie_name \[get_lib_cells */$tieCell\]"
    puts $o "set_cell_location $tie_name -coordinates \"$pin_loc\""
    puts $o "connect_pin  -non_incremental -driver  $tie_name/X \[get_pins $pin\]"
}
close $o
}

proc addNonSIRep {spec} {
set f [open $spec r]
puts $spec
set debug 1
while {[gets $f line] >= 0} {
    if {[regexp {^load\s+(\S+)} $line match load]} {
        set load_h($load) 1
        set load_rep($load) ""
    }
    if {[regexp {^ck_net\s+(\S+)} $line match ck_net]} {
        set load_ck($load) $ck_net
        puts "$load $ck_net"
    }
    if {[regexp {^FCFPRep(\S+)} $line match suffix]} {
        set rep "FCFPRep$suffix"
        set load_rep($load) "$load_rep($load) $rep"
    }
}
foreach load [array names load_h] {
puts $load_rep($load)
    set load_used $load
    puts $load
    if {[sizeof_collection [get_port -quiet $load]] == 1} {
        set i 0
        set eco_buf eco_buf_$i
        while {[sizeof_collection [get_cells -quiet eco_buf_$i]]} {
            incr i
            set eco_buf eco_buf_$i
        }
        set inst_loc [lindex [get_attribute [get_ports $load] bbox] 0]
        insert_buffer [get_ports $load] -new_cell_names eco_buf_$i -lib_cell [get_lib_cells */HDN6BLVT08_BUF_8]
        set_cell_location eco_buf_$i -coordinates $inst_loc
        set load_used eco_buf_$i/A
    } else {
        set inst_loc [lindex [get_attribute [get_pins $load] bbox] 0]
    }
    set load_net [get_object_name [get_nets -of_objects [get_pin $load_used]]]
    disconnect_net -net [get_nets $load_net] [get_pins $load_used]
    for { set i 0 } { $i < [llength $load_rep($load)] } {incr i} {
        set rep [lindex $load_rep($load) $i]
        if {$debug == 1} {
            puts "# create rep $rep"
        }
        create_cell $rep [get_lib_cells */HDBLVT08_FSDPQ_V2Y2_1]
        set_cell_location $rep -coordinates $inst_loc
        set si_tie_net "${rep}_tie_si_net"
        set se_tie_net "${rep}_tie_se_net"
        create_net $si_tie_net
        create_net $se_tie_net
        set si_tie "${rep}_tie_si"
        set se_tie "${rep}_tie_se"
        create_cell $si_tie [get_lib_cells */HDBSVT08_TIE0_1]
        create_cell $se_tie [get_lib_cells */HDBSVT08_TIE0_1]
        set_cell_location $si_tie -coordinates $inst_loc
        set_cell_location $se_tie -coordinates $inst_loc
        connect_net -net [get_nets $si_tie_net] [get_pins $rep/SI]
        connect_net -net [get_nets $se_tie_net] [get_pins $rep/SE]
        connect_net -net [get_nets $si_tie_net] [get_pins $si_tie/X]
        connect_net -net [get_nets $se_tie_net] [get_pins $se_tie/X]
        if {$i == 0} {
            connect_net -net [get_nets $load_net] [get_pins $rep/D]
            if {$debug == 1} {
                puts "# connect_net $load_net $rep/D"
            }
        } else {
            connect_net -net [get_nets $q_net] [get_pins $rep/D]
            if {$debug == 1} {
                puts "# connect_net $q_net  $rep/D"
            }
        }
        set ck_net $load_ck($load) 
        connect_net -net [get_nets $ck_net] [get_pins $rep/CK]
        if {$debug == 1} {
            puts "#connect_net [get_object_name $ck_net]  $rep/CK"
        }
        set q_net "${rep}_q"
        create_net $q_net
        set si_net $q_net
        if {$debug == 1} {
            puts "# connect $q_net $rep/Q"
        }
        connect_net -net [get_nets $q_net] [get_pins $rep/Q]
        if {$i == [expr [llength $load_rep($load)] - 1]} {
            connect_net -net [get_nets $q_net] [get_pins $load_used]
            if {$debug == 1} {
                puts "# connect $q_net $load_used"
            }
        }
    }
}
}


proc addSIRep {spec} {
set f [open $spec r]
puts $spec
set debug 0
while {[gets $f line] >= 0} {
    if {[regexp {^load\s+(\S+)} $line match load]} {
        set load_h($load) 1
        set load_rep($load) ""
    }
    if {[regexp {^ck_net\s+(\S+)} $line match ck_net]} {
        set load_ck($load) $ck_net
        puts "$load $ck_net"
    }
    if {[regexp {^si_load\s+(\S+)} $line match si_load]} {
        set load_si($load) $si_load
    }
    if {[regexp {^FCFPRep(\S+)} $line match suffix]} {
        set rep "FCFPRep$suffix"
        set load_rep($load) "$load_rep($load) $rep"
    }
}

foreach load [array names load_h] {
puts $load_rep($load)
    set load_used $load
    puts $load
    if {[sizeof_collection [get_port -quiet $load]] == 1} { 
        set i 0
        set eco_buf eco_buf_$i
        while {[sizeof_collection [get_cells -quiet eco_buf_$i]]} {
            incr i
            set eco_buf eco_buf_$i
        }
        set inst_loc [lindex [get_attribute [get_ports $load] bbox] 0]
        insert_buffer [get_ports $load] -new_cell_names eco_buf_$i -lib_cell [get_lib_cells */HDN6BLVT08_BUF_8]
        set_cell_location eco_buf_$i -coordinates $inst_loc
        set load_used eco_buf_$i/A
    } else {
        set inst_loc [lindex [get_attribute [get_pins $load] bbox] 0]
    }
    set load_net [get_object_name [get_nets -of_objects [get_pin $load_used]]]
    set ck_net [get_nets $load_ck($load)]
    set si_net [get_nets -of_objects [get_pins $load_si($load)]]
    set si_rep [get_object_name [get_cells -of_objects [get_pins $load_si($load)]]]
    set se_net [get_nets -of_objects [get_pins $si_rep/SE]]
    disconnect_net -net [get_nets $si_net] [get_pins $load_si($load)]
    disconnect_net -net [get_nets $load_net] [get_pins $load_used]
    for { set i 0 } { $i < [llength $load_rep($load)] } {incr i} {
        set rep [lindex $load_rep($load) $i]
        if {$debug == 1} {
            puts "# create rep $rep"
        }
        create_cell $rep [get_lib_cells */HDBLVT08_FSDPQ_V2Y2_1]
        set_cell_location $rep -coordinates $inst_loc
        if {$i == 0} {
            connect_net -net [get_nets $load_net] [get_pins $rep/D] 
            connect_net -net [get_nets $si_net] [get_pins $rep/SI]
            connect_net -net [get_nets $se_net] [get_pins $rep/SE]
            if {$debug == 1} {
                puts "# connect_net $load_net $rep/D"
                puts "# connect_net [get_object_name $si_net] $rep/SI"
            }
        } else {
            connect_net -net [get_nets $q_net] [get_pins $rep/D]
            connect_net -net [get_nets $q_net] [get_pins $rep/SI]
            if {$debug == 1} {
                puts "# connect_net $q_net  $rep/D"
                puts "# connect_net $q_net  $rep/SI"
            }
            connect_net -net [get_nets $se_net] [get_pins $rep/SE]
        }
        connect_net -net [get_nets $ck_net] [get_pins $rep/CK]
        if {$debug == 1} {
            puts "#connect_net [get_object_name $ck_net]  $rep/CK"
        }
        set i 0
        set q_net "${rep}_q_$i"
        while {[sizeof_collection [get_net -quiet ${rep}_q_$i]]} {
            incr i
            set q_net ${rep}_q_$i
        }
        create_net $q_net
        set si_net $q_net
        if {$debug == 1} {
            puts "# connect $q_net $rep/Q" 
        }
        connect_net -net [get_nets $q_net] [get_pins $rep/Q]
        if {$i == [expr [llength $load_rep($load)] - 1]} {
            connect_net -net [get_nets $q_net] [get_pins $load_si($load)]
            connect_net -net [get_nets $q_net] [get_pins $load_used]
            if {$debug == 1} {
                puts "# connect $q_net $load_si($load)"
                puts "# connect $q_net $load_used"
            }
        }
    }
}
}

proc checkFloatInput {pins} {
set o [open checkFloatInput.rpt w]
foreach_in_collection pin [get_pins $pins] {
    if {[get_nets -quiet -of_objects $pin] == 0} {
        puts $o "[get_object_name $pin]"
    } else {
        set drv_port [get_ports -quiet [all_connected -leaf [get_nets -quiet -of_objects $pin]] -filter "direction == in"]
        set drv_pin [get_pins -quiet [all_connected -leaf [get_nets -quiet -of_objects $pin]] -filter "direction == out"]
        if {[sizeof_collection $drv_port] == 0  && [sizeof_collection $drv_pin] == 0 } {
            puts $o "[get_object_name $pin]"
        }
    }
}
close $o
}
   
proc checkFloatPin {pins} {
set o [open checkFloatPin.rpt w]
foreach_in_collection pin [get_pins $pins] {
    if {[sizeof_collection [all_connected [get_nets -quiet -of_objects $pin] -leaf]] == 1} {
        puts  $o "[get_object_name $pin]"
    }
}
close $o
}

proc pin2Net {pins} {
foreach_in_collection pin [get_pins $pins] {
    puts "[get_object_name [get_nets -of_objects $pin]]"
}
}

proc showRep {xml} {
set f [open $xml r]
open o [open showRep.tcl w]
global xml_contract
global xml_net_bundle
global xml_net_constraint
global xml_net_rep
global xml_rep_order
global xml_rep_scan_enable_type
global xml_rep_usageCount
while {[gets $f line] >= 0} {
    if {[regexp {<rep\s+constraint=\"(\S+)\s+(\S+)\"\s+container=\"(\S+)\"\s+contract=\"(\S+)\"\s+domain=\"(\S+)\"\s+file=\"(\S+)\"\s+limited=\"(\S+)\"\s+negedge=\"(\S+)\"\s+pd=\"(\S+)\"\s+rep_inst=\"(\S+)\"\s+scan_balance=\"(\S+)\"\s+scanned=\"(.*)\"\s+sdc_clk=\"(\S+)\">} $line match constraint0 constraint1 container contract domain file limited negedge pd rep_inst scan_balance scanned sdc_clk] == 1} {
        set xml_contract($contract) 1
    }
    if {[regexp {<net\s+bundle=\"(\S+)\"\s+fgcg_ctrl=\"(\S+)\"\s+matched=\"(\S+)\"\s+maxdist=\"(\S+)\"\s+name=\"(\S+)\"\s+orig_bundle=\"(\S+)\"\s+pdestimate=\"(\S+)\"\s+rep_type=\"(\S+)\">} $line match bundle fgcg_ctrl matched maxdist name orig_bundle pdestimate rep_type]} {
        set xml_net_bundle($name) $bundle
        set xml_net_constraint($name) "$constraint0 $constraint1"
        set xml_net_rep($name) ""
    }
    if {[regexp {<repInstance\s+id=\"(\S+)\"\s+instName=\"(\S+)\"\s+order=\"(\S+)\"\s+parentInstance=\"(\S+)\"\s+scan_enable_type=\"(\S+)\"\s+usageCount=\"(\S+)\"\s+\/>} $line match repInstance instName order parentInstance scan_enable_type usageCount]} {
        set xml_net_rep($name) "$xml_net_rep($name) $parentInstance/$instName"
        set xml_rep_order($parentInstance/$instName) $order
        set xml_rep_scan_enable_type($parentInstance/$instName) $scan_enable_type
        set xml_rep_usageCount($parentInstance/$instName) $usageCount
    }
}

close $f
}

proc calcRepDist {reps} {
puts ""
for { set i 0 } { $i < [llength $reps] } {incr i} {
    set rep0 [lindex $reps $i]
    if {$i == [expr [llength $reps] -1] } {
        puts "$rep0 END"
        break
    }
    if {[sizeof_collection [get_cells -quiet $rep0]] == 0} {
        puts "# abort due to no cell found $rep0"
        break
    }
    set bbox [get_attribute [get_cells $rep0] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set j [expr $i + 1]
    set rep1 [lindex $reps $j]
    if {[sizeof_collection [get_cells -quiet $rep1]] == 0} {
        puts "# abort due to no cell found $rep1"
        break
    }
    set bbox [get_attribute [get_cells $rep1] bbox]
    set llx1 [lindex [lindex $bbox 0] 0]
    set lly1 [lindex [lindex $bbox 0] 1]
    set dist [expr abs($llx0 - $llx1) + abs($lly0 - $lly1)]
    puts "$rep0 $dist"
}
puts ""
}

proc getRepDist {reps_list} {
set f [open $reps_list r]
set o [open getRepDist.rpt w]
while {[gets $f line] >= 0} {
    set rep0 [lindex $line 0]
    set bbox [get_attribute [get_cells $rep0] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set rep1 [lindex $line 1]
    set bbox [get_attribute [get_cells $rep1] bbox]
    set llx1 [lindex [lindex $bbox 0] 0]
    set lly1 [lindex [lindex $bbox 0] 1]
    set dist [expr abs($llx0 - $llx1) + abs($lly0 - $lly1)]
    puts $o "$rep0 $rep1 $dist"
}
close $f
close $o
}

proc getIoRepMargin {reps_list rep_port_list} {
set f [open $rep_port_list r]
set pf [open $reps_list r]
set o [open getIoRepMargin.rpt w]
while {[gets $f line] >= 0} {
    if {[llength $line] == 3} {
        set input [lindex $line 0]
        set rep [lindex $line 1]
        set output [lindex $line 2]
        if {[regexp {/NA} $output]} {
            set input_h($rep) $input
        } elseif{[regexp {/NA} $input]} {
            set output_h($rep) $output
        } else {
            set input_h($rep) $input
            set output_h($rep) $output
        }
    }
    if {[llength $line] == 2} {
        #set input [lindex $line 0]
        #set rep [lindex $line 1]
        #set input_h($rep) $input
    }
}
close $f
while {[gets $pf line] >= 0} {
    set rep0 [lindex $line 0]
    set bbox [get_attribute [get_cells $rep0] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set rep1 [lindex $line 1]
    set bbox [get_attribute [get_cells $rep1] bbox]
    set llx1 [lindex [lindex $bbox 0] 0]
    set lly1 [lindex [lindex $bbox 0] 1]
    set dist [expr abs($llx0 - $llx1) + abs($lly0 - $lly1)]
    
    if {[info exists output_h($rep0)]} {
        set bbox [get_attribute [get_pins $output_h($rep0)] bbox]
        set llx_pin [lindex [lindex $bbox 0] 0]
        set lly_pin [lindex [lindex $bbox 0] 1]
        set dist [expr abs($llx1 - $llx_pin) + abs($lly1 - $lly_pin)]
        puts $o "$rep0 $rep1 $output_h($rep0) $dist"
    }
    if {[info exists input_h($rep1)]} {
        set bbox [get_attribute [get_pins $input_h($rep1)] bbox]
        set llx_pin [lindex [lindex $bbox 0] 0]
        set lly_pin [lindex [lindex $bbox 0] 1]
        set dist [expr abs($llx0 - $llx_pin) + abs($lly0 - $lly_pin)]
        puts $o "$rep0 $rep1 $input_h($rep1) $dist"
    }
}
close $o
}
    
proc getNearestCkNet {pattern obj} {
if {[sizeof_collection [get_ports -quiet $obj]]} {
    set bbox [get_attribute [get_ports $obj] bbox]
    set obj_name [get_object_name [get_ports $obj]]
}
if {[sizeof_collection [get_pins -quiet $obj]]} {
    set bbox [get_attribute [get_pins $obj] bbox]
    set obj_name [get_object_name [get_pins $obj]]
}

set llx [lindex [lindex $bbox 0] 0]
set lly [lindex [lindex $bbox 0] 1]
set dist 99999
set ck_drv ""
foreach_in_collection rep [get_cells $pattern -filter "is_sequential == true"] {
    set ck_drv [filter_collection [all_connected [get_nets -of_objects [get_pins [get_object_name $rep]/CK]] -leaf] "direction == out"]
    set bbox [get_attribute [get_pin [get_object_name $rep]/CK] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set dist_tmp [expr abs($llx - $llx0) + abs($lly - $lly0)]
    if {$dist_tmp < $dist} {
        set dist $dist_tmp
        set rep_neareast [get_object_name $rep]
    }
}
puts "$obj_name $rep_neareast [get_object_name [get_nets -of_objects [get_pins $rep_neareast/CK]]] $dist"
#puts "load $obj_name"
#puts "ck_net [get_object_name [get_nets -of_objects [get_pins $rep_neareast/CK]]]"
#puts "si_load $rep_neareast/SI"
return "$rep_neareast [get_object_name [get_nets -of_objects [get_pins $rep_neareast/CK]]] $dist"
}


proc getNearestSIPin {obj pattern} {
if {[sizeof_collection [get_ports -quiet $obj]]} {
    set bbox [get_attribute [get_ports $obj] bbox]
}
if {[sizeof_collection [get_pins -quiet $obj]]} {
    set bbox [get_attribute [get_pins $obj] bbox]
}

set llx [lindex [lindex $bbox 0] 0]
set lly [lindex [lindex $bbox 0] 1]
set dist 99999
set si_load ""
foreach_in_collection rep [get_cells $pattern -filter "is_sequential == true"] {
    set si_load [filter_collection [all_connected [get_nets -of_objects [get_pins [get_object_name $rep]/SI]] -leaf] "direction == out"]
    set bbox [get_attribute [get_pin [get_object_name $rep]/SI] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set dist_tmp [expr abs($llx - $llx0) + abs($lly - $lly0)]
    if {$dist_tmp < $dist} {
        set dist $dist_tmp
        set rep_neareast [get_object_name $rep]
    }
}
puts "$rep_neareast $rep_neareast/SI $dist"
return "$rep_neareast $rep_neareast/SI $dist"
}

proc removeBufferPin {drvs} {
foreach_in_collection drv [get_pins $drvs] {
    puts "# Process [get_object_name $drv]"
    if {[sizeof_collection [filter_collection [all_fanout -from $drv -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF*"]]} {
        remove_buffer [filter_collection [all_fanout -from $drv -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF* "]
    }
    if {[sizeof_collection [filter_collection [all_fanout -from $drv -only_cells -trace_arcs all] "design_type == lib_cell"]]} {    
        remove_buffer [filter_collection [all_fanout -from $drv -only_cells -trace_arcs all] "design_type == lib_cell"]
    }
}
}

proc removeBufferLod {loads} {
foreach_in_collection lod [get_pins $loads] {
    puts "# Process [get_object_name $lod]"
    if {[sizeof_collection [filter_collection [all_fanin -to $lod -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF*"]]} {
        remove_buffer [filter_collection [all_fanin -to $lod -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF* "]
    }
    if {[sizeof_collection [filter_collection [all_fanin -to $lod -only_cells -trace_arcs all] "design_type == lib_cell"]]} {
        remove_buffer [filter_collection [all_fanin -to $lod -only_cells -trace_arcs all] "design_type == lib_cell"]
    }
}
}


proc removeBuffer {nets} {
#removeRoute $nets
#set o [open removeBuffer.tcl w]
set f [open removeBuffer.rpt w]
foreach_in_collection net [get_nets $nets] {
    set cells [get_flat_cells -of_objects $net]
    if {[sizeof_collection $cells] > 2} {
        puts "# [get_object_name $net] is MFN, skip..."
        puts $f "# [get_object_name $net] is MFN, skip..."
        continue
    }
    set o [open removeBuffer.tcl w]
    puts "# Processing [get_object_name $net]"
    set buffers [filter_collection [all_fanout -from [get_nets $net] -only_cells -flat -trace_arcs all] "ref_name =~ *BUF* && full_name !~ *FCFP_assign_BUF*"]
    set inv [filter_collection [all_fanout -from [get_nets $net] -only_cells -flat -trace_arcs all] "ref_name =~ *INV* && full_name !~ *FCFP_assign_BUF*" ]
    if {[sizeof_collection $buffers]} {
        puts "# remove buffer before removing inv for  [get_object_name $net]"
        puts $o "remove_buffer \{[get_object_name $buffers]\}"
        removeCellRoute $buffers
        remove_buffer  $buffers
    }
    set n_inv [sizeof_collection $inv]
    if {[expr fmod($n_inv,2)] != 0 && $n_inv > 2} {
        set o_cell [get_object_name [get_flat_cells -of_objects [filter_collection [get_pins -of_objects $net] "direction == in"]]]
        puts "# skip cell $o_cell"
        set new_net [get_nets -of_objects [get_pins $o_cell/X]]
        set inv [filter_collection [all_fanout -from [get_nets $new_net] -only_cells -flat -trace_arcs all] "ref_name =~ *INV* && full_name !~ *FCFP_assign_BUF*" ]
        removeCellRoute $inv
        remove_buffer $inv
        continue
    }
    if {[sizeof_collection $inv] > 2} {
        
        puts $o "remove_buffer \{[get_object_name $inv]\}"
        puts "inv [sizeof_collection $inv]"
        removeCellRoute $inv
        remove_buffer $inv
    }
    close $o
    #source removeBuffer.tcl

}
close $f
#close $o
#source removeBuffer.tcl
} 

proc genAddSIRepSpec {spec} {
set f [open $spec r]
set o [open genAddSIRepSpec.spec w]
while {[gets $f line] >= 0} {
    if {[regexp {^load\s+(\S+)} $line match load]} {
        set load_h($load) 1
        puts $o ""
    }
    if {[regexp {^ck_net\s+(\S+)} $line match ck_net]} {
    }
    if {[regexp {^si_load\s+(\S+)} $line match si_load]} {
    }
    if {[regexp {^FCFPRep(\S+)CLK} $line match suffix]} {
        set rep "FCFPRep${suffix}CLK"
        if {$load_h($load) == 1} {
            set result [getNearestCkNet FCFPRep${suffix}CLK* $load]
            set nearest_ck [lindex $result 1]
            set nearest_SI "[lindex $result 0]/SI"
            puts $o "load $load"
            puts $o "ck_net $nearest_ck"
            puts $o "si_load $nearest_SI"
            puts $o "$line"
            set load_h($load) 0
        } else {
            puts $o "$line"
        }
    }
    
}
close $f
close $o
}

proc removeRoute {nets} {
remove_routes -user_route -detail_route -nets $nets
}

proc removeCellRoute {cells} {
set nets [get_nets -of_objects [filter_collection [get_pins -of_objects [get_cells -quiet $cells]] "port_type == signal"]]
remove_routes -user_route -detail_route -nets $nets
set_routing_rule [get_nets $nets] -min_routing_layer M4 -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low

}

proc rerouteNet {nets layer} {
catch {set_routing_rule [get_nets $nets] -min_routing_layer $layer -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low}
catch {route_eco -nets $nets -reroute  any_nets -utilize_dangling_wires true}
}

proc fastRoute {nets layer} {
set_routing_rule [get_nets $nets] -min_routing_layer $layer -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low
removeAllRoute
removeOtherNet $nets
route_group -stop_after_global_route true -nets $nets
route_track
}

proc removeOtherNets {nets} {
set nets_removed [remove_from_collection [get_nets * -hierarchical] [get_nets $nets] ]
remove_nets $nets_removed -force 
}

proc resetNet {nets {layer M4}} {
remove_routes -user_route -detail_route -nets [get_nets $nets]
set_routing_rule [get_nets $nets] -min_routing_layer $layer -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low
}

proc addBuffer {nets} {
set dist 70
foreach net $nets {
    if {[sizeof_collection [get_nets -q $net]] } {
        catch {set net_length [get_attribute [get_nets $net] dr_length ]}
        set time_stamp [clock format [clock sec] -format "%a_%d_%b_%Y_%H"]
        set owner simchen
        if {[regexp {gc} [get_object_name $net]]} {
            set domain "GFX"
        } else {
            set domain "SOC"
        }
        catch {add_buffer_on_route -net_prefix fixDrv_${owner}_${time_stamp} -cell_prefix ${domain}_${owner}_${time_stamp} -repeater_distance $dist -first_distance 30 -lib_cell HDN6BLVT08_BUF_8  $net}
  }
}
}

proc addBufferBK {nets} {
set dist 70
foreach net $nets {
  if {[sizeof_collection [get_nets -q $net]] } {
  catch {set net_length [get_attribute [get_nets $net] dr_length ]}
  if {$net_length > $dist} {
    set time_stamp [clock format [clock sec] -format "%a_%d_%b_%Y_%H"]
    set owner simchen
    catch {add_buffer_on_route -net_prefix fixDrv_${owner}_${time_stamp} -cell_prefix fixDrv_${owner}_${time_stamp} -repeater_distance $dist -first_distance 30 -lib_cell HDN6BLVT08_BUF_8  $net}
    } else {
     echo "Info:no need insert buffer"
   }

  }
}
}



proc delayCk {pin} {
set range 20
set prefix simchen
set ck_buf HDBLVT08_BUF_CK_4 
set bbox [get_attribute $pin bbox]
set x [lindex [lindex $bbox 0] 0]
set y [lindex [lindex $bbox 0] 1]
set llx [expr $x - $range]
set lly [expr $y - $range]
set urx [expr $x + $range]
set ury [expr $y + $range]
set x_list ""
set y_list ""
puts "$llx $lly $urx $ury"
set loc_orig(0) "$llx $lly"
set loc_orig(1) "$llx $ury"
set loc_orig(2) "$urx $ury"
set loc_orig(3) "$urx $lly"

for { set i 0 } { $i < 4} {incr i} {
    set dis 99999
    foreach_in_collection cell [get_cells  -within "{$llx $lly} {$urx $ury}" -filter "is_hard_macro == false"] {
        set bbox [get_attribute $cell bbox]
        set x_tmp [lindex [lindex $bbox 0] 0]
        set y_tmp [lindex [lindex $bbox 0] 1]
        set dis_tmp [expr abs($x_tmp - [lindex $loc_orig($i) 0]) + abs($y_tmp - [lindex $loc_orig($i) 1])]
        if {$dis_tmp < $dis} {
            set dis $dis_tmp
            set loc($i) "$x_tmp $y_tmp"
            #puts "loc $i  [lindex $loc_orig($i) 0] [lindex $loc_orig($i) 1] : $dis $dis_tmp $x_tmp $y_tmp "
        }
    }
}
set name [insert_buffer $pin -lib_cell $ck_buf -new_cell_names $prefix]
set_cell_location $name -coordinates "$loc(0)"
if {[sizeof_collection [get_cells -quiet $name]]} {
    puts "# add buffer [get_object_name $name] at $loc(0)"
}
set name [insert_buffer $pin -lib_cell $ck_buf -new_cell_names $prefix]
set_cell_location $name -coordinates "$loc(1)"
if {[sizeof_collection [get_cells -quiet $name]]} {
    puts "# add buffer [get_object_name $name] at $loc(1)"
}
set name [insert_buffer $pin -lib_cell $ck_buf -new_cell_names $prefix]
set_cell_location $name -coordinates "$loc(2)"
if {[sizeof_collection [get_cells -quiet $name]]} {
    puts "# add buffer [get_object_name $name] at $loc(2)"
}
set name [insert_buffer $pin -lib_cell $ck_buf -new_cell_names $prefix]
set_cell_location $name -coordinates "$loc(3)"
if {[sizeof_collection [get_cells -quiet $name]]} {
    puts "# add buffer [get_object_name $name] at $loc(3)"
}
#puts "$loc0 | $loc1 | $loc2 | $loc3"
}

proc genNewCellName {prefix} {
set i 0
set n 99999
while {$i < $n} {
    if {[sizeof_collection [get_cells -quiet ${prefix}_$i]] == 0} {
        break
    } else {
        incr i
    }
}
return ${prefix}_$i
}

proc getObjLoc {obj} {
if {[sizeof_collection [get_cells -quiet $obj]]} {
    set obj_e [get_cells $obj]
} elseif {[sizeof_collection [get_pins -quiet $obj]]} {
    set obj_e [get_pins $obj]
} elseif {[sizeof_collection [get_ports -quiet $obj]]} {
    set obj_e [get_ports $obj]
} else {
    return "NA"
    puts "# $obj not recognized."
}

set bbox [get_attribute $obj_e bbox]
set llx [lindex [lindex $bbox 0] 0]
set lly [lindex [lindex $bbox 0] 1]
set urx [lindex [lindex $bbox 1] 0]
set ury [lindex [lindex $bbox 1] 1]
#puts "$obj $llx $lly"
return "$llx $lly"
}

proc getObjDis {obj0 obj1} {
set x0 [lindex [getObjLoc $obj0] 0]
set y0 [lindex [getObjLoc $obj0] 1]
set x1 [lindex [getObjLoc $obj1] 0]
set y1 [lindex [getObjLoc $obj1] 1]
set dis [expr abs($x0 -$x1) + abs($y0 -$y1)]
puts "$obj0 $obj1 $dis"
return $dis
}

proc insertBuffer {load_pin {suffix insertBuff}} {
set interval 70
set owner simchen
set time_stamp [clock format [clock sec] -format "%a_%d_%b_%Y_%H"]
set prefix "${owner}_${suffix}"
set buf HDBLVT08_BUF_6 
set drv [filter_collection [all_connected [all_connected $load_pin] -leaf] "direction == out"]
if {[sizeof_collection $drv] == 0} {
    puts "# No driver found."
    return 0
}
set dis [getObjDis $load_pin [get_object_name $drv]]
set x_s [lindex [getObjLoc $drv] 0]
set y_s [lindex [getObjLoc $drv] 1]
set x_e [lindex [getObjLoc $load_pin] 0]
set y_e [lindex [getObjLoc $load_pin] 1]
set n [expr $dis / $interval]
set x_interval [expr ($x_e - $x_s) / $n]
set y_interval [expr ($y_e - $y_s) / $n]

for { set i 0 } { $i < [expr $n - 1] } {incr i} {
    set name [insert_buffer $load_pin -lib_cell $buf -new_cell_names $prefix]
    removeCellRoute $name

    set x [expr $x_s + $x_interval * ($i + 1)]
    set y [expr $y_s + $y_interval * ($i + 1)]
    set_cell_location $name -coordinates "$x $y"

}
}

proc moveObjToObj {obj0 obj1} {
set loc [getObjLoc $obj1]
set_cell_location $obj0 -coordinates "$loc"
}

proc checkFloatNets {nets} {
foreach_in_collection net [get_nets $nets] {
    if {[sizeof_collection [all_connected $net]] == 1} {
        puts "[get_object_name $net] [sizeof_collection [all_connected $net]] [get_object_name [all_connected $net]]"
    }
}
}

proc getNetRouteLength {nets} {
foreach_in_collection net [get_nets $nets] {
    set routes [get_attribute $net route_length] 
    if {$routes == 0} {
        continue
    }
    set sum 0
    puts "[get_object_name $net]"
    foreach route $routes {
        set layer [lindex $route 0]
        set l [lindex $route 1]
        set sum [expr $sum + $l]
        puts "$route"
    }
    puts "# [get_object_name $net] $sum"
}
}

proc hp {drv} {
change_selection [get_nets -of_objects [all_fanout -from $drv -flat -trace_arcs all]]
}


proc hpc {drvs} {
set cells ""
foreach drv $drvs {
    set cells [add_to_collection [get_cells [all_fanout -from $drv -flat -only_cells -trace_arcs all] -filter "design_type == lib_cell"] $cells]
}
change_selection $cells 
gui_change_highlight -remove -all_colors

}

proc genTileNet {nets} {
foreach_in_collection net [get_nets $nets] {
    foreach_in_collection pin [all_connected $net] {
        set port [get_attribute $pin name]
        set tile [get_attribute [get_cells -of_objects $pin] ref_name]
        puts "$tile $port"
    }
}

}

proc so {obj} {
if {[sizeof_collection [get_cells -quiet $obj]]} {
    set obj_e [get_cells $obj]
} elseif {[sizeof_collection [get_pins -quiet $obj]]} {
    set obj_e [get_pins $obj]
} elseif {[sizeof_collection [get_ports -quiet $obj]]} {
    set obj_e [get_ports $obj]
} elseif {[sizeof_collection [get_nets -quiet $obj]]} {
    set obj_e [get_nets $obj]
} else {
    puts "# $obj not recognized."
}
change_selection $obj_e
}


proc removeConGestedBufRamdon {} {
set bufs [filter_collection [get_selection] "ref_name =~ *BUF* && full_name !~ *FCFP_assign_BUF*"]
set n [sizeof_collection $bufs]
set n [expr $n / 2]
set i 0
foreach_in_collection buf $bufs {
    remove_buffer $buf
    incr i
    if {$i > $n} {
        break
    }
}
}

proc selectNonTie {} {
set bufs [filter_collection [get_selection] "ref_name !~ *TIE* && full_name !~ *tie*"]
change_selection $bufs
}

proc saveUnfix {} {
set bufs [filter_collection [get_cells * -hierarchical] "is_fixed == false"]
change_selection $bufs
saveCells
}

proc selectUnfix {} {
set bufs [filter_collection [get_selection] "is_fixed == false"]
change_selection $bufs

}

proc filterCellPower {power} {
set new_cells ""
foreach_in_collection cell [get_selection] {
    set cell_power [get_object_name [all_connected [get_object_name $cell]/VDD]]
    if {[regexp "$power" $cell_power]} {
        set new_cells [add_to_collection $new_cells $cell]
    }
}
change_selection $new_cells
}

proc selectName {name} {
set bufs [filter_collection [get_selection] "full_name =~ *$name*"]
change_selection $bufs

}



proc checkGFXRegionPower {} {
set o [open checkGFXRegionPower.rpt w]
remove_placement_blockages *
create_placement_blockage -boundary " {-10548.1350 -1417.2000} {-8265.7260 -206.6400} " 
create_placement_blockage -boundary " {-10548.1350 229.2000} {-8265.7980 1353.0510}"
create_placement_blockage -boundary " {-10553.0940 1331.5800} {-8414.2260 1435.3200}" 
create_placement_blockage -boundary " {-8167.3020 -1701.1200} {8176.8780 1725.1200}" 
create_placement_blockage -boundary " {-8173.4580 -11670.2400} {8183.0720 -1701.1200}" 
create_placement_blockage -boundary " {-8173.4580 1725.1000} {8183.0340 11694.2400}" 
create_placement_blockage -boundary " {-9425.8620 37.6200} {-8439.4900 228.7200}" 
create_placement_blockage -boundary " {-9432.8340 -464.2200} {-8266.7100 131.2800}" 
create_placement_blockage -boundary " {8275.3740 229.2000} {10557.7110 1357.9200}" 
create_placement_blockage -boundary " {8276.2860 -1328.1600} {8349.5880 39.84}" 
create_placement_blockage -boundary " {8276.2860 -40.0800} {8328.8970 90.7200}"
create_placement_blockage -boundary " {8281.5300 -228.3000} {8479.8330 -33.4800}"
create_placement_blockage -boundary " {8349.5880 -1329.1200} {10557.7110 -205.2000}" 
create_placement_blockage -boundary " {8422.8900 1358.2800} {10562.6700 1441.2000}" 
create_placement_blockage -boundary " {8423.8020 -1411.3200} {10562.6700 -1329.4800}" 

foreach_in_collection bkg [get_placement_blockages *] {
    puts "[get_attribute $bkg bbox]"
    set bbox [get_attribute $bkg bbox]
    set cells [get_cells -within $bbox]
    set cells [filter_collection $cells "design_type == lib_cell"]
    puts "$bbox | [sizeof_collection $cells]"
    foreach_in_collection cell $cells {
        set pins [filter_collection [get_pins [get_object_name $cell]/*] "direction == in && is_user_pg == false"]
        puts $o "# [get_object_name $cell] [get_object_name $pins]"
        if {[sizeof_collection $pins]} {
            foreach_in_collection pin $pins {
                set drv [all_fanin -to $pin -flat -startpoints_only]
                if {[sizeof_collection $drv] == 0} {
                    if {[regexp {^gc_} [get_object_name $cell]] || [regexp {compute_array} [get_object_name $cell]]} {
                        break 
                    }
                }

                if {[regexp {^gc_} [get_object_name $drv]] || [regexp {compute_array} [get_object_name $drv]]} {
                    break
                } else {
                    puts $o "[get_object_name $cell] [get_object_name $drv] | in"
                    break 
                }
        
            }
        } else {
            set pin [filter_collection [get_pins [get_object_name $cell]/*] "direction == out  && is_user_pg == false"]
            set drv [all_fanout -from $pin -flat -endpoints_only]
            if {[sizeof_collection $drv] == 0} {
                if {[regexp {^gc_} [get_object_name $cell]] || [regexp {compute_array} [get_object_name $cell]]} {
                    continue
                }
            }
            if {[regexp {^gc_} [get_object_name $drv]] || [regexp {compute_array} [get_object_name $drv]]} {
                continue
            } else {
                puts $o "[get_object_name $cell] [get_object_name $drv] | out"
                continue
            }
        }
    }
}
close $o
}

proc removeAllRoute {} {
remove_routes -net_types signal -detail_route
remove_routes -net_types signal -detail_route -user_route
}

proc getSrc {} {
foreach_in_collection cell [get_selection] {
    set pins [filter_collection [get_pins [get_object_name $cell]/*] "direction == in && port_type == signal"]
    if {[sizeof_collection $pins]} {
        foreach_in_collection pin $pins {
            set drv [all_fanin -to $pin -flat -startpoints_only -trace_arcs all]
            puts "[get_object_name $pin] [get_object_name [all_fanin -to $pin -flat -startpoints_only]]"
            hp $drv 
        }
    }
}
}

proc putSelected {} {
foreach_in_collection obj [get_selection] {
    puts "[get_object_name $obj] [get_attribute $obj ref_name]"
}
}

proc putSelectedNet {} {
foreach_in_collection net [get_nets -of_objects [get_shapes [get_selection ]]]  {puts [get_object_name $net]}
}

proc getCellsByPower {power} {
set shapes [filter_collection [get_shapes -of_objects [get_nets $power]] "layer_name == M0"]
set geom_shapes [create_geo_mask $shapes -merge]
set geom_shapes_upsize [resize_polygons -objects $geom_shapes -size {0 0 0 0.48}]
set geom_shapes_dosize [resize_polygons -objects $geom_shapes_upsize -size {0 0 0 -0.48}]
set shapes_size [copy_to_layer -geo_masks $geom_shapes_dosize -layer M12]
set cells ""
set i 0
foreach_in_collection shape $shapes_size {
    puts "create_placement_blockage -name simchen_${i}_${power} -boundary   \"[get_attribute $shape bbox]\""
    set cells [add_to_collection $cells [get_cells -within [get_attribute $shape boundary]]]
    incr i
}
remove_shapes $shapes_size
return [filter_collection $cells "design_type == lib_cell"]
}


proc checkBACOPower {cells} {
set o [open checkBACOPower.rpt w]
foreach_in_collection cell $cells {
    set pins [filter_collection [get_pins [get_object_name $cell]/*] "direction == in && is_user_pg == false"]
    #puts $o "# [get_object_name $cell] [get_object_name $pins]"
    if {[sizeof_collection $pins]} {
        foreach_in_collection pin $pins {
            set drv [all_fanin -to $pin -flat -startpoints_only]
            if {[sizeof_collection $drv] == 0} {
                    continue
            }

            if {[regexp {dxio_pcie_|nbio_pcie|smu_mp1_t|smu_thm_t|nbio_nbif|smu_clkc3_t1|vdci|SSB} [get_object_name $drv]]} {
                break
            } else {
                puts $o "[get_object_name $cell] [get_object_name $drv] | in"
                break
            }

        }
    }
}
close $o
}

proc checkVsi {power} {
 set cells ""
foreach_in_collection cell [get_selection] {
    set llx [lindex [get_attribute $cell bbox] 0 0]
    set lly [lindex [get_attribute $cell bbox] 0 1]
    set urx [lindex [get_attribute $cell bbox] 1 0]
    set ury [lindex [get_attribute $cell bbox] 1 1]
    if {[sizeof_collection [filter_collection [get_shapes -intersect "{$llx $lly} {$urx $ury}"] "layer_name == M0" ]] == 0} {
         set cells "$cells [get_object_name $cell]"
        continue
    }
    foreach_in_collection shape [filter_collection [get_shapes -intersect "{$llx $lly} {$urx $ury}"] "layer_name == M0" ] {
        set net_name [get_object_name [get_attribute $shape owner]]
        if {[regexp "$power" $net_name] == 0 && [regexp {VSS} $net_name] == 0} {
            #puts "[get_object_name $cell] [get_object_name [get_attribute $shape owner]]"
            set cells "$cells [get_object_name $cell]"
        }
    }
}
puts "[llength $cells] $cells"
if {[llength $cells]} {
    change_selection [get_cells $cells]
}

}

proc checkVsiDrv {power drvs} {
foreach_in_collection drv [get_pins $drvs] {
    set cells [get_cells [all_fanout -from $drv -flat -only_cells] -filter "design_type == lib_cell"]
    set cells_viols ""
    foreach_in_collection cell $cells {
        set llx [lindex [get_attribute $cell bbox] 0 0]
        set lly [lindex [get_attribute $cell bbox] 0 1]
        set urx [lindex [get_attribute $cell bbox] 1 0]
        set ury [lindex [get_attribute $cell bbox] 1 1]
        foreach_in_collection shape [filter_collection [get_shapes -intersect "{$llx $lly} {$urx $ury}"] "layer_name == M0" ] {
            set net_name [get_object_name [get_attribute $shape owner]]
            if {[regexp "$power" $net_name] == 0 && [regexp {VSS} $net_name] == 0} {
                #puts "[get_object_name $cell] [get_object_name [get_attribute $shape owner]]"
                set cells_viols "$cells_viols [get_object_name $cell]"
            }
        }
    }
    if {[llength $cells_viols]} {
        puts "[get_object_name $drv] [llength $cells_viols] $cells_viols"
        change_selection [get_cells $cells_viols]
    }
}
}


proc dumpPlacementBkg {} {
set i 0
foreach_in_collection shape [get_placement_blockages] {
    puts "create_placement_blockage -name simchen_$i -boundary \"[get_attribute $shape bbox]\""
    incr i
}
}

proc dumpPinBkg {} {
set i 0
foreach_in_collection shape [get_pin_blockages] {
    #puts "create_placement_blockage -name simchen_$i -boundary \"[get_attribute $shape bbox]\""
    #eval "create_pin_blockage   -boundary \"[get_attribute $shape bbox]\""
    puts "create_pin_blockage   -boundary \"[get_attribute $shape bbox]\""
    incr i
}
}


proc fixVsi {power cells} {
set o [open fixVsi.rpt w]
set range 360
#set power_shapes [filter_collection [get_shapes -of_objects [get_nets $power]] "layer_name == M0"]
set n [sizeof_collection [get_cells $cells]]
set k 0
foreach_in_collection cell [get_cells $cells] {
    puts "# $k of $n"
    incr k
    set llx [lindex [get_attribute $cell bbox] 0 0]
    set lly [lindex [get_attribute $cell bbox] 0 1]
    set urx [lindex [get_attribute $cell bbox] 1 0]
    set ury [lindex [get_attribute $cell bbox] 1 1]
    set llx_range [expr $llx - $range]
    set lly_range [expr $lly - $range]
    set urx_range [expr $urx + $range]
    set urx_range [expr $ury + $range]
    set range_h(2) "{$llx $lly} {[expr $urx + $range] $ury}"
    set range_h(0) "{[expr $llx - $range]  $lly} {$urx $ury}"
    set range_h(1) "{$llx $lly} {$urx [expr $ury + $range]}"
    set range_h(3) "{$llx [expr $lly - $range]} {$urx $ury}"
    set power_shapes [filter_collection [get_shapes -intersect  "{$llx_range $lly_range} {$urx_range $urx_range}"] "layer_name == M0 && owner.full_name == $power"]
    #puts "{$llx_range $lly_range} {$urx_range $urx_range}"
    set cell_loc "$llx $lly"
    set loc ""
    foreach i [array names range_h] {
        #puts "# range_shape: $range_h($i) $i"
        set range_shape [create_geo_mask -objects [create_poly_rect -boundary $range_h($i)]]
        set found_shapes [compute_polygons -objects1 $power_shapes -objects2 $range_shape -operation AND]
        set real_shapes [copy_to_layer -geo_masks $found_shapes -layer M12]
        if {[sizeof_collection $real_shapes] == 0} {
            continue
        }
        set shape_list ""
        foreach_in_collection shape $real_shapes {
            set llx [lindex [get_attribute $shape bbox] 0 0]
            set lly [lindex [get_attribute $shape bbox] 0 1]
            set urx [lindex [get_attribute $shape bbox] 1 0]
            set ury [lindex [get_attribute $shape bbox] 1 1]
            #puts "# real shape : $llx $lly $urx $ury"
            if {$i == 0} {
                set shape_list "$shape_list $urx"
            }
            if {$i == 2} {
                set shape_list "$shape_list $llx"
            }
            if {$i == 1} {
                set shape_list "$shape_list $lly"
            }
             if {$i == 3} {
                set shape_list "$shape_list $ury"
            }
        }
        if {[llength $shape_list] == 0} {
            continue
             #return 0
        }
        if {$i == 0} {      
            set loc "[expr [lindex [lsort -real $shape_list] end] - 2] $lly"
        }
        if {$i == 2} {
            set loc "[expr [lindex [lsort -real $shape_list] 0] + 2 ] $lly"
        }
        if {$i == 1} {
            set loc "$llx [lindex [lsort -real $shape_list] 0]"
        }
        if {$i == 3} {
            set loc "$llx [lindex [lsort -real $shape_list] end]"
        }
        if {[llength $loc]} {
            remove_shapes $real_shapes
             set dis [expr abs([lindex $cell_loc 0] - [lindex $loc 0]) + abs([lindex $cell_loc 1] - [lindex $loc 1]) ]
            puts $o "# [get_object_name $cell] $loc $dis"
            puts $o "set_cell_location -coordinates {$loc} [get_object_name $cell]"
            break
        }

    }
    if {[llength $loc] == 0} {
        puts $o "# [get_object_name $cell] cannot found power with $range"
        continue
    }
    #return "[get_object_name $cell] $loc"
}
close $o
}


proc removeBufferPath {from to} {
set from_cells [remove_from_collection [filter_collection [all_fanout -from $from -flat -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF*"]  [get_cells -of_objects [get_pins $from]]]
foreach_in_collection cell $from_cells {
    #puts "[get_object_name $cell]"
    set cell_h([get_object_name $cell]) 1
}
set to_cells [remove_from_collection [filter_collection [all_fanin -to $to  -flat -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *BUF*"] [get_cells -of_objects [get_pins $to]]]
set path_buf ""
foreach_in_collection cell $to_cells {
    if {[info exists cell_h([get_object_name $cell])]} {
        #puts "[get_object_name $cell]"
        set path_buf "$path_buf [get_object_name $cell]"
    }
}
if {[sizeof_collection [get_cells -quiet $path_buf]]} {
    #removeCellRoute [get_cells $path]
    #remove_buffer [get_cells $path]
}

set from_cells [remove_from_collection [filter_collection [all_fanout -from $from -flat -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *INV*"]  [get_cells -of_objects [get_pins $from]]]
foreach_in_collection cell $from_cells {
    #puts "[get_object_name $cell]"
    set cell_inv_h([get_object_name $cell]) 1
}
set to_cells [remove_from_collection [filter_collection [all_fanin -to $to  -flat -only_cells -trace_arcs all] "design_type == lib_cell && ref_name =~ *INV*"] [get_cells -of_objects [get_pins $to]]]
set path_inv ""
foreach_in_collection cell $to_cells {
    if {[info exists cell_inv_h([get_object_name $cell])]} {
        #puts "[get_object_name $cell]"
        set path_inv "$path_inv [get_object_name $cell]"
    }
}
if {[sizeof_collection [get_cells -quiet $path_inv]]} {
    if {[expr fmod([llength $path_inv],2)] != 0} {
        puts "# $from Inv not pair skip"
        return 0
    }
    if {[llength $path_buf]} {
        removeCellRoute [get_cells $path_buf]
        remove_buffer [get_cells $path_buf]
    }
    removeCellRoute [get_cells $path_inv]
    remove_buffer [get_cells $path_inv]
    return 1
}
if {[llength $path_buf]} {
    removeCellRoute [get_cells $path_buf]
    remove_buffer [get_cells $path_buf]
}


}

proc insertBufferByLoc {path_spec load_pins {suffix insertBufferByLoc}} {
set interval 70
set owner simchen
set time_stamp [clock format [clock sec] -format "%a_%d_%b_%Y_%H"]
set prefix "${owner}_${suffix}_${time_stamp}"
set buf HDN6BLVT08_BUF_8

for {set i 0 } { $i < [llength $path_spec] } {incr i} {
    set x [lindex [lindex $path_spec $i] 0]
    set y [lindex [lindex $path_spec $i] 1]
    set name [insert_buffer $load_pins -lib_cell $buf -new_cell_names $prefix]
    removeCellRoute $name
    set_cell_location $name -coordinates "$x $y"
}
}    

proc insertBufferByPathVar {path_spec load_pins {suffix replan_buf_tree}} {
set interval 60
set owner simchen
set time_stamp [clock format [clock sec] -format "%a_%d_%b_%Y_%H"]
set prefix "${owner}_${suffix}"
set buf HDN6BLVT08_BUF_8
remove_routes -user_route -detail_route -nets [all_connected $load_pins -leaf]

foreach  load_pin $load_pins {
    set drv [filter_collection [all_connected [all_connected $load_pin] -leaf] "direction == out"]
    set x_s [lindex [getObjLoc $drv] 0]
    set y_s [lindex [getObjLoc $drv] 1]
    set x_e [lindex [getObjLoc $load_pin] 0]
    set y_e [lindex [getObjLoc $load_pin] 1]
    break
}
set pn 0
for  { set i 0 } { $i < [llength $path_spec] } {incr i} {
    set x [lindex [lindex $path_spec $i] 0]
    set y [lindex [lindex $path_spec $i] 1]
    set path_orig($pn) "$x $y"
    set path($pn) "$x $y"
    incr pn

}

set x0 [lindex $path(0) 0]
set y0 [lindex $path(0) 1]
puts "[get_object_name $drv] $x_s $y_s | [get_object_name $load_pin ] $x_e $y_e | $x0 $y0"

set dis_s [expr abs($x_s - $x0) +  abs($y_s - $y0)]
set dis_e [expr abs($x_e - $x0) +  abs($y_e - $y0)]
puts "$dis_s | $dis_e"

set path(0) "$x_s $y_s"
set  path([expr $pn + 1]) "$x_e $y_e"
set pn_new [expr $pn + 1]
for { set i 0 } { $i <= [expr $pn - 1] } {incr i} {
    set j [expr $i + 1]
    set x [lindex $path_orig($i) 0]
    set y [lindex $path_orig($i) 1]
    set path($j) "$x $y"
    puts "$j $x $y $pn"
    
}
set pn $pn_new
for { set i 0 } { $i <= [expr $pn - 2] } {incr i} {
    set xl [lindex $path($i) 0] 
    set yl [lindex $path($i) 1]
    set j [expr $i + 1]
    set xu [lindex  $path($j) 0]
    set yu [lindex  $path($j) 1]
    set dis [expr abs($xu - $xl) + abs($yu - $yl)]
    set n  [expr $dis / $interval]
    if {$n < 1} {
        set n 1
    }
    set x_interval [expr ($xu - $xl) / $n]
    set y_interval [expr ($yu - $yl) / $n]
    puts "$n"
    for { set k 0 } { $k < [expr $n - 1] } {incr k} {
        set name [insert_buffer $load_pins -lib_cell $buf -new_cell_names $prefix]
        set nets [get_nets -of_objects [filter_collection [get_pins -of_objects [get_cells -quiet $name]] "is_user_pg == false"]] 
        set_routing_rule [get_nets $nets] -min_routing_layer M4 -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low
        set x [expr $xl + $x_interval * ($k + 1)]
        set y [expr $yl + $y_interval * ($k + 1)]
        set_cell_location $name -coordinates "$x $y"
        puts "$x $y | $xl $yl | $xu $yu | main $i $pn"
    }
}
foreach_in_collection pin [get_pins $load_pins] {
    if {[sizeof_collection [get_pins $load_pins]] > 1} {
        break
    }
    set xl [lindex $path([expr $pn - 1]) 0]
    set yl [lindex $path([expr $pn - 1]) 1]
    set xu [lindex [getObjLoc $pin] 0]
    set yu [lindex [getObjLoc $pin] 1]
    set dis [expr abs($xu - $xl) + abs($yu - $yl)]
    set n  [expr $dis / $interval]
    if {$n < 1} {
        set n 1
    }
    set x_interval [expr ($xu - $xl) / $n]
    set y_interval [expr ($yu - $yl) / $n]

    for { set k 0 } { $k < [expr $n - 1] } {incr k} {
        set name [insert_buffer $pin -lib_cell $buf -new_cell_names $prefix]
        set nets [get_nets -of_objects [filter_collection [get_pins -of_objects [get_cells -quiet $name]] "is_user_pg == false"]] 
        set_routing_rule [get_nets $nets] -min_routing_layer M4 -max_routing_layer M11  -max_layer_mode_soft_cost high -min_layer_mode_soft_cost low
        set x [expr $xl + $x_interval * ($k + 1)]
        set y [expr $yl + $y_interval * ($k + 1)]
        set_cell_location $name -coordinates "$x $y"
        puts "$x $y | $xl $yl | $xu $yu | [get_object_name $pin]"
    }
}

}

proc removeTieBuffer {nets} {
foreach_in_collection net [get_nets $nets] {
    while {1} {    
        set cells [filter_collection [get_cells -of_objects $net] "design_type == lib_cell && ref_name =~ *BUF*"] 
        if {[sizeof_collection $cells]} {
            remove_buffer -net $net
        } else {
            break
        }
    }
}
}

proc fixAnt {pins {n 10}} {
set o [open fixAnt.tcl w]
set i 0
foreach_in_collection pin [get_pins $pins] {
    set pin_name [get_object_name $pin]
    puts $o "## fix $pin_name"
    for { set j 0 } { $j < $n } {incr j} {
        set ant_cell simchen_ant_inst_$i
        while {[sizeof_collection [get_cells -quiet simchen_ant_inst_$i]]} {
            incr i
            set  ant_cell simchen_ant_inst_$i
        }
        puts $o "set tie_cell_loc \[lindex \[get_attribute \[get_pins $pin_name\] bbox\] 0\]"
        puts $o "create_cell $ant_cell \[get_lib_cells */HDBLVT08_TIEDIN_4\]"
        create_cell $ant_cell [get_lib_cells */HDBLVT08_TIEDIN_4]
        puts $o "set_cell_location $ant_cell -coordinates \"\$tie_cell_loc\""

        puts $o "connect_net -net \[get_nets \[all_connected $pin_name \]\] \[get_pins $ant_cell/X\]"
    }
}
close $o
}

proc showConnectedCells {cells} {
set nets [get_nets -of_objects [filter_collection [get_pins -of_objects [get_cells -quiet $cells]] "port_type == signal"]]

set cells_show [filter_collection [get_cells -of_objects [get_nets $nets]] "design_type == lib_cell"]
change_selection $cells_show
}

proc backTrace {inst {n 1000}} {
set cur_cell [get_object_name [get_cells $inst]]
set i 0
set chain ""
while {$i < $n} {
    if {[sizeof_collection [filter_collection [get_pins $cur_cell/* ] "port_type == signal && direction == in"]] == 0} {
        set chain "$chain TIE"
        set i 2000
    }
    foreach_in_collection in [filter_collection [get_pins $cur_cell/* ] "port_type == signal && direction == in"] {
        set net [all_connected $in -leaf]
        set out [filter_collection [all_connected $net -leaf] "direction == out"]
        if {[sizeof_collection $out] == 0} {
            set chain "$chain INPUT_FLOAT"
            set i 2000
            break
        }
        set cur_cell [get_object_name [get_cells -of_object $out]]
        set chain "$chain $cur_cell"
        if {[get_attribute [get_cells $cur_cell] design_type] != "lib_cell"} {
            set i 2000
            set chain "$chain END"
            break
        }
        break
    }
    incr i
}
puts "$chain"
}

proc frontTrace {inst {n 1000}} {
set cur_cell [get_object_name [get_cells $inst]]
set i 0
set chain ""
while {$i < $n} {
    foreach_in_collection out [filter_collection [get_pins $cur_cell/* ] "port_type == signal && direction == out"] {
        set net [all_connected $out -leaf]
        set in [filter_collection [all_connected $net -leaf] "direction == in"]
        if {[sizeof_collection $out] == 0} {
            set chain "$chain OUTPUT_FLOAT"
            set i 2000
            break
        }
        set cur_cell [get_object_name [get_cells -of_object $in]]
        set chain "$chain $cur_cell"
        if {[get_attribute [get_cells $cur_cell] design_type] != "lib_cell"} {
            set i 2000
            set chain "$chain END"
            break
        }
        break
    }
    incr i
}
puts "$chain"
}


proc checkNetlist {} {
set_message_info -id DCHK-002 -limit 0 
set_message_info -id DCHK-003 -limit 0 
set_message_info -id DCHK-004 -limit 0 
set_message_info -id DCHK-005 -limit 0 
set_message_info -id DCHK-007 -limit 0 
set_message_info -id DCHK-011 -limit 0 
set_message_info -id DCHK-014 -limit 0 
set_message_info -id DCHK-015 -limit 0 
set_message_info -id DCHK-021 -limit 0 
set_message_info -id DCHK-026 -limit 0 
set_message_info -id DCHK-027 -limit 0 
check_netlist > checkNetlist.rpt

}

proc checkE32Phy {} {
set llx_chip [lindex [get_attribute [current_design] boundary_bbox ] 0 0]
set urx_chip [lindex [get_attribute [current_design] boundary_bbox ] 1 0]
set phys [get_cells {
dxio_xgmi_cphy4444_t5/uphy_wrapper_xgmi2/usnps_phy_wrapper1/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t4/uphy_wrapper_xgmi2/usnps_phy_wrapper0/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t5/uphy_wrapper_xgmi2/usnps_phy_wrapper0/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t6/uphy_wrapper_xgmi2/usnps_phy_wrapper2/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t6/uphy_wrapper_xgmi2/usnps_phy_wrapper3/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t4/uphy_wrapper_xgmi2/usnps_phy_wrapper2/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t5/uphy_wrapper_xgmi2/usnps_phy_wrapper2/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t5/uphy_wrapper_xgmi2/usnps_phy_wrapper3/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t7/uphy_wrapper_xgmi2/usnps_phy_wrapper1/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t7/uphy_wrapper_xgmi2/usnps_phy_wrapper0/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t4/uphy_wrapper_xgmi2/usnps_phy_wrapper3/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t6/uphy_wrapper_xgmi2/usnps_phy_wrapper1/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t4/uphy_wrapper_xgmi2/usnps_phy_wrapper1/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t6/uphy_wrapper_xgmi2/usnps_phy_wrapper0/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t7/uphy_wrapper_xgmi2/usnps_phy_wrapper2/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
dxio_xgmi_cphy4444_t7/uphy_wrapper_xgmi2/usnps_phy_wrapper3/u_snps_phy_dft_gasket/u_dwc_pcie4esm_phy_x4_ns/pma
}
]
set llx_list ""
foreach_in_collection phy $phys {
    set llx [lindex [get_attribute [get_cells $phy] boundary_bbox ] 0 0]
    set urx [lindex [get_attribute [get_cells $phy] boundary_bbox ] 1 0]
    puts "[get_object_name $phy] $llx $urx"
    set phy_x($llx) [get_object_name $phy]
    set llx_list "$llx_list $llx"   
}
set llx_list_sort [lsort -r $llx_list]
puts $llx_list_sort
for { set i 0 } { $i < [llength $llx_list_sort] } {incr i} { 
    set phy_l $phy_x([lindex $llx_list_sort $i])
    set phy_l_x [lindex $llx_list_sort $i]
    set del_l [expr [lindex $llx_list_sort $i] - $llx_chip]
    set phy_r $phy_x([lindex $llx_list_sort [expr [llength $llx_list_sort] - 1 - $i]])
    set phy_urx [lindex [get_attribute [get_cells $phy_r] boundary_bbox ] 1 0]
    set del_r [expr $urx_chip - $phy_urx]
    puts "$phy_l $phy_r | $phy_l_x $phy_urx | $del_l $del_r"
}
}

proc updateFeedsXml {} {
set top [get_attribute [current_design] name]
set o [open cell/$top/GetTileData.feedthru.xml w]
set file_name "cell/$top/GetTileData.feedthru.bk.xml"
set f [open $file_name r]
puts $file_name
while {[gets $f line] >= 0} {
    if {[regexp {<feedthru\s+tile=\"\S+\">} $line]} {
        puts $o $line
    }
    if {[regexp {<feed\s+input=\"(\S+)\"\s+inputLayer=\S+\s+inputPinBox=\S+\s+\S+\s+\S+\s+\S+\s+inputX=\S+\s+inputY=\S+\s+output=\"(\S+)\"} $line match feed_input feed_output]} {
        set is_input 1
        set is_internal 0
        set feed_input_h($feed_input) 0
        set feed_reg($feed_input) ""
        puts $o $line
        #puts $feed_input
    }
    if {[regexp {<internal\s+input=\"(\S+)\"} $line match feed_input]} {
        set is_input 1
        set is_internal 1
        set feed_input_h($feed_input) 0
        set feed_reg($feed_input) ""
        puts $o $line
    }
    if {[regexp {<internal\s+output=\"(\S+)\"} $line match feed_input]} {
        set is_input 0
        set is_internal 1
        set feed_input_h($feed_input) 0
        set feed_reg($feed_input) ""
        puts $o $line
    }

    if {[regexp {<buf\s+fromNet=\"(\S+)\"\s+masterName=\"(\S+)\"\s+name=\"(\S+)\"\s+order=\"(\S+)\"\s+orient=\"(\S+)\"\s+placementStatus=\"(\S+)\"\s+toNet=\"(\S+)\"\s+xPos=\"(\S+)\"\s+yPos=\"(\S+)\"\s+/>} $line match fromNet masterName name order orient placementStatus toNet xPos yPos]} {
        if {[sizeof_collection [get_cells -quiet $name]] == 0} {
            puts "Buf: $feed_input $name"
        }
        set buff $name
        #puts "$feed_input $fromNet $masterName $name $order $orient $placementStatus $toNet $xPos $yPos"
    }
    if {[regexp {<rep\s+clockNetName=\"(\S+)\"\s+fromNet=\"(\S+)\"\s+masterName=\"(\S+)\"\s+name=\"(\S+)\"\s+order=\"(\S+)\"\s+orient=\"(\S+)\"\s+placementStatus=\"(\S+)\"\s+repClockDriv=\"(\S+)\"\s+repClockNet=\"(\S+)\"\s+repDomain=\"(\S+)\"\s+toNet=\"(\S+)\"\s+xPos=\"(\S+)\"\s+yPos=\"(\S+)\"\s+/>} $line match clockNetName fromNet masterName name order orient placementStatus repClockDriv repClockNet repDomain toNet xPos yPos]} {
        #puts "$clockNetName $fromNet $masterName $name $order $orient $placementStatus $repClockDriv $repClockNet $repDomain $toNet $xPos $yPos"
        set feed_reg($feed_input) "$feed_reg($feed_input) $name"
        set reg_name($name) 1
        set feed_input_h($feed_input) [expr $feed_input_h($feed_input) + 1]
        set feed_reg($feed_input) "$feed_reg($feed_input) $name"
        set reg_clockNetName($name) $clockNetName
        set reg_fromNet($name) $fromNet
        set reg_masterName($name) $masterName
        set reg_order($name) $order
        set reg_orient($name) $orient
        set reg_placementStatus($name) $placementStatus
        set reg_repClockDriv($name) $repClockDriv
        set reg_repClockNet($name) $repClockNet
        set reg_repDomain($name) $repDomain
        set reg_toNet($name) $toNet
        set reg_xPos($name) $xPos
        set reg_yPos($name) $yPos
        set reg_info "$feed_input $clockNetName $fromNet $masterName $name $order $orient $placementStatus $repClockDriv $repClockNet $repDomain $toNet $xPos $yPos"
        #puts "$reg_info"
        if {[sizeof_collection [get_cells -quiet $name]] == 0} {
            puts "Reg: $feed_input $name"
        }
    }
    ## check remove or add
    if {[regexp {</feed>} $line] || [regexp {</internal>} $line]} {
        puts "$feed_input [llength [getRepChain $feed_input]]"
        if {$is_input == 1 || $is_input == 0} {
            if {[llength [getRepChain $feed_input]] == [llength $feed_reg($feed_input)] && [llength [getRepChain $feed_input]] == 0} {
                #continue
                #puts $o $line
        
            }
            if {[llength [getRepChain $feed_input]] == 0 && $is_internal == 0} {
                puts $o "    <buf fromNet=\"$feed_input\" masterName=\"HDN6BLVT08_BUF_8\" name=\"${feed_input}_BUF\" order=\"1\" orient=\"R0\" placementStatus=\"unplaced\" toNet=\"$feed_output\" xPos=\"0\" yPos=\"0\" />"
                puts $o $line
            }
            if {[llength [getRepChain $feed_input]] > 0} {
                for { set i 0 } { $i < [llength [getRepChain $feed_input]] } {incr i} {
                    set name [lindex [getRepChain $feed_input] $i]
                    set clockNetName [get_object_name [all_connected $name/CK]]
                    set fromNet [get_object_name [all_connected $name/D]]
                    set order [expr $i + 1]
                    set repClockDriv [get_object_name [filter_collection [all_fanin -to $name/CK -flat -levels 1] "direction == out"]]
                    if {[regexp {FCFPRepFF(\S+)([a-zA-Z])\d+} $name match clk0 clk1]} {
                        set repDomain "$clk0$clk1"
                    }
                    set toNet [get_object_name [all_connected $name/Q]]
                    puts $o "    <rep clockNetName=\"$clockNetName\" fromNet=\"$fromNet\" masterName=\"HDBLVT08_FSDPQ_V2Y2_1\" name=\"$name\" order=\"$order\" orient=\"R0\" placementStatus=\"placed\" repClockDriv=\"$repClockDriv\" repClockNet=\"$repClockNet\" repDomain=\"$repDomain\" toNet=\"$toNet\" xPos=\"0\" yPos=\"0\" />"
                }
                puts $o $line
            }
        }
        
    } 
}

foreach_in_collection port [get_ports * -filter "direction == in && full_name !~ FE_FEED* && full_name !~ ScanEn"] {
    set feed_input [get_object_name $port]
    if {[llength [getRepChain $feed_input]] > 0  && [info exist feed_input_h($feed_input)] == 0} {
        set  feed_input_h($feed_input) 0
        puts $o "  <internal input=\"$feed_input\" inputLayer=\"M1\" inputPinBox=\"((0 0) (0.04 0.04))\" inputX=\"0\" inputY=\"0\" repCount=\"[llength [getRepChain $feed_input]]\" repFirstLength=\"1000\">"
        for { set i 0 } { $i < [llength [getRepChain $feed_input]] } {incr i} {
            set name [lindex [getRepChain $feed_input] $i]
            set reg_name($name)  1
            set clockNetName [get_object_name [all_connected $name/CK]]
            set fromNet [get_object_name [all_connected $name/D]]
            set order [expr $i + 1]
            set repClockDriv [get_object_name [filter_collection [all_fanin -to $name/CK -flat -levels 1] "direction == out"]]
            if {[regexp {FCFPRepFF(\S+)([a-zA-Z])\d+} $name match clk0 clk1]} {
                set repDomain "$clk0$clk1"
            }
            set toNet [get_object_name [all_connected $name/Q]]
            puts $o "    <rep clockNetName=\"$clockNetName\" fromNet=\"$fromNet\" masterName=\"HDBLVT08_FSDPQ_V2Y2_1\" name=\"$name\" order=\"$order\" orient=\"R0\" placementStatus=\"placed\" repClockDriv=\"$repClockDriv\" repClockNet=\"$repClockNet\" repDomain=\"$repDomain\" toNet=\"$toNet\" xPos=\"0\" yPos=\"0\" />"
        }
        puts $o "  </internal>"
    }
}

foreach_in_collection port [get_ports * -filter "direction == out && full_name !~ FE_FEED*"] {
    set reg_exist 0
    set feed_input [get_object_name $port]
    if {[llength [getRepChain $feed_input]] > 0 && [info exist feed_input_h($feed_input)] == 0} {
        foreach reg [getRepChain $feed_input] {
            if {[info exist reg_name($reg)]} {
                set reg_exist 1
            }
        }
        if {$reg_exist == 1} {
            continue
        }
        puts $o "  <internal output=\"$feed_input\" outputLayer=\"M1\" outputPinBox=\"((0 0) (0.04 0.04))\" outputX=\"0\" outputY=\"0\" repCount=\"[llength [getRepChain $feed_input]]\" repFirstLength=\"1000\">"
        for { set i 0 } { $i < [llength [getRepChain $feed_input]] } {incr i} {
            set name [lindex [getRepChain $feed_input] $i]
            set clockNetName [get_object_name [all_connected $name/CK]]
            set fromNet [get_object_name [all_connected $name/D]]
            set order [expr $i + 1]
            set repClockDriv [get_object_name [filter_collection [all_fanin -to $name/CK -flat -levels 1] "direction == out"]]
            if {[regexp {FCFPRepFF(\S+)([a-zA-Z])\d+} $name match clk0 clk1]} {
                set repDomain "$clk0$clk1"
            }
            set toNet [get_object_name [all_connected $name/Q]]
            puts $o "    <rep clockNetName=\"$clockNetName\" fromNet=\"$fromNet\" masterName=\"HDBLVT08_FSDPQ_V2Y2_1\" name=\"$name\" order=\"$order\" orient=\"R0\" placementStatus=\"placed\" repClockDriv=\"$repClockDriv\" repClockNet=\"$repClockNet\" repDomain=\"$repDomain\" toNet=\"$toNet\" xPos=\"0\" yPos=\"0\" />"
        }
        puts $o "  </internal>"
    }
}



foreach_in_collection rep [get_cells FCFPRep*] {
    set name [get_object_name $rep]
    if {[info exist reg_name($rep)] == 0} {
        #puts "$name"
    }
}
close $f
puts $o "</feedthru>"
close $o
}

proc getRepChain {start} {
set n 100
if {[sizeof_collection [get_ports -quiet $start]]} {
    if {[get_attribute [get_ports $start] direction] == "in"} {
        set current [get_ports $start]
        set stop 0
        set rep_list ""
        set i 0
        while {$stop == 0 && $i < $n} {
            set next [filter_collection [all_fanout -from $current -endpoints_only -flat -levels 1] "full_name =~ FCFPRep*/D"]
            if {[sizeof_collection $next] == 1} {
                set name [get_object_name [get_cells -of_objects $next]]
                #puts "$name [get_object_name $next]"
                set rep_list "$rep_list $name"
                set current [get_pins $name/Q]
            } else {
                set stop 1
            }
            incr i
        }
    } else {
        set current [get_ports $start]
        set stop 0
        set rep_list ""
        set i 0
        while {$stop == 0 && $i < $n} {
            set next [filter_collection [all_fanin -to $current -flat -levels 1] "full_name =~ FCFPRep*/Q"]
            if {[sizeof_collection $next] == 1} {
                set name [get_object_name [get_cells -of_objects $next]]
                set rep_list "$name $rep_list"
                set current [get_pins $name/D]
            } else {
                set stop 1
            }
            incr i
        }
    }
}
return $rep_list
}

proc getTiePin {all_pins} {
foreach_in_collection pin [get_pins $all_pins] {
    set net_name [get_object_name [all_connected $pin]]
    set pin_name [get_object_name $pin]
    set ref_pin_name [get_attribute $pin lib_pin_name]
    if {[regexp {Logic} $net_name]} {
        puts "$pin_name $net_name"
    } elseif {[sizeof_collection [all_connected $pin]] == 0} {
        puts "$pin_name NA"
    } else {
        set pin_is_tied($ref_pin_name) $pin_name
    }
}
}


proc resizeFp {util ar} {
set keepout 2
set h_pitch 0.16
set v_pitch 0.152
set macro_area 0
foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set macro_area [expr $macro_area+[get_attribute $macro area]]
}
set cell_area 0
foreach_in_collection cell [get_cells -hierarchical * -filter "design_type == lib_cell" ] {
    set cell_area [expr $cell_area+[get_attribute $cell area]]
}
set core_area [get_attribute [current_design] core_area_area]

set bbox [get_attribute [current_design ] boundary_bbox]
set llx [lindex $bbox 0 0]
set lly [lindex $bbox 0 1]
set urx [lindex $bbox 1 0]
set ury [lindex $bbox 1 1]
puts "$llx $lly $urx $ury"
set w [expr $urx - $llx]
set h [expr $ury - $lly]
set new_ar $ar
set new_util $util
if {$ar == 0} {
    set new_ar [expr w/h]
}
if {$util == 0} {
    set new_util [expr $cell_area / ($core_area - $macro_area)]
}
set new_area [expr $cell_area / $new_util + $macro_area]
set new_h [expr sqrt($new_area)]
set new_w [expr $new_h * $new_ar]
set new_w [expr (round(round($new_w / 5.472)/2)*2 + 1)*5.472 + 1.824]
set new_w [expr round(($new_w / 5.472) )*5.472 + 1.824]
set new_h [expr round(($new_h / 4.8))*4.8]
set p0  "[expr $new_w/2*(-1)] [expr $new_h/2*(-1)]"
set p1 "[expr $new_w/2*(-1)] [expr $new_h/2]"
set p2 "[expr $new_w/2] [expr $new_h/2]"
set p3 "[expr $new_w/2] [expr $new_h/2*(-1)]"
set pin_l_list ""
set pin_r_list ""
set pin_b_list ""
set pin_t_list ""
foreach_in_collection port [get_ports *] {
    set pin_name [get_object_name $port]
    set pin_bbox [get_attribute $port bbox]
    if {[llength [get_attribute $port layer]] == 0} {
        continue
    }
    set pin_layer($pin_name) [get_attribute $port layer_name]
    set pin_llx [lindex $pin_bbox 0 0]
    set pin_lly [lindex $pin_bbox 0 1]
    set pin_urx [lindex $pin_bbox 1 0]
    set pin_ury [lindex $pin_bbox 1 1]
    set pin_width [expr $pin_urx - $pin_llx]
    set pin_height [expr $pin_ury - $pin_lly]
    set pin_width_h($pin_name) $pin_width
    set pin_height_h($pin_name) $pin_height
    if {$pin_width > $pin_height} {
        set pin_dir "h"
        if {$pin_llx < 0} {
            set pin_l($pin_name) $pin_lly
            if {[info exists pin_l_loc($pin_lly)]} {
                set pin_l_loc($pin_lly) "$pin_l_loc($pin_lly) $pin_name"
            } else {
                set pin_l_loc($pin_lly) $pin_name
            }
        } else {
            set pin_r($pin_name) $pin_lly
            if {[info exists pin_r_loc($pin_lly)]} {
                set pin_r_loc($pin_lly) "$pin_r_loc($pin_lly) $pin_name"
            } else {
                set pin_r_loc($pin_lly) $pin_name
            }
        }
    } else {
        set pin_dir "v"
        if {$pin_lly < 0} {
            set pin_b($pin_name) $pin_llx
            if {[info exists pin_b_loc($pin_llx)]} {
                set pin_b_loc($pin_llx) "$pin_b_loc($pin_llx) $pin_name"
            } else {
                set pin_b_loc($pin_llx) "$pin_name"
            }
        } else {
            set pin_t($pin_name) $pin_llx
            if {[info exists pin_t_loc($pin_llx)]} {
                set pin_t_loc($pin_llx) "$pin_t_loc($pin_llx) $pin_name"
            } else {
                set pin_t_loc($pin_llx) $pin_name
            }
        }
    }
}

puts "initialize_floorplan -boundary \{\{$p0\} \{$p1\} \{$p2\} \{$p3\}\} -site_def TS07_DST -pin_snap wire_track"
eval "initialize_floorplan -boundary \{\{$p0\} \{$p1\} \{$p2\} \{$p3\}\} -site_def TS07_DST -pin_snap wire_track"


foreach lly [array names pin_l_loc] {
    set pin_l_list "$pin_l_list $lly"
}

set pin_l_list [lsort -increasing -real $pin_l_list]
if {$new_h - [llength $pin_l_list] * $v_pitch < 0} {
    puts "# left edge overflow"
    return 0
}
for { set i 0 } { $i < [llength $pin_l_list] } {incr i} {
    set loc [lindex $pin_l_list $i]
    foreach pin $pin_l_loc($loc) {
        #puts "$loc $i $pin"
        set llx [expr $new_w/2 * (-1)]
        set lly [expr $new_h/2 * (-1) + ($new_h - [llength $pin_l_list] * $v_pitch) / 2 +  $i*$v_pitch]
        set urx [expr $llx + $pin_width_h($pin)]
        set ury [expr $lly + $pin_height_h($pin)]
        #puts "fastRePlacePin $pin {{$llx $lly} {$urx $ury}} $pin_layer($pin)"
        eval "fastRePlacePin $pin {{$llx $lly} {$urx $ury}} $pin_layer($pin) "
    }
}
foreach lly [array names pin_r_loc] {
    set pin_r_list "$pin_r_list $lly"
}
set pin_r_list [lsort -increasing -real $pin_r_list]
if {$new_h - [llength $pin_r_list] * $v_pitch < 0} {
    puts "# right edge overflow"
    return 0
}

for { set i 0 } { $i < [llength $pin_r_list] } {incr i} {
    set loc [lindex $pin_r_list $i]
    foreach pin $pin_r_loc($loc) {
        set llx [expr $new_w/2 - $pin_width_h($pin)]
        set lly [expr $new_h/2 * (-1) + ($new_h - [llength $pin_r_list] * $v_pitch) / 2 + $i*$v_pitch]
        set urx [expr $llx + $pin_width_h($pin)]
        set ury [expr $lly + $pin_height_h($pin)]
        eval "fastRePlacePin $pin {{$llx $lly} {$urx $ury}} $pin_layer($pin)"
    }
}

foreach llx [array names pin_b_loc] {
    set pin_b_list "$pin_b_list $llx"
}
set pin_b_list [lsort -increasing -real $pin_b_list]
if {$new_w - [llength $pin_b_list] * $h_pitch < 0} {
    puts "# bottom edge overflow"
    return 0
}

for { set i 0 } { $i < [llength $pin_b_list] } {incr i} {
    set loc [lindex $pin_b_list $i]
    foreach pin $pin_b_loc($loc) {
        set llx [expr $new_w/2 * (-1) + ($new_w - [llength $pin_b_list] * $h_pitch) / 2 +  $i*$h_pitch]
        set lly [expr $new_h/2 * (-1)]
        set urx [expr $llx + $pin_width_h($pin)]
        set ury [expr $lly + $pin_height_h($pin)]
        eval "fastRePlacePin $pin {{$llx $lly} {$urx $ury}} $pin_layer($pin)"
    }
}

foreach llx [array names pin_t_loc] {
    set pin_t_list "$pin_t_list $llx"
}
set pin_t_list [lsort -increasing -real $pin_t_list]

if {$new_w - [llength $pin_t_list] * $h_pitch < 0} {
    puts "# top edge overflow"
    return 0
}

for { set i 0 } { $i < [llength $pin_t_list] } {incr i} {
    set loc [lindex $pin_t_list $i]
    foreach pin $pin_t_loc($loc) {
        set llx [expr $new_w/2 * (-1) + ($new_w - [llength $pin_t_list] * $h_pitch) / 2 +  $i*$h_pitch]
        set lly [expr $new_h/2 -  $pin_height_h($pin)]
        set urx [expr $llx + $pin_width_h($pin)]
        set ury [expr $lly + $pin_height_h($pin)]
        eval "fastRePlacePin $pin {{$llx $lly} {$urx $ury}} $pin_layer($pin)"
    }
}


}

proc fastRePlacePin {pin_name bbox layer} {
unplacePort $pin_name
set shape [create_shape -shape_type rect -boundary $bbox -layer $layer]
set terminal [create_terminal -port $pin_name -object $shape -direction all]
set_attribute [get_ports $pin_name] physical_status fixed
}

proc unplacePort {ports} {
foreach_in_collection port [get_ports $ports] {
    if {[regexp VSS [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        #continue
    }
    if {[regexp VDD [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        #continue
    }
    if {[sizeof_collection [get_shapes -quiet -of_objects [get_terminals -quiet -of_objects [get_ports $port]]]] != 0} {
        remove_shapes [get_shapes -of_objects [get_terminals -of_objects [get_ports $port]]]
        set_attribute [get_ports $port] physical_status unplaced
    }
}
}

proc removeSSBShield {} {
remove_nets [get_nets -quiet FCFP_SSB_SHIELD_GROUND_NET_VSS]
foreach_in_collection pin [get_pins */FCFP_SSB_SHIELD_GROUND_NET_VSS] {
    if {[sizeof_collection [all_connected $pin]]} {
        puts "# remove [get_object_name [all_connected $pin]] from [get_oject_name $pin] "
        remove_nets [all_connected $pin]
    }
}
}


proc setMacroFix {} {
set_attribute  [get_cells -hierarchical * -filter "design_type == macro" ] physical_status fixed 
}

proc setStdUnplace {} {
set_attribute  [get_cells -hierarchical * -filter "design_type == lib_cell" ] physical_status unplaced
}

proc addPinBlockage {} {
remove_pin_blockages -all
set macro_list "nv31_el3 g6ddr2x16bchv2p0V"
set width 3
set height 32
foreach macro_ref $macro_list {
    foreach_in_collection macro_inst [get_cells -hierarchical * -filter "ref_name == $macro_ref"] {
        set bbox [get_attribute $macro_inst boundary_bbox]
        set llx [lindex [lindex $bbox 0] 0]
        set lly [lindex [lindex $bbox 0] 1]
        set urx [lindex [lindex $bbox 1] 0]
        set ury [lindex [lindex $bbox 1] 1]
        set llx_new [expr $llx - $width]
        set urx_new [expr $urx - 2]
        set lly_new [expr $lly - $height]
        set ury_new [expr $ury + $height]
        eval "create_pin_blockage   -boundary {{$llx_new $lly_new} {$urx_new $ury_new}}"
    }

}
}

proc tunePinReuse {dir} {

set top [get_attribute [current_design] name]
setCenterCoor
## read ssb pins
if {[file exists $dir/data/PlanSSB/$top.allPorts.txt]} {
    set f [open $dir/data/PlanSSB/$top.allPorts.txt r]
    set pins ""
    while {[gets $f line] >= 0} {
        if {[regexp {#} $line match pin]} {
            #set pins "$pins $pin"
            continue
            #puts $pin
        } else {
            set pins "$pins [lindex $line 0]"
        }
    }
    write_def -objects [get_ports $pins] -fixed_vias_only -compress gzip -units 2000 -version 5.7 $dir/ssb_pin/$top.ssb_pin.def.gz 
    unplacePort [get_ports *]
    ## read new shape def
    #read_def -no_incremental /proj/navi31n6-pdfcfp4-nobackup/simchen/NLB/main/pd/tiles/CHIP_MCD_MCD_1228_ssb_TileBuilder_Dec27_2220_54394_GUI/pkg_def/$top.def.gz
} else { 
    ## read new shape def
    #read_def -no_incremental /proj/navi31n6-pdfcfp4-nobackup/simchen/NLB/main/pd/tiles/CHIP_MCD_MCD_1228_ssb_TileBuilder_Dec27_2220_54394_GUI/pkg_def/$top.def.gz
    unplacePort [get_ports *]
}
if {[file exists $dir/preassign_pin/$top.def.gz]} {
    read_def -include {ports}  $dir/preassign_pin/$top.def.gz
}
if {[file exists $dir/ssb_pin/$top.ssb_pin.def.gz]} {
    read_def $dir/ssb_pin/$top.ssb_pin.def.gz
}

#setCenterCoor
if {[file exists /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$top.tcl]} {
    #source /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$top.tcl 
}
if {[file exists /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$top.forPin.tcl]} {
    #source /home/simchen/navi31/fcfp/tile_macros/NLD/fp_00/$top.forPin.tcl
}

#source /home/simchen/navi31/fcfp/N6_basic.tsmc.cpode.trackplan.tcl
#addPinBlockage
}

proc placeSpecificPins {ports} {
set_individual_pin_constraints -ports * -length 0.4 -pin_spacing 2 -allowed_layers {M5 M6 M7 M8 M9 M10}
set_block_pin_constraints -allowed_layers {M5 M6 M7 M8 M9 M10} -self
if {[sizeof_collection $ports] > 0} {
    place_pins -ports [get_ports $ports]
}
}

proc placePinByOrder {pin_list dir x y} {
set n 3 
set depth 0.4
set f [open $pin_list r]
set o [open placePinByOrder.tcl w]
set ports ""
set llx $x
set lly $y
set i 0
while {[gets $f line] >= 0} {
    set port [lindex $line 0]
    set layer [lindex $line 3]
    if {[sizeof_collection [get_port -quiet $port]] == 0} {
        puts "$port does not exist"
        continue
    }
    if {$dir == "h"} {
        set pitch 0.076
        set width 0.038
        set urx [expr $llx + $width]
        set ury [expr $lly + $depth]
        if {$i == 0} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M5"}
        if {$i == 1} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M7"}
        if {$i == 2} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M9"}
        if {$i == 2} {
            set llx [expr $llx + $n*$pitch]
        }
        
    } else {
        set pitch 0.08
        set width 0.04
        set urx [expr $llx + $depth]
        set ury [expr $lly + $width]
        if {$i == 0} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M4"}
        if {$i == 1} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M6"}
        if {$i == 2} {puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} M8"}
        if {$i == 2} {
            set lly [expr $lly + $n*$pitch]
        }

    }
    incr i
    if {$i == 3} {
        set i 0
    }
    unplacePort $port
}
close $o
close $f

}

proc textToList {text} {
global t2l
set t2l ""
set f [open $text r]
while {[gets $f line] >= 0} {
    set t2l "$t2l $line"
}
close $f
}

proc alignFeedPorts {ports} {
set is_h(M3) 0
set is_h(M4) 1
set is_h(M5) 0
set is_h(M6) 1
set is_h(M7) 0
set is_h(M8) 1
set is_h(M9) 0
set is_h(M10) 1
set is_h(M11) 0
set o [open alignPorts.tcl w]
foreach_in_collection port [get_ports $ports] {
    if {[sizeof_collection [get_shapes -of_objects [get_ports $port]]] > 1} {
        continue
    }
    set layer [get_attribute [get_ports $port] layer_name]
    set llx [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]
    set urx [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 0]
    set ury [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 1]
    
    set port_name [get_object_name $port]
    set aligned_port [regsub {__AMD_\S+} $port_name {}]
    set aligned_port [regsub {FE_FEEDX_MFT_[0-9]__\S+__\S+__} $aligned_port {}]
    set aligned_port [remove_from_collection [get_ports *${aligned_port}*] [get_ports $port]]
    puts "[get_object_name  $aligned_port]"
    if {[sizeof_collection $aligned_port]!=1} { continue}
    set llx_a [lindex [lindex [get_attribute [get_ports $aligned_port] bbox] 0 ] 0]
    set lly_a [lindex [lindex [get_attribute [get_ports $aligned_port] bbox] 0 ] 1]
    set urx_a [lindex [lindex [get_attribute [get_ports $aligned_port] bbox] 1 ] 0]
    set ury_a [lindex [lindex [get_attribute [get_ports $aligned_port] bbox] 1 ] 1]

    set port_name [get_object_name $port]

    set layer_a [get_attribute [get_ports $aligned_port] layer_name]
    if {$is_h($layer_a) == 1} {
        puts $o "fastRePlacePin $port_name {{$llx $lly_a} {$urx $ury_a}} $layer_a"
    } else {
        puts $o "fastRePlacePin $port_name {{$llx_a $lly} {$urx_a $ury}} $layer_a"
    }
    set port [get_object_name $port]
    if {$llx == $urx || $lly == $ury} {
         continue
    }
    if {[regexp {\S} $layer] == 0} {
        puts "# WARNING $port has no layer"
        continue
    }
}
close $o
}

proc addNdm {ndm} {
set_ref_libs -add [file normalize $ndm]
set_ref_libs -rebind -lib [file normalize $ndm]
}

proc createUsrDecap {llx lly urx ury} {
set pitch_x 66
set pitch_y 133
set f [open createUsrDecap.tcl w]
set row [expr round(($ury - $lly) / $pitch_y)]
set col [expr round(($urx - $llx) / $pitch_x)]
set x $llx 
set y $lly 
set n 0
puts "$llx $lly $urx $ury $row $col"
for { set i 0 } { $i < $col } {incr i} {
    for { set j 0 } { $j < $row } {incr j} {
        while {[sizeof_collection [get_cells usr_decap_$n]]>0} {
            incr n
        }
        create_cell usr_decap_$n [get_lib_cells */Usr1Phydecapv_n7]
        puts $f "set_cell_location -coordinates {$x $y} \[get_cells usr_decap_$n\]"
        set y [expr $y + $pitch_y]
        incr n
    }
    set y $lly
    set x [expr $x + $pitch_x]
}
close $f
source createUsrDecap.tcl
}

proc showDFTOconn {} {
foreach_in_collection pin [get_pins {dfx_dftcnr0_t/dftio* dfx_dftcnr0_t/DFTIO*}] {
    puts "[get_object_name [all_connected [get_nets -of [get_pin]]]]"
    foreach_in_collection load [all_fanout -from $pin -endpoints_only -only_cells] {
        puts "[get_object_name $load] [get_attribute $load ref_name]"
    }
}
}

# prepare hfn spec: perl /home/simchen/navi32/fcfp/extractPath.pl > hfn.spec
# prepare hfn net list: hfn.list
# generate hfn.split.list: genDrvLoadList hfn.list > hfn.split.list
# generate hfn.mfg: perl /home/simchen/navi32/fcfp/genHfnMFT.pl hfn.spec hfn.split.list > hfn.mft 
proc genDrvLoadList {netlist} {
set f [open $netlist r]
while {[gets $f line] >= 0} {
    if {[sizeof_collection [get_nets $line]] == 0} {continue}
    set drv [filter_collection [all_connected [get_nets $line]] "direction == out"]
    set lod [filter_collection [all_connected [get_nets $line]] "direction == in"]
    foreach_in_collection pin $lod {
       puts "[get_object_name $drv] [get_object_name $pin]" 
    }
}
}

proc convertHierToFlatMFT {mft} {
set f [open $mft r]
set o [open convertHierToFlatMFT.txt w]
while {[gets $f line] >= 0} {
    if {[regexp {route.*-from\s+(\S+)\s+-to\s+(\S+)\s+-through\s+(.*)} $line match s e t]} {
        if {[regexp {io_chip_t} $s]} {
            set flat_pin_s [lindex [get_object_name [get_pins [all_connected -leaf [get_nets -of [get_pins $s]]] -filter "full_name=~io_chip_t*"]] 0]
            if {[llength $flat_pin_s] == 0} {
                puts $o "# no pin for $s"
                continue
            }
            puts $o "# [get_object_name $s]"
        } else {
            set flat_pin_s $s
        }
        if {[regexp {io_chip_t} $e]} {
            set flat_pin_e [lindex [get_object_name [get_pins [all_connected -leaf [get_nets -of [get_pins $e]]] -filter "full_name=~io_chip_t*"]] 0]
            if {[llength $flat_pin_s] == 0} {
                puts $o "# no pin for $e"
                continue
            }
            puts $o "# [get_object_name $e]"
        } else {
            set flat_pin_e $e
        }

    puts $o "route -bidir -from $flat_pin_s -to $flat_pin_e -through $t"
    }
}
close $f
close $o
}

proc placeDFTIOLogic {} {
set o [open placeDFTIOLogic.tcl w]
set i 0
foreach_in_collection inst [get_cells io_chip_t/io_chip_dftio/uPAD_DFTIO*] {
    set io_$i 0 
    set bbox [get_attribute $inst bbox]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set urx [lindex [lindex $bbox 1] 0]
    set ury [lindex [lindex $bbox 1] 1]

    set llx [expr $llx - 20]
    set lly [expr $lly - 20]
    set urx [expr $urx + 20]
    set ury [expr $ury + 20]
    set insts_in [filter_collection [all_fanin  -to [get_pins [get_object_name $inst]/*] -only_cells -flat -trace_arcs all] "full_name=~io_chip_t*"]
    set insts_out [filter_collection [all_fanout -from [get_pins [get_object_name $inst]/*] -only_cells -flat -trace_arcs all] "full_name=~io_chip_t*"]
    puts $o "create_bound -name io_$i -type hard -boundary {{$llx $lly} {$urx $ury}} \[get_cells {[get_object_name $insts_in] [get_object_name $insts_out]}\]"
    incr i
}
close $o
}

proc genAbutPin {pins} {
set o [open genAbutPin.tcl w]
foreach_in_collection pin [get_pins $pins] {
    set abut_pin [remove_from_collection [all_connected [get_nets -of [get_pins $pin]]] [get_pins $pin]]
    set bbox [get_attribute $pin bbox]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set urx [lindex [lindex $bbox 1] 0]
    set ury [lindex [lindex $bbox 1] 1]
    set layer [get_attribute $pin layer_name]    
    set pin_name [get_object_name $abut_pin]
    set pin_name [regsub ".*\/" $pin_name ""]
    puts $o "fastRePlacePin $pin_name \{$bbox\} $layer"
}

close $o
}


proc remove_feed_s {} {
set f [open remove_feed.list r]
while {[gets $f line] >= 0} {
    set feed_removed [lindex $line 0]
    set drv [lindex $line 1]
    set lod [get_object_name [remove_from_collection [all_connected [get_nets -of [get_pins $feed_removed]]] [get_pins $feed_removed] ]]
    set net [get_object_name [get_nets -of [get_pins $feed_removed]]]
    puts "disconnect_net -net $net \[get_pins $lod\]"
    puts "remove_net $net"
    set net [get_object_name [get_nets -of [get_pins $drv]]]
    puts "connect_net -net $net \[get_pins $lod\]"
}
}

proc remove_feed_d {} {
set f [open io_cit_refclkio_gcd_chip_t.list r]
while {[gets $f line] >= 0} {
    set pin0 [lindex $line 0]
    set pin1 [lindex $line 1]
    set drv0 [get_object_name [remove_from_collection [all_connected [get_nets -of [get_pins $pin0]]] [get_pins $pin0] ]]
    set net0 [get_object_name [get_nets -of [get_pins $pin0]]]
    puts "disconnect_net -net $net \[get_pins $pin0\]"
    puts "remove_net $net0"
    set lod1 [get_object_name [remove_from_collection [all_connected [get_nets -of [get_pins $pin1]]] [get_pins $pin1] ]]
    set net1 [get_object_name [get_nets -of [get_pins $pin1]]]
    puts "disconnect_net -net $net \[get_pins $pin1\]"
    puts "remove_net $net1"
    puts "connect_pin  -non_incremental -driver  $drv0 \[get_pins $lod1\]"
}
}

proc checkFcfpRepDist {} {
#FCFPRepFFcgcg_Cpl_GFXCLK536567_MBUR_FCFPRepFFcgcg_Cpl_GFXCLK539159_MBUR_FCFPRepFFcgcg_Cpl_GFXCLK537341_MBUR_FCFPRepFFcgcg_Cpl_GFXCLK537134
#  FCFPRep*GFX*/Q*
foreach_in_collection pin [get_pins  TCDX*/*/Q*] {
    #  FCFP*/D*
    set end [filter_collection [all_fanout -from $pin -endpoints_only -flat] "full_name =~ TCDX*/*/D*"]
    if {[sizeof_collection $end] == 0} {
        continue
    }
    set bbox [get_attribute [get_pins $pin] bbox]
    set llx0 [lindex [lindex $bbox 0] 0]
    set lly0 [lindex [lindex $bbox 0] 1]
    set bbox [get_attribute [get_pins $end] bbox]
    set llx1 [lindex [lindex $bbox 0] 0]
    set lly1 [lindex [lindex $bbox 0] 1]
    set path_dis [expr round(abs($llx0 - $llx1) + abs($lly0 -$lly1))]
    set nets [get_flat_nets -of_objects [filter_collection [all_fanout -from $pin -flat] "direction == in"]]
    #puts "[get_object_name $pin] [get_object_name $nets]"
    set M0_length 0
    set M1_length 0
    set M2_length 0
    set M3_length 0
    set M4_length 0
    set M5_length 0
    set M6_length 0
    set M7_length 0
    set M8_length 0
    set M9_length 0
    set M10_length 0
    set M11_length 0
    set M12_length 0
    set M13_length 0
    foreach_in_collection net $nets {
        #puts "# net: [get_object_name $net]"
        set length [format %.2f [get_attri [get_flat_nets $net] dr_length]]
        set layer_length [get_attri [get_flat_nets $net] route_length ]
        set net_name [get_object_name [get_flat_nets $net]]

        foreach layer $layer_length {
           regexp {(M\d+)\s(\S+)} $layer match ly dist
           set ${ly}_length [expr \$${ly}_length + $dist]
        }

    }
    puts "[get_object_name $pin] [get_object_name $end] $llx0 $lly0 $llx1 $lly1 $path_dis $length $M0_length $M1_length $M2_length $M3_length $M4_length $M5_length $M6_length $M7_length $M8_length $M9_length $M10_length $M11_length $M12_length"
    
    
}
}

proc checkRouteDensity {llx lly urx ury layer} {
# resolution means how many section divided for the region
set resolution 100
set pitch_h(M6) 0.08
set pitch_h(M8) 0.08
set pitch_h(M10) 0.08
set pitch_h(M5) 0.076
set pitch_h(M7) 0.076
set pitch_h(M9) 0.076
set pitch_h(M11) 0.076

puts "$llx $lly $urx $ury $layer"
if {$layer == "M4" || $layer == "M6" || $layer == "M8" || $layer == "M10" || $layer == "M12"} {
    set layers "M6 M8 M10"
    set delta [expr ($urx - $llx) / $resolution]
    for { set i 0 } { $i < $resolution } {incr i} {
        set x [expr $llx + $i*$delta]
        set xd [expr $x + 0.04]
        foreach layer $layers {
            set wires_h($layer) [sizeof_collection [get_shapes -intersect "{$x $lly} {$xd $ury}" -filter "layer_name == $layer && (shape_use == detail_route || shape_use == user_route)"]]
            #puts "$layer $wires_h($layer) {$x $lly} {$xd $ury} "
            set density_h($layer) [expr $wires_h($layer)/(($ury - $lly) / $pitch_h($layer))]
        }
        puts "$x  $density_h(M6) $density_h(M8) $density_h(M10)"
    }

}
if {$layer == "M5" || $layer == "M7" || $layer == "M9" || $layer == "M11" || $layer == "M13"} {
    set delta [expr ($urx - $llx) / $resolution]
    for { set i 0 } { $i < $resolution } {incr i} {
        set y [expr $lly + $i*$delta]
        set yd [expr $y + 0.04]
        set wires_h($layer) [sizeof_collection [get_shapes -intersect "{$y $llx} {$urx $yd}" -filter "layer_name == $layer && shape_use == detail_route"]]
        set density_h($layer) [expr $wires_h($layer)/(($ury - $lly) / $pitch_h($layer))]
    }
    puts "$x $wires_h($layer) $density_h(M5) $density_h(M7) $density_h(M9) $density_h(M11)"

}

}
