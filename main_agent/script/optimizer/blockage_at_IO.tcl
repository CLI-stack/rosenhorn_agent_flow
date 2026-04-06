
proc blockage_at_core_edges {blkg_typ blkg_width block_per} {
set boundary [get_attribute [current_design] boundary]
set edge_dir 0
#set blkg_width 5
set bin_size $blkg_width
if {$blkg_typ=="partial"} {
set partial 1
} else {
set partial 0
}
#puts $partial
for {set i 0} {$i<[llength $boundary]} {incr i} {

set prev_edge_dir $edge_dir

set a [lindex $boundary $i]
if {$i==[expr [llength $boundary]-1]} {
set b [lindex $boundary 0]
} else {
set b [lindex $boundary [expr $i+1]]
}

set x1 [lindex $a 0]
set x2 [lindex $b 0]

set y1 [lindex $a 1]
set y2 [lindex $b 1]

if {$y1==$y2} {
if {$x2>$x1} {
##blkg down
set edge_dir "right"
set t [expr $y2-$blkg_width]
if {$i>>0 && $prev_edge_dir=="down"} {
set x1 [expr $x1-$blkg_width]
}
if {$i==[expr [llength $boundary]-1] && $starting_edge_dir=="up"} {
set x2 [expr $x2+$blkg_width]
}

set bn "{{$x1 $y1} {$x2 $t}}"
if {[expr $partial==1]} {
set llx [lindex $bn 0 0 0]
set lly [lindex $bn 0 0 1]
set uux [lindex $bn 0 1 0]
set uuy [lindex $bn 0 1 1]

if {$llx>$uux} {
set lx $uux;set ux $llx
} else {
set lx $llx;set ux $uux
}

if {$lly>$uuy} {
set ly $uuy;set uy $lly
} else {
set ly $lly;set uy $uuy
}



for {set sy $ly} {$sy<$uy} {set sy [expr $sy+$bin_size]} {
set ty [expr $sy+$bin_size]
if {$ty>$uy} {
set ty $uy
}
for {set sx $lx} {$sx<$ux} {set sx [expr $sx+$bin_size]} {
set tx [expr $sx+$bin_size]
if {$tx>$ux} {
set tx $ux
}
#puts "partial"
set bin "{{$sx $sy} {$tx $ty}}"

if {[catch {create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per} result]} {
} else {
create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per
}
#puts $bin
}
}



#
} else {


create_placement_blockage -type $blkg_typ -boundary $bn
}
} else {
##up
set edge_dir "left"
set t [expr $y2+$blkg_width]
if {$i>>0 && $prev_edge_dir=="up"} {
set x1 [expr $x1+$blkg_width]
}
if {$i==[expr [llength $boundary]-1] && $starting_edge_dir=="down"} {
set x2 [expr $x2-$blkg_width]
}

set bn "{{$x2 $t} {$x1 $y1}}"
#create_placement_blockage -type $blkg_typ -boundary $bn

if {$partial==1} {
set llx [lindex $bn 0 0 0]
set lly [lindex $bn 0 0 1]
set uux [lindex $bn 0 1 0]
set uuy [lindex $bn 0 1 1]

if {$llx>$uux} {
set lx $uux;set ux $llx
} else {
set lx $llx;set ux $uux
}

if {$lly>$uuy} {
set ly $uuy;set uy $lly
} else {
set ly $lly;set uy $uuy
}



for {set sy $ly} {$sy<$uy} {set sy [expr $sy+$bin_size]} {
set ty [expr $sy+$bin_size]
if {$ty>$uy} {
set ty $uy
}
for {set sx $lx} {$sx<$ux} {set sx [expr $sx+$bin_size]} {
set tx [expr $sx+$bin_size]
if {$tx>$ux} {
set tx $ux
}

set bin "{{$sx $sy} {$tx $ty}}"
if {[catch {create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per} result]} {
} else {
create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per
}
}
}



#
} else {


create_placement_blockage -type $blkg_typ -boundary $bn
}


}
}

if {$x1==$x2} {
if {$y2>$y1} {
##right
set edge_dir "up"
set t [expr $x1+$blkg_width]
if {$i>>0 && $prev_edge_dir=="right"} {
set y1 [expr $y1-$blkg_width]
}
if {$i==[expr [llength $boundary]-1] && $starting_edge_dir=="left"} {
set y2 [expr $y2+$blkg_width]
}

set bn "{{$x2 $y2} {$t $y1}}"
#create_placement_blockage -type $blkg_typ -boundary $bn

if {$partial==1} {

set llx [lindex $bn 0 0 0]
set lly [lindex $bn 0 0 1]
set uux [lindex $bn 0 1 0]
set uuy [lindex $bn 0 1 1]

if {$llx>$uux} {
set lx $uux;set ux $llx
} else {
set lx $llx;set ux $uux
}

if {$lly>$uuy} {
set ly $uuy;set uy $lly
} else {
set ly $lly;set uy $uuy
}


for {set sy $ly} {$sy<$uy} {set sy [expr $sy+$bin_size]} {
set ty [expr $sy+$bin_size]
if {$ty>$uy} {
set ty $uy
}
for {set sx $lx} {$sx<$ux} {set sx [expr $sx+$bin_size]} {
set tx [expr $sx+$bin_size]
if {$tx>$ux} {
set tx $ux
}

set bin "{{$sx $sy} {$tx $ty}}"
if {[catch {create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per} result]} {
} else {
create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per
}
}
}



#
} else {


create_placement_blockage -type $blkg_typ -boundary $bn
}


} else {
#left
set edge_dir "down"
set t [expr $x1-$blkg_width]
if {$i>>0 && $prev_edge_dir=="left"} {
set y1 [expr $y1+$blkg_width]
}
if {$i==[expr [llength $boundary]-1] && $starting_edge_dir=="right"} {
set y2 [expr $y2-$blkg_width]
}

set bn "{{$t $y1} {$x2 $y2}}"
#create_placement_blockage -type $blkg_typ -boundary $bn
if {$partial==1} {

set llx [lindex $bn 0 0 0]
set lly [lindex $bn 0 0 1]
set uux [lindex $bn 0 1 0]
set uuy [lindex $bn 0 1 1]

if {$llx>$uux} {
set lx $uux;set ux $llx
} else {
set lx $llx;set ux $uux
}

if {$lly>$uuy} {
set ly $uuy;set uy $lly
} else {
set ly $lly;set uy $uuy
}



for {set sy $ly} {$sy<$uy} {set sy [expr $sy+$bin_size]} {
set ty [expr $sy+$bin_size]
if {$ty>$uy} {
set ty $uy
}
for {set sx $lx} {$sx<$ux} {set sx [expr $sx+$bin_size]} {
set tx [expr $sx+$bin_size]
if {$tx>$ux} {
set tx $ux
}


set bin "{{$sx $sy} {$tx $ty}}"
if {![catch {create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per} result]} {

create_placement_blockage -type partial -boundary $bin  -blocked_percentage $block_per
}
}
}



#
} else {


create_placement_blockage -type $blkg_typ -boundary $bn
}



}
}
if {$i==0} {
set starting_edge_dir $edge_dir
}

}

}


puts ""
puts "Usage:"
puts ""
puts "        blockage_at_core_edges <blockage_type(partial/soft/hard)> <blockage_width> <blocked_percentage_for_partial_blkg>"

puts ""
puts "Example:  blockage_at_core_edges partial 5 60"
puts ""
puts "Example: blockage_at_core_edges soft 5 60"
