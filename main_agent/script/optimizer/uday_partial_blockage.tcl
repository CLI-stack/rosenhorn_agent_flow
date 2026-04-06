proc create_partial_blockage {args} {

    set options(-location)          {}
    set options(-bin_width)         {}
    set options(-bin_height)        {}
    set options(-density)           {}
    parse_proc_arguments -args $args options

    if {[llength $options(-location)] >= 1 } {
        set llx [lindex $options(-location) 0 0 ]
        set lly [lindex $options(-location) 0 1 ]
        set urx [lindex $options(-location) 1 0 ]
        set ury [lindex $options(-location) 1 1 ]
       } else {
        puts "provide dimesions of the blockage."
       }

    if {[llength $options(-bin_width)] >= 1} {
        set bin_x [lindex $options(-bin_width) 0 0 ]
       } else {
        set bin_x 5
       }

    if {[llength $options(-bin_height)] >= 1} {
        set bin_y [lindex $options(-bin_height) 0 0 ]
       }  else {
        set bin_y 5
       }

    if {[llength $options(-density)] >= 1} {
        set den [lindex $options(-density) 0 0 ]
       } else {
        set den 50
       } 

set a1 $llx
set b1 $lly
set a2 [expr $a1 + $bin_x]
set b2 [expr $b1 + $bin_y] 

create_placement_blockage -type partial  -blocked_percentage $den -boundary "{{$a1 $b1} {$a2 $b2}}"                         

set j $llx
set i $lly

while {$i <= $ury} {
   while {$j < $urx} {
        set a1 [expr $a1 + $bin_x]
        set a2 [expr $a1 + $bin_x]
        set j $a2
        if {$a2 <= $urx} {
             create_placement_blockage -type partial  -blocked_percentage $den -boundary "{{$a1 $b1} {$a2 $b2}}"                       
         }        

   } 

set b1 [expr $b1 + $bin_y]
set b2 [expr $b1 + $bin_y]
set i $b2
set j $llx
set a1 $llx
set a2 [expr $a1 + $bin_x]
       if {$b2 <= $ury} {
           create_placement_blockage -type partial  -blocked_percentage $den -boundary "{{$a1 $b1} {$a2 $b2}}"                       
         }
  }
} 

puts "\n COMMAND FORMAT::    create_partial_blockage -location {{lower_x lower_y } {upper_x upper_y}} 
                                             -bin_width <float/int value> -bin_height <float/int value> -density <value>"


define_proc_attributes create_partial_blockage -info "creating Partial Blockage over the given location with bins" -define_args { \
        {-location          "Define the dimensions of the Blockage." "" string required} \
        {-bin_width         "Define the width of the bin." "" float required} \
        {-bin_height        "Define the height of the bin." "" float required} \
        {-density           "Define the density of each bin." "" int required} \
}        
