#created on 
#@author: Hongyu Ma, Hongyu.Ma@amd.com

#FUNC: magnet place fanout tiledfx logic to MESH_ROOT_BUFF to shorten median latency
#MAIN_CLOCK_NAME need to put in params
#currently CTS_MAIN_CLOCK_TARGET_LATENCY is not work

########
set magnet_all_mark 1
if {[info exists P(MAIN_CLOCK_NAME)]} {
    set MESH_PATTERN $P(MAIN_CLOCK_NAME)
} else {
    if {$magnet_all_mark == 0} {
        regexp  {:.*\.design} [get_object_name [current_design]] tile_name
        regsub ":" $tile_name "" tmp_var1
        set tile_group_name [lindex [split $tmp_var1 "_"] 0]
        switch $tile_group_name {
            umc {
                set MESH_PATTERN {UCLK}
            }
            df {
                set MESH_PATTERN {FCLK}
            }
            vcn {
                set MESH_PATTERN {VCN_DCLK}
            }
            dcn {
                set MESH_PATTERN {DISPCLK}
            }
            pcie {
                set MESH_PATTERN {PCIE16_LANE0_RX_CLK}
            }
            gfx {
                set MESH_PATTERN {GFXCLK}
            }
            cf {
                set MESH_PATTERN {SMNCLK}
            }
            nbio {
                set MESH_PATTERN {NBIO_LCLK}
            }
            default {
                set MESH_PATTERN {SOCCLK}
            }
        }
    } else {
        set MESH_PATTERN {*}
    }
} 

set MESH_PATTERN *${MESH_PATTERN}*
set root_buffer_list [get_cells -filter "full_name =~ ${MESH_PATTERN}MESH_CTS_ROOT* && full_name !~ *DIODE*"]
set output_file "rpts/FxCts/PreClockOpt.rpt"
set file_out [open $output_file w]
if {$root_buffer_list == ""} {
    puts "Warning: Rootbuffer not exist, check main clock name or scripts "
} else {
    foreach_in_collection root_buffer $root_buffer_list {
        set input_pin [get_pins -quiet -of_objects $root_buffer -filter "port_type == signal && direction == in"]
        set port [get_ports -quiet -of_objects [get_nets -of_objects $input_pin]]
        puts $file_out "bound tile_dfx_logic of port: [get_object_name $port]"
        set output_pin [get_pins -of_objects $root_buffer -filter "port_type == signal && direction == out"]
        set fanout_cells [get_cells [all_fanout -flat -only_cells -from $output_pin] -filter "is_integrated_clock_gating_cell == true ||  full_name=~*d0nt_clk_gate_cell* || full_name=~ *d0nt_mux* || full_name=~ *d0nt_buf* || full_name=~ *MPCTS_SPLIT* || full_name=~ *ShortChain* && full_name !~ *vdci3*"]
        if {[sizeof_collection $fanout_cells]} {
            puts "Info: magnet place fanout tile_dfx_cells([sizeof_collection $fanout_cells]) for root_buffer: [get_object_name $root_buffer]"
            magnet_placement [get_cells $root_buffer]  -move_fixed -mark_fixed -cells $fanout_cells
            foreach cell $fanout_cells  {
                puts $file_out "[get_object_name $cell]\n"
            }
        } else {
            puts "Warning: no fanout cells from root_buffer"
        }
    }
    close $file_out
}


#set qor_latency_rpt "rpts/FxCts/FxCts_qor_latency.rpt.gz"
#set input_file "FxCts_qor_latency.rpt"
#if {[file exists $qor_latency_rpt] && [file size $qor_latency_rpt] > 0} {
#    catch {exec gunzip -c $qor_latency_rpt > $input_file}
#} else {
#    puts "There is no FxCts_qor_latency.rpt maybe is the first time to run cts"
#}
#set line_contents ""
#if {[file exists $input_file] && [file size $input_file] > 0} {
#    set file_in [open $input_file r]
#    while {[gets $file_in line] >= 0} {
#        lappend line_contents $line     
#    }
#}


#set MESH_PATTERN $P(MAIN_CLOCK_NAME)
#if {$line_contents != ""} {
#    set pattern "default_*${MESH_PATTERN}|^${MESH_PATTERN}"
#    set main_clock_candidate ""
#    foreach line $line_contents {
#        if {[regexp  $pattern [lindex $line 0]]} {
#            puts $line
#            if {[lindex $line 8] != "" && [lindex $line 8] != "--"} {
#                lappend main_clock_candidate $line
#            }
#        }
#    }
#    if {$main_clock_candidate != ""} {
#        set sink_num 0
#        foreach ele $main_clock_candidate {
#            if {[lindex $ele 2] != "" && [lindex $ele 2] > $sink_num} {
#                set sink_num [lindex $ele 2]
#                set main_clock [lindex $ele 0]
#                set median_latency [lindex $ele 8]
#            }
#        }
#        puts "main_clock: ${main_clock} median_latency: ${median_latency}"
#        if {[info exists P(CTS_MAIN_CLOCK_TARGET_LATENCY)]} {
#            if {$median_latency > $P(CTS_MAIN_CLOCK_TARGET_LATENCY)} {
#                puts "Warning: median latency > Target value"
#                set magnet_trriger 1
#            } else {
#                set magnet_trriger 0
#            }
#        } else {
#            puts "There is no Target latency setting"
#        }
#    }
#}
