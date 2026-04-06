if {[file exists data/floorplan/floorplan.tcl]} {
} else {
    write_floorplan -output data/floorplan -include "macros blockages cells" -force
}
puts "Warning: need to enable user floorplan "
