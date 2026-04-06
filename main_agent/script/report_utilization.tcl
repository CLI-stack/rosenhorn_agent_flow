#!/bin/tcsh
# TCL script to report design utilization in Fusion Compiler / ICC2
# Usage: source report_utilization.tcl

# Get design name
set design_name [get_object_name [current_design]]
set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

# Create reports directory if it doesn't exist
if {![file exists reports]} {
    file mkdir reports
}

set report_file "reports/utilization_${design_name}.rpt"

# Open report file
set fh [open $report_file w]

puts $fh "################################################################################"
puts $fh "# Utilization Report"
puts $fh "# Design: $design_name"
puts $fh "# Date: $timestamp"
puts $fh "################################################################################"
puts $fh ""

close $fh

# Report basic utilization
puts "Generating utilization report..."
redirect -append $report_file {
    puts "=============================================================================="
    puts "                         BASIC UTILIZATION"
    puts "=============================================================================="
    report_utilization
    puts ""
}

# Report utilization with objects breakdown
redirect -append $report_file {
    puts "=============================================================================="
    puts "                    UTILIZATION BY OBJECTS"
    puts "=============================================================================="
    report_utilization -objects
    puts ""
}

# Report design physical information
redirect -append $report_file {
    puts "=============================================================================="
    puts "                    DESIGN PHYSICAL INFORMATION"
    puts "=============================================================================="
    report_design -physical
    puts ""
}

# Report placement density (if placement exists)
if {[sizeof_collection [get_cells -hier -filter "is_placed==true"]] > 0} {
    redirect -append $report_file {
        puts "=============================================================================="
        puts "                    PLACEMENT DENSITY"
        puts "=============================================================================="
        report_placement -density
        puts ""
    }
}

# Report voltage area utilization (if voltage areas exist)
if {[sizeof_collection [get_voltage_areas *]] > 0} {
    redirect -append $report_file {
        puts "=============================================================================="
        puts "                UTILIZATION BY VOLTAGE AREA"
        puts "=============================================================================="
        report_utilization -voltage_area
        puts ""
    }
}

# Report QoR summary (includes utilization metrics)
redirect -append $report_file {
    puts "=============================================================================="
    puts "                         QOR SUMMARY"
    puts "=============================================================================="
    report_qor -summary
    puts ""
}

puts "Utilization report generated: $report_file"
puts "Report includes:"
puts "  - Basic utilization"
puts "  - Object breakdown"
puts "  - Physical design info"
if {[sizeof_collection [get_cells -hier -filter "is_placed==true"]] > 0} {
    puts "  - Placement density"
}
if {[sizeof_collection [get_voltage_areas *]] > 0} {
    puts "  - Voltage area utilization"
}
puts "  - QoR summary"
