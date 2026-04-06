puts {Sourcing $Id: //depot/tools/aticad/1.0/flow/TileBuilder/supra/templates/fc_shell/fx_fp_place_macros.tcl#22 $ $Date: 2024/01/11 $ }
#########################################################################
# NAME: add_halo_to_pushdown_clkbuf
# DESCRIPTION: Adds given halo to the push down clock buffers given in
# buf_list. Need to specify the exact cell list in buf_list.
# PARAMS: DFP_PUSHDOWN_CLKBUF_ADDHALO, DFP_PUSHDOWN_CLKBUF_LIST, 
#         DFP_PUSHDOWN_CLKBUF_HALO       
# INPUT: halo, buf_list
# OUTPUT: Halo around given pushdown clock buffers mentioned in buf_list.
##########################################################################

#proc adds the halo to the push down clock buffers.
proc add_halo_to_pushdown_clkbuf {halo buf_list} {  
  set coll {}
  # Getting the clock buffer instance names in a list 
  foreach ckbuf $buf_list {
    set coll [add_to_collection -unique $coll [get_cells -physical_contex -quiet -hier -filter "ref_name=~ $ckbuf"]]
  }
  
  if {[sizeof $coll] > 0} {
    if {[llength $halo]==1} {
        create_keepout_margin -outer [list $halo $halo $halo $halo] $coll -type hard
        puts "Adding $halo micron halo for following pushdown clock buffers: [get_attribute $coll full_name]"
    } elseif {[llength $halo]==2} {
        create_keepout_margin -outer [list [lindex $halo 0] [lindex $halo 1] [lindex $halo 0] [lindex $halo 1]] $coll -type hard       
        puts "Adding $halo micron halo for following pushdown clock buffers: [get_attribute $coll full_name]"
    } elseif {[llength $halo]==4} {
        create_keepout_margin -outer [list [lindex $halo 0] [lindex $halo 1] [lindex $halo 2] [lindex $halo 3]] $coll -type hard        
        puts "Adding $halo micron halo for following pushdown clock buffers: [get_attribute $coll full_name]"
    } else {
        puts "Warning: DFP_PUSHDOWN_CLKBUF_HALO is not defined correctly. The supported syntax as below:\n\ta). DFP_PUSHDOWN_CLKBUF_HALO = d\n\tb). DFP_PUSHDOWN_CLKBUF_HALO = lr tb\n\tc). DFP_PUSHDOWN_CLKBUF_HALO = l b r t" 
    }  
  }
}

# adds snapped halo instead
proc add_snapped_halo_to_pushdown_clkbuf {halo buf_list} {  
  set coll {}
  # Getting the clock buffer instance names in a list 
  foreach ckbuf $buf_list {
    set coll [add_to_collection -unique $coll [get_cells -physical_contex -quiet -hier -filter "ref_name=~ $ckbuf"]]
  } 
  if {[sizeof $coll] > 0} {
    create_snapped_keepout_margin $coll $halo
    puts "Added snapped $halo micron halo for following pushdown clock buffers: [get_attribute $coll full_name]"
    }
}

#proc to check for halo requred around the macros 
######################################################################
# NAME: check_ram_halo
# DESCRIPTION: Checks the required halo present on all macros excluding
# the cells given in exclude_pats list. Macros need to be placed in 
# design before using this proc.
# PARAMS: DFP_CHECK_RAM_HALO, DFP_RAM_SPACING, DFP_RAM_HALO, 
#         DFP_CHECK_HALO_EXCL_PATTERN
# INPUT:  halo_required, exclude_pats list    
# OUTPUT: Error if any violation found.
######################################################################
proc check_ram_halo {halo_required {exclude_pats {}}} {
  set all_macros_cells [get_cells -physical_context -filter "is_hard_macro==true"]
  foreach_in_collection macro $all_macros_cells {
    set macro_name [get_attribute [get_cells -physical_context $macro] full_name]
    set skip 0
    foreach pat $exclude_pats {
      if {[string match $pat $macro_name]} {
        set skip 1
        break
      }
    }
    set placement_status [get_attribute $macro is_placed]
    if {[string match false $placement_status]} {
      puts "Error: $macro_name is not Placed"
    }
    if { $skip == 0 && [string match true $placement_status]} {
      set margin "[get_attribute $macro outer_keepout_margin_hard]"
      set left_halo "[lindex [lindex $margin 0] 0]"
      set bottom_halo "[lindex [lindex $margin 0] 1]"
      set right_halo "[lindex [lindex $margin 1] 0]"
      set top_halo "[lindex [lindex $margin 1] 1]"
      if {[regexp "no_outer_keepout_margin" $left_halo] || [regexp "no_outer_keepout_margin" $right_halo] || [regexp "no_outer_keepout_margin" $top_halo] || [regexp "no_outer_keepout_margin" $bottom_halo]} {
        puts "ERROR: No Halo Specified for $macro_name"
      } else {
          if {($left_halo < $halo_required) && ($right_halo < $halo_required) && ($bottom_halo < $halo_required) && ($top_halo < $halo_required)} {
          puts "Error: Halo is less than $halo_required for $macro_name"
          puts "Halo Info: $margin"
          }
      }
    }
 }
}

######################################################################
# NAME: check_ram_spacing
# DESCRIPTION: Checks the minimum channel spacing required in the design
# flow. Flags errors if any violations found. Violations include macro 
# overlapping, space less than given halo when macros are abutted, space
# less than the channel_spacing specified.
# PARAMS: DFP_RAM_SPACING, DFP_RAM_HALO,DFP_CHECK_HALO_EXCL_PATTERN,
#         DFP_CHECK_RAM_HALO
# INPUT: min_channel_spacing, halo, exclude_pats
# OUTPUT:Error if any violation found.
#####################################################################

#Proc to check spacing between the two macros
proc check_ram_spacing {min_channel_spacing exclude_pats} {
  set all_macros_cells [get_cells -physical_context -filter "is_hard_macro==true"]
  foreach_in_collection macro $all_macros_cells {
    set macro_name [get_attribute [get_cells -physical_context $macro] full_name]
    puts $macro_name
    set skip 0
    foreach pat $exclude_pats {
      if {[string match $pat $macro_name]} {
        set skip 1
        break
     }
    }
    set placement_status [get_attribute $macro is_placed]
    if {[string match false $placement_status]} {
      puts "Error: $macro_name is not Placed"
    }
    if {$skip == 0 && [string match true $placement_status]} {
      set llx [lindex [lindex [get_attribute $macro bbox] 0] 0]
      set lly [lindex [lindex [get_attribute $macro bbox] 0] 1]
      set urx [lindex [lindex [get_attribute $macro bbox] 1] 0]
      set ury [lindex [lindex [get_attribute $macro bbox] 1] 1]
      set req_llx [expr $llx - $min_channel_spacing]
      set req_lly [expr $lly - $min_channel_spacing]
      set req_urx [expr $urx + $min_channel_spacing]
      set req_ury [expr $ury + $min_channel_spacing]	 	 
      foreach_in_collection inst [filter_collection [get_objects_by_location -quiet -classes cell -intersect "{{$req_llx $req_lly} {$req_urx $req_ury}}"] "is_hard_macro"] {
        set inst_name "[get_attribute [get_cells -physical_context $inst] full_name]"
        set sel_llx [lindex [lindex [get_attribute $inst bbox] 0] 0]
        set sel_lly [lindex [lindex [get_attribute $inst bbox] 0] 1]
        set sel_urx [lindex [lindex [get_attribute $inst bbox] 1] 0]
        set sel_ury [lindex [lindex [get_attribute $inst bbox] 1] 1]
        set right_space [expr abs($urx - $sel_llx)]
        set left_space [expr abs($llx - $sel_urx)]
        set top_space [expr abs($ury - $sel_lly)]
        set bottom_space [expr abs($lly - $sel_ury)]
        set margin [get_attribute [get_cells $inst_name] outer_keepout_margin_hard]
        #set left_halo   [lindex $margin 0]
        #set bottom_halo [lindex $margin 1] 
        #set right_halo  [lindex $margin 2]
        #set top_halo    [lindex $margin 3]	    
        if {$margin eq "0 0 0 0"} {
          puts "Alert : No Halo Specified for $inst_name so not checking the minimum macro distance "
        }
# icc2 bbox will have halo values too.
#          set total_left_halo [expr $left_halo + $left_halo ]
#          set total_right_halo [expr $right_halo + $right_halo ]
#          set total_top_halo [expr $top_halo + $top_halo ]
#          set total_bottom_halo [expr $bottom_halo + $bottom_halo ]
          if {$ury > $sel_lly && $lly < $sel_ury} {
          if {$right_space < $min_channel_spacing || $left_space < $min_channel_spacing} {
              puts "ERROR : Spacing between $macro_name & $inst_name is less than minimum channel spacing, ${min_channel_spacing}u"
            }
          } elseif {$urx > $sel_llx && $llx < $sel_urx} {
              if {$top_space < $min_channel_spacing || $bottom_space < $min_channel_spacing} {
                 puts "ERROR : Spacing between $macro_name & $inst_name is less than minimum channel spacing, ${min_channel_spacing}u"
              }
            }
    }
    set x1 [lindex [lindex [get_attribute $macro bbox] 0] 0]
    set y1 [lindex [lindex [get_attribute $macro bbox] 0] 1] 
    set x2 [lindex [lindex [get_attribute $macro bbox] 1] 0] 
    set y2 [lindex [lindex [get_attribute $macro bbox] 1] 1] 
    if {[sizeof [get_objects_by_location -classes cell -quiet -filter "is_hard_macro==true" -intersect [list [list $x1 $y1] [list $x2 $y2]]]] > 1} {
      set i "[sizeof [get_objects_by_location -classes cell -quiet -filter "is_hard_macro==true" -intersect [list [list $x1 $y1] [list $x2 $y2]]]]"
      puts "Error: The macro [get_attribute $macro full_name] overlapping with [expr $i-1] other macros "
    }
   } 
}  
}


##########################################################################################
# NAME: tile_snap
# DESCRIPTION: It is used for creating def during COLDSTART.
# PARAMS: CHOSEN_COLDSTART, COLDSTART_ASPECT_RATIO, COLDSTART_CORE_SIDE_LENGTH,
# COLDSTART_CORE_OFF_SET, COLDSTART_SHAPE, COLDSTART_CORE_SIDE_RATIO,
# COLDSTART_INITIAL_DENSITY, FLOORPLAN_TILE_SNAP_HORIZONTAL, FLOORPLAN_TILE_SNAP_VERTICAL, 
# COLDSTART_ORIENTATION,COLDSTART_SNAP_EXTRA_OPTIONS
# INPUT: aspect_ratio, core_side_length, core_off_set, core_shape, core_side_ratio,
#        initial_density, tile_snap_horizontal, tile_snap_vertical, orientation, extra options
# OUTPUT:Creates DEF with mentioned requirements.
##########################################################################################
# tile_snap -core_side_length <$COLDSTART_CORE_SIDE_LENGTH> -core_off_set <$COLDSTART_CORE_OFF_SET> -core_shape <$COLDSTART_SHAPE> -core_side_ratio <$COLDSTART_CORE_SIDE_RATIO> -aspect_ratio <$COLDSTART_ASPECT_RATIO> -initial_density <$COLDSTART_INITIAL_DENSITY> -tile_snap_horizontal <$FLOORPLAN_TILE_SNAP_HORIZONTAL> -tile_snap_vertical <$FLOORPLAN_TILE_SNAP_VERTICAL> -orientation <$COLDSTART_ORIENTATION> -extra_options <$COLDSTART_SNAP_EXTRA_OPTIONS>
proc tile_snap { args } {
    global TARGET_NAME
    global P
    global env
    #adjust aspect ratio and utilization first before snapping
    parse_proc_arguments -args $args params
    set til            $params(-initial_density)
    set c_side_length  $params(-core_side_length)
    set orientation  $params(-orientation)
    set extra_options  $params(-extra_options)
    if {![info exists params(-no_flip_first_row)]} {
	set flip_first_row "true"
    } else {
	set flip_first_row "false"
    }
    if {![info exists params(-core_shape)] || $params(-core_shape) eq "" } {
	set c_shape "R"
    } else {
	set c_shape $params(-core_shape)
    }
    if {![info exists params(-aspect_ratio)] || $params(-aspect_ratio) eq "" } {
	set aspect 1
    } else {
	set aspect $params(-aspect_ratio)
    }
    if {![info exists params(-core_side_ratio)] || $params(-core_side_ratio) eq "" } {
	set c_ratio [list 1 1 ]
    } else {
	set c_ratio $params(-core_side_ratio)
    }
    if {$c_shape == "R" && $c_side_length == "" && ($aspect < 1 || $aspect > 1)} {
	set aside [format "%0.2f" [expr $aspect/(1.0 + $aspect)]]
	set bside [format "%0.2f" [expr 1.0 - $aside]]
	set c_ratio [list $aside $bside]
    }
    set c_off_set "" 
    set c_off_set $params(-core_off_set)
    if {[llength $c_off_set] == 0} {
	set c_off_set [list 0]
    } else {
	set c_off_set  $params(-core_off_set)
    }
    set site_def_size [list]
    set all_site_defs [lsort -unique [get_attribute -quiet [get_lib_cells -filter "design_type==lib_cell"] site_name]]
    foreach my_site_def $all_site_defs {
	set my_site_def [get_site_defs $my_site_def]
	set site_height [get_attr $my_site_def height]
	set site_width [get_attr $my_site_def width]
	set site_name [get_attr $my_site_def full_name]
	lappend site_def_size [list $site_name $site_width $site_height]
    }
    # sort the site by width and height
    set sorted_site_def_size [lsort -index 1 $site_def_size]
    set sorted_site_def_size [lsort -index 2 $sorted_site_def_size]
    # get the smallest one as default site
    set default_site_def [lindex $sorted_site_def_size 0 0]
    set unit_height [lindex $sorted_site_def_size 0 2]
    # leave the other sites used for create_site_array later
    set sorted_site_def_size [lreplace $sorted_site_def_size 0 0]

    #source_if_exists $P(NODE_DIR)/supra/templates/fc_shell/fx_fp_place_macros.tcl
    if {[info procs __tile_snap_init_floorplan] != ""} {
        set base_cmd [__tile_snap_init_floorplan $c_off_set $flip_first_row $default_site_def]
    } else {
        set base_cmd  "initialize_floorplan -core_offset { $c_off_set }  -flip_first_row $flip_first_row  -site_def $default_site_def"
    }
    if { [info exists orientation] && $orientation != ""} {
      set base_cmd "$base_cmd -orientation $orientation"
    }
    if { [info exists extra_options] && $extra_options != ""} {
      set base_cmd "$base_cmd $extra_options"
    }

    set cmd1 "$base_cmd"

    if { [info exists c_side_length] && $c_side_length != ""  } {
        if {[info procs __tile_snap_c_side_length] != ""} {
            set cmd1 [__tile_snap_c_side_length $base_cmd $c_side_length $c_shape]
        } else {
            set cmd1 "$base_cmd -shape $c_shape  -side_length {$c_side_length}"
        }
        puts "#### $cmd1"
        eval $cmd1
    } else {
        set cmd1 "$cmd1 -shape $c_shape -side_ratio {$c_ratio} -core_utilization $til"
        puts "#### $cmd1"
        eval $cmd1
    }
    set tileSnapHorizontal $params(-tile_snap_horizontal)
    set tileSnapVertical $params(-tile_snap_vertical)
    if { $tileSnapHorizontal == 0 || $tileSnapVertical == 0} {
	puts "Error: please supply non-zero snapping values.FLOORPLAN_TILE_SNAP_VER | FLOORPLAN_TILE_SNAP_HORIZONTAL"
    }
    if { $c_shape eq "R" } {
	set fplanBox [get_attribute [get_core_area] bbox]
	set fplanW [expr [lindex [lindex $fplanBox 1] 0] -  [lindex  [lindex $fplanBox 0] 0]]
	set fplanH [expr [lindex  [lindex $fplanBox 1] 1]-  [lindex  [lindex $fplanBox 0] 1] ]
    set fplanWorig $fplanW
    set fplanHorig $fplanH
	set hGridCount [expr int ($fplanH/$tileSnapVertical)]
	set wGridCount [expr int ($fplanW/$tileSnapHorizontal)]
    if {[expr $fplanH - $hGridCount*$tileSnapVertical] > 1e-6} {
        puts "Tile snap enforced\n"
        if {[info procs __tile_snap_fplanH] != ""} {
            set fplanH [__tile_snap_fplanH $hGridCount $tileSnapVertical]
        } else {
            set fplanH [expr  (($hGridCount+1)*$tileSnapVertical) ]
        }
    }
    if {[expr $fplanW - $wGridCount*$tileSnapHorizontal] > 1e-6} {
        puts "Tile snap enforced\n"
        if {[info procs __tile_snap_fplanW] != ""} {
            set fplanW [__tile_snap_fplanW $wGridCount $tileSnapHorizontal]
        } else {
            set fplanW [expr  (($wGridCount+1)*$tileSnapHorizontal) ]
        }
    }
    
    if {[info procs __tile_snap_core_fp_enforced] != "" && [__tile_snap_core_fp_enforced]} {
        # do nothing
    } else {
        if {$fplanH != $fplanHorig || $fplanW != $fplanWorig} {
	        puts "#### $base_cmd -side_length {$fplanW $fplanH}"
	        set cmd2 "$base_cmd -side_length {$fplanW $fplanH}"
	        puts "RESET: $cmd2" 
	        eval $cmd2
        }
    }
    }

    if { $c_shape eq "L" } {
      
      set fplanBound [get_attribute [get_core_area] boundary]

      if { $orientation eq "N"} {
          set fplanA [expr [lindex [lindex $fplanBound 0] 0] -[lindex [lindex $fplanBound 5] 0]] 
          set fplanB [expr [lindex [lindex $fplanBound 0] 1] -[lindex [lindex $fplanBound 1] 1]]
          set fplanC [expr [lindex [lindex $fplanBound 2] 0] -[lindex [lindex $fplanBound 1] 0]] 
          set fplanD [expr [lindex [lindex $fplanBound 2] 1] -[lindex [lindex $fplanBound 3] 1]]
      } elseif { $orientation eq "S" } {
          set fplanA [expr [lindex [lindex $fplanBound 1] 0] -[lindex [lindex $fplanBound 2] 0]] 
          set fplanB [expr [lindex [lindex $fplanBound 3] 1] -[lindex [lindex $fplanBound 2] 1]]
          set fplanC [expr [lindex [lindex $fplanBound 3] 0] -[lindex [lindex $fplanBound 4] 0]] 
          set fplanD [expr [lindex [lindex $fplanBound 5] 1] -[lindex [lindex $fplanBound 4] 1]]
      } elseif { $orientation eq "E"} {
          set fplanA [expr [lindex [lindex $fplanBound 0] 1] -[lindex [lindex $fplanBound 1] 1]] 
          set fplanB [expr [lindex [lindex $fplanBound 1] 0] -[lindex [lindex $fplanBound 2] 0]]
          set fplanC [expr [lindex [lindex $fplanBound 2] 1] -[lindex [lindex $fplanBound 3] 1]] 
          set fplanD [expr [lindex [lindex $fplanBound 3] 0] -[lindex [lindex $fplanBound 4] 0]]
      } else {
          set fplanA [expr [lindex [lindex $fplanBound 3] 1] -[lindex [lindex $fplanBound 2] 1]] 
          set fplanB [expr [lindex [lindex $fplanBound 4] 0] -[lindex [lindex $fplanBound 3] 0]]
          set fplanC [expr [lindex [lindex $fplanBound 5] 1] -[lindex [lindex $fplanBound 4] 1]] 
          set fplanD [expr [lindex [lindex $fplanBound 0] 0] -[lindex [lindex $fplanBound 5] 0]]
      }

      set AGridCount [expr int ($fplanA/$tileSnapVertical)]
      set BGridCount [expr int ($fplanB/$tileSnapHorizontal)]
      set CGridCount [expr int ($fplanC/$tileSnapVertical)]
      set DGridCount [expr int ($fplanD/$tileSnapHorizontal)]

      puts "side A = $fplanA, side B  = $fplanB, side C  =  $fplanC, side D  = $fplanD"
      puts "      NORTH              EAST                  WEST                 SOUTH         "
      puts "   A                                                D              "
      puts "-------               -------------               -------      --------------------"
      puts "|     | B             |           | A             |C    |     D|                  |"
      puts "|     |               |        B  |          B    |     |      |                  |"
      puts "|      ---------      |    --------         -------     |       ------|           |"
      puts "|         C     |     |    |                |           |          C  |           |"
      puts "|               |D    |    |C               |A          |             | B         |"
      puts "|_______________|     |__D_|                |___________|             |_______A___|"
      
    if {[info procs __tile_snap_fplanL] != ""} {
        lassign [__tile_snap_fplanL $AGridCount $BGridCount $CGridCount $DGridCount $tileSnapVertical $tileSnapHorizontal] fplanA fplanB fplanC fplanD
    } else {
        puts "\nTile snap enforced\n"
        set fplanA   [expr  (($AGridCount+1)*$tileSnapVertical) ]
        set fplanB   [expr  (($BGridCount+1)*$tileSnapHorizontal) ]
        set fplanC   [expr  (($CGridCount+1)*$tileSnapVertical) ]
        set fplanD   [expr  (($DGridCount+1)*$tileSnapHorizontal) ]
      }
    if {[info procs __tile_snap_core_fp_enforced] != "" && [__tile_snap_core_fp_enforced]} {
        # do nothing
    } else {
        puts "side A = $fplanA, side B  = $fplanB, side C  =  $fplanC, side D  = $fplanD"
        set cmd3 "$base_cmd -shape L -side_length {$fplanA $fplanB $fplanC $fplanD}" 

        puts "#### $cmd3"
        puts "RESET: $cmd3" 
        eval $cmd3
    }
    }

    if {[info procs __tile_snap_invalid_lib_check] != "" && [__tile_snap_invalid_lib_check]} {
        # do nothing
    } else {
    # remove and create new default site arrays
    set core_boundary [get_attribute [get_site_arrays] boundary]
    remove_site_arrays -all
    set cmd "create_site_array -name ${default_site_def}_row -site $default_site_def -boundary {$core_boundary}  -core_offset {$c_off_set} -flip_first_row $flip_first_row -default"
    puts "$cmd"
    eval $cmd
    # create site array for other Sites which are used in the stdcell ndm
    foreach my_site_def $sorted_site_def_size {
        set site_name  [lindex $my_site_def 0]
        set site_height [lindex $my_site_def 2]
        set is_doubleHeight 0
        if {[expr $site_height/$unit_height] == 2}  {
	    set is_doubleHeight 1
        }
        set cmd ""
        if {$is_doubleHeight == 1} {
	    if {[regexp -nocase {VGV|bcoreExt} $site_name]} {
		# vgv need a offset when don't flip the first row
		set row_offset [list]
		if {$flip_first_row == "false"} {
		    set row_offset [list [lindex $c_off_set 0] [expr [lindex $c_off_set 1] + $unit_height]]
		} else {
		    set row_offset $c_off_set
		}
		set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$row_offset}  -transparent true -flip_first_row $flip_first_row"
	    } elseif {[regexp -nocase {GVG|bcore} $site_name]} {
		# gvg need a offset when flip the first row
		set row_offset [list]
		if {$flip_first_row == "true"} {
		    set row_offset [list [lindex $c_off_set 0] [expr [lindex $c_off_set 1] + $unit_height]]
		} else {
		    set row_offset $c_off_set
		}         
		set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$row_offset}  -transparent true -flip_first_row $flip_first_row"
	    } else {
		puts "Error: new double Height site names are used, need to fix the regexp"
	    }
        } else  {
	    # other single height sites
	    set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$c_off_set}  -transparent true -flip_first_row $flip_first_row"
        }
        puts "$cmd"
        eval $cmd
    }
    }   
    #set allinfo [report_attributes -app [get_site_arrays]]

    #puts "all site array $allinfo"
    #create_site_array -name core_row -site $default_site_def -boundary $core_boundary -core_offset {20.064 19.2} -flip_first_row false -default
    #create_site_array -site bcore -boundary $core_boundary -core_offset {20.064 19.2} -flip_first_row false -transparent true
    #create_site_array -site bcoreExt -boundary $core_boundary -core_offset {20.064 19.2} -flip_first_row false -transparent true
    #  else {
    #set cmd "initialize_floorplan -core_offset {$c_off_set} -side_length {$c_side_length} -flip_first_row $flip_first_row -site_def $default_site_def"
    #  puts "#### initialize_floorplan -core_offset {$c_off_set} -side_length {$c_side_length} -flip_first_row $flip_first_row -site_def $default_site_def"
    # puts "RESET: $cmd " 
    # eval $cmd
    #}
    # WA for cutting create_site_arrays.
    if {! [info exists P]} {
      source "$env(FLOW_DIR)/util/ParamsDB.tcl"
    }
    sh rm -rf ./site_arrays.def
    write_def -include {rows_tracks} -version "$P(DEFOUT_VERSION)" ./site_arrays.def
    remove_site_arrays -all
    remove_site_rows -all
    read_def ./site_arrays.def
    sh rm -rf ./site_arrays.def

    if { [info exists P(IC_TRACKPLAN_SCRIPT)] } {
      # Create the ICC2 trackplan from script
      source -echo -verbose "$P(IC_TRACKPLAN_SCRIPT)"
    }
}

define_proc_attributes tile_snap -info "Read offset pitch maxDist minDist ignore" -define_args { \
    {-core_side_length "side lengths in numerical order" "" list optional } \
    {-core_off_set "The distance from the core to all die sides in um" "" list optional } \
    {-core_shape "core shape R|T|U|L Default is R" "" string optional } \
    {-core_side_ratio "the side a,b,... size ratios" "" list required } \
    {-aspect_ratio "the y:x aspect ratio" "" float optional } \
    {-initial_density "Initial density" "" float optional } \
    {-tile_snap_horizontal "horizontal tile snap value" "" float required } \
    {-tile_snap_vertical "vertical tile snap value" "" float required } \
    {-no_flip_first_row "Don't Flip the first row" "" string optional } \
    {-orientation "orientation" "" string optional } \
    {-extra_options "other options" "" string optional } \
}

#proc to create multiple site arrays us 
######################################################################################
# NAME: amd_create_site_arrays
# DESCRIPTION: 
# It could remove the wrong site_def in the input def and  
# create all the needed site rows:single or double height (get from the ndm stdcells). 
# the smallest site is defined as the default
# INPUT:
# -flip_first_row   if the first row is flip during initialize_floorplan
######################################################################################
proc amd_create_site_arrays { args } {
    parse_proc_arguments -args $args params
    if {![info exists params(-flip_first_row)]} {
      set flip_first_row "true"
    } else {
      set flip_first_row $params(-flip_first_row)
    }
    set chip_x [lindex [get_attribute [current_block ] boundary] 0 0]
    set chip_y [lindex [get_attribute [current_block ] boundary] 0 1]

    set core_x [lindex [get_attribute [get_core_area ] bbox] 0 0]
    set core_y [lindex [get_attribute [get_core_area ] bbox] 0 1]

    set c_off_set [list [expr $core_x - $chip_x] [expr $core_y - $chip_y]]
    set site_def_size [list]
    set all_site_defs [lsort -unique [string map { "{" ""  "}" "" } [get_attribute [get_lib_cells -filter "design_type!=macro&&design_type!=pad"] site_name]]]
    foreach my_site_def $all_site_defs {
      set my_site_def [get_site_defs -q $my_site_def]
      if {[string equal $my_site_def ""]} {
        puts "Cannot find current site def:my_site_def"
        continue
      }
      set site_height [get_attr $my_site_def height]
      set site_width [get_attr $my_site_def width]
      set site_name [get_attr $my_site_def full_name]
      lappend site_def_size [list $site_name $site_width $site_height]
    }
    # sort the site by width and height
    set sorted_site_def_size [lsort -index 1 $site_def_size]
    set sorted_site_def_size [lsort -index 2 $sorted_site_def_size]
    # get the smallest one as default site
    set default_site_def [lindex $sorted_site_def_size 0 0]
    set unit_height [lindex $sorted_site_def_size 0 2]
    # leave the other sites used for create_site_array later
    set sorted_site_def_size [lreplace $sorted_site_def_size 0 0]


    # remove and create new default site arrays
    #set core_boundary [get_attribute [current_block] boundary]
    set core_boundary [get_attribute [get_core_area] boundary]
    
    # get the existing site rows to see if the first row is flipped
    set core_bbox [get_attribute [get_core_area] bbox]
    set first_row_bbox [list [lindex $core_bbox 0] [list [lindex $core_bbox 1 0] [expr [lindex $core_bbox 0 1] + 0.01]]]
    set find_rows [get_objects_by_location -q -classes site_row -intersect $first_row_bbox]
    set minheight 100.0
    set first_row ""
    foreach_in_collection my_row $find_rows {
      set my_row_name [get_attribute $my_row full_name]
      set my_row_height [get_attribute $my_row  site_height]
      if {$my_row_height < $minheight} {
        set minheight $my_row_height
        set first_row $my_row_name
      }
    }
    if {![string equal $first_row ""]} {
      set site_orientation [get_attribute [get_site_rows $first_row] site_orientation]
      if {[regexp {R0|MY} $site_orientation]} {
        set flip_first_row false 
        puts "Find the first site row in the design: $first_row not flipped"
      } else {
        set flip_first_row true
        puts "Find the first site row in the design: $first_row flipped"
      }
    }
    remove_site_rows -all
    remove_site_arrays -all

    set cmd "create_site_array -name ${default_site_def}_row -site $default_site_def -boundary {$core_boundary}  -core_offset {$c_off_set} -flip_first_row $flip_first_row -default"
    puts "$cmd"
    eval $cmd

    set cur_block [current_block]
    # create site array for other Sites which are used in the stdcell ndm
    foreach my_site_def $sorted_site_def_size {
      set site_name  [lindex $my_site_def 0]
      set site_height [lindex $my_site_def 2]
      set num_unitHeight [expr $site_height/$unit_height] 
      if {[expr fmod($site_height,$unit_height)] >= 0.001} {
        puts "$site_name is not multiples of unit height, skip"
        continue
      }
      puts "creating site array for $site_name"
      set cmd ""
      if {$num_unitHeight > 1} {
        set cell_type ""
        if {[regexp -nocase {VGV|bcoreExt} $site_name]} {
          set cell_type "VGV"
        } elseif {[regexp -nocase {GVG|bcore} $site_name]} {
          set cell_type "GVG"
        } elseif {[regexp -nocase {ibunit} $site_name]} {
          set cell_type "ibunit"
        } else {
          set dh_cells [get_lib_cells -filter "site_name==$site_name" */*/frame]
          set find_type 0
          foreach_in_collection my_cell $dh_cells {
            set my_cellname [get_object_name $my_cell]
            regsub {/} $my_cellname {:} my_cellname
            regsub {/} $my_cellname {.} my_cellname
            #set my_cellname "${my_cellname}.frame"
            if { [catch { current_block $my_cellname }] } {
              puts "cannot open $my_cellname"
              continue
            }
            set vss_bbox [get_attr  [get_terminals -quiet -filter "name==VSS"] bbox]
            set vss_y1 [lindex $vss_bbox 0 1]
            set vss_y2 [lindex $vss_bbox 1 1]
            set vss_mid [expr ($vss_y1 + $vss_y2)/2.0]
       
            set vss_mid2bottom [expr fmod($vss_mid, $unit_height)] 
            if {[expr fmod($vss_mid2bottom,2)] < 0.001 } {
              set cell_type "GVG"    
            } else {
              set cell_type "VGV"    
            } 
            set find_type 1
            close_blocks
            current_block $cur_block
            break
          }
          if { $find_type == 0 } { 
            puts "Error: cannot determin the cell type VGV/GVG"
          }
        }

        if { [string equal $cell_type "VGV"] } {
        # vgv need a offset when don't flip the first row
          set row_offset [list]
          if {$flip_first_row == "false"} {
            set row_offset [list [lindex $c_off_set 0] [expr [lindex $c_off_set 1] + $unit_height]]
          } else {
            set row_offset $c_off_set
          }
          set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$row_offset}  -transparent true -flip_first_row false"
        } elseif { [string equal $cell_type "GVG"] } {
        # gvg need a offset when flip the first row
          set row_offset [list]
          if {$flip_first_row == "true"} {
            set row_offset [list [lindex $c_off_set 0] [expr [lindex $c_off_set 1] + $unit_height]]
          } else {
            set row_offset $c_off_set
          }         
          set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$row_offset}  -transparent true -flip_first_row false"
        } elseif { [string equal $cell_type "ibcore6T"] } {
        # ibunit
          set cmd "create_site_array -name ${site_name}_row -site $site_name -boundary {$core_boundary} -transparent true -direction horizontal -aligned false -flip_first_row false -flip_alternate_row false"
        }
      } else  {
      # other single height sites
        set cmd "create_site_array -name ${site_name}_row -site $site_name  -boundary {$core_boundary} -core_offset {$c_off_set}  -transparent true -flip_first_row $flip_first_row"
      }
      puts "$cmd"
      eval $cmd
    }
    current_block $cur_block
}

define_proc_attributes amd_create_site_arrays -info "create single height and double height site arrays according to the core offset and whether to flip the first fow" -define_args { \
    {-flip_first_row "Flip the first row" "" string optional } \
}

proc macro_blockage { margin } {
  set x 0
  set y 0
  set init_margin $margin
  foreach_in_collection macro [get_cells -physical_context -filter "is_hard_macro==true"] {
    # To honor macro's original halo.
    set halo [get_attribute $macro outer_keepout_margin_hard] 
    if { $halo ne "0 0 0 0" } {
      set halo [lindex [lsort -decreasing  $halo] 0]
      if { $halo > $margin} {
        set margin $halo
      }
    }
    set bbox  [get_attribute $macro boundary ]
    create_placement_blockage -type hard -name pbonmacro_$x -boundary $bbox
    incr x
    set bbox \{$bbox\}
    set poly_bbox [resize_polygons -size $margin -objects [create_poly_rect -boundary $bbox]]
    set new_poly_bbox [compute_polygons -operation NOT -objects1 $poly_bbox -objects2 $bbox]
    foreach poly $new_poly_bbox {
      create_placement_blockage -type hard -name pbaround_macro_$y -boundary $poly
      incr y
    }
    set margin $init_margin
  }
  puts "INFO: Placement Blockages have been created on and around for all the macros for given margin.\n"
}

proc create_placement_blockage_for_macro { args } {
  parse_proc_arguments -args $args params
  set macro_list $params(-macro_list)
  set blockage_list $params(-blockage_list)
  set inst_list $params(-inst_list)
  set orien $params(-orien)
  set coll []
  if {$macro_list != ""} { 
    foreach macro_name $macro_list { 
      if { $orien != ""} {
        set filt "ref_name =~ $macro_name && (orientation == $orien)"
      } else {
          set filt "ref_name =~ $macro_name"
      }
      append_to_collection coll [get_cells -quiet -hier -filter $filt]
    }
  }
  if {$inst_list != ""} { 
    foreach inst_name $inst_list { 
      if { $orien != ""} {
        set filt "name =~ $inst_name && (orientation == $orien)"
      } else {
          set filt "name =~ $inst_name"
      }
      append_to_collection coll [get_cells -quiet -hier -filter $filt]
    }
  }
  if {$blockage_list == ""} {
    puts "INFO: placement blockage dimension is not given, hence not created"
    return
  }
  if { [sizeof $coll] >  0 } {
    foreach_in_collection name $coll {
      puts "create placement blockage for [get_attr $name name]"
      set poly_macro_area [create_poly_rect -boundary [get_att $name boundary]]
      foreach_in_collection poly_split_tmp [split_polygons -objects [resize_polygons -objects $poly_macro_area -size $blockage_list] -output poly_rect -split horizontal] {
        create_placement_blockage -boundary [get_att $poly_split_tmp point_list] -type hard
        }
      }
      #snapping placement blockage to the row,even cpp
      create_placement_blockage_for_macro $coll
    } else {
       puts "INFO: list of macros are given to create placement blocakge around it."
    }
}
define_proc_attributes create_placement_blockage_for_macro -info "create placement blockage for given macro ref names or inst names with given blockages to be applied." -define_args { \
    {-macro_list "list of macros ref names" "" list optional } \
    {-inst_list "list of instance names" "" list optional } \
    {-blockage_list "blocakges to be applied" "" list optional } \
    {-orien "orientation of macro" "" string optional } \
}
######################################################################
# NAME: convert_to_dbu
# DESCRIPTION: Converts microns to DBU. This can be used for encounter
# compatibility.
# INPUT: val
# OUTPUT: val converted to DBU units.
######################################################################
proc convert_to_dbu { val } {
  set factor [get_attri [current_lib] scale_factor]
  set val2 "[expr $val*$factor]"
  return [expr round($val2)]
}

######################################################################
# NAME: convert_to_micron
# DESCRIPTION: Converts DBU units to microns. This can be used for 
# encounter compatibility.
# INPUT:  val       
# OUTPUT: val converted to micron 
######################################################################
proc convert_to_micron { val } {
  set factor [expr [get_attri [current_lib] scale_factor]*1.0]
  set val3 [format "%0.4f" [expr $val / $factor]]
  return $val3
}
##################################################################################
# NAME: adjust_row_cuts_to_snap_grid
# DESCRIPTION: It is used for Rowsnapping around Macros.
# PARAMS: IC_OBS_ROWCUT_SNAP_GRID_PITCH, IC_OBS_ROWCUT_SNAP_GRID_OFFSET, 
# IC_OBS_ROWCUT_SNAP_GRID_MAXDIST, IC_OBS_ROWCUT_SNAP_GRID_MINDIST, 
# IC_OBS_ROWCUT_SNAP_GRID_IGNORE_CELLNAME_PATTERN, IC_OBS_ROWCUT_SNAP_GRID_SEVERITY        
# INPUT: pitch, offset, maxDist, minDist, ignore (if any), severity (Alert/Error)
# OUTPUT:Create blockages around Macros for cutting std rows.
##################################################################################
#adjust_row_cuts_to_snap_grid -pitch {5.85} -offset {2.925} -maxDist {2.925} -minDist {0.6} -ignore {} -severity {Alert}
proc adjust_row_cuts_to_snap_grid {args} {
  global P
  parse_proc_arguments -args $args params
  if {$params(-pitch) <= 0} {
    return
  }
  set params(offset) $params(-offset)
  set params(pitch) $params(-pitch)
  set params(maxDist) $params(-maxDist)
  set params(minDist) $params(-minDist)
  set params(ignore) $params(-ignore)
  set params(severity) $params(-severity)
  set offsetDBU [convert_to_dbu $params(offset)]
  set pitchDBU [convert_to_dbu $params(pitch)]
  set maxDistDBU [convert_to_dbu $params(maxDist)]
  set minDistDBU [convert_to_dbu $params(minDist)]
  set snapping_alert_dist [expr $params(maxDist) / 2 ]
  set snapping_total 0
  set snapping_diff 0
  set ignorePattern $params(ignore)
  regsub {^\s+$} $params(severity) {ALERT} params(severity)
  regsub -all {\s} $ignorePattern {} ignorePattern
  regsub -all {,} $ignorePattern {|} ignorePattern
#  set box [get_attribute [get_designs] core_area_bbox]
  set box [get_attribute [get_designs] boundary_bbox ]
  set tileDBU(x1) [convert_to_dbu [lindex $box 0 0]]
  set tileDBU(y1) [convert_to_dbu [lindex $box 0 1]]
  set tileDBU(x2) [convert_to_dbu [lindex $box 1 0]]
  set tileDBU(y2) [convert_to_dbu [lindex $box 1 1]]
  if {[info exists params(-zhaMacro)] && $params(-zhaMacro) != ""} {
      regsub -all {\*} $params(-zhaMacro) {.*} zhaMacroRegex
      regsub -all {\s+} $zhaMacroRegex {|} zhaMacroRegex
      puts "INFO: zhaMacro regexp pattern $zhaMacroRegex"
  }

  set row_cut 1
  if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
      set row_cut 0
      # For somes nodes, there is even cpp requirement, prepare the related params here
      set site_width [expr [get_attr [get_site_defs unit] width] * 2]
      set row_height [get_attr [get_site_defs unit] height]
      set tilex [lindex [get_attri -objects [current_block] -name boundary] 0 0]
      set tiley [lindex [get_attri -objects [current_block] -name boundary] 0 1]
      set corex [lindex [get_attri [get_core_area] boundary] 0 0]
      set corey [lindex [get_attri [get_core_area] boundary] 0 1]
      set offsetx [expr ($corex - $tilex)]
      set offsety [expr ($corey - $tiley)]

  }
  ### include macro halos

  set boxList {}
  set i 0 
  if { [sizeof_collection [get_placement_blockages -quiet "*HALO_* PITCH*"]] > 0 } {
    remove_placement_blockage  [get_placement_blockages -quiet "*HALO_* PITCH*"]
  }
  set x 0
  foreach_in_collection macro [get_cells -physical_context -filter "is_hard_macro==true"] {
    set cellName [get_attribute [get_cells -physical_context $macro] full_name]
    set refName [get_attri $macro ref_name]
    if {$ignorePattern ne "" && ([regexp $ignorePattern $cellName matchinst] || [regexp $ignorePattern $refName matchref])} {
        if {[info exists matchinst] && $matchinst != ""} {puts "Ignore Halo of cell $cellName by matching the inst name pattern $matchinst"; unset matchinst}
        if {[info exists matchref] && $matchref != ""} {puts "Ignore Halo of cell $cellName by pattern $matchref"; unset matchref}
    } else {
      set instHaloValue [get_attribute $macro outer_keepout_margin_hard]
      regsub -all "\[{}]" $instHaloValue  "" instHaloValue
      set instbox [get_attribute $macro boundary ]
      set instbox \{$instbox\} 
      if { $instHaloValue eq "0 0 0 0"} {
        set margin_l 0
        set margin_t 0
        set margin_r 0
        set margin_b 0
      } else {
          set margin_l [format "%.4f" [lindex $instHaloValue 0 ]]
          set margin_b [format "%.4f" [lindex $instHaloValue 1 ]]
          set margin_r [format "%.4f" [lindex $instHaloValue 2 ]]
          set margin_t [format "%.4f" [lindex $instHaloValue 3 ]]
      }
      set poly_bbox [resize_polygons -size [list $margin_l $margin_b $margin_r $margin_t] -objects [create_poly_rect -boundary $instbox]]
      set new_poly_bbox [compute_polygons -operation NOT -objects1  $poly_bbox -objects2 $instbox]
      if { ($margin_l != 0) || ($margin_t != 0) || ($margin_r != 0) || ($margin_b != 0) } {
        foreach poly $new_poly_bbox {
          create_placement_blockage -boundary "$poly" -type hard -name HALO_$i
          if {$row_cut==1} {
              cut_rows -within [get_attr [get_placement_blockage HALO_$i] bbox]
          }
          incr i 
        }
      }
        if { [llength [get_attr $macro boundary]] > 4 } {
          foreach_in_collection poly [split_polygon -output poly_rect -objects $instbox] { 
            if {[info exists zhaMacroRegex] && [regexp $zhaMacroRegex [get_attri $macro ref_name]]} {
                puts "INFO: macro [get_object_name $macro]([get_attri $macro ref_name]) match zha pattern $params(-zhaMacro), set its blockage name to ZHA_MACRO_HALO, would not add extend blockage PITCH_* for it"
                set new_pb [create_placement_blockage -boundary "$poly" -type hard -name ZHA_MACRO_HALO_RECTI_$x]
            } else {
                set new_pb [create_placement_blockage -boundary "$poly" -type hard -name MACRO_HALO_RECTI_$x]
            }
            if {$row_cut==1} {
                cut_rows -within [get_attr $new_pb bbox]
            }
            incr x
          }
        } else {
            if {[info exists zhaMacroRegex] && [regexp $zhaMacroRegex [get_attri $macro ref_name]]} {
                puts "INFO: macro [get_object_name $macro]([get_attri $macro ref_name]) match zha pattern $params(-zhaMacro), set its blockage name to ZHA_MACRO_HALO, would not add extend blockage PITCH_* for it"
                set new_pb [create_placement_blockage -boundary "$instbox" -type hard -name ZHA_MACRO_HALO_$x]
            } else {
                set new_pb [create_placement_blockage -boundary "$instbox" -type hard -name MACRO_HALO_$x]
            }
            if {$row_cut==1} {
                cut_rows -within [get_attr $new_pb bbox]
            }
            incr x
        }
      # sure rows are cut around halos by creating an additional overlapping placement obstruction.
    }
  }
  

  set i 0
  ### include user defined obstructions
  foreach_in_collection blockage [get_placement_blockages -quiet "MACRO_HALO*"] {
    set pb_bbox [get_attribute $blockage bbox]
    set pb_bbox \{$pb_bbox\}
    if { [regexp MACRO_HALO_RECTI [get_attr $blockage name] ] } {
      set macro [get_objects_by_location -classes cell -intersect [create_poly_rect -boundary $pb_bbox] -filter "is_hard_macro==true" ]
}    else {
      set macro [get_objects_by_location -classes cell -touching [create_poly_rect -boundary $pb_bbox] -filter "is_hard_macro==true" ]
    }
    set instHaloValue [get_attribute $macro outer_keepout_margin_hard]
    regsub -all "\[{}]" $instHaloValue  "" instHaloValue
    set pb_bbox [get_attribute $blockage bbox]
    set haloLLX [expr [lindex [lindex $pb_bbox 0 ] 0 ] - [lindex $instHaloValue 0]]
    set haloLLY [expr [lindex [lindex $pb_bbox 0 ] 1 ] - [lindex $instHaloValue 1]]
    set haloURX [expr [lindex [lindex $pb_bbox 1 ] 0 ] + [lindex $instHaloValue 2]]
    set haloURY [expr [lindex [lindex $pb_bbox 1 ] 1 ] + [lindex $instHaloValue 3]]
    lappend boxList [list $haloLLX $haloLLY $haloURX $haloURY]
  }

  foreach box $boxList {

    # For some nodes, the iniital blockage edge would not be always the keepout margin edge, therefore refine the OBS box here
    if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
        set obsLLX [lindex $box 0]; set obsLLY [lindex $box 1]
        set obsURX [lindex $box 2]; set obsURY [lindex $box 3]
        set to_snapOBSx1 [expr $obsLLX - $corex]; set to_snapOBSy1 [expr $obsLLY - $corey]
        set to_snapOBSx2 [expr $obsURX - $corex]; set to_snapOBSy2 [expr $obsURY - $corey]
        lassign [__snap_macro_blockage_helper $to_snapOBSx1 $to_snapOBSx2 $site_width] snapOBS_x1 snapOBS_x2
        lassign [__snap_macro_blockage_helper $to_snapOBSy1 $to_snapOBSy2 $row_height] snapOBS_y1 snapOBS_y2
        set newx1 [expr $corex + $snapOBS_x1]; set newx2 [expr $corex + $snapOBS_x2]
        set newy1 [expr $corey + $snapOBS_y1]; set newy2 [expr $corey + $snapOBS_y2]
        set box  [list $newx1 $newy1 $newx2 $newy2]
    }
    if { [llength [lindex $box 1] ] == 1 } {
      set obsDBU(x1) [convert_to_dbu [lindex $box 0]]
      set obsDBU(y1) [convert_to_dbu [lindex $box 1]]
      set obsDBU(x2) [convert_to_dbu [lindex $box 2]]
      set obsDBU(y2) [convert_to_dbu [lindex $box 3]]
    } else {
      set obsDBU(x1) [convert_to_dbu [lindex $box 0 0]]
      set obsDBU(y1) [convert_to_dbu [lindex $box 0 1]]
      set obsDBU(x2) [convert_to_dbu [lindex $box 1 0]]
      set obsDBU(y2) [convert_to_dbu [lindex $box 1 1]]
    }

    ### snap left blockage edge
    # space between grid and left edge of blockage
    set deltaDBU [expr ($obsDBU(x1) - ($tileDBU(x1) + $offsetDBU)) % $pitchDBU]
    set x1DBU $obsDBU(x1)
    # make sure distance between snap grid and left edge of blockage is between min and max distance
    if {$deltaDBU > $maxDistDBU} {
      set x1DBU [expr $obsDBU(x1) - ($deltaDBU - $maxDistDBU)]
    } elseif {$deltaDBU < $minDistDBU} {
      set x1DBU [expr $obsDBU(x1) - ($deltaDBU + ($pitchDBU - $maxDistDBU))]
      }
          #puts "deltaDBU calculation"
    if {$x1DBU < $tileDBU(x1)} {
      set x1DBU $tileDBU(x1)
    }
 
    # create new obstruct between original obstruct and snap grid
    if {$x1DBU != $obsDBU(x1)} {

      if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
          set extX1 [convert_to_micron $x1DBU]
          set to_snapEXTx1 [expr $extX1 - $corex]
          lassign [__snap_macro_blockage_helper $to_snapEXTx1 0 $site_width] snapEXT_x1 snapEXT_x2
          set newEXTx1 [expr $corex + $snapEXT_x1]
          set x1DBU [convert_to_dbu $newEXTx1]
      }
      set x1 [convert_to_micron $x1DBU]
      set y1 [convert_to_micron $obsDBU(y1)]
      set x2 [convert_to_micron $obsDBU(x1)]
      set y2 [convert_to_micron $obsDBU(y2)]
      #puts  [format "Info: Creating additional obstruction: (%0.3f,%0.3f)->(%0.3f,%0.3f)" $x1 $y1 $x2 $y2]
      puts   "create_placement_blockage -boundary {{$x1 $y1} { $x2 $y2}} -type hard -name PITCH_$i"
      eval "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH_$i"
      if {$row_cut==1} {
          #cut_row -within [list [list $x1 $y1] [list $x2 $y2]]
          puts "cut_rows -within {{ $x1 $y1} { $x2 $y2}}"
          eval "cut_rows -within {{ $x1 $y1} { $x2 $y2}}"
      }
      set i [expr $i + 1]
      set snapping_diff [expr $x2 - $x1]
      set snapping_total [expr $snapping_total + $snapping_diff]
      if {$snapping_diff >= $snapping_alert_dist} {
        puts "$params(severity): row snapping is too large: $snapping_diff, please check your ram placment on area: ($x1 $y1), ($x2 $y2)"

      } else {
        puts "Row snapping is : $snapping_diff"

      }
    }
    
    ### snap right blockage edge
    # space between grid and right edge of blockage
    set deltaDBU [expr ($obsDBU(x2) - ($tileDBU(x1) + $offsetDBU)) % $pitchDBU]
    if {$deltaDBU > 0} {
      set deltaDBU [expr $pitchDBU - $deltaDBU]
    }
    set x2DBU $obsDBU(x2)
    # make sure distance between right edge of blockage and the next snap grid is between min and max distance
        
    if {$deltaDBU > $maxDistDBU} {
      set x2DBU [expr $obsDBU(x2) + ($deltaDBU - $maxDistDBU)]
    } elseif {$minDistDBU > $deltaDBU} {
        set x2DBU [expr $obsDBU(x2) + ($deltaDBU + ($pitchDBU - $maxDistDBU))]
    }
    
    if {$x2DBU > $tileDBU(x2)} {
      set x2DBU $tileDBU(x2)
    }
    # create new obstruct between original obstruct and snap grid
    if {$x2DBU != $obsDBU(x2)} {
      
      if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
          set extX2 [convert_to_micron $x2DBU]
          set to_snapEXTx2 [expr $extX2 - $corex]
          lassign [__snap_macro_blockage_helper 0 $to_snapEXTx2 $site_width] snapEXT_x1 snapEXT_x2
          set newEXTx2 [expr $corex + $snapEXT_x2]
          set x2DBU [convert_to_dbu $newEXTx2]
      }
      set x1 [convert_to_micron $obsDBU(x2)]
      set y1 [convert_to_micron $obsDBU(y1)]
      set x2 [convert_to_micron $x2DBU]
      set y2 [convert_to_micron $obsDBU(y2)]

      #puts  [format "Info: Creating additional obstruction: (%5.3f,%5.3f)->(%5.3f,%5.3f)" $x1 $y1 $x2 $y2]
      puts  "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH2_$i"
      eval "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH2_$i"
      if {$row_cut==1} {
          #cut_row -within [list [list $x1 $y1] [list $x2 $y2]]
          puts "cut_rows -within {{$x1 $y1} {$x2 $y2}}"
          eval "cut_rows -within {{$x1 $y1} {$x2 $y2}}"
      }

      set i [expr $i + 1]
      set snapping_diff [expr $x2 - $x1]
      set snapping_total [expr $snapping_total + $snapping_diff]
      if {$snapping_diff >= $snapping_alert_dist} {
        puts "$params(severity): row snapping is too large: $snapping_diff, please check your ram placment on area: ($x1 $y1), ($x2 $y2)"
      } else {
        puts "Row snapping is : $snapping_diff"

      }
    }
  }
  puts  "Row snapping total distances are: $snapping_total"
}

define_proc_attributes adjust_row_cuts_to_snap_grid -info "Read offset pitch maxDist minDist ignore" -define_args { \
    {-offset "The distance from the left edge of the tile to the first snap grid point in um" "" float required} \
    {-pitch "The snap grid pitch in um" "" float required } \
    {-maxDist "The maximum distance allowed between a blockage edge and the nearest non-overlapping snap grid in um" "" float required} \
    {-minDist "The minimum distance allowed between a blockage edge and the nearest non-overlapping snap grid in um" "" float optional } \
    {-zhaMacro "zero halo abutment macro ref name wildcard pattern" "" string optional} \
    {-severity "ALERT:Severity of warning reported if a row end is adjusted by more the 1/2 of the maxDist distance" "" string required } \
    {-ignore "Ignore cell pattern" "" string required} \
}

#below version only cuts GVG/VGVCORE and PGCORE rows needed for DFP tiles.  Unit sites are not cut
#adjust_row_cuts_to_snap_grid -pitch {5.85} -offset {2.925} -maxDist {2.925} -minDist {0.6} -ignore {} -severity {Alert}
proc adjust_row_cuts_to_snap_grid_dfp {args} {
  global P
  parse_proc_arguments -args $args params
  if {$params(-pitch) <= 0} {
    return
  }
  set params(offset) $params(-offset)
  set params(pitch) $params(-pitch)
  set params(maxDist) $params(-maxDist)
  set params(minDist) $params(-minDist)
  set params(ignore) $params(-ignore)
  set params(severity) $params(-severity)
  set offsetDBU [convert_to_dbu $params(offset)]
  set pitchDBU [convert_to_dbu $params(pitch)]
  set maxDistDBU [convert_to_dbu $params(maxDist)]
  set minDistDBU [convert_to_dbu $params(minDist)]
  set snapping_alert_dist [expr $params(maxDist) / 2 ]
  set snapping_total 0
  set snapping_diff 0
  set ignorePattern $params(ignore)
  regsub {^\s+$} $params(severity) {ALERT} params(severity)
  regsub -all {\s} $ignorePattern {} ignorePattern
  regsub -all {,} $ignorePattern {|} ignorePattern
#  set box [get_attribute [get_designs] core_area_bbox]
  set box [get_attribute [get_designs] boundary_bbox ]
  set tileDBU(x1) [convert_to_dbu [lindex $box 0 0]]
  set tileDBU(y1) [convert_to_dbu [lindex $box 0 1]]
  set tileDBU(x2) [convert_to_dbu [lindex $box 1 0]]
  set tileDBU(y2) [convert_to_dbu [lindex $box 1 1]]
  if {[info exists params(-zhaMacro)] && $params(-zhaMacro) != ""} {
      regsub -all {\*} $params(-zhaMacro) {.*} zhaMacroRegex
      regsub -all {\s+} $zhaMacroRegex {|} zhaMacroRegex
      puts "INFO: zhaMacro regexp pattern $zhaMacroRegex"      
  }

  set row_cut 1
  if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
      # For some nodes, there is even cpp requirement, prepare the related params here
      set site_width [expr [get_attr [get_site_defs unit] width] * 2]
      set row_height [get_attr [get_site_defs unit] height]
      set tilex [lindex [get_attri -objects [current_block] -name boundary] 0 0]
      set tiley [lindex [get_attri -objects [current_block] -name boundary] 0 1]
      set corex [lindex [get_attri [get_core_area] boundary] 0 0]
      set corey [lindex [get_attri [get_core_area] boundary] 0 1]
      set offsetx [expr ($corex - $tilex)]
      set offsety [expr ($corey - $tiley)]

  }
  set PGCORE_row_cut_resize_y 0

  set boxList {}
  set i 0 
  if { [sizeof_collection [get_placement_blockages -quiet "*HALO_* PITCH*"]] > 0 } {
    remove_placement_blockage  [get_placement_blockages -quiet "*HALO_* PITCH*"]
  }
  foreach_in_collection macro [get_cells -physical_context -filter "is_hard_macro==true"] {
    set cellName [get_attribute [get_cells -physical_context $macro] full_name]
    set refName [get_attri $macro ref_name]
    if {$ignorePattern ne "" && ([regexp $ignorePattern $cellName matchinst] || [regexp $ignorePattern $refName matchref])} {
        if {[info exists matchinst] && $matchinst != ""} {puts "Ignore Halo of cell $cellName by matching the inst name pattern $matchinst"; unset matchinst}
        if {[info exists matchref] && $matchref != ""} {puts "Ignore Halo of cell $cellName by pattern $matchref"; unset matchref}
    } else {
      set instHaloValue [get_attribute $macro outer_keepout_margin_hard]
      regsub -all "\[{}]" $instHaloValue  "" instHaloValue
      set instbox [get_attribute $macro boundary_bbox ]
      set llx [format "%.4f" [lindex $instbox 0 0]]
      set lly [format "%.4f" [lindex $instbox 0 1]]
      set urx [format "%.4f" [lindex $instbox 1 0]]
      set ury [format "%.4f" [lindex $instbox 1 1]]
      set poly [create_poly_rect -boundary [list [list $llx $lly] [list $urx $ury]]]
      if { $instHaloValue eq "0 0 0 0"} {
        set margin_l 0
        set margin_t 0
        set margin_r 0
        set margin_b 0
      } else {
          set margin_l [format "%.4f" [lindex $instHaloValue 0 ]]
          set margin_b [format "%.4f" [lindex $instHaloValue 1 ]]
          set margin_r [format "%.4f" [lindex $instHaloValue 2 ]]
          set margin_t [format "%.4f" [lindex $instHaloValue 3 ]]
      }
      set poly_bbox [resize_polygons -size [list $margin_l $margin_b $margin_r $margin_t] -objects $poly]
      set new_poly_bbox [compute_polygons -operation NOT -objects1  $poly_bbox -objects2 $poly]
      if { ($margin_l != 0) || ($margin_t != 0) || ($margin_r != 0) || ($margin_b != 0) } {
        foreach_in_collection new_poly [get_attribute $new_poly_bbox poly_rects] {
          create_placement_blockage -boundary $new_poly -type hard -name HALO_$i
          if {$row_cut==1} {
              #cut_row -within "$poly"
              #cut_row_within "$poly"
              #cut_row_within [get_attr [get_placement_blockage HALO_$i] bbox]
              cut_row_by_name PGCORE [get_attr [resize_polygons [get_placement_blockage HALO_$i] -size "0 $PGCORE_row_cut_resize_y"] bbox]
              cut_row_by_name GVGCORE [get_attr [get_placement_blockage HALO_$i] bbox]
              cut_row_by_name VGVCORE [get_attr [get_placement_blockage HALO_$i] bbox]
          }
          incr i 
        }
      }
      if {[info exists zhaMacroRegex] && [regexp $zhaMacroRegex [get_attri $macro ref_name]]} {
          puts "INFO: macro [get_object_name $macro]([get_attri $macro ref_name]) match zha pattern $params(-zhaMacro), set its blockage name to ZHA_MACRO_HALO, would not add extend blockage PITCH_* for it"
          set new_pb [create_placement_blockage -boundary $poly -type hard -name ZHA_MACRO_HALO_$i]
      } else {
          set new_pb [create_placement_blockage -boundary $poly -type hard -name MACRO_HALO_$i]
      }
      if {$row_cut==1} {
          #cut_row -within "$poly"
          #cut_row_within [get_attr [get_placement_blockage MACRO_HALO_$i] bbox]
          cut_row_by_name PGCORE [get_attr [resize_polygons $new_pb -size "0 $PGCORE_row_cut_resize_y"] bbox]
          cut_row_by_name GVGCORE [get_attr $new_pb bbox]
          cut_row_by_name VGVCORE [get_attr $new_pb bbox]
      }
      incr i 
      # sure rows are cut around halos by creating an additional overlapping placement obstruction.
    }
  }
  

  set i 0
  ### include user defined obstructions
  foreach_in_collection blockage [get_placement_blockages -quiet "MACRO_HALO*"] {
    set pb_bbox [get_attribute $blockage bbox]
    set pb_bbox \{$pb_bbox\}
    set macro [get_objects_by_location -quiet -classes cell -within [create_poly_rect -boundary $pb_bbox] -filter "is_hard_macro==true" ]
    if {![sizeof $macro]} {
        set macro [get_objects_by_location -quiet -classes cell -intersect [create_poly_rect -boundary $pb_bbox] -filter "is_hard_macro==true" ]
    }
    set instHaloValue [get_attribute $macro outer_keepout_margin_hard]
    regsub -all "\[{}]" $instHaloValue  "" instHaloValue
    if { $instHaloValue eq "0 0 0 0"} {
        set margin_l 0
        set margin_t 0
        set margin_r 0
        set margin_b 0

    } else {
        set margin_l [format "%.4f" [lindex $instHaloValue 0]]
        set margin_b [format "%.4f" [lindex $instHaloValue 1]]
        set margin_r [format "%.4f" [lindex $instHaloValue 2]]
        set margin_t [format "%.4f" [lindex $instHaloValue 3]]
    }
    set pb_bbox [get_attribute $blockage bbox]
    set haloLLX [expr [lindex [lindex $pb_bbox 0 ] 0 ] - $margin_l]
    set haloLLY [expr [lindex [lindex $pb_bbox 0 ] 1 ] - $margin_b]
    set haloURX [expr [lindex [lindex $pb_bbox 1 ] 0 ] + $margin_r]
    set haloURY [expr [lindex [lindex $pb_bbox 1 ] 1 ] + $margin_t]
    lappend boxList [list $haloLLX $haloLLY $haloURX $haloURY]
  }

  foreach box $boxList {

    # For some nodes the iniital blockage edge would not be always the keepout margin edge, therefore refine the OBS box here
    if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
        set obsLLX [lindex $box 0]; set obsLLY [lindex $box 1]
        set obsURX [lindex $box 2]; set obsURY [lindex $box 3]
        set to_snapOBSx1 [expr $obsLLX - $corex]; set to_snapOBSy1 [expr $obsLLY - $corey]
        set to_snapOBSx2 [expr $obsURX - $corex]; set to_snapOBSy2 [expr $obsURY - $corey]
        lassign [__snap_macro_blockage_helper $to_snapOBSx1 $to_snapOBSx2 $site_width] snapOBS_x1 snapOBS_x2
        lassign [__snap_macro_blockage_helper $to_snapOBSy1 $to_snapOBSy2 $row_height] snapOBS_y1 snapOBS_y2
        set newx1 [expr $corex + $snapOBS_x1]; set newx2 [expr $corex + $snapOBS_x2]
        set newy1 [expr $corey + $snapOBS_y1]; set newy2 [expr $corey + $snapOBS_y2]
        set box  [list $newx1 $newy1 $newx2 $newy2]
    }
    if { [llength [lindex $box 1] ] eq 1 } {
      set obsDBU(x1) [convert_to_dbu [lindex $box 0]]
      set obsDBU(y1) [convert_to_dbu [lindex $box 1]]
      set obsDBU(x2) [convert_to_dbu [lindex $box 2]]
      set obsDBU(y2) [convert_to_dbu [lindex $box 3]]
    } else {
      set obsDBU(x1) [convert_to_dbu [lindex $box 0 0]]
      set obsDBU(y1) [convert_to_dbu [lindex $box 0 1]]
      set obsDBU(x2) [convert_to_dbu [lindex $box 1 0]]
      set obsDBU(y2) [convert_to_dbu [lindex $box 1 1]]
    }

    ### snap left blockage edge
    # space between grid and left edge of blockage
    set deltaDBU [expr ($obsDBU(x1) - ($tileDBU(x1) + $offsetDBU)) % $pitchDBU]
    set x1DBU $obsDBU(x1)
    # make sure distance between snap grid and left edge of blockage is between min and max distance
    if {$deltaDBU > $maxDistDBU} {
      set x1DBU [expr $obsDBU(x1) - ($deltaDBU - $maxDistDBU)]
    } elseif {$deltaDBU < $minDistDBU} {
      set x1DBU [expr $obsDBU(x1) - ($deltaDBU + ($pitchDBU - $maxDistDBU))]
      }
          #puts "deltaDBU calculation"
    if {$x1DBU < $tileDBU(x1)} {
      set x1DBU $tileDBU(x1)
    }
 
    # create new obstruct between original obstruct and snap grid
    if {$x1DBU != $obsDBU(x1)} {

      if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
          set extX1 [convert_to_micron $x1DBU]
          set to_snapEXTx1 [expr $extX1 - $corex]
          lassign [__snap_macro_blockage_helper $to_snapEXTx1 0 $site_width] snapEXT_x1 snapEXT_x2
          set newEXTx1 [expr $corex + $snapEXT_x1]
          set x1DBU [convert_to_dbu $newEXTx1]
      }      
      set x1 [convert_to_micron $x1DBU]
      set y1 [convert_to_micron $obsDBU(y1)]
      set x2 [convert_to_micron $obsDBU(x1)]
      set y2 [convert_to_micron $obsDBU(y2)]
      #puts  [format "Info: Creating additional obstruction: (%0.3f,%0.3f)->(%0.3f,%0.3f)" $x1 $y1 $x2 $y2]
      puts   "create_placement_blockage -boundary {{$x1 $y1} { $x2 $y2}} -type hard -name PITCH_$i"
      eval "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH_$i"
      if {$row_cut==1} {
          #cut_row -within [list [list $x1 $y1] [list $x2 $y2]]
          #puts "cut_row_within {{ $x1 $y1} { $x2 $y2}}"
          #eval "cut_row_within {{ $x1 $y1} { $x2 $y2}}"
          puts "cut_row_by_name PGCORE {{ $x1 [expr $y1 - $PGCORE_row_cut_resize_y]} { $x2 [expr $y2 + $PGCORE_row_cut_resize_y]}}"
          eval "cut_row_by_name PGCORE {{ $x1 [expr $y1 - $PGCORE_row_cut_resize_y]} { $x2 [expr $y2 + $PGCORE_row_cut_resize_y]}}"
          puts "cut_row_by_name GVGCORE {{ $x1 $y1} { $x2 $y2}}"
          eval "cut_row_by_name GVGCORE {{ $x1 $y1} { $x2 $y2}}"
          puts "cut_row_by_name VGVCORE {{ $x1 $y1} { $x2 $y2}}"
          eval "cut_row_by_name VGVCORE {{ $x1 $y1} { $x2 $y2}}"
      }

      set i [expr $i + 1]
      set snapping_diff [expr $x2 - $x1]
      set snapping_total [expr $snapping_total + $snapping_diff]
      if {$snapping_diff >= $snapping_alert_dist} {
        puts "$params(severity): row snapping is too large: $snapping_diff, please check your ram placment on area: ($x1 $y1), ($x2 $y2)"

      } else {
        puts "Row snapping is : $snapping_diff"

      }
    }
    
    ### snap right blockage edge
    # space between grid and right edge of blockage
    set deltaDBU [expr ($obsDBU(x2) - ($tileDBU(x1) + $offsetDBU)) % $pitchDBU]
    if {$deltaDBU > 0} {
      set deltaDBU [expr $pitchDBU - $deltaDBU]
    }
    set x2DBU $obsDBU(x2)
    # make sure distance between right edge of blockage and the next snap grid is between min and max distance
        
    if {$deltaDBU > $maxDistDBU} {
      set x2DBU [expr $obsDBU(x2) + ($deltaDBU - $maxDistDBU)]
    } elseif {$minDistDBU > $deltaDBU} {
        set x2DBU [expr $obsDBU(x2) + ($deltaDBU + ($pitchDBU - $maxDistDBU))]
    }
    
    if {$x2DBU > $tileDBU(x2)} {
      set x2DBU $tileDBU(x2)
    }
    # create new obstruct between original obstruct and snap grid
    if {$x2DBU != $obsDBU(x2)} {

      if {[info exists P(FP_PLACE_MACROS_EVEN_CPP)] && $P(FP_PLACE_MACROS_EVEN_CPP) == 1} {
          set extX2 [convert_to_micron $x2DBU]
          set to_snapEXTx2 [expr $extX2 - $corex]
          lassign [__snap_macro_blockage_helper 0 $to_snapEXTx2 $site_width] snapEXT_x1 snapEXT_x2
          set newEXTx2 [expr $corex + $snapEXT_x2]
          set x2DBU [convert_to_dbu $newEXTx2]
      }      
      set x1 [convert_to_micron $obsDBU(x2)]
      set y1 [convert_to_micron $obsDBU(y1)]
      set x2 [convert_to_micron $x2DBU]
      set y2 [convert_to_micron $obsDBU(y2)]

      #puts  [format "Info: Creating additional obstruction: (%5.3f,%5.3f)->(%5.3f,%5.3f)" $x1 $y1 $x2 $y2]
      puts  "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH2_$i"
      eval "create_placement_blockage -boundary {{$x1 $y1} {$x2 $y2}} -type hard -name PITCH2_$i"
      if {$row_cut==1} {
          #cut_row -within [list [list $x1 $y1] [list $x2 $y2]]
          puts "cut_row_by_name GVGCORE {{$x1 $y1} {$x2 $y2}}"
          eval "cut_row_by_name GVGCORE {{$x1 $y1} {$x2 $y2}}"
          puts "cut_row_by_name VGVCORE {{$x1 $y1} {$x2 $y2}}"
          eval "cut_row_by_name VGVCORE {{$x1 $y1} {$x2 $y2}}"
          puts "cut_row_by_name PGCORE {{$x1 [expr $y1 - $PGCORE_row_cut_resize_y]} {$x2 [expr $y2 + $PGCORE_row_cut_resize_y]}}"
          eval "cut_row_by_name PGCORE {{$x1 [expr $y1 - $PGCORE_row_cut_resize_y]} {$x2 [expr $y2 + $PGCORE_row_cut_resize_y]}}"
      }


      set i [expr $i + 1]
      set snapping_diff [expr $x2 - $x1]
      set snapping_total [expr $snapping_total + $snapping_diff]
      if {$snapping_diff >= $snapping_alert_dist} {
        puts "$params(severity): row snapping is too large: $snapping_diff, please check your ram placment on area: ($x1 $y1), ($x2 $y2)"
      } else {
        puts "Row snapping is : $snapping_diff"

      }
    }
  }
  puts  "Row snapping total distances are: $snapping_total"
}

define_proc_attributes adjust_row_cuts_to_snap_grid_dfp -info "Read offset pitch maxDist minDist ignore" -define_args { \
    {-offset "The distance from the left edge of the tile to the first snap grid point in um" "" float required} \
    {-pitch "The snap grid pitch in um" "" float required } \
    {-maxDist "The maximum distance allowed between a blockage edge and the nearest non-overlapping snap grid in um" "" float required} \
    {-minDist "The minimum distance allowed between a blockage edge and the nearest non-overlapping snap grid in um" "" float optional } \
    {-zhaMacro "zero halo abutment macro ref name wildcard pattern" "" string optional} \
    {-severity "ALERT:Severity of warning reported if a row end is adjusted by more the 1/2 of the maxDist distance" "" string required } \
    {-ignore "Ignore cell pattern" "" string required} \
}



#######
## create placement blockage of a tile based on the $TILE_HALO param
## this is used in IcFpTileHalo target in floorplan stage

proc create_tile_halo { tile_halo } {
  if { $tile_halo != "0 0 0 0"} {
    puts "create_tile_halo with \"$tile_halo\" "
    if {[sizeof_collection [get_placement_blockages -quiet TILE_HALO_*]] > 0} {
     remove_placement_blockages [get_placement_blockages TILE_HALO_*]
    }
    set size ""
    foreach th $tile_halo {
      set size "$size -$th"
    }
    set core_poly  [get_attr [current_design ] boundary]
    set poly_bbox [resize_polygons -size "$size" -objects [create_poly_rect -boundary $core_poly]]
    set new_poly_bbox [compute_polygons -operation NOT -objects1 $core_poly -objects2 $poly_bbox]
    set i 0
    foreach_in_collection poly [split_polygon -output poly_rect -objects $new_poly_bbox] {  
      create_placement_blockage -boundary "$poly" -type hard -name TILE_HALO_$i
      cut_rows -within [get_attr [get_placement_blockage TILE_HALO_$i] bbox]
      incr i 
    }
  }
} 

proc pre_place_pins {horizontal_layers veritical_layers} {
    global TARGET_NAME
    global P
    global env
    
    if {! [info exists P]} {
	source "$env(FLOW_DIR)/util/ParamsDB.tcl"
    }
    
    # This section of code will place pins and mark them as fixed.
    # The COLDSTART_PLACE_*SIDE_PORTS params can be used to specify port sides. Eg.
    #
    # COLDSTART_PLACE_TOPSIDE_PORTS      = SSE CCLK
    # COLDSTART_PLACE_LEFTSIDE_PORTS     = Feedthru_R0*
    # COLDSTART_PLACE_RIGHTSIDE_PORTS    = Feedthru_R4*
    # COLDSTART_PLACE_BOTTOMSIDE_PORTS   = TstCcgEn
    #
    # Set COLDSTART_PLACE_PINS = 1 to enable pin placement
    #

    # Create pin blockages around tracks used by power grid to now create pin access issues
    set horizontal_list {}
    set veritical_list {}
    foreach temp $horizontal_layers {
	lappend horizontal_list $temp
    }
    foreach temp $veritical_layers {
	lappend veritical_list $temp
    }
    set layer_list [lsort -unique [concat $horizontal_list $veritical_list]]

    set allRoutingLayers [get_layers -quiet -filter "layer_type==interconnect"]

    # If layers are not user specified, use all routing layers between specified min and max layer
    if {[llength $layer_list] == 0} {
	foreach_in_collection rLayer $allRoutingLayers {
	    set minLayerNum [get_attribute [get_layers $P(OPTIMIZATION_MIN_ROUTING_LAYER)] mask_order_in_type]
	    set maxLayerNum [get_attribute [get_layers $P(OPTIMIZATION_MAX_ROUTING_LAYER)] mask_order_in_type]
	    set layerNum [get_attribute $rLayer mask_order_in_type]
	    set direction [get_attribute $rLayer routing_direction]
	    if {($layerNum > $minLayerNum) && ($layerNum < $maxLayerNum)} {
		lappend layer_list [get_attribute $rLayer full_name]
		if {$direction == "horizontal"} {
		    lappend horizontal_list [get_attribute $rLayer full_name]
		} else {
		    lappend veritical_list [get_attribute $rLayer full_name]
		}
	    }
	}
    }

    # Ensure that PG layers are removed from the layer list
    set allRoutingLayerNumList [get_attribute $allRoutingLayers mask_order_in_type]
    set sortedRoutingLayerNumList [lsort -increasing -integer $allRoutingLayerNumList]
    set sortedRoutingLayerList {}
    foreach layerNum $sortedRoutingLayerNumList {
	foreach_in_collection rLayer $allRoutingLayers {
	    set rlayerNum [get_attribute $rLayer mask_order_in_type]
	    if {$rlayerNum == $layerNum} {
		lappend sortedRoutingLayerList [get_attribute $rLayer full_name]
		continue
	    }
	}
    }
    #source_if_exists $P(NODE_DIR)/supra/templates/fc_shell/fx_fp_place_macros.tcl
    if {[info procs __pre_place_pins_pg_layers] != ""} {
        set PGLayerList [__pre_place_pins_pg_layers $sortedRoutingLayerList]
    } else {
        puts "Error: PG layers are not defined for this technology, not placing pins."
        return
    }

    foreach PGlayer $PGLayerList {
	if {[lsearch -exact $layer_list $PGlayer] != -1} {
	    set idx [lsearch -exact $layer_list $PGlayer]
	    set layer_list [lreplace $layer_list $idx $idx]
	}
    }

    puts "INFO: pin layer list = \'$layer_list\'"
    puts "INFO: horizontal layer list = \'$horizontal_list\'"
    puts "INFO: vertical layer list = \'$veritical_list\'"

    if {([regexp "^I2FpPreSyn.*" $TARGET_NAME] || [regexp "^FxFpPreSyn.*" $TARGET_NAME]) && ($P(COLDSTART_PARTIAL_DEF) == "1")} {
	if {[info exists P(POWER_NET_NAME)] && ($P(POWER_NET_NAME) != "")} {
	    set power_net_names [lsort -dictionary -unique $P(POWER_NET_NAME)]
	} else {
	    set power_net_names {}
	}
	if {[info exists P(GROUND_NET_NAME)] && ($P(GROUND_NET_NAME) != "")} {
	    set ground_net_names [lsort -dictionary -unique $P(GROUND_NET_NAME)]
	} else {
	    set ground_net_names {}
	}
	if {$power_net_names != "" && $ground_net_names != ""} {
	    set pot_pg_net_names [concat $power_net_names $ground_net_names]
	} else {
	    set pot_pg_net_names {}
	}
	if {[llength $pot_pg_net_names] > 0} {
	    set pg_net_names {}
	    foreach pg_net $pot_pg_net_names {
		if {[sizeof_collection [get_nets -quiet $pg_net]] > 0} {
		    lappend pg_net_names $pg_net
		}
	    }
	    if {[llength $pg_net_names] > 0} {
		removeExistingGrid [list $pg_net_names]
	    }
	}
	set all_cells [get_cells -quiet -filter "design_type==lib_cell"]
	set cells_outside 0
	set cells_within [get_objects_by_location -quiet -classes cell -filter "design_type==lib_cell" -within [get_attribute [get_core_area] bbox]]
	if {[sizeof_collection $all_cells] > 0} {
	    if {[sizeof_collection $all_cells] != [sizeof_collection $cells_within]} {
		set cells_outside 1
	    }
	}
	set unplaced_macs 0
	if {[sizeof_collection [get_cells -quiet -physical_context -filter "design_type==macro && is_fixed==false"]] > 0} {
	    set unplaced_macs 1
	}
	if {$cells_outside || $unplaced_macs} {
	    if {$unplaced_macs} {
		set_macro_constraints -allowed_orientations {N FN S FS} [get_cells -quiet -physical_context -filter "design_type==macro && is_fixed==false"]
		set_autoplace_macro_constraints
	    }
	    create_placement -floorplan -congestion
	}
    }

    set cur_core_area [get_attribute -objects [get_core_area] -name boundary]
    set core_x0 0
    set core_y0 0
    set core_x1 [lindex [lindex $cur_core_area 2] 0]
    set core_y1 [lindex [lindex $cur_core_area 2] 1]

    foreach layer $layer_list {
	set count 0
	set vias [get_vias -quiet -filter "(net_type == ground || net_type == power) && lower_layer_name == $layer"]
	
	if {[regexp $layer "$horizontal_list"]} {
	    echo "Horizontal $layer has [sizeof $vias] Vias "
	    foreach_in_collection via $vias {
		set via_name [get_object_name $via]
		set bbox [get_attribute [get_vias $via] bbox]
		set bbox_y0 [expr [lindex [lindex $bbox 0] 1] + 0.03]
		set bbox_y1 [expr [lindex [lindex $bbox 1] 1] - 0.03]
		create_pin_blockage -layers $layer -boundary [list [list ${core_x0} ${bbox_y0}]  [list ${core_x1} ${bbox_y1}]]  -name PINBLOCK_${layer}_${count}
		incr count
	    }
	} elseif {[regexp $layer "$veritical_list"]} {
	    echo "Vertical $layer has [sizeof $vias] Vias "
	    foreach_in_collection via $vias {
		set via_name [get_object_name $via]
		set bbox [get_attribute [get_vias $via] bbox]
		set bbox_x0 [expr [lindex [lindex $bbox 0] 0] + 0.08]
		set bbox_x1 [expr [lindex [lindex $bbox 1] 0] - 0.08]
		create_pin_blockage -layers $layer -boundary [list [list ${bbox_x0} ${core_y0}]  [list ${bbox_x1} ${core_y1}]]  -name PINBLOCK_${layer}_${count}
		incr count
	    }
	} else {
	    echo "VIA layer isnt found"
	}
    }

    set_block_pin_constraints -self -pin_spacing 2 -allowed_layers [get_layers $layer_list]

    if { [info exists P(COLDSTART_PLACE_TOPSIDE_PORTS)] && [llength $P(COLDSTART_PLACE_TOPSIDE_PORTS)] > 0  } {
	set coll_ports $P(COLDSTART_PLACE_TOPSIDE_PORTS)
	foreach_in_collection cur_port [get_ports $coll_ports] {
	    set_individual_pin_constraints -ports [get_object_name $cur_port] -sides 2
	    puts [get_object_name $cur_port]
	}
    }
    
    if {[info exists P(COLDSTART_PLACE_RIGHTSIDE_PORTS)] && [llength $P(COLDSTART_PLACE_RIGHTSIDE_PORTS)] > 0} {
	set coll_ports $P(COLDSTART_PLACE_RIGHTSIDE_PORTS)
	foreach_in_collection cur_port [get_ports $coll_ports] {
	    set_individual_pin_constraints -ports [get_object_name $cur_port] -sides 3
	    puts [get_object_name $cur_port]
	}
    }

    if {[info exists P(COLDSTART_PLACE_BOTTOMSIDE_PORTS)] && [llength $P(COLDSTART_PLACE_BOTTOMSIDE_PORTS)] > 0} {
	set coll_ports $P(COLDSTART_PLACE_BOTTOMSIDE_PORTS)
	foreach_in_collection cur_port [get_ports $coll_ports] {
	    set_individual_pin_constraints -ports [get_object_name $cur_port] -sides 4
	    puts [get_object_name $cur_port]
	}
    }
    
    if { [info exists P(COLDSTART_PLACE_LEFTSIDE_PORTS)] && [llength $P(COLDSTART_PLACE_LEFTSIDE_PORTS)] > 0  } {
	set coll_ports $P(COLDSTART_PLACE_LEFTSIDE_PORTS)
	foreach_in_collection cur_port [get_ports $coll_ports] {
	    set_individual_pin_constraints -ports [get_object_name $cur_port] -sides 1
	    puts [get_object_name $cur_port]
	}
    }
    
    puts "INFO: Placing pins"
    place_pins -self

    set ports [get_ports -quiet -filter {port_type != "power" && port_type != "ground"}]
    set terminals [get_terminals -quiet -of $ports]
    set_attribute $terminals physical_status fixed
    if {[sizeof_collection [get_pin_blockages -quiet PINBLOCK_*]] > 0} {
	remove_pin_blockages [get_pin_blockages -quiet PINBLOCK_*]    
    }

    if {([regexp "^I2FpPreSyn.*" $TARGET_NAME] || [regexp "^FxFpPreSyn.*" $TARGET_NAME]) && ($P(COLDSTART_PARTIAL_DEF) == "1")} {
        if {[sizeof_collection [get_placement_blockages -quiet autoplace_macro_keepout_*]] > 0} {
	    remove_placement_blockages [get_placement_blockages autoplace_macro_keepout_*]
        }
    }
}

proc set_autoplace_macro_constraints {} {
    global TARGET_NAME
    global P
    global env
    
    if {! [info exists P]} {
	source "$env(FLOW_DIR)/util/ParamsDB.tcl"
    }

    # Create placement blockages for macro keepaway
    if {[info exists P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)]} {
	if {[llength $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)] > 0} {
	    set valid_mka 0
	    if {[llength $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)] == 1} {
		set valid_mka 1
		set lka $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)
		set rka $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)
		set tka $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)
		set bka $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)
	    } elseif {[llength $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY)] == 4} {
		set valid_mka 1
		set lka [lindex $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY) 0]
		set tka [lindex $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY) 1]
		set rka [lindex $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY) 2]
		set bka [lindex $P(I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY) 3]
	    } else {
		puts "ERROR : \$I2_AUTOPLACE_MACROS_EDGE_KEEPAWAY must be <value> | <left top right bottom>"
	    }
	    if {$valid_mka} {
		set my_des_box [get_attribute [get_core_area] bbox]
		set dlx [lindex [lindex $my_des_box 0] 0]
		set dly [lindex [lindex $my_des_box 0] 1]
		set dux [lindex [lindex $my_des_box 1] 0]
		set duy [lindex [lindex $my_des_box 1] 1]
		# left edge
		set lx $dlx
		set ly $dly
		set ux [expr $dlx + $lka]
		set uy $duy
		create_placement_blockage -boundary "{{$lx $ly} {$ux $uy}}" -type hard_macro -name "autoplace_macro_keepout_left"
		# right edge
		set lx [expr $dux - $rka]
		set ly $dly
		set ux $dux
		set uy $duy
		create_placement_blockage -boundary "{{$lx $ly} {$ux $uy}}" -type hard_macro -name "autoplace_macro_keepout_right"
		# top edge
		set lx $dlx
		set ly [expr $duy - $tka]
		set ux $dux
		set uy $duy
		create_placement_blockage -boundary "{{$lx $ly} {$ux $uy}}" -type hard_macro -name "autoplace_macro_keepout_top"
		# bottom edge
		set lx $dlx
		set ly $dly
		set ux $dux
		set uy [expr $dly + $bka]
		create_placement_blockage -boundary "{{$lx $ly} {$ux $uy}}" -type hard_macro -name "autoplace_macro_keepout_bottom"
	    }
	}
    }

    # Specify min spacing between macros
    if {[info exists P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)]} {
	set vert_margin 0
	set horiz_margin 0
	if {[llength $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)] == 1} {
	    set vert_margin $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)
	    set horiz_margin $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)
	} elseif {[llength $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)] == 2} {
	    set vert_margin [lindex $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN) 0]
	    set horiz_margin [lindex $P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN) 1]
	} else {
	    puts "ERROR : \$I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN set with an invalid keepout margin value of \'$P(I2_AUTOPLACE_MACROS_KEEPOUT_MARGIN)\'"
	}
	set cmd "set_app_options -list {plan.macro.spacing_rule_heights {0um ${vert_margin}um} plan.macro.spacing_rule_widths {0um ${horiz_margin}um}}"
	eval $cmd
    }

    if {([regexp $TARGET_NAME "^I2FpPreSyn.*"] || [regexp $TARGET_NAME "^FxFpPreSyn.*"]) && ($P(COLDSTART_PARTIAL_DEF) == "1")} {
	set_app_options -list {plan.macro.macro_place_only true}
	set_app_options -list {plan.macro.cross_block_connectivity_planning soft}
	set_app_options -list {plan.place.congestion_driven_mode both}
    }
}

proc check_fixed_macro_placement {} {
    global TARGET_NAME
    global P
    global env
    
    if {! [info exists P]} {
	source "$env(FLOW_DIR)/util/ParamsDB.tcl"
    }
    
    set all_fixed_macs [get_cells -quiet -physical_context -filter "design_type==macro && is_fixed==true"]
    set fixed_macs_within_tile [get_objects_by_location -quiet -classes cell -filter "design_type==macro && is_fixed==true" -within [get_attribute [current_block] boundary]]
    if {[sizeof_collection $all_fixed_macs] > 0} {
	if {[sizeof_collection $all_fixed_macs] != [sizeof_collection $fixed_macs_within_tile]} {
	    puts "ERROR : [expr [sizeof_collection $all_fixed_macs] - [sizeof_collection $fixed_macs_within_tile]] macros with fixed placement are placed outside of the tile boundary"
	    set fixed_macs_outside_tile [remove_from_collection $all_fixed_macs $fixed_macs_within_tile]
		foreach_in_collection mac $fixed_macs_outside_tile {
		    puts "INFO : [get_attribute $mac full_name] is placed outside of the tile boundary"
		}
	}
    }
}

#>>>> ORIGINAL //depot/tools/aticad/1.0/flow/TileBuilder/supra/templates/icc2_shell/i2_fp_place_macros.tcl#43
#==== THEIRS //depot/tools/aticad/1.0/flow/TileBuilder/supra/templates/icc2_shell/i2_fp_place_macros.tcl#51

proc create_dual_height_rows { } {
    global P
    global env

  set rows [get_site_rows -quiet -filter "site_name == unit"]
  if { [sizeof_collection $rows] <= 0 && [info exists P(NDM_KEEP_SITE_NAME)]} {
    set rows [get_site_rows -quiet -filter "site_name == $P(NDM_KEEP_SITE_NAME)"]
  }
  if { [sizeof_collection $rows] <= 0} {
    set rows [get_site_rows -quiet -filter "site_name == core"]
  }
  if { [sizeof_collection $rows] <= 0} {
    set rows [get_site_rows -quiet -filter "site_name == CORE"]
  }
  if {[sizeof_collection $rows] == 0} {
      set rows [get_site_rows]
  }

  set llySorted [lsort -real -unique [get_attribute [get_site_rows $rows] bbox_lly]]
  set y1 [lindex $llySorted 0]
  set first_unit_row_orientation "dummy"
  foreach_in_collection ss $rows {
     set lly [get_attribute $ss bbox_lly]
     if { $lly == $y1} {
          set first_unit_row_orientation [get_attribute $ss site_orientation]
          set site_height [get_attribute $ss site_height]
     }
  }
  puts "INFO: first unit site orientation is $first_unit_row_orientation.  First row yoffset is $y1 ..."

   set GVGCORE_offset 0
   set VGVCORE_offset 0
   if { $first_unit_row_orientation == "MX" } {
      ## first row has vdd at bottom and gnd on top, so overlap with VGV
      set VGVCORE_offset 0
      set GVGCORE_offset $site_height
   } elseif { $first_unit_row_orientation == "R0"} {
      set GVGCORE_offset 0
      set VGVCORE_offset $site_height
   } else {
      puts "ERROR: Cannot understand the orientation of the first row $first_unit_row_orientation"
      return 0
   }

   #set x1 [lindex [get_attribute [get_core_area] bbox] 0 0]
   #set y1 [lindex [get_attribute [get_core_area] bbox] 0 1]
   #set x2 [lindex [get_attribute [get_core_area] bbox] 1 0]
   #set y2 [lindex [get_attribute [get_core_area] bbox] 1 1]


   puts "Creating dual height rows VGVCORE "
   puts "Calling create_site_array -site VGVCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true  -core_offset {0 $VGVCORE_offset} -y_margin 0 -name VGV -flip_alternate_row true ..."
   
   create_site_array -site VGVCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true  -core_offset "0 $VGVCORE_offset" -y_margin 0 -name VGV -flip_alternate_row false -flip_first_row true -aligned false

   puts "Creating dual height rows GVGCORE "
   puts "Calling create_site_array -site GVGCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true -core_offset {0 $GVGCORE_offset} -y_margin 0 -name GVG -flip_alternate_row false ..."
   create_site_array -site GVGCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true -core_offset "0 $GVGCORE_offset" -y_margin 0 -name GVG -flip_alternate_row false -aligned false
}

#Proc Used to ad PGRows with given Y pitch and Y offset
#PGCORE site type has to exist in library
#GF14 library has this added
#proc addPGrows { PGpitch } {
proc addPGrows { } {
    global P
    global env
    global TARGET_NAME
    set ofile [open rpts_uncompressed/${TARGET_NAME}/extraPGCore.txt w+]    

    set unitSiteName $P(DFP_PLACE_PG_ROWTYPE)
    set PGCORE_site_height [get_attribute [get_site_defs PGCORE] height]
    ## get unit site row height
    set unit_site_height    [get_attribute [get_site_defs unit] height]
    set unit_site_width     [get_attribute [get_site_defs unit] width]
    set coreLly [lindex [get_attribute [get_core_area] bbox] 0 1]

    set rows [get_site_rows -filter "site_name==core||site_name==unit||site_name==TS07_DST||site_name==TS06_DST"]
    set first_unit_row_orientation [get_attribute [index_collection [sort_collection $rows bbox_lly] 0] site_orientation]

    puts "INFO: first unit site orientation is $first_unit_row_orientation"

    set pattern "gpulite"
    if {[info exists P(DFP_GRID_PATTERN)] && $P(DFP_GRID_PATTERN) != ""} {
        foreach field $P(DFP_GRID_PATTERN) {
	    if {[regexp {(\w+):(\w+)} $field pat area pattern]} {
	        if {$area=="SCOPE"} {
		   break
		}
	    }
	}
    }
    if {$pattern == "gpulite"} {
	set M10PitchInRows 6.0
    } else {
	set M10PitchInRows 4.0
    }
    set m10_pitch [expr $M10PitchInRows*$unit_site_height]
    if {$pattern == "gpulite"} {
        if { $first_unit_row_orientation == "R0"} {
            set init_offset [expr 4*$unit_site_height]
        } else {
            set init_offset [expr 3*$unit_site_height]
        }
    } else {
        if { $first_unit_row_orientation == "R0"} {
            set init_offset [expr 4*$unit_site_height]
        } else {
            set init_offset [expr 5*$unit_site_height]
        }
    }
    set PGCORE_offset [expr $init_offset + $m10_pitch]

    if {[info exists P(DFP_PGCORE_OFFSET)] && $P(DFP_PGCORE_OFFSET)!= ""} {
        set PGCORE_offset $P(DFP_PGCORE_OFFSET)
    }

    set PGPitchInRows [getPGCorePitchRowCount]
    set PGPitchInRows [expr ceil($PGPitchInRows/$M10PitchInRows)*$M10PitchInRows]
    puts "Final PGCORE row pitch: $PGPitchInRows"
    set PGpitch [expr $PGPitchInRows * $unit_site_height]
    set PGpitch [expr $PGpitch - $PGCORE_site_height]

    puts "Creating quad height rows PGCORE "
    puts "Calling create_site_array -site PGCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true -core_offset {0 $PGCORE_offset} -y_margin $PGpitch -name PGCORE -flip_alternate_row false -aligned false..."
  
    create_site_array -site PGCORE  -boundary [get_attribute [get_core_area] boundary] -transparent true -core_offset "0 $PGCORE_offset" -y_margin $PGpitch -name PGCORE -flip_alternate_row false -aligned false

    set origPg [get_site_rows -quiet -filter "site_name==PGCORE"]   

    set macro_blockages [get_placement_blockages]   
    set channel_width $P(DFP_PLACE_CHANNEL_WIDTH)
    set_app_options -name place.floorplan.sliver_size -value ${channel_width}um
    derive_placement_blockages
    set channel_blockage [get_placement_blockages -quiet -filter "is_derived==true"]
    set_attribute $channel_blockage blockage_type hard

    if { [sizeof_collection $channel_blockage] < 1} {
        puts "No thin channels found ..."
        return
    }
    set core_poly [create_geo_mask -objects [create_poly_rect -boundary [get_attribute [get_core_area] boundary]]]
    if {[regexp {14} $P(TECHNO_NAME)]} {
        set rows [get_site_rows]
    } else {
        set rows [compute_polygons -operation not -objects1 $core_poly -objects2 $macro_blockages]
    }
    set channel_rows_anded [compute_polygons -operation and -objects1 $rows -objects2 $channel_blockage]
    if {[get_attribute $channel_rows_anded is_empty] == "true"} {
        puts "INFO: No thin channel having rows. All channels bboxes: [get_attribute $channel_blockage bbox]."
	return
    }
    remove_placement_blockage $channel_blockage
    set bad_boxes_split [split_polygons -objects $channel_rows_anded -output poly_rect -split vertical]
    if {[sizeof $bad_boxes_split] == 1} {
        set bad_boxes [list [get_attribute $bad_boxes_split bbox]]
    } else {
        set bad_boxes [get_attribute $bad_boxes_split bbox]
    }
    set horizontal_chan {}
    foreach bbox $bad_boxes {
        foreach {x1 y1} [lindex $bbox 0] {}
        foreach {x2 y2} [lindex $bbox 1] {}
	if { [expr abs($x2-$x1)] > [expr abs($y2-$y1)] && [expr abs($y2-$y1)] > 1.2 && [expr abs($x2-$x1)] > 10.0} {
	    lappend horizontal_chan $bbox
	}
    }
    if {[llength $horizontal_chan] == 0} {
        puts "INFO : No thin horizontal channels found"
	return
    }
    set horizontal_chan_geo [create_geo_mask -objects $horizontal_chan]
    set horizontal_chan_grown [reSizeGeoMask horizontal_chan_geo "$channel_width 0"]
    set horizontal_chan_merged [reSizeGeoMask horizontal_chan_grown "-$channel_width 0"]
    set bad_boxes_split2 [split_polygons -objects $horizontal_chan_merged -output poly_rect]
    if {[sizeof $bad_boxes_split2] == 1} {
        set bad_boxes2 [list [get_attribute $bad_boxes_split2 bbox]]
    } else {
        set bad_boxes2 [get_attribute $bad_boxes_split2 bbox]
    }
    set horizontal_chan_filter {}
    foreach bbox $bad_boxes2 {
        foreach {x1 y1} [lindex $bbox 0] {}
        foreach {x2 y2} [lindex $bbox 1] {}
	if { [expr abs($y2-$y1)] >= 1.92} {
	    set skip 0
	    foreach bbox_n $bad_boxes2 {
		foreach {x1_n y1_n} [lindex $bbox_n 0] {}
		foreach {x2_n y2_n} [lindex $bbox_n 1] {}
		if { [expr $y1 == $y2_n] || [expr $y2 == $y1_n] } {
		    if {[expr abs($x2 - $x1)] > [expr abs($x2_n - $x1_n)]} {
		        set skip 1
			lappend horizontal_chan_filter $bbox
		    } elseif {[expr abs($x2_n - $x1_n)] > [expr abs($x2 - $x1)] && [expr abs($y2_n-$y1_n)] >= 1.92} {
		        set skip 1
			lappend horizontal_chan_filter $bbox_n
		    }
		}
	    }
	    if {$skip == 0} {
	  	lappend horizontal_chan_filter $bbox
	    }
	}
    }
    if {[llength $horizontal_chan_filter] == 0} {
        puts "INFO : No thin horizontal channels found"
	return
    }
    set channels_final [create_geo_mask -objects $horizontal_chan_filter]
    set bad_boxes_split_final [split_polygons -objects $channels_final -output poly_rect -split vertical]
    if {[sizeof $bad_boxes_split_final] == 1} {
        set bad_boxes_final [list [get_attribute $bad_boxes_split_final bbox]]
    } else {
        set bad_boxes_final [get_attribute $bad_boxes_split_final bbox]
    }
    set cnt 0   
    foreach bbox $bad_boxes_final {
        foreach {x1 y1} [lindex $bbox 0] {}
        foreach {x2 y2} [lindex $bbox 1] {}
	if { [expr abs($x2-$x1)] > [expr abs($y2-$y1)] } {
	    set search_bbox [list [list [expr $x1 + $unit_site_width] [expr $y1 - $unit_site_height]] [list [expr $x2 - $unit_site_width] [expr $y2 + $unit_site_height]]]
	    set blockage_intersect [get_placement_blockages -quiet -intersect $search_bbox -filter "blockage_type==hard"]
	    if {![sizeof $blockage_intersect]} { continue }
	    set rows [get_site_rows -quiet -intersect $bbox  -filter "bbox_lly >= [expr $y1 + $unit_site_height] && bbox_ury <= [expr $y2 - $unit_site_height] && site_name==PGCORE"]
    	    append_to_collection rows [get_site_rows -quiet -within $bbox  -filter "bbox_lly >= [expr $y1 + $unit_site_height] && bbox_ury <= [expr $y2 - $unit_site_height] && site_name==PGCORE"]

	    if { $rows == ""} {
        	set existingSites [get_site_rows -filter "site_name==$unitSiteName" -intersect $bbox] 
        	set llySorted [lsort -real -unique [get_attribute [get_site_rows $existingSites] bbox_lly]]

        	set first_unit_row_lly [lindex $llySorted 0]
        	if { $first_unit_row_lly < $y1} {
           	    set first_unit_row_lly [lindex $llySorted 1]
        	}
        	foreach_in_collection ss $existingSites {
            	    set lly [get_attribute $ss bbox_lly]
            	    if { $lly == $first_unit_row_lly} {
                  	set first_unit_row_orientation [get_attribute $ss site_orientation]
                  	#Below is done to make sure we do not have small gaps between PGCORE and CORE sites at the edge of the design.  This causes power grid DRCs
                  	set x1_p [get_attribute $ss bbox_llx]
                  	set x2_p [get_attribute $ss bbox_urx]
                  	set z1 [expr abs($x1_p - $x1)]
                  	set z2 [expr abs($x2_p - $x2)]
                  	puts "z1 $z1 z2 $z2 x1 $x1 x2 $x2 x1_p $x1_p x2_p $x2_p"
                  	if { [expr abs($x1_p - $x1)] < 1} {
                     	    puts "#INFO restting x1 to match CORE row edge $x1_p ..."
                     	    set x1 [expr $x1_p - 0.001]
                  	}
                  	if { [expr abs($x2_p - $x2)] < 1} {
                     	    puts "#INFO restting x2 to match CORE row edge $x2_p ..."
                     	    set x2 [expr $x2_p + 0.001]
                  	}
            	    }
        	}
        	set siteToBboxOffset [expr $first_unit_row_lly - $y1]
        	set y $first_unit_row_lly
		set init_lly [expr $coreLly + $init_offset]
		set pgcore_y [expr $init_lly + int([expr $y -$init_lly]/$m10_pitch) *$m10_pitch + $m10_pitch]
		set diff1 [expr $pgcore_y - $y]
		if {[expr $diff1 < 2*$unit_site_height]} {
		    set pgcore_y [expr $pgcore_y + $m10_pitch]
		}
		set diff2 [expr $y2- $pgcore_y]
		if {[expr $diff2 < 6*$unit_site_height]} {
		    puts "ERROR : No valid VSS stripe for PGCORE in this channel $x1 $y1 $x2 $y2"
		    puts "#Skipped channel  $bbox ..."
		    continue
		}
		set bOffset [expr $pgcore_y - $y1]
        	set bbox_new [list [list [expr ceil ($x1/$unit_site_width)*$unit_site_width] $y1] [list [expr ceil ($x2/$unit_site_width)*$unit_site_width] $y2]]


	        puts "#INFO create_site_array -site PGCORE  -boundary $bbox_new -transparent true -core_offset {0 $bOffset} -y_margin 100000 -name PGCORE_extra_${cnt} -flip_alternate_row false -aligned false..."
		create_site_array -site PGCORE  -boundary $bbox_new -transparent true -core_offset "0 $bOffset" -y_margin 100000 -name PGCORE_extra_${cnt} -flip_alternate_row false -aligned false
		incr cnt
       	    }
      	}
    }

    set allPg [get_site_rows -quiet -filter "site_name==PGCORE"]
    set extraPg [remove_from_collection $allPg $origPg]
    foreach_in_collection pg $extraPg {
       puts $ofile "[get_attribute $pg bbox_lly]"
    }

    close $ofile
}


#==== YOURS //vega20-mikechen-dec27_015843-TileBuilder-11873/TileBuilder/supra/templates/icc2_shell/i2_fp_place_macros.tcl
proc add_bkg_over_mac {args} {
  parse_proc_arguments -args $args results
  set mac_refns $results(-mac_refns)
  set row_cut_halo ""
  puts "#INFO: Adding blockages over macros "

  if {$mac_refns != ""} {
    set 1siteWidth [get_attr [get_site_defs unit] width]; set 2siteWidth [expr $1siteWidth * 2]
   # set avoidAlso [getCellBboxOnGeoMask $mac_refns];
    set summedGeo [create_geo_mask]
    if {$1siteWidth == ""} {puts "Error: unit site is not defined, pls do check ...";return}
    #eergin doing one macro at a time as when macros abut we get polygons not rectangles so num poitns ends up being more than 4
    foreach mm $mac_refns {
      set avoidAlso [getCellBboxOnGeoMask $mm]

    foreach_in_collection polyRect [get_attribute $avoidAlso poly_rects] {
      set pp [get_attribute $polyRect point_list]
      if { [llength $pp] != 4} {
          puts "There are  [llength $pp] points in poly_rect cannot size skipping ..."
          continue
      }
      set width [expr abs([lindex $pp 0 0] - [lindex $pp 2 0])]
      set widthS [expr $width/$2siteWidth]
      set tmpGeo [create_geo_mask]
      #we are snapping x1/x2 to $2siteWidth regardless if the sram width is multiple of $2siteWidth
      #if {ceil($widthS) ne $widthS} {
      set x2 [expr [lindex  $pp 2 0]/$2siteWidth]
      set x1 [expr [lindex  $pp 0 0]/$2siteWidth]
      if { ceil($x2) ne $x2 } {
        set x2 [expr ceil ([lindex  $pp 2 0]/$2siteWidth) * $2siteWidth]
        puts "#INFO Snapping x2 $x2 was off cpp ..."
      } else {
        set x2 [lindex $pp 2 0]
      }

      if { ceil($x1) ne $x1 } {
        set x1 [expr floor ([lindex  $pp 0 0]/$2siteWidth) * $2siteWidth]
        puts "#INFO Snapping x1 $x1 was off cpp ..."
      } else {
        set x1  [lindex  $pp 0 0]
      }
      set width2 [expr abs($x2-$x1)]
      set width2S [expr $width2/$2siteWidth]
      if { ceil($width2S) ne $width2S } {
        set x2 [expr $x2 + $1siteWidth]
        puts "#INFO Increasing x2 by 1 cpp $x2 to make blockage multiple of 0.114 ..."
      }
      set width2 [expr abs($x2-$x1)]
      set bb [list [list $x1 [lindex $pp 0 1]] [list $x1 [lindex $pp 1 1]] [list $x2 [lindex $pp 2 1]] [list $x2 [lindex $pp 3 1]]]
      set tmpGeo [create_geo_mask $bb]
      #} else {
      #  set tmpGeo [create_geo_mask $pp]
      #}
      set summedGeo [compute_polygons -operation or -objects1 $tmpGeo -objects2 $summedGeo]
    }
   }
    # Get the left and right halo value to identify snapped blockage boundary
    set chosen_refn [lindex $mac_refns 0]
    set chosen_cell [index_collection [get_cells -hier -filter "ref_name == $chosen_refn"] 0]
    set outer_keepout [get_attri $chosen_cell outer_keepout_margin_hard]
    if {[llength $outer_keepout] != 4} {
       puts "ALERT: odd outer_keepout_margin_hard value. pls do check ..."
       return
    }
    if {[llength [lsort -unique $outer_keepout]] != 1} {
       puts "ALERT: multiple keepout values on [get_object_name $chosen_cell] is not equal. Not supported ..."
       return
    } else {
       set row_cut_halo [lindex $outer_keepout 0]
       puts "INFO: The retrived left/right halo value is $row_cut_halo"
    }
    if {$row_cut_halo!=""} {
       set avoidAlso [reSizeGeoMask summedGeo $row_cut_halo]
    } else {
       set avoidAlso [reSizeGeoMask summedGeo {0 0 0 0}]
    }
    foreach_in_collection polyRect [get_attribute $avoidAlso poly_rects] {
      set cmd "create_placement_blockage -type hard -boundary \{[get_attribute $polyRect point_list]\}"
      puts $cmd
      eval $cmd
    }
  }
}

define_proc_attributes add_bkg_over_mac \
-info "add hard blockage over normal macros for even multiples site width requirements" \
-define_args { \
  {-mac_refns "Specify the macro ref names that need hard blockage over" "string" list required} \
}

proc create_cmacs_bkg {cmacs} {
   set cellTypes [lsort -unique [get_attribute $cmacs ref_name]]
   array set _Thalo {}
   array set _Bhalo {}
   array set _Lhalo {}
   array set _Rhalo {}
   set cmds ""
   echo "Has [llength $cellTypes] types customed sram: $cellTypes"
   #set _Lhalo 0.0; set  _Rhalo 0.0
   foreach type $cellTypes {
      set _Lhalo($type) 0.00
      set _Rhalo($type) 0.00
      set _Bhalo($type) 0.96
      if {[string match crfps2ps* $type]} {
        set _Bhalo($type) 0.48
      }
      set h [get_attri [get_lib_cells -quiet */$type] height]
      set flag [expr int($h/0.24+0.5)%2]
      if {$flag} {set _Thalo($type) 0.72} else {set _Thalo($type) 0.96}
      if [sizeof [get_cells -quiet -hierarchical -filter "ref_name == $type && (orientation == R0 || orientation == MY)"]] {
         set cmd "create_keepout_margin -outer \{$_Lhalo($type) $_Bhalo($type) $_Rhalo($type) $_Thalo($type)\} \[get_cells -quiet -hierarchical -filter \{ref_name == $type && (orientation == R0 || orientation == MY)\}\]"
         lappend cmds $cmd
      }
      if [sizeof [get_cells -quiet -hierarchical -filter "ref_name == $type && (orientation == R180 || orientation == MX)"]] {
         set cmd "create_keepout_margin -outer \{$_Lhalo($type) $_Thalo($type) $_Rhalo($type) $_Bhalo($type)\} \[get_cells -quiet -hierarchical -filter \{ref_name == $type && (orientation == R180 || orientation == MX)\}\]"
         lappend cmds $cmd
      }
      if [sizeof [get_cells -quiet -hierarchical -filter "ref_name == $type && !defined(orientation)"]] {
         set cmd "create_keepout_margin -outer \{$_Lhalo($type) $_Bhalo($type) $_Rhalo($type) $_Thalo($type)\} \[get_cells -quiet -hierarchical -filter \{ref_name == $type && !defined(orientation)\}\]"
         lappend cmds $cmd
      }
   }
   puts "Started creating keepout margin for customed srams ..."
   if [llength $cmds] {
      foreach cmd $cmds {
         echo "Applying command: $cmd"
         eval $cmd
      }
   }
   puts "Stopped creating keepout margin for customed srams ..."
}

proc check_mac_list {} {
   global P
   global srams_list analogs_list
   if {! [info exists P]} {
      source "$env(FLOW_DIR)/util/ParamsDB.tcl"
   }
   if {$P(PERSONALITY) == "fcpnr"} {return}
   set all_macs [get_cells -quiet -physical_context -filter "design_type==macro"]
   set err_lst ""

   if {![sizeof_collection $all_macs]} {
      puts "No macro cell exists in this tile ..."
      return
   } else {
      set mac_types [lsort -unique [get_attribute $all_macs ref_name]]
   }
   
   if {[llength $srams_list] > 0} {
      foreach el $srams_list {
         if {[lsearch -exact $mac_types $el] != -1} {
            set idx [lsearch -exact $mac_types $el]
            set mac_types [lreplace $mac_types $idx $idx]
         } else {
            lappend err_lst $el
         }
      }
      if {[llength $err_lst] == [llength $srams_list]} {
         puts "ALERT: All ref names \"$srams_list\" specified in data/srams.list are not instantialized in design.(CHECKMAC_01)"
      } elseif [llength $err_lst] {
         puts "ALERT: These \"$err_lst\" rams are not instantialized in design.(CHECKMAC_02)"
      }
      set err_lst ""
   }

   if {[info exists P(DFP_CUSTOM_RAM_PATTERN)] && $P(DFP_CUSTOM_RAM_PATTERN) != ""} {
      foreach ptn $P(DFP_CUSTOM_RAM_PATTERN) {
         append flt_str "ref_name =~ $ptn || "
      }
      set flt_str [string trim $flt_str " |"]
      set custom_srams_list [lsort -unique [get_attri [get_cells -q -hier -filter "design_type==macro && ($flt_str)"] ref_name]]
      if {[llength $custom_srams_list] > 0} {
         foreach el $custom_srams_list {
            if {[lsearch -exact $mac_types $el] != -1} {
               set idx [lsearch -exact $mac_types $el] 
               set mac_types [lreplace $mac_types $idx $idx]
            } else {
               lappend err_lst $el
            }
         }
         if {[llength $err_lst] == [llength $custom_srams_list]} {
            puts "ALERT: All ref names \"$custom_srams_list\" specified by DFP_CUSTOM_RAM_PATTERN are not instantialized in design.(CHECKMAC_01)"
         } elseif [llength $err_lst] {
             puts "ALERT: These \"$err_lst\" custom rams are not instantialized in design.(CHECKMAC_02)"
         }
      }
      set err_lst ""
   }

   if {[llength $analogs_list] > 0} {
      foreach el $analogs_list {
         if {[info exists custom_srams_list] && [lsearch -exact $custom_srams_list $el] != -1} {continue}
         if {[lsearch -exact $mac_types $el] != -1} {
            set idx [lsearch -exact $mac_types $el] 
            set mac_types [lreplace $mac_types $idx $idx]
         } else {
            lappend err_lst $el
         }
      }
      if {[llength $err_lst] == [llength $analogs_list]} {
         puts "ALERT: All ref names \"$analogs_list\" specified in data/analogs.list are not instantialized in design.(CHECKMAC_01)"
      } elseif [llength $err_lst] {
         puts "ALERT: These \"$err_lst\"  other macros are not instantialized in design.(CHECKMAC_02)"
      }
      set err_lst ""
   }
   if [llength $mac_types] {
      puts "ALERT: \"$mac_types\" typs macro cell are all not included in data/srams.list, data/analogs.list and DFP_CUSTOM_RAM_PATTERN. Pls do check ...(CHECKMAC_03)"
      return $mac_types
   }
}

proc get_macs {macs_list} {
   set FltStr ""

   foreach el $macs_list {
      append FltStr "ref_name == $el ||"
   }
   set FltStr [string trim $FltStr |]
   return [get_cells -hier -quiet -filter "$FltStr"]
}

######
# Snaps keepouts to even rows/sites to meet floorplanning reqs
proc create_snapped_keepout_margins { macros halo } {

    global P

    # always snap to even sites
    set site_width [expr [get_attr [get_site_defs unit] width] * 2]
    # snap to row height
    set row_height [get_attr [get_site_defs unit] height]

    foreach_in_collection macro $macros {
        set bbox [get_attribute -name boundary_bbox $macro]
        if {[llength $halo]==1 || ([llength $halo] != 2 && [llength $halo] != 4) } {
            set keepout_llx [expr [llx $bbox] - [lindex $halo 0]] ; set keepout_urx [expr [urx $bbox] + [lindex $halo 0]]
            set keepout_lly [expr [lly $bbox] - [lindex $halo 0]] ; set keepout_ury [expr [ury $bbox] + [lindex $halo 0]]
        } elseif {[llength $halo] == 2} {
            set keepout_llx [expr [llx $bbox] - [lindex $halo 0]] ; set keepout_urx [expr [urx $bbox] + [lindex $halo 0]]
            set keepout_lly [expr [lly $bbox] - [lindex $halo 1]] ; set keepout_ury [expr [ury $bbox] + [lindex $halo 1]]
        } elseif {[llength $halo] == 4} {
            set keepout_llx [expr [llx $bbox] - [lindex $halo 0]] ; set keepout_urx [expr [urx $bbox] + [lindex $halo 2]]
            set keepout_lly [expr [lly $bbox] - [lindex $halo 1]] ; set keepout_ury [expr [ury $bbox] + [lindex $halo 3]]
        }

        # recycle helper fn
        lassign [__snap_macro_blockage_helper $keepout_llx $keepout_urx $site_width] snap_llx snap_urx
        lassign [__snap_macro_blockage_helper $keepout_lly $keepout_ury $row_height] snap_lly snap_ury

        set llx_margin [expr [llx $bbox] - $snap_llx]; set urx_margin [expr $snap_urx - [urx $bbox]]
        set lly_margin [expr [lly $bbox] - $snap_lly]; set ury_margin [expr $snap_ury - [ury $bbox]]

        set cmd "create_keepout_margin -outer \{$llx_margin $lly_margin $urx_margin $ury_margin\} \[get_cells [get_attribute -name full_name $macro]\]"
        puts $cmd
        eval $cmd
    }
}

###### 
proc snap_macro_blockage {macs} {
    global P

    # always snap to even sites
    set site_width [get_attr [get_site_defs unit] width]
    # snap to row height
    set row_height [get_attr [get_site_defs unit] height]
    set row_height [expr $row_height * 2]

    # get the offset value in case core_area origin is not starting from (0, 0)
    set tilex [lindex [get_attri -objects [current_block] -name boundary_bbox] 0 0]
    set tiley [lindex [get_attri -objects [current_block] -name boundary_bbox] 0 1]
    set corex [lindex [get_attri [get_core_area] bbox] 0 0]
    set corey [lindex [get_attri [get_core_area] bbox] 0 1]
    set offsetx [expr ($corex - $tilex)]
    set offsety [expr ($corey - $tiley)]

    foreach_in_collection mac [get_cells -quiet $macs] {
        set keepout [get_keepout_margins -quiet -of_objects [get_cells -quiet $mac]]
        if {[sizeof $keepout]} {
            set keepout_boundary [get_attribute $keepout boundary]
            set keepout_poly_rects [create_poly_rect -boundary $keepout_boundary]
            set snap_keepout 1
            # split into rectangular sections if necessary
            if {[llength $keepout_boundary] > 4} {
                set keepout_poly_rects [split_polygons -split horizontal -output poly_rect -objects $keepout_poly_rects]
                set snap_keepout 0
            }

            foreach_in_collection keepout_poly_rect $keepout_poly_rects {
                set point_list [get_attribute $keepout_poly_rect point_list]
                puts "keepout bbox is $point_list"
                set x1 [llx $point_list]; set x2 [urx $point_list]
                set y1 [lly $point_list]; set y2 [ury $point_list]
                
                set to_snapx1 [expr $x1 - $tilex -$offsetx]
                set to_snapy1 [expr $y1 - $tiley - $offsety]
                set to_snapx2 [expr $x2 - $tilex - $offsetx]
                set to_snapy2 [expr $y2 - $tiley -$offsety]

                # snap to site
                lassign [__snap_macro_blockage_helper $to_snapx1 $to_snapx2 $site_width] snap_x1 snap_x2
                # snap to row
                lassign [__snap_macro_blockage_helper $to_snapy1 $to_snapy2 $row_height] snap_y1 snap_y2

                set newx1 [expr $tilex + $offsetx + $snap_x1] ; set newx2 [expr $tilex + $offsetx + $snap_x2]
                set newy1 [expr $tiley + $offsety + $snap_y1] ; set newy2 [expr $tiley + $offsety + $snap_y2]

                puts "INFO: keepout left side x1 $x1 snapped to $newx1 ..."
                puts "INFO: keepout right side x2 $x2 snapped to $newx2 ..."
                puts "INFO: keepout bottom side y1 $y1 snapped to $newy1 ..."
                puts "INFO: keepout top side y2 $y2 snapped to $newy2 ..."
                set outer_bbox "{{$newx1 $newy1} {$newx1 $newy2} {$newx2 $newy2} {$newx2 $newy1}}"
                set cmd "create_placement_blockage -boundary $outer_bbox"
                puts $cmd
                eval $cmd
                if {$snap_keepout == 1} {
                    remove_keepout_margins $keepout
                    set mac_bbox [get_attribute $mac boundary_bbox]
                    set llx_margin [expr [llx $mac_bbox] - $newx1]; set urx_margin [expr $newx2 - [urx $mac_bbox]]
                    set lly_margin [expr [lly $mac_bbox] - $newy1]; set ury_margin [expr $newy2 - [ury $mac_bbox]]

                    set cmd "create_keepout_margin -outer \{$llx_margin $lly_margin $urx_margin $ury_margin\} \[get_cells [get_attribute -name full_name $mac]\]"
                    puts $cmd
                    eval $cmd
                }
            }
        } else {
          puts "ALERT: no keepout found on the macros [get_object_name [get_cells -q $macs]]"
        }
    }
}

## This proc returns the snapped coordinates needed by snap_macro_blockage
# Snapping always increases the size of the blockage
proc __snap_macro_blockage_helper { point_1 point_2 quantized_distance } {
    if {$quantized_distance == 0} {
        puts "ERROR: Row height or site width cannot be zero. Check your floorplan for errors."
        return
    }
    set point_1_quotient [expr $point_1 / $quantized_distance]
    set point_2_quotient [expr $point_2 / $quantized_distance]

    set point_1 [expr floor($point_1_quotient) * $quantized_distance]
    set point_2 [expr ceil($point_2_quotient) * $quantized_distance]

    return [list $point_1 $point_2]
}
#######

proc separate_crams {crams} {
    set unit_tile_width [get_attribute [get_site_defs unit] width]
    set pin_left_macros []
    set pin_right_macros []
    foreach_in_collection macro $crams {
        set llx [get_attribute $macro bbox_llx]
        set urx [get_attribute $macro bbox_urx]
        set signal_terminals [get_terminals -of [get_pins -of $macro -filter "port_type==signal"]]
        set sterm [index_collection $signal_terminals 0]
        set sterm_bbox [get_attribute $sterm bbox]
        set sterm_llx [lindex $sterm_bbox 0 0]
        set sterm_urx [lindex $sterm_bbox 1 0]
        set left_delta [expr abs($sterm_llx-$llx)]
        set right_delta [expr abs($sterm_urx-$urx)]
        if {$left_delta<$right_delta} {
            append_to_collection pin_left_macros $macro
        } else {
            append_to_collection pin_right_macros $macro
        }
    }
    set pin_left_macro_grow_right [create_geo_mask ]
    set pin_right_macro_grow_left [create_geo_mask ]
    if {[sizeof $pin_left_macros]>0} {
        set pin_left_macro_grow_right [resize_polygons -objects $pin_left_macros -size [list 0 0 $unit_tile_width 0]]
    }
    if {[sizeof $pin_right_macros]>0} {
        set pin_right_macro_grow_left [resize_polygons -objects $pin_right_macros -size [list $unit_tile_width 0 0 0]]
    }
    set abutting_macros {}
    set abutment [compute_polygons -operation and -objects1 $pin_left_macro_grow_right -objects2 $pin_right_macro_grow_left]
    if {![get_attribute $abutment is_empty]} {
        foreach_in_collection poly [get_attribute $abutment poly_rects] {
            set abutting_macro [get_objects_by_location -classes cell -intersect $poly]
            set ab_geo [create_geo_mask -objects $abutting_macro -merge]
            set ab_geo [resize_polygons -objects $ab_geo -size [list $unit_tile_width 0 0 0]]
            append_to_collection abutting_macros $abutting_macro
        }
    }
    set standalone_macros [remove_from_collection $crams $abutting_macros]
    set sa_left_macros [remove_from_collection $standalone_macros $pin_right_macros]
    set sa_right_macros [remove_from_collection $standalone_macros $pin_left_macros]
    return [list $abutting_macros $sa_left_macros $sa_right_macros]
}

proc convert_keepouts_to_bkgs {macs {type pode}} {
   puts "#INFO converting outer_keepout_margin_hard to blockages ..."
   set mPoly [create_geo_mask]
   set mList [get_cells $macs]
   foreach_in_collection macro $mList {
      set bb [get_attribute $macro outer_keepout_margin_hard -quiet]
      if { $bb != ""} {
       set size $bb
       set tempPoly [create_geo_mask -objects $macro]
       set cmd "set tempResized \[reSizeGeoMask tempPoly {$size}\]"
       eval $cmd
       set mPoly [compute_polygons -operation or -objects1 $tempResized -objects2 $mPoly]
      }
   }
   if {$type == "cpode"} {
       set unit_tile_width [get_attribute [get_site_defs unit] width]
       lassign [separate_crams $macs] ab_macros lsa_macros rsa_macros
       foreach_in_collection macro [get_cells -quiet "$ab_macros $lsa_macros"] {
          set bb [get_attribute $macro outer_keepout_margin_hard -quiet]
          if { $bb != ""} {
           set size $bb
           set tempPoly [create_geo_mask -objects $macro]
           set cmd "set tempResized \[reSizeGeoMask tempPoly {$size}\]"
           eval $cmd
           set tempResized [resize_polygons -objects $tempResized -size [list $unit_tile_width 0 0 0]]
           set mPoly [compute_polygons -operation or -objects1 $tempResized -objects2 $mPoly]
          }
       }
       foreach_in_collection macro [get_cells -quiet $rsa_macros] {
          set bb [get_attribute $macro outer_keepout_margin_hard -quiet]
          if { $bb != ""} {
           set size $bb
           set tempPoly [create_geo_mask -objects $macro]
           set cmd "set tempResized \[reSizeGeoMask tempPoly {$size}\]"
           eval $cmd
           set tempResized [resize_polygons -objects $tempResized -size [list 0 0 $unit_tile_width 0]]
           set mPoly [compute_polygons -operation or -objects1 $tempResized -objects2 $mPoly]
          }
       }
   }
 
   set bcnt 0
   foreach_in_collection polyRect [get_attribute $mPoly poly_rects] {
        create_placement_blockage -type hard -boundary [get_attribute $polyRect point_list]
        incr bcnt
   }
 
   puts "#INFO Created $bcnt placement blockages using outer_keepout_margin_hard to blockages ..."
}

proc add_sram_boundary_routing_blockage {} {
        global P
        set pattern "xxxxxx"
	catch {regexp {\((.+)\)} $P(PERL_PATTERN_CELL_IS_SRAM) tmp pattern} err
	set ram_pattern "$pattern.*/.*"
	set sram_lib_cells [get_lib_cells -regexp $ram_pattern]
	set sram_lib_cell_names [get_attribute $sram_lib_cells  name]

	foreach sram_ref_name $sram_lib_cell_names {                                                                                        
		set sram_instances [get_cells -hierarchical -quiet -filter "ref_name == $sram_ref_name"]                                                  
		append_to_collection  srams $sram_instances                                                                                          
	}

        foreach layer_blockage $P(ROUTE_SRAM_BOUNDARY_BLOCKAGES) {
	   regexp {(\S+)\s+(\S+)\s+(\S+)} $layer_blockage -> layer horizontal_blockage_width vertical_blockage_width

	   foreach_in_collection macro $srams {
		set macro_boundary [get_attribute $macro boundary]
		set macro_bound_poly [create_poly_rect -boundary $macro_boundary]
		
	        if { $layer == "M2"} {
		    #M2 : add routing blockage on 3 sides (except the side with pins)
		    set cw [get_attribute $macro width]
		    set left_box [resize_polygons -objects $macro_boundary -size "0 0 -[expr $cw/2] 0"]
		    set right_box [resize_polygons -objects $macro_boundary -size "-[expr $cw/2] 0 0 0"]  
		    if { [sizeof [get_objects_by_location  -classes {pin} -within [get_attribute $left_box bbox]]] > [sizeof [get_objects_by_location  -classes {pin} -within [get_attribute $right_box bbox]]]} {
			set outer_blockage_poly [resize_polygons -objects $macro_boundary -size "0 $vertical_blockage_width $horizontal_blockage_width $vertical_blockage_width"]
		    } else {
			set outer_blockage_poly [resize_polygons -objects $macro_boundary -size "$horizontal_blockage_width $vertical_blockage_width 0 $vertical_blockage_width"]
		    }	
		} else {
		    #M1 #M3 : add routing blockage on all 4 sides
		    set outer_blockage_poly [resize_polygons -objects $macro_boundary -size "$horizontal_blockage_width $vertical_blockage_width $horizontal_blockage_width $vertical_blockage_width"]  	     }
	       set rb_poly [compute_polygons -operation NOT -objects1 $outer_blockage_poly -objects2 $macro_bound_poly]
	       
	       # if M3 block the entire macro
	       if { $layer == "M3"} {
		   set rb_poly $outer_blockage_poly
	       }
	       foreach_in_collection rb_rect [get_attribute -quiet $rb_poly poly_rects] {
		   echo "[get_attribute $rb_rect bbox]"
		   create_routing_blockage -zero_spacing -boundary $rb_rect -layers $layer
	        }
	    }
	}
}

proc left_shift_list {listVar {count 1}} {
    upvar 1 $listVar l
    if {![info exists l]} {
        puts "AMD-Warning: left_shift_list variable could not be found"
    }
    if {![llength $l]} {puts "AMD-Warning... Empty"}
    set r [lrange $l 0 [incr count -1]]
    set l [lreplace $l [set l 0] $count]
    return $r
}

proc reinsert_macros_from_json {args} {
    global P
    global env
    global TARGET_NAME

    # Parse the args
    parse_proc_arguments -args ${args} results

    # Initialize the variables based on the args
    upvar 1 $results(-settings_name) dictMacros
    set dictMacros [dict create]
    set jsonFile $results(-jsonFile)

    # Ensure the json_loader has been sourced
    source "$env(FLOW_DIR)/lib/tcl/json/json_loader.tcl"

    # Populate the macros dictionary from the JSON
    if [regexp {\.gz$} $jsonFile] {
        if {[catch {open "|zcat $jsonFile" r} fh]} {
            puts "AMD-Error: Could not open gzipped JSON file $jsonFile!"
        }
    } else {
        if {[catch {open "$jsonFile" r} fh]} {
            puts "ERROR: Could not open JSON file $jsonFile!"
        }
    }
    set jsondata ""
    while {[gets $fh line] != -1} {
        append jsondata "$line"
    }
    close $fh
    if {[llength $jsondata] > 0} {
        set dictMacros [::json::json2dict $jsondata]
    }

    # Act on the data in the macros dictionary
    if {[dict size $dictMacros] > 0} {
        set instlist [lsort -unique [dict keys $dictMacros]]
    } else {
        set instlist [list ]
    }
    if {[llength $instlist] == 0} {
        puts "AMD-Warning: No macros to back-annotate"
    } else {
        #####################################################################
        # Iterate through the instance list to instantiate all macros
        #####################################################################
        for {set i 0} {$i < [llength $instlist]} {incr i} {
            set inst [lindex $instlist $i]
            set cell_name [dict get $dictMacros $inst cell]
            set verified_hier {}
            set hier [split $inst "/"]
            if {[sizeof_collection [get_lib_cell */$cell_name]] == 0} {
                puts "AMD-Error: Not creating \'$inst\' because no library/macro cell found for \'$cell_name\'"
                continue
            }
            while {[llength $hier] > 1} {
                if {![sizeof_collection [get_cell  -quiet ${verified_hier}[lindex $hier 0]]] > 0} {
                    puts "AMD-Info: CREATE HIER CELL : ${verified_hier}[lindex $hier 0]"
                    set design_name ${verified_hier}[lindex $hier 0]
                    regsub -all {\/} $design_name {_} design_name
                    puts "AMD-Info: create hierarchy: $design_name"
                    create_module $design_name
                    puts "AMD-Info: create hier cell: ${verified_hier}[lindex $hier 0] $design_name"
                    create_cell  ${verified_hier}[lindex $hier 0] $design_name
                }
                set verified_hier ${verified_hier}[left_shift_list hier]/
                regsub -all {\{|\}} $verified_hier {} verified_hier
            }
            if {[sizeof_collection [get_cells $inst]] == 0} {
                puts "AMD-Info: create leaf cell $inst $cell_name"
                set tmpcell [create_cell $inst [index_collection [get_lib_cell */$cell_name] 0]]
            } else {
                puts "AMD-Info: found leaf cell $inst"
                set tmpcell [get_cells $inst]
            }
            if {[dict exists $dictMacros $inst location]} {
                set x [lindex [split [dict get $dictMacros $inst location]] 0]
                set y [lindex [split [dict get $dictMacros $inst location]] 1]
                set orient [dict get $dictMacros $inst orientation]
                set halo [dict get $dictMacros $inst halo]
                set_cell_location -fixed -coordinates [list $x $y] -orientation $orient $tmpcell
                puts "AMD-Info: set location for $inst, $x, $y"
                if {![regexp {0\s*0\s*0\s*0} $halo]} {
                    puts "AMD-Info: Create halo for $inst: The halo width is \{$halo\} (left bottom right top)"
                    set cmd_halo "create_keepout_margin -type hard \[get_cells $inst \] -outer \{$halo\}"
                    eval $cmd_halo
                }
            }
        }
    }
}
define_proc_attributes reinsert_macros_from_json -info "Re-insert Macros from JSON" -define_args {
    { -settings_name  "Name of TCL dictionary to save all settings"  "dictMacros" string required}
    { -jsonFile       "JSON containing the macros data"              "jsonFile" string required }
}

proc getPGCorePitchRowCount { } {
    global P
    global env
    global TARGET_NAME
    global srams_list analogs_list

    ##################################################################################################
    # Begin script defaults                                                                          #
    ##################################################################################################
    set siteName "CORE"
    set restrictSitesByName 1
    set leftHaloDist 1
    set rightHaloDist 1
    set topHaloDist 3
    set bottomHaloDist 3
    ##################################################################################################
    # End script defaults                                                                            #
    ##################################################################################################

    #######################################################################
    # Finds the smallest site

    set smallestSite 0
    set smallestHeight 100
    puts "Checking for site definitions..."    
    puts "Found definitions for: [get_attribute [get_site_defs] name]."
    puts "The sites used in this project are:"
    # Iterate through all LEF definitions for this technology 
    foreach_in_collection site [get_site_defs] {
        set site_NAME [get_attribute $site name]
        if { [get_site_rows -quiet -filter "site_name==$site_NAME"] != "" } {
            puts "$site_NAME"
            if { [get_attribute $site height] < $smallestHeight } {
                set smallestHeight [get_attribute $site height]
                set smallestSite $site
            }    
        } 
    }
    if {$smallestSite != "" && $smallestSite != 0} {
        set siteName [get_attribute $smallestSite name]
        puts "Setting primary site (for placeable area calculation) as: $siteName."
    }
    #######################################################################

    set debugOutput 0
    set rowCount 0
    set obsCount 0

    set tileArea 0
    set rowArea 0
    set placeableRowArea 0
    set totalCellArea 0
    set stdCellArea 0
    set fixedStdcellArea 0
    set macroArea 0
    set fixedMacroArea 0
    set unfixedMacroArea 0
    set sramArea 0
    set analogArea 0
    set miscCellArea 0

    set physicalCellArea 0
    set totalDcapArea 0
    set totalPdfArea 0
    set totalTapArea 0
    set totalBoundaryArea 0
    set totalFillArea 0

    set physAreaByType(FILL) 0
    set physAreaByType(DCAP) 0
    set physAreaByType(PDF) 0
    set physAreaByType(TAP) 0
    set physAreaByType(BNDRY) 0

    set driveSeparator [string map {{\b} {}} [string trim $P(PERL_PATTERN_CELL_DRIVE_STR) "/"]]
    set fillPattern [string map {{\b} {}} [string trim $P(PERL_PATTERN_CELL_IS_FILL) "/"]]
    set dcapPattern [string map {{\b} {}} [string trim $P(PERL_PATTERN_CELL_IS_DCAP) "/"]]
    set fillPatternForPhysical "_FILL"
    set dcapPatternForPhysical "DCAP"
    set pdfdfiPattern "PDF_DFI"
    set boundaryPattern "_CAP"
    set tapPattern "TAP"

    set cellList {}
    set footPrintCellList {}
    set cellGroupList {}
    #array set cellGroupHash {}
    array set cellHash {}
    array set physHash {}
    array set footprintHash {}
    set footPrintRegexp [join [list {^(.*)} $driveSeparator {(.*)$}] ""]
    if {[info exists P(PERL_PATTERN_CELL_FOOTPRINT)]} {
        set footPrintRegexp $P(PERL_PATTERN_CELL_FOOTPRINT)
    }  

    set tileArea [compute_area [get_attribute -name boundary -objects [current_block]]]
    set core_bbox [get_attribute [current_block] core_area_bbox]
    set core_llx [lindex [lindex $core_bbox 0] 0]
    set core_lly [lindex [lindex $core_bbox 0] 1]
    set core_urx [lindex [lindex $core_bbox 1] 0]
    set core_ury [lindex [lindex $core_bbox 1] 1]
    set tileHeight [expr $core_ury - $core_lly]
    set tileWidth [expr  $core_urx - $core_llx]
    


    puts "\n##########################Started calculating std cell utilization################################"
    puts "\$Id: //depot/tools/aticad/1.0/flow/TileBuilder/supra/templates/fc_shell/fx_fp_place_macros.tcl#22 $"
    puts "##################################################################################################"
   
    set report_everything 1
    if {$report_everything} {
        puts "Info: not ignoring any cells in calculation"
    } else {
        puts "Info: Cells ignored for utilization calculation are: ${fillPattern}|${dcapPattern}|${pdfdfiPattern}"
    }
    puts "Info: Area units in square microns"

    set all_cells [get_cells -hier * -filter "is_hierarchical == false"]
    set all_cells_filtered [remove_from_collection $all_cells [get_cells -quiet -hier * -filter "design_type == cover"]]
    #
    # Calculate total areas for each cell and footprint type
    #
    foreach_in_collection instName $all_cells_filtered {
        set cellName [get_attribute $instName ref_name]
        # Cache physical cell type info for summary report
        if {! [info exists physHash($cellName,type)] && ! [info exists cellHash($cellName,type)] } {
            set cellWidth [get_attribute $instName width]
            set cellHeight [get_attribute $instName height]
            set cellArea [expr $cellWidth * $cellHeight]
            if {[regexp $fillPatternForPhysical $cellName]} {
                set physHash($cellName,type) "FILL"
                set physHash($cellName,size) $cellArea
            } elseif {[regexp $dcapPatternForPhysical $cellName]} {
                set physHash($cellName,type) "DCAP"
                set physHash($cellName,size) $cellArea
            } elseif {[regexp $pdfdfiPattern $cellName]} {
                set cellHash($cellName,type) "PDF"
                set physHash($cellName,size) $cellArea
            } elseif {[regexp $tapPattern $cellName]} {
                set physHash($cellName,type) "TAP"
                set physHash($cellName,size) $cellArea
            } elseif {[regexp $boundaryPattern $cellName]} {
                set physHash($cellName,type) "BNDRY"
                set physHash($cellName,size) $cellArea
            }
        }
        if {[info exists physHash($cellName,type)]} {
            set physAreaByType($physHash($cellName,type)) [expr $physAreaByType($physHash($cellName,type)) + $physHash($cellName,size)]
        }

        #
        # Check if celltype is part of ignore cells prefix list
        #
        if {! $report_everything && (
            [regexp $fillPattern $cellName] ||
            [regexp $dcapPattern $cellName] || 
            [regexp $pdfdfiPattern $cellName])} {
            continue
        }

        #
        # Cache cell info
        #
        if {! [info exists cellHash($cellName,type)]} {
            set cellWidth [get_attribute $instName width]
            set cellHeight [get_attribute $instName height]
            set cellHash($cellName,width) $cellWidth
            set cellHash($cellName,height) $cellHeight
            set cellHash($cellName,size) [expr $cellWidth * $cellHeight]
            set cellHash($cellName,count) 1
            set is_macro [get_attribute $instName is_hard_macro]
            set is_io [get_attribute $instName is_io]
            if {!$is_macro && !$is_io} {
                set cellType "Std"
                regsub $footPrintRegexp $cellName {\1} footPrintCellName
            } else {
                set cellType "Macro"
                puts "Macro cell Type: $cellName"
                set footPrintCellName $cellName
                # Type of macro?
                if { [lsearch $srams_list $cellName] != -1 } {
                    set cellMacroType "SRAM"
                } elseif { [lsearch $analogs_list $cellName] != -1 } {
                    set cellMacroType "ANALOG"
                } else {
                    set cellMacroType "OTHER"
                }
                set cellHash($cellName,macroType) $cellMacroType
            }
            set cellHash($cellName,footprint) $footPrintCellName
            set cellHash($cellName,type) $cellType
            lappend cellList $cellName
        } else {
            incr cellHash($cellName,count)
            set cellType $cellHash($cellName,type)
        }

        if {[get_attribute $instName is_fixed] == true} {
            if {$cellType == "Std"} {
                # set fixedStdcellArea [ expr $fixedStdcellArea + $cellHash($cellName,size) ]
            } elseif {$cellType == "Macro"} {
                set fixedMacroArea [ expr $fixedMacroArea + $cellHash($cellName,size) ]
                #
                # Consider placed macros bounding box as blockages
                #
                set instBox [get_attribute $instName boundary_bbox]
   
                set obsBoxX1($obsCount) [lindex [lindex $instBox 0] 0]
                set obsBoxY1($obsCount) [lindex [lindex $instBox 0] 1]
                set obsBoxX2($obsCount) [lindex [lindex $instBox 1] 0]
                set obsBoxY2($obsCount) [lindex [lindex $instBox 1] 1]
                incr obsCount
            }
        } elseif {$cellType == "Macro"} {
            set unfixedMacroArea [ expr $unfixedMacroArea + [expr [expr $cellHash($cellName,width) + $leftHaloDist + $rightHaloDist] * [expr $cellHash($cellName,height) + $topHaloDist + $bottomHaloDist] ] ]
        }
    }
    foreach cell $cellList {
        set cellArea [expr $cellHash($cell,count) * $cellHash($cell,size)]
        set cellHash($cell,area) $cellArea
        set totalCellArea [expr $totalCellArea + $cellArea]
        if {$cellHash($cell,type) == "Std"} {
            set stdCellArea [expr $stdCellArea + $cellArea]
        } elseif {$cellHash($cell,type) == "Macro"} {
            set macroArea [expr $macroArea + $cellArea]
            if {$cellHash($cell,macroType) == "SRAM"} {
                set sramArea [expr $sramArea + $cellArea]
            } elseif {$cellHash($cell,macroType) == "ANALOG"} {
                set analogArea [expr $analogArea + $cellArea]
            }
        } else {
            set miscCellArea [expr $miscCellArea + $cellArea]
        }
    }
    #
    # Parse all rows and populate row array with row boxes
    #
    #
    # Restrict rows accounted; Consider only with name of site $siteName
    #
    if {$restrictSitesByName == 1} {
        set allRows [get_site_rows -filter "site_name == $siteName || site_name == unit"]
    } else {
        set allRows [get_site_rows]
    }
    foreach_in_collection rowName $allRows {
        if {! [info exists siteWidth] } {
            set siteWidth [get_attribute $rowName site_space]
        }
        set rowBoxX1($rowCount) [get_attribute $rowName bbox_llx]
        set rowBoxY1($rowCount) [get_attribute $rowName bbox_lly]
        set rowBoxX2($rowCount) [get_attribute $rowName bbox_urx]
        set rowBoxY2($rowCount) [get_attribute $rowName bbox_ury]

        if {! [info exists rowBoxX1_min]  || $rowBoxX1_min > $rowBoxX1($rowCount)} {
            set rowBoxX1_min $rowBoxX1($rowCount)
        }

        set rowArea [expr $rowArea + [ expr [expr $rowBoxX2($rowCount) - $rowBoxX1($rowCount)] * [expr $rowBoxY2($rowCount) - $rowBoxY1($rowCount)] ] ]

        set rowStatus($rowCount) "YES"
        incr rowCount
    }
    if {! [info exists siteWidth]} {
        set siteWidth [get_attribute [get_core_area] tile_width]
    }
    #
    # Check for rowArea
    #
    if {$rowArea == 0} {
        puts "Error: Rows not found in design; Check if specified site name is correct in the header, incase restrictSitesByName is 1"
    }
    #
    # Parse all blockages
    #
    foreach_in_collection obsName [get_placement_blockages -quiet -filter "blockage_type == hard"] {
        set obsGeo [create_geo_mask -objects $obsName]
        set polygons [get_attri [split_polygons -objects $obsGeo] poly_rects]
        foreach_in_collection ply $polygons {
            set obsBox [get_attribute $ply bbox]
            set obsBoxX1($obsCount) [lindex [lindex $obsBox 0] 0]
            set obsBoxY1($obsCount) [lindex [lindex $obsBox 0] 1]
            set obsBoxX2($obsCount) [lindex [lindex $obsBox 1] 0]
            set obsBoxY2($obsCount) [lindex [lindex $obsBox 1] 1]
            incr obsCount
        }
    }
    
    # Cutting rows if overlapping with blockages
    #
    for {set i 0} {$i < $obsCount} {incr i} {
        for {set j 0} {$j < $rowCount} {incr j} {
            #
            # Checking for blockage overlapping the row in X or Y direction
            #
            if {($obsBoxY1($i) < $rowBoxY2($j)) && ($obsBoxY2($i) > $rowBoxY1($j)) && ($obsBoxX1($i) < $rowBoxX2($j)) && ($obsBoxX2($i) > $rowBoxX1($j)) && ($rowStatus($j) == "YES")} {
                if { ($rowBoxX1($j) >= $obsBoxX1($i)) && ($rowBoxX2($j) <= $obsBoxX2($i)) } {
                    #
                    # Row completely blocked
                    #
                    set rowStatus($j) "NO"

                } elseif { ($rowBoxX1($j) >= $obsBoxX1($i)) && ($rowBoxX2($j) > $obsBoxX2($i))} {
                    #
                    # Blockage is on left side of row
                    #
                    set rowBoxX1($j) $obsBoxX2($i)

                } elseif { ($rowBoxX1($j) < $obsBoxX1($i)) && ($rowBoxX2($j) <= $obsBoxX2($i))} {
                    #
                    # Blockage is on right side of the row
                    #
                    set rowBoxX2($j) $obsBoxX1($i)

                } elseif { ($rowBoxX1($j) < $obsBoxX1($i)) && ($rowBoxX2($j) > $obsBoxX2($i))} {
                    #
                    # Blockage is in the middle of the row
                    #
                    # Adding new row on right side of blockage
                    #
                    set rowBoxX1($rowCount) $obsBoxX2($i)
                    set rowBoxX2($rowCount) $rowBoxX2($j)
                    set rowBoxY1($rowCount) $rowBoxY1($j)
                    set rowBoxY2($rowCount) $rowBoxY2($j)
                    set rowStatus($rowCount) $rowStatus($j)
                    incr rowCount

                    #
                    # Modification of left segment of row
                    #
                    set rowBoxX2($j) $obsBoxX1($i)
                }
            }
        }
    }
    for {set i 0} {$i < $rowCount} {incr i} {
        if {$rowStatus($i) == "YES"} {
            set placeableRowArea [expr $placeableRowArea + [ expr [expr $rowBoxX2($i) - $rowBoxX1($i)] * [expr $rowBoxY2($i) - $rowBoxY1($i)] ] ]
        }
    }


# Reduce placeable area for unfixed macro cells and misc cells
    #
    if {$miscCellArea != 0} {
        puts "Info: Misc cells found, Placeable area reduced to account for these cells"
        set placeableRowArea [expr $placeableRowArea - $miscCellArea]
    }
    if {$unfixedMacroArea != 0} {
        puts "Info: Unfixed macro cells found, Placeable area reduced to account for these cells"
        puts "         Default halos of $leftHaloDist um on left, $rightHaloDist um on right, $topHaloDist um on top, $bottomHaloDist um on bottom considered for unfixed macro cells"
        set placeableRowArea [expr $placeableRowArea - $unfixedMacroArea]
    }
    if {$placeableRowArea == 0} {
        puts "ERROR: Placeable ROW Area is 0! Something is likely wrong with the floorplan!"
        return -1
    }
    puts "Placeable Row area is: $placeableRowArea"
    puts "Macro Area : $macroArea"
    set tileArea_woMacro [expr $tileArea - $macroArea]
    puts "TileArea: $tileArea"
    puts "TileArea without Macro : $tileArea_woMacro"

    set tileWidth_woMacro [expr $tileArea_woMacro/$tileHeight]
    set siteHeight  [ get_attribute  [get_site_defs -filter is_default] height]
    set PGCORE_singleRowArea [expr $tileWidth_woMacro*4*$siteHeight]
    set pgCell_rule_type_list $P(DFP_LDO_POWER_GATE_LIBCELL_AND_RULE_LIST)
    set pgCellList [split $pgCell_rule_type_list ":"]
    if  {[llength $pgCellList] == 6} {
        puts "This is PGCORE ONO type power gating"
        set currentDensity 4.02
    } else { 
        puts "This is DLDO type of power gating"
        set currentDensity 6.124
    }     
    set switchCurrent 0.00035

    set switchCellArea 1.423
    set tileCurrent [expr $currentDensity*$tileArea*1e-6]
    set switchCount [expr $tileCurrent/$switchCurrent]
    set switchArea [expr $switchCount*$switchCellArea]
    set PGCORE_RowArea [expr $switchArea/0.7]



    set PGCORE_RowCount [expr int($PGCORE_RowArea/$PGCORE_singleRowArea)]
    set PGCORE_RowPitch [expr $tileHeight/$PGCORE_RowCount]
    set PGCORE_RowPitchRowCount [expr int($PGCORE_RowPitch/$siteHeight)]
    if {[info exists P(DFP_PGCORE_SCALE)] && $P(DFP_PGCORE_SCALE)!= ""} {
            puts "As param DFP_PGCORE_SCALE exists, scaling the PGCORE row pitch"
            set PGCORE_RowPitchRowCount  [expr int($PGCORE_RowPitchRowCount*$P(DFP_PGCORE_SCALE))]
    }
    puts "PGCORE row pitch based on area calculation: $PGCORE_RowPitchRowCount"
    if {$PGCORE_RowPitchRowCount < 72} {
        set PGCORE_RowPitchRowCount 72
    } elseif {$PGCORE_RowPitchRowCount > 120 } {
        set PGCORE_RowPitchRowCount 120
    }

    set PGCORE_OverHead [expr 100*$PGCORE_RowArea/$tileArea]
    puts "PGOCRE row overhead based on calculation (before insertion of PGCORE rows): $PGCORE_OverHead"
    return $PGCORE_RowPitchRowCount
}

proc finetune_sniffer_cells { cells } {

    set unit_site_width [get_attribute [get_site_defs -filter is_default] width]
    set core_geo [create_geo_mask -objects [create_poly_rect -boundary [get_attribute [get_core_area] boundary]]]
    set blk_geo [create_geo_mask -objects [get_placement_blockages -quiet]]
    set core_bbox [get_attribute [get_core_area] bbox]
    set tile_width [expr [urx $core_bbox] - [llx $core_bbox]]

    foreach_in_collection cell $cells {
        set cell_geo [create_geo_mask -objects [get_cells -quiet $cell]]
        set tmp_check_geo [resize_polygon -objects $cell_geo -size "$tile_width 0"]
        set tmp_check_geo [compute_polygons -operation AND -objects1 $tmp_check_geo -objects2 $core_geo]
        set tmp_check_geo [compute_polygons -operation NOT -objects1 $tmp_check_geo -objects2 $blk_geo]
        set tmp_check_geo [split_polygons -split horizontal $tmp_check_geo -output geo_mask]
        set tmp_check_geo [compute_polygons -operation INTERSECT -objects1 $tmp_check_geo -objects2 $cell_geo]
        set check_geo [compute_polygons -operation NOT -objects1 $tmp_check_geo -objects2 $cell_geo]
  
        set poly_rects [split_polygons -split horizontal $check_geo -output poly_rect]
        set max_poly_width 0    
        set multiplier 1
        set fail_poly_cnt 0
        set poly_cnt [sizeof_collection $poly_rects]

        set poly_is_odd 1

        foreach_in_collection poly_rect $poly_rects {
            set cell_x [lindex [get_attribute $cell origin] 0]
            set poly_width [get_attribute $poly_rect width]
            set poly_is_odd [expr int([expr ($poly_width / $unit_site_width)]) % 2]
            if {! $poly_is_odd} {
                if {$poly_width > $max_poly_width} {
                    set max_poly_width $poly_width
                    set poly_llx [get_attribute $poly_rect bbox_llx]
                    if {$poly_llx < $cell_x} {
                        set multiplier -1
                    } else {
                        set multiplier 1
                    }
                }
            }
            incr fail_poly_cnt
        }

        if {$fail_poly_cnt != $poly_cnt} {
            puts "Error: Can not find a appropriate position to place sniffer cell [get_attribute $cell full_name], Need to check the floorplan for potential PO.R.15."
            return
        }
        if {! $poly_is_odd} {
            set original_physical_status [get_attribute $cell physical_status]
            set_attribute -quiet $cell physical_status placed
            set delta [expr $unit_site_width * $multiplier]
            echo "move_objects -delta \"$delta 0\" [get_attribute $cell full_name] -simple"
            move_objects -delta "$delta 0" $cell -simple
            snap_cell_mask_shift $cell
            set_attribute -quiet $cell physical_status $original_physical_status
        }
    }
}
proc create_blk_for_po_r_15_2 { args } {
  global po_r_15_2
  global iteration_po_r_15_2
  global index_vio_po_r_15_2
  global index_pb_po_r_15_2
  set geo_poly [split_polygons -objects $args -output geo_mask -split vertical]

  ## merge the vertical bbox with same Y coordinates
  foreach_in_collection geo_merge $geo_poly {
    set y1_split [lindex [get_attribute [get_attribute $geo_merge poly_rects] bbox] 0 1]
    set y2_split [lindex [get_attribute [get_attribute $geo_merge poly_rects] bbox] 1 1]
    append_to_collection vert_box(${y1_split}_$y2_split) $geo_merge
  }
  set geo_poly_fix ""
  foreach vert_each [array names vert_box] {
    if { [sizeof_collection $geo_poly_fix] == 0 } {
      set geo_poly_fix [create_geo_mask -objects $vert_box($vert_each) -merge]
    } else {
        foreach_in_collection vert_fix [get_attribute [create_geo_mask -objects $vert_box($vert_each) -merge] poly_rects] {
          append_to_collection geo_poly_fix [create_geo_mask -objects $vert_fix]
        }
    }
  }
  ## find po group < 10cpp
  foreach_in_collection geo_tmp $geo_poly_fix {
    set poly_tmp_width [get_attribute [get_attribute $geo_tmp poly_rects] width]
    if { $poly_tmp_width < $po_r_15_2 } {
      puts "AMD-Info: violated area $index_vio_po_r_15_2: [get_attribute [get_attribute $geo_tmp poly_rects] bbox]"
      if { [info exists geo_violated] } {
        append_to_collection geo_violated $geo_tmp
      } else {
          set geo_violated $geo_tmp
      }
      incr index_vio_po_r_15_2 1
    }
  }
  ## create placement blockage in violated area
  if { [info exists geo_violated] } {
    puts "AMD-Info: ITERATION $iteration_po_r_15_2"
    foreach_in_collection poly_fix_each [get_attribute $geo_violated poly_rects] {
      set poly_each_width [get_attribute $poly_fix_each width]
      set geo_fix_size [resize_polygons -objects $args -size [list [expr $poly_each_width * -1] 0]]
      set geo_fix_halo [compute_polygons -operation NOT -objects1 $args -objects2 $geo_fix_size]
      set geo_remove [compute_polygons -operation AND -objects1 [create_geo_mask -objects $poly_fix_each] -objects2 $geo_fix_halo]
      if { [get_att $geo_remove is_empty] } { 
        puts "Error: can't fix below area: [get_att $poly_fix_each bbox], skip"
        if { [info exists geo_remove_total] } {
            set geo_remove_total [compute_polygons -operation OR -objects1 $geo_remove_total -objects2 $poly_fix_each]
        } else {
            set geo_remove_total $poly_fix_each
        }
        #next
        continue
      }
      foreach_in_collection blk_fin [get_attribute $geo_remove poly_rects] {
        puts "AMD-Info: create placement blockage $index_pb_po_r_15_2 [get_attribute $blk_fin bbox]"
        create_placement_blockage -boundary [get_attribute $blk_fin bbox] -type hard -name "PB_${iteration_po_r_15_2}_${index_pb_po_r_15_2}_fixPO_R_15_2"
        incr index_pb_po_r_15_2 1
      }
      if { [info exists geo_remove_total] } {
        set geo_remove_total [compute_polygons -operation OR -objects1 $geo_remove_total -objects2 $geo_remove]
      } else {
          set geo_remove_total $geo_remove
      }
    }
    incr iteration_po_r_15_2 1
    set geo_update [compute_polygons -operation NOT -objects1 $args -objects2 $geo_remove_total]
    unset geo_violated geo_remove_total
    create_blk_for_po_r_15_2 $geo_update
  }
}
proc merge_blockage_small_space {pbkg_x pbkg_y} {
  set pbkg_x_half [expr double($pbkg_x) / 2]
  set geo_size_x [list $pbkg_x_half 0]
  set geo_shrk_x [list [expr $pbkg_x_half * -1] 0]
  
  set pbkg_y_half [expr double($pbkg_y) / 2]
  set geo_size_y [list 0 $pbkg_y_half]
  set geo_shrk_y [list 0 [expr $pbkg_y_half * -1]]
  
  set pb_all [get_placement_blockages -quiet *]
  if { [sizeof_collection $pb_all] > 0 } {
  	set geo_mask_pb [create_geo_mask [get_placement_blockages $pb_all]]
    set geo_kp [create_geo_mask [get_attribute [get_keepout_margins] boundary]]
    set geo_mask_pb [compute_polygons -operation OR -objects1 $geo_mask_pb -objects2 $geo_kp]
  	
  	set sized_geo_x [resize_polygons -objects $geo_mask_pb -size $geo_size_x]
  	set geo_mask_cp_x [create_geo_mask -objects $sized_geo_x -merge] 
  	set shrk_geo_x [resize_polygons -objects $geo_mask_cp_x -size $geo_shrk_x]
    set geo_x_final [compute_polygons -operation NOT -objects1 $shrk_geo_x -objects2 $geo_mask_pb]
  
  	set pb_name_suffix "_FixSpace"
  	set index_PB 0
    if { [sizeof_collection [split_polygons $geo_x_final]] > 0 } {
      foreach_in_collection geo_each [split_polygons $geo_x_final] {
        set boundary_pb [get_attribute [get_attribute $geo_each poly_rects] point_list]
  	    puts "AMD-Info: creating placement blockages \"PB_$index_PB${pb_name_suffix}_X$pbkg_x\" with boundary $boundary_pb"
  	    create_placement_blockage -boundary [get_attribute [get_attribute $geo_each poly_rects] point_list] -type hard -name "PB_$index_PB${pb_name_suffix}_X$pbkg_x"
  	    incr index_PB 1
  	  }
    }
  
    set geo_mask_pb_fix [compute_polygons -operation OR -objects1 $geo_mask_pb -objects2 $geo_x_final]
    set sized_geo_y [resize_polygons -objects $geo_mask_pb_fix -size $geo_size_y]
    set geo_mask_cp_y [create_geo_mask -objects $sized_geo_y -merge]
    set shrk_geo_y [resize_polygons -objects $geo_mask_cp_y -size $geo_shrk_y]
    set geo_y_final [compute_polygons -operation NOT -objects1 $shrk_geo_y -objects2 $geo_mask_pb_fix]
  
    if { [sizeof_collection [split_polygons $geo_y_final]] > 0 } {
      foreach_in_collection geo_each_fix [split_polygons $geo_y_final] {
        set boundary_pb_fix [get_attribute [get_attribute $geo_each_fix poly_rects] point_list]
        puts "AMD-Info: creating placement blockages \"PB_$index_PB${pb_name_suffix}_Y$pbkg_y\" with boundary $boundary_pb_fix"
        create_placement_blockage -boundary [get_attribute [get_attribute $geo_each_fix poly_rects] point_list] -type hard -name "PB_$index_PB${pb_name_suffix}_Y$pbkg_y"
        incr index_PB 1
      }
    }
  
  } else {
      puts "AMD-Info: No placement blockages found."
  }
}
