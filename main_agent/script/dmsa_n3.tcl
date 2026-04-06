### do not modify below , only modify ~/common_settting.tcl ###
set enable_elvt 0
set IO_dont_touch 1

source DMSA_SF/cmds/DMSA_common_setting.tcl

puts "Sourcing ParamsDB.tcl and tunesource file"
#source "/home/andys1/eco_n5/pt_uti/ParamsDB.tcl"
#source "/home/andys1/eco_n5/pt_uti/tunesource.tcl"
source "$FLOWDIR/util/ParamsDB.tcl"
source "$FLOWDIR/supra/templates/tcl/tunesource.tcl"

puts "Sourcing templates/pt_shell/ptprocs.tcl"
#source "/home/andys1/eco_n5/pt_uti/ptprocs.tcl"
#source "/home/weiwelee/script/pt_uti/ptprocs.tcl" 
#source "/home/andys1/eco_n5/pt_uti/report_path_xtalk_delays.tcl"
source "$FLOWDIR/supra/templates/pt_shell/ptprocs.tcl"
source "$FLOWDIR/supra/templates/pt_shell/report_path_xtalk_delays.tcl"

global P

set num_of_pt [expr [llength $nonsi_ptTarget] + [llength $si_ptTarget]]
#set lef_list [list tech/technology/tech_lef/N6_INNOVUS_13M_1X1Xa1Ya5Y2Yy2Z_P80.tlef]
set lef_list [sh grep ^LEF_HEADER tile.params | awkk 3]
set fp [open tech/lists/lef.list]
while { [gets $fp line] >= 0 } {
   lappend lef_list $line
}
close $fp
set nonsi_stp [list]
set nonsi_hld [list]
set si_stp [list]
set si_hld [list]
set stp [list]
set hld [list]
set all [list]
set clock_uncertainty_t [list]
set i 0
set date [sh env TZ=MYT-8 date]
set day [lindex $date 2]
set Month [lindex $date 1]
set tim  [lindex $date 3]
set tim  [split $tim ":"]
set h [lindex $tim 0]
set m [lindex $tim 1]
set s [lindex $tim 2]
set t "${h}_${m}_$s"
set eco_name_cell DMSA_${day}_${Month}_${t}_U
set eco_name_net DMSA_${day}_${Month}_${t}_Net
set eco_name_pt_cell [list]
set eco_name_pt_net [list]
set lef_list_all [list]
set enable_elvt_pt [list]
set enable_ulvt_pt [list]
foreach corner $nonsi_ptTarget {
    if {[regexp {Stp} $corner]} {
        lappend nonsi_stp "nonsi_$corner"
    } else {
        lappend nonsi_hld "nonsi_$corner"
    }
    lappend clock_uncertainty_t "nonsi_$corner"
    lappend clock_uncertainty_t [lindex $nonsi_ptTarget_uncertainty $i]
    lappend eco_name_pt_cell "nonsi_$corner"
    lappend eco_name_pt_cell "$eco_name_cell"
    lappend eco_name_pt_net "nonsi_$corner"
    lappend eco_name_pt_net "$eco_name_net"
    lappend lef_list_all "nonsi_$corner"
    lappend lef_list_all $lef_list
    lappend enable_elvt_pt "nonsi_$corner"
    lappend enable_elvt_pt $enable_elvt
    lappend enable_ulvt_pt "nonsi_$corner"
    lappend enable_ulvt_pt $enable_ulvt
    incr i
}

set i 0
foreach corner $si_ptTarget {
    if {[regexp {Stp} $corner]} {
        lappend si_stp "si_$corner"
    } else {
        lappend si_hld "si_$corner"
    }
    lappend clock_uncertainty_t "si_$corner"
    lappend clock_uncertainty_t [lindex $si_ptTarget_uncertainty $i]
    lappend eco_name_pt_cell "si_$corner"
    lappend eco_name_pt_cell "$eco_name_cell"
    lappend eco_name_pt_net "si_$corner"
    lappend eco_name_pt_net "$eco_name_net"
    lappend lef_list_all "si_$corner"
    lappend lef_list_all $lef_list
    lappend enable_elvt_pt "si_$corner"
    lappend enable_elvt_pt $enable_elvt
    lappend enable_ulvt_pt "si_$corner"
    lappend enable_ulvt_pt $enable_ulvt
    incr i
}
set stp [concat $nonsi_stp $si_stp]
set hld [concat $nonsi_hld $si_hld]
set all [concat $stp $hld]

#############################################################


puts "### Just after starting pt_shell: [clock format [clock seconds]]"
puts "    Compare this line with the previous message to see how much time it took to get a license"

if {[lindex [split [lindex [split $sh_product_version -] 1] .] 0] < 2013} {
    echo "[join {ERR OR} {}]: PrimeTime physical is only available in 2013 versions and later."
}



# do a little switcheroo on TILEBUILDER_TMPDIR. the children will use this env var when loaded from
# a command file to dump reports. if multiple ones are going at the same time they will clobber
# each other :(
if {[info exists env(TILEBUILDER_TMPDIR)]} {
    set _TBTMPDIR_BAK $env(TILEBUILDER_TMPDIR)
    unset env(TILEBUILDER_TMPDIR)
} else {
    set _TBTMPDIR_BAK {}
}

set multi_scenario_working_directory .
set multi_scenario_merged_error_log merged_errors.log
set multi_scenario_fault_handling exit
set search_path     { . }

# Uncomment one of the following add_distributed_hosts but NOT BOTH
# Launch slave sessions to lsf

set lsfres "primetimeX=1:duration=5"

#set_host_options -name bulk \
#                 -num_processes $num_of_pt \
#                 -max_cores 4 \
#                 -submit_command "bsub -o $multi_scenario_working_directory -n 1 -rn -R 'rusage\[tmp=4500,mem=25000\] span\[hosts=1\] order\[cpuf:-maxmem:-mem\] select\[(type==RHEL7_64)&&(csbatch||parallel)\]' -q regr_high -P navi31-pd" \
#                 -terminate_command "[sh which bkill]"
#mem=60000
set_host_options -name bulk \
                 -num_processes $num_of_pt \
                 -max_cores 16 \
                 -submit_command "bsub -o $multi_scenario_working_directory -n 16 -rn -R 'rusage\[tmp=5500,mem=15000\] span\[hosts=1\] order\[cpuf:-maxmem:-mem\] select\[(type==RHEL7_64||type==RHEL8_64)&&(dedicated||csbatch||gb64||parallel||tmpshortrr)\]' -q regr_high  -P $P(TILEBUILDER_LSFPROJECT) -J DMSA_slave" \
                 -terminate_command "[sh which bkill]"


# Loading up data in the slave sessions
catch {exec $P(FLOW_DIR)/supra/scripts/gen_eco/btopper 'PtFixEco.ptSlave'} res
puts $res

# Temporary workaround for 2017.06-SP3-2 and earlier for DMSA timeout issue (DMPTBSPE-27311)
set distributed_sh_protocol_error_detection_timeout 999999
set distributed_farm_protocol_error_detection_timeout 999999

start_hosts

foreach corner $nonsi_ptTarget {
    echo "Create scenario nonsi_$corner!"
    if { [file exists "$P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd"] } {
        create_scenario -name nonsi_$corner -specific_data $P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd
    } else {
        puts "$P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd not exists , pls check"
        exit
    }
}
foreach corner $si_ptTarget {
    echo "Create scenario si_$corner!"
    if { [file exists "$P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd"] } {
        create_scenario -name si_$corner -specific_data $P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd
    } else {
        puts "$P(BASE_DIR)/DMSA_SF/cmds/$corner.cmd not exists , pls check"
        exit
    }
}


current_session -all
current_scenario -all

set FLOW_DIR $P(FLOW_DIR)
#0114 add
#set_distributed_variables { FLOW_DIR }
#set sh_flow_summary_file 111.rpt
set_distributed_variables { FLOW_DIR }

remote_execute {
    puts "Sourcing ParamsDB.tcl and tunesource file"
    source "$FLOW_DIR/util/ParamsDB.tcl"
    source "$FLOW_DIR/supra/templates/tcl/tunesource.tcl"
    puts "Sourcing templates/pt_shell/ptprocs.tcl"
    source "$FLOW_DIR/supra/templates/pt_shell/ptprocs.tcl"
    source "$FLOW_DIR/supra/templates/pt_shell/report_path_xtalk_delays.tcl"
}


# load tbc here
if {[regexp "2019.03-SP[23456789]" [string range $sh_product_version 2 end]] || [lindex [split $sh_product_version -] 1] > 2019.03} {
	#source /home/andys1/eco_n5/pt_uti/disable_hier_option.tbc
    source $P(FLOW_DIR)/supra/templates/pt_shell/disable_hier_option.tbc
}
if {[regexp "2016.12-SP[3456789]" [string range $sh_product_version 2 end]] || [lindex [split $sh_product_version -] 1] > 2017.06} {
	#source /home/andys1/eco_n5/pt_uti/fix_eco_xtalk_p2.4.tbc
	source $P(FLOW_DIR)/supra/templates/pt_shell/fromsnps/fix_eco_xtalk_p2.4.tbc
}

remote_execute {
	if {[regexp "2019.03-SP[23456789]" [string range $sh_product_version 2 end]] || [lindex [split $sh_product_version -] 1] > 2019.03} {
	    #source /home/andys1/eco_n5/pt_uti/disable_hier_option.tbc
		source $FLOW_DIR/supra/templates/pt_shell/disable_hier_option.tbc

	}
    if {[regexp "2016.12-SP[3456789]" [string range $sh_product_version 2 end]] || [lindex [split $sh_product_version -] 1] > 2017.06} {
	    #source /home/andys1/eco_n5/pt_uti/fix_eco_xtalk_p2.4.tbc
	    source $FLOW_DIR/supra/templates/pt_shell/fromsnps/fix_eco_xtalk_p2.4.tbc
	}

}

set date [sh env TZ=MYT-8 date]
set day [lindex $date 2]
set Month [lindex $date 1]
set tim  [lindex $date 3]
set tim  [split $tim ":"]
set h [lindex $tim 0]
set m [lindex $tim 1]
set s [lindex $tim 2]
set t "${h}_${m}_$s"

set eco_instance_name_prefix "DMSA_${day}_${Month}_${t}_U"
set eco_net_name_prefix "DMSA_${day}_${Month}_${t}_net"

array set  eco_name_pt_cell_pt  $eco_name_pt_cell
array set  eco_name_pt_net_pt   $eco_name_pt_net
array set  lef_list_all_pt      $lef_list_all

set_distributed_variables { eco_name_pt_cell_pt  eco_name_pt_net_pt  lef_list_all_pt }

remote_execute {
    set eco_instance_name_prefix $eco_name_pt_cell_pt
    set eco_net_name_prefix $eco_name_pt_net_pt
}

set PERSONALITY $P(PERSONALITY)
set DCAP_CELLLIST $P(DCAP_CELLLIST)
set FILL_CELLLIST $P(FILL_CELLLIST)
set_distributed_variables { PERSONALITY DCAP_CELLLIST FILL_CELLLIST }
if { $physical_aware_setup ==1 || $physical_aware_hold ==1 } {
    remote_execute {
        if { $PERSONALITY == "placenroute" } {
            set db "ReRoute"
        } elseif {$PERSONALITY == "eco" } {
            set db "EcoRoute"
        }
        #if {[lindex [split $sh_product_version -] 1] == "2013.06"} {
            #source /home/andys1/eco_n5/pt_uti/enable_physical_aware_eco_modes.tbc
        #}
        set_app_var eco_allow_filler_cells_as_open_sites true
        source $FLOW_DIR/supra/templates/pt_shell/fromsnps/PrimeECO_advanced_legalizer_20220308.tbc
    	if {[lindex [split [lindex [split $sh_product_version -] 1] .] 0] >= 2018} {
    		set_eco_options -enable_pin_color_alignment_check -power_ground_net_layer {M1}
    	} else {
    		set_eco_options -physical_constraint_file data/${db}.powblk
    	}
        
        set filler_cell_list $P(DCAP_CELLLIST)
        append filler_cell_list " "
        append filler_cell_list $P(FILL_CELLLIST)

        set_eco_options -physical_lib_path $lef_list_all_pt \
            -physical_design_path data/${db}.def.gz \
            -physical_lib_constraint_file data/${db}.advrules.gz \
            -filler_cell_names { $filler_cell_list } \
            -log_file lef_def.log
    
        report_eco_options
    
    	if {[lindex [split [lindex [split $sh_product_version -] 1] .] 0] >= 2015} {
    		echo "[date]"
    		check_eco
    		echo "[date]"
    	}
    
    }
}

#if { $physical_aware == 1 } {
#    ### Enabling Physically Aware Clock Network ECOs
#    set_eco_options -physical_enable_clock_data
#}

if { $stp != "" } {
    current_scenario $stp
    remote_execute {
        set_false_path -hold -from [all_clocks] -to [all_clocks]
    }
}
if { $hld != "" } {
    current_scenario $hld
    remote_execute {
        set_false_path -setup -from [all_clocks] -to [all_clocks]
    }
}
current_scenario $all

remote_execute {
    set_false_path -hold -from [remove_from_collection [all_inputs] [amd_get_real_clock_ports]]
    set_false_path -hold -to [all_outputs]
    set_false_path -setup -from [remove_from_collection [all_inputs] [amd_get_real_clock_ports]]
    set_false_path -setup -to [all_outputs]
}

current_scenario -all
set report_default_significant_digits 3
set pba_exhaustive_endpoint_path_limit 
array set enable_ulvt_pt_slave  $enable_ulvt_pt
array set enable_elvt_pt_slave  $enable_elvt_pt
set_distributed_variables { report_default_significant_digits pba_exhaustive_endpoint_path_limit enable_elvt_pt enable_ulvt_pt_slave enable_elvt_pt_slave}
set eco_physical_upsize_cell_density_threshold 0.975
remote_execute {
	set eco_physical_upsize_cell_density_threshold 0.975
}

set DONTUSE_CELLLISTFILE_SETUP $P(DONTUSE_CELLLISTFILE_SETUP)
set DOUSE_CELLLISTFILE_SETUP $P(DOUSE_CELLLISTFILE_SETUP)
set TIELOW_CELL $P(TIELOW_CELL)
set TIEHIGH_CELL $P(TIEHIGH_CELL)
set BASE_DIR $P(BASE_DIR)
set FLOW_DIR $P(FLOW_DIR)
set ALLTILES_DIR $P(ALLTILES_DIR)

set_distributed_variables { DONTUSE_CELLLISTFILE_SETUP DOUSE_CELLLISTFILE_SETUP TIELOW_CELL TIEHIGH_CELL ALLTILES_DIR BASE_DIR FLOW_DIR enable_ulvt IO_dont_touch}

remote_execute {
    # process dont_use, dont_touch cells and lists
    # start by clearing anything inherited from the library
	set_dont_use [get_lib_cells -of_objects [get_libs]] false
    define_user_attribute pt_dont_use -quiet -type boolean -class lib_cell
    puts "Slaves Sourcing templates/pt_shell/ptprocs.tcl"
    #source "/home/andys1/eco_n5/pt_uti/ptprocs.tcl"
    #source "/home/weiwelee/script/pt_uti/ptprocs.tcl"     
    #source "/home/andys1/eco_n5/pt_uti/report_path_xtalk_delays.tcl"
    source "$FLOW_DIR/supra/templates/pt_shell/ptprocs.tcl"
    source "$FLOW_DIR/supra/templates/pt_shell/report_path_xtalk_delays.tcl"

    proc process_size_only_cell {size_only} {
        global TARGET_NAME
     
        foreach glob $size_only {
            set cellinst [get_cells -quiet -hier -filter "@ref_name =~ $glob"]
            if {[sizeof_collection $cellinst]} {
                amd_print_msg -info "set_size_only $glob"
                if {($TARGET_NAME == "DgSynthesize") || ($TARGET_NAME == "DgFastSynthesize")} {
                    set_size_only $cellinst -all_instances
                } else {
                    set_size_only $cellinst
                }
            }
        }
    }
     
    proc process_size_only_inst {size_only} {
        global TARGET_NAME
     
        foreach glob $size_only {
           set inst [get_hier_cells  $glob]
           if {$inst != {}} {
               amd_print_msg -info "set_size_only $glob"
               if {($TARGET_NAME == "DgSynthesize") || ($TARGET_NAME == "DgFastSynthesize")} {
                   set_size_only $inst -all_instances
               } else {
                   set_size_only $inst
               }
           }
        }
    }
     
    proc get_hier_cells {hier_pattern} {
     
        set out {}
        if {[regexp {[\*\?]} $hier_pattern]} {
            set out [get_cells -quiet -hier * -filter "full_name =~ $hier_pattern && is_hierarchical == false"]
        } else {
            set out [get_cells -quiet $hier_pattern ]
        }
     
        return $out
    }

    #process_dont_use [list ]
    #process_dont_use_file [list $DONTUSE_CELLLISTFILE_SETUP]
    process_do_use [list ]
    if { $enable_ulvt == 1 } {
        process_do_use_file [list tech/douse/douse_setup.ulvtlvt.aon]
    } else {
        process_do_use_file [list $DOUSE_CELLLISTFILE_SETUP]
    }
    process_do_touch_cell [list $TIELOW_CELL $TIEHIGH_CELL]
    process_dont_touch_cell [list ]
    process_dont_touch_cell [list MRK* PDLY* *SYNC* *CDC* TIE*PROG*]
    process_dont_touch_cell_file ../data/DontTouchCell.list
    #process_dont_touch_cell_file /home/andys1/eco_n5/pt_uti/donttouch_default.txt
	process_dont_touch_cell_file $ALLTILES_DIR/scripts/uselists/donttouch_cells.txt
    #process_dont_touch_inst [list *d0nt* *dbg_client*/*_RstSync/urst_sync/U1 *FEEDX_MFT_BUF* *FEEDX_FE_BUF* *FCFP_SSB* *FCFP_SSB*/* *feed_io_buffering_eco_cell* *_IntestEdt_i *_ExtestEdt_i SPARE_lo SPARE_lo_* SPARE_hi_* DBG_CLK_SEED_BUFFER*]
    process_dont_touch_inst [list ]
    #process_dont_touch_inst [list *rtl_tessent_edt_fti_*_inst* *edt_fti_bypass_logic_* *d0nt* *dbg_client*/*_RstSync/urst_sync/U1 *FEEDX_MFT_BUF* *FEEDX_FE_BUF* *FCFP_SSB* *FCFP_SSB*/* *feed_io_buffering_eco_cell* *_IntestEdt_i *_ExtestEdt_i SPARE_lo SPARE_lo_* SPARE_hi_* DBG_CLK_SEED_BUFFER*]    
    process_dont_touch_inst [list *d0nt* *rtl_tessent_edt_fti_*_inst* *edt_fti_bypass_logic_* *dbg_client*/*_RstSync/urst_sync/U1 *FEEDX_MFT_BUF* *FEEDX_FE_BUF* *FCFP_SSB* *FCFP_SSB*/* *feed_io_buffering_eco_cell* SPARE_lo SPARE_lo_* SPARE_hi_* ]
    process_dont_touch_inst_file ../data/DontTouchInst.list
    process_size_only_cell [list ]
    process_size_only_inst [list *d0nt_* *_IntestEdt_i* *_ExtestEdt_i* *DBG_CLK_SEED_BUFFER*]
    process_dont_touch_net [list ]
    process_dont_touch_net [list */I_AVFS_*PACK*/I_AVFS_*_REPLICA_PATH/AvfsLfsr*]
    process_dont_touch_net_file ../data/DontTouchNet.list
    process_ideal_net [list ]
    process_ideal_net_file ../data/IdealNet.list
    #process_do_use [list ]
    ##process_do_use_file [list $P(BASE_DIR)/tech/douse/douse_setup.lvt.ono ]
    #if { $enable_ulvt == 0 } {
    #    if { [file exists $BASE_DIR/tech/douse/douse_setup.lvt.ono] } { process_do_use_file  [list $BASE_DIR/tech/douse/douse_setup.lvt.ono] }
    #} else {
    #    if { [file exists $BASE_DIR/tech/douse/douse_setup.lvt.ono] } { process_do_use_file  [list $BASE_DIR/tech/douse/douse_setup.lvt.ono] }
    #    if { [file exists /home/boonthee/eco_n5/pt_uti/douse_setup.ulvtll.ono] } { process_do_use_file [list /home/boonthee/eco_n5/pt_uti/douse_setup.ulvtll.ono] }
    #    if { [file exists /home/boonthee/eco_n5/pt_uti/douse_setup.ulvtll_ulvt_mix.ono] } { process_do_use_file [list /home/boonthee/eco_n5/pt_uti/douse_setup.ulvtll_ulvt_mix.ono] }
    #}

    #set all cells to dont touch false
    #foreach_in_collection libo [get_libs] {
    #    set libn [get_attribute $libo full_name]
    #    set cl [get_lib_cells -quiet $libn/*]
    #    if { $cl != {} } {
    #        amd_print_msg -info "set_dont_touch $libn/* false"
    #        set_dont_touch [get_cells -quiet -of [get_lib_cells $cl]] false
    #    }
    #}

    # OPTROUTE_FREEZE_IO set to 1: set_dont_touch on IO cells/nets
    if {$IO_dont_touch == 1} {
        set _io_cell_instances [add_to_collection -unique [get_cells [all_fanout -flat -from [all_inputs] -only_cells] -filter "is_sequential == false"] [get_cells -quiet [all_fanin -flat -to [all_outputs] -only_cells] -filter "is_sequential == false"]]
        set_dont_touch $_io_cell_instances
        set _io_net_instances [add_to_collection -unique [get_nets -quiet -of [get_pins -filter direction==in [all_fanout -flat -from [all_inputs]]]] [get_nets -quiet -of [get_pins -filter direction==out [all_fanin -flat -to [all_outputs]]]]]    
        set_dont_touch $_io_net_instances
    }
    set_dont_touch [get_nets -quiet df__df_tl__TCDX*/shqbit_pre_buf*] false
    set_dont_touch [get_cells -quiet df__df_tl__TCDX*/shqbit_pre_buf*] false
    #set _io_cell_instances {}
    #set _io_net_instances {}

    #set_dont_touch [get_nets -of_objects [get_pins -hierarchical */SI -filter {full_name!~*SPARE*}]] false

## adapted from PtOpt
proc dont_touch_io { {mode 1} } { 
    set flopFanout ""
    set flopFanin ""
    if {$mode==2 || $mode==4} {
        set flopFanout [all_fanout -trace_arcs all -flat -from [all_registers -output_pins]]
        set flopFanin [all_fanin -trace_arcs all -flat -to [all_registers -data_pins]]
    }
    set ioFilter "undefined(clocks)"
    set inputFanout [all_fanout -trace_arcs all -flat -from [filter_collection [all_inputs] $ioFilter]]
    set outputFanin [all_fanin -trace_arcs all -flat -to [all_outputs]]
    append_to_collection -unique ioPins [remove_from_collection $outputFanin $flopFanin]
    append_to_collection -unique ioPins [remove_from_collection $inputFanout $flopFanout]
    set ioCells [get_cell -of_object $ioPins]
    if {$mode>2} {
        set coreFlopPins [remove_from_collection [get_pins -of_object [all_registers] -filter direction==out||is_data_pin==true] $ioPins]
        set ioCells [remove_from_collection $ioCells [get_cells -of_object $coreFlopPins]]
    }
	puts "Info: Running dont_touch_io using mode 1"
	set_dont_touch $ioCells true
    return 0
}
#dont_touch_io 1
}

array unset clock_uncertainty
array set clock_uncertainty $clock_uncertainty_t
set_distributed_variables {clock_uncertainty}

current_scenario -all

remote_execute {
	if {[llength [get_clocks -quiet]]} {
		if {$clock_uncertainty != 0} {
			#set_path_margin $clock_uncertainty -to [all_clocks]
            #Fix nosi will take si clock uncertainty
            set_clock_uncertainty $clock_uncertainty -from [all_clocks] -to [all_clocks]
            puts "clock_uncertainty is $clock_uncertainty"
		}
	}
}

#tunesource "tune/PtFixEco/PtFixEco.preupdate_timing.tcl"

## include eco attributes in timing reports
set timing_report_include_eco_attributes true
remote_execute {
	set timing_report_include_eco_attributes true
#source /home/humei/eco.tcl
	echo "started timing update: [date]"
	update_timing
	echo "finished timing update: [date]"
}


pushtimer "report_pretiming"

redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/pre_fix.report_timing_max.rpt.gz { report_timing -delay_type max -nets -capacitance -transition_time -input_pins -nosplit -path_type full_clock_expanded -max_paths 100000 -nworst 10 }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/pre_fix.report_timing_min.rpt.gz { report_timing -delay_type min -nets -capacitance -transition_time -input_pins -nosplit -path_type full_clock_expanded -max_paths 100000 -nworst 10 }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/pre_fix.report_global_timing_max.rpt.gz { report_global_timing -include {non_violated} -separate_all_groups -delay_type max }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/pre_fix.report_global_timing_min.rpt.gz { report_global_timing -include {non_violated} -separate_all_groups -delay_type min }

remote_execute {
    redirect -compress -file pre_qor.rpt.gz {report_qor}
    redirect -compress -file pre_max_tran.rpt.gz {report_constraint -max_transition -all_violators -nosplit}
}

#remote_execute {
#    redirect -compress -file before_qor.rpt.gz {report_qor}
#        #source "/home/andys1/eco_n5/pt_uti/ptprocs.tcl" 
#    source "/home/weiwelee/script/pt_uti/ptprocs.tcl"
#    source "${FLOW_DIR}/supra/templates/pt_shell/amdprocs/amd_report_qor_native.tcl"
#    #set_app_var power_enable_analysis true
#    redirect -compress -file before_amd_qor.rpt.gz {amd_report_qor}
#    redirect -compress -file before_amd_leakage.rpt.gz {statLeakagePower}
#    redirect -compress -file before_report_constraints.rpt.gz {report_constraints}
#    #redirect -compress -file SOC_report.rpt.gz {report_timing  -delay_type max -path_type full_clock_expanded -nets -capacitance -transition_time -input_pins -nosplit -include_hierarchical_pins  -group SOCLCK -nworst 1 -max_paths 100000  -unique_pins  -include_hierarchical_pin }
#}

poptimer "report_pretiming"


report_multi_scenario_design -session -scenario

set_app_var eco_report_unfixed_reason_max_endpoints 1000000

set PTFIXECO_DRC_BUFFERS [sh grep ECO_PTFIXECO_DRC_BUFFERS $P(BASE_DIR)/tile.params | cut -f 2 -d "="]
set PTFIXECO_DRC_CLOCK_BUFFERS [sh grep ECO_PTFIXECO_DRC_CLOCK_BUFFERS $P(BASE_DIR)/tile.params | cut -f 2 -d "="]
set PTFIXECO_HOLD_BUFFERS [sh grep ECO_PTFIXECO_HOLD_BUFFERS $P(BASE_DIR)/tile.params | cut -f 2 -d "="]
#tunesource "tune/PtFixEco/PtFixEco.setup.tcl"

#source /home/andys1/eco_n5/pt_uti/enable_improved_setup_buffering.tbc
#remote_execute {
#    source /home/andys1/eco_n5/pt_uti/enable_improved_setup_buffering.tbc
#}
source $P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
##/proj/at2_til39_nobackup/junwewei/gc_vmw_t1211/TileBuilder/supra/templates/pt_shell/enable_improved_setup_buffering.tbc

##$P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
#/proj/at2_til39_nobackup/junwewei/gc_vmw_t1211/TileBuilder/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
remote_execute {
    source $P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
    #/proj/at2_til39_nobackup/junwewei/gc_vmw_t1211/TileBuilder/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
    ##$FLOW_DIR/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
}


if { $stp_no_area_increase == 1 } {
    remote_execute {
        set eco_alternative_cell_attribute_restrictions "area"
    }
}


if {$physical_aware_setup == 1 } { set physical_mode occupied_site } else { set physical_mode none }
echo "INFO:physical_mode = $physical_mode "

if { [regexp {drv} $fix_type] } {
current_scenario $stp
fix_eco_drc -type max_transition \
    -verbose \
    -methods { size_cell } \
    -physical_mode $physical_mode
    #-buffer_list $PTFIXECO_DRC_BUFFERS
fix_eco_drc -type max_capacitance \
    -verbose \
    -methods { size_cell } \
    -physical_mode $physical_mode
    #-buffer_list $PTFIXECO_DRC_BUFFERS
fix_eco_drc -type noise \
    -verbose \
    -methods { size_cell } \
    -physical_mode $physical_mode
    #-buffer_list $PTFIXECO_DRC_BUFFERS
} 

if { [regexp {setup} $fix_type] } {
    current_scenario $stp
    remote_execute {
        set eco_alternative_cell_attribute_restrictions "area"
    }
    #### VT Swap Shqbit cell first

    fix_eco_timing -hold_margin 0 \
        -verbose \
        -pba_mode none \
        -slack_lesser_than 0 \
        -slack_greater_than -9999 \
        -methods { size_cell } \
        -physical_mode $physical_mode \
        -ignore_drc \
        -type setup
    
    if { $stp_no_area_increase == 0 } {
        remote_execute {
            set eco_alternative_cell_attribute_restrictions ""
        }
        current_scenario -all
        fix_eco_timing -hold_margin 0 \
            -verbose \
            -pba_mode none \
            -slack_lesser_than 0 \
            -slack_greater_than -9999 \
            -methods { size_cell } \
            -physical_mode $physical_mode \
            -ignore_drc \
            -type setup
    
    }
    
    if { $clock_network == 1 } { 
        set physical_mode none
        echo "INFO:physical_mode = $physical_mode "
        
        set clk_buf ""
        foreach c $PTFIXECO_DRC_CLOCK_BUFFERS {
            append clk_buf "*/$c " 
        }
        set_distributed_variables {clk_buf}
        remote_execute {
            define_user_attribute -type boolean -class lib_cell is_clk_cell
            set_user_attribute [get_lib_cell $clk_buf] is_clk_cell true
            set eco_alternative_cell_attribute_restrictions is_clk_cell
            set_eco_options -physical_enable_clock_data
        }
        current_scenario -all
        fix_eco_timing -hold_margin 0 \
            -verbose \
            -pba_mode none \
            -slack_lesser_than 0 \
            -slack_greater_than -9999 \
            -cell_type clock_network \
            -clock_fixes_per_change 1 \
            -clock_max_level_from_reg 0 \
            -physical_mode $physical_mode \
            -ignore_drc \
            -methods { size_cell insert_buffer } \
            -buffer_list $PTFIXECO_DRC_CLOCK_BUFFERS \
            -type setup
    }
}


remote_execute {
    set eco_alternative_cell_attribute_restrictions ""
    set hold_buf_list [expand_cell_patterns -exclude_pt_dont_use_cell -cell_pattern {BUFFD0P5AMDBWP143M117H3P48CPDLVT BUFFD1BWP143M117H3P48CPDLVT  BUFFD1P5BWP143M117H3P48CPDLVT BUFFD2BWP143M117H3P48CPDLVT BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVT BUFFD2BWP143M169H3P48CPDLVT BUFFD3BWP143M169H3P48CPDLVT DELAD0P5BWP143M117H3P48CPDLVT DELAD1AMDBWP143M117H3P48CPDLVT DELCD0P5BWP143M117H3P48CPDLVT DELDD0P5AMDBWP143M117H3P48CPDLVT DELAAD1AMDBWP143M169H3P48CPDLVT DELBD1AMDBWP143M169H3P48CPDLVT DELCD1BWP143M169H3P48CPDLVT DELDD1AMDBWP143M169H3P48CPDLVT BUFFD0P5AMDBWP143M117H3P48CPDLVTLL BUFFD1BWP143M117H3P48CPDLVTLL  BUFFD1P5BWP143M117H3P48CPDLVTLL BUFFD2BWP143M117H3P48CPDLVTLL BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVTLL BUFFD2BWP143M169H3P48CPDLVTLL BUFFD3BWP143M169H3P48CPDLVTLL DELAD0P5BWP143M117H3P48CPDLVTLL DELAD1AMDBWP143M117H3P48CPDLVTLL DELCD0P5BWP143M117H3P48CPDLVTLL DELDD0P5AMDBWP143M117H3P48CPDLVTLL DELAAD1AMDBWP143M169H3P48CPDLVTLL DELBD1AMDBWP143M169H3P48CPDLVTLL DELCD1BWP143M169H3P48CPDLVTLL DELDD1AMDBWP143M169H3P48CPDLVTLL}]
}

if {$physical_aware_hold == 1 } { set physical_mode occupied_site } else { set physical_mode none }
echo "INFO:physical_mode = $physical_mode "

#set PTFIXECO_HOLD_BUFFERS_ULVT "BUFFD2BWP210H6P51CNODLVT BUFFD2BWP210H6P51CNODLVTLL BUFFD1BWP210H6P51CNODLVT BUFFD1BWP210H6P51CNODLVTLL DELAD1BWP210H6P51CNODLVT DELAD1BWP210H6P51CNODLVTLL DELBD1BWP210H6P51CNODLVT DELBD1BWP210H6P51CNODLVTLL DELCD1BWP210H6P51CNODLVT DELCD1BWP210H6P51CNODLVTLL DELDD1BWP210H6P51CNODLVT DELDD1BWP210H6P51CNODLVTLL DELED1BWP210H6P51CNODLVT DELED1BWP210H6P51CNODLVTLL DELFD1BWP210H6P51CNODLVT DELFD1BWP210H6P51CNODLVTLL DELGD1BWP210H6P51CNODLVT DELGD1BWP210H6P51CNODLVTLL BUFFD2BWP210H6P51CNODULVT BUFFD2BWP210H6P51CNODULVTLL BUFFD1BWP210H6P51CNODULVT BUFFD1BWP210H6P51CNODULVTLL DELAD1BWP210H6P51CNODULVT DELAD1BWP210H6P51CNODULVTLL DELBD1BWP210H6P51CNODULVT DELBD1BWP210H6P51CNODULVTLL DELCD1BWP210H6P51CNODULVT DELCD1BWP210H6P51CNODULVTLL DELDD1BWP210H6P51CNODULVT DELDD1BWP210H6P51CNODULVTLL DELED1BWP210H6P51CNODULVT DELED1BWP210H6P51CNODULVTLL DELFD1BWP210H6P51CNODULVT DELFD1BWP210H6P51CNODULVTLL DELGD1BWP210H6P51CNODULVT DELGD1BWP210H6P51CNODULVTLL"

set hold_buf_list "BUFFD0P5AMDBWP143M117H3P48CPDLVT BUFFD1BWP143M117H3P48CPDLVT BUFFD1P5BWP143M117H3P48CPDLVT BUFFD2BWP143M117H3P48CPDLVT BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVT BUFFD2BWP143M169H3P48CPDLVT BUFFD3BWP143M169H3P48CPDLVT DELAD0P5BWP143M117H3P48CPDLVT DELAD1AMDBWP143M117H3P48CPDLVT DELCD0P5BWP143M117H3P48CPDLVT DELDD0P5AMDBWP143M117H3P48CPDLVT DELAAD1AMDBWP143M169H3P48CPDLVT DELBD1AMDBWP143M169H3P48CPDLVT DELCD1BWP143M169H3P48CPDLVT DELDD1AMDBWP143M169H3P48CPDLVT BUFFD0P5AMDBWP143M117H3P48CPDLVTLL BUFFD1BWP143M117H3P48CPDLVTLL BUFFD1P5BWP143M117H3P48CPDLVTLL BUFFD2BWP143M117H3P48CPDLVTLL BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVTLL BUFFD2BWP143M169H3P48CPDLVTLL BUFFD3BWP143M169H3P48CPDLVTLL DELAD0P5BWP143M117H3P48CPDLVTLL DELAD1AMDBWP143M117H3P48CPDLVTLL DELCD0P5BWP143M117H3P48CPDLVTLL DELDD0P5AMDBWP143M117H3P48CPDLVTLL DELAAD1AMDBWP143M169H3P48CPDLVTLL DELBD1AMDBWP143M169H3P48CPDLVTLL DELCD1BWP143M169H3P48CPDLVTLL DELDD1AMDBWP143M169H3P48CPDLVTLL BUFFD0P5AMDBWP143M117H3P48CPDLVT BUFFD1BWP143M117H3P48CPDLVT BUFFD1P5BWP143M117H3P48CPDLVT BUFFD2BWP143M117H3P48CPDLVT BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVT BUFFD2BWP143M169H3P48CPDLVT BUFFD3BWP143M169H3P48CPDLVT DELAD0P5BWP143M117H3P48CPDLVT DELAD1AMDBWP143M117H3P48CPDLVT DELCD0P5BWP143M117H3P48CPDLVT DELDD0P5AMDBWP143M117H3P48CPDLVT DELAAD1AMDBWP143M169H3P48CPDLVT DELBD1AMDBWP143M169H3P48CPDLVT DELCD1BWP143M169H3P48CPDLVT DELDD1AMDBWP143M169H3P48CPDLVT BUFFD0P5AMDBWP143M117H3P48CPDLVTLL BUFFD1BWP143M117H3P48CPDLVTLL BUFFD1P5BWP143M117H3P48CPDLVTLL BUFFD2BWP143M117H3P48CPDLVTLL BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVTLL BUFFD2BWP143M169H3P48CPDLVTLL BUFFD3BWP143M169H3P48CPDLVTLL DELAD0P5BWP143M117H3P48CPDLVTLL DELAD1AMDBWP143M117H3P48CPDLVTLL DELCD0P5BWP143M117H3P48CPDLVTLL DELDD0P5AMDBWP143M117H3P48CPDLVTLL DELAAD1AMDBWP143M169H3P48CPDLVTLL DELBD1AMDBWP143M169H3P48CPDLVTLL DELCD1BWP143M169H3P48CPDLVTLL DELDD1AMDBWP143M169H3P48CPDLVTLL BUFFD0P5AMDBWP143M117H3P48CPDLVT BUFFD1BWP143M117H3P48CPDLVT BUFFD1P5BWP143M117H3P48CPDLVT BUFFD2BWP143M117H3P48CPDLVT BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVT BUFFD2BWP143M169H3P48CPDLVT BUFFD3BWP143M169H3P48CPDLVT DELAD0P5BWP143M117H3P48CPDLVT DELAD1AMDBWP143M117H3P48CPDLVT DELCD0P5BWP143M117H3P48CPDLVT DELDD0P5AMDBWP143M117H3P48CPDLVT DELAAD1AMDBWP143M169H3P48CPDLVT DELBD1AMDBWP143M169H3P48CPDLVT DELCD1BWP143M169H3P48CPDLVT DELDD1AMDBWP143M169H3P48CPDLVT BUFFD0P5AMDBWP143M117H3P48CPDLVTLL BUFFD1BWP143M117H3P48CPDLVTLL BUFFD1P5BWP143M117H3P48CPDLVTLL BUFFD2BWP143M117H3P48CPDLVTLL BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVTLL BUFFD2BWP143M169H3P48CPDLVTLL BUFFD3BWP143M169H3P48CPDLVTLL DELAD0P5BWP143M117H3P48CPDLVTLL DELAD1AMDBWP143M117H3P48CPDLVTLL DELCD0P5BWP143M117H3P48CPDLVTLL DELDD0P5AMDBWP143M117H3P48CPDLVTLL DELAAD1AMDBWP143M169H3P48CPDLVTLL DELBD1AMDBWP143M169H3P48CPDLVTLL DELCD1BWP143M169H3P48CPDLVTLL DELDD1AMDBWP143M169H3P48CPDLVTLL BUFFD0P5AMDBWP143M117H3P48CPDLVT BUFFD1BWP143M117H3P48CPDLVT BUFFD1P5BWP143M117H3P48CPDLVT BUFFD2BWP143M117H3P48CPDLVT BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVT BUFFD2BWP143M169H3P48CPDLVT BUFFD3BWP143M169H3P48CPDLVT DELAD0P5BWP143M117H3P48CPDLVT DELAD1AMDBWP143M117H3P48CPDLVT DELCD0P5BWP143M117H3P48CPDLVT DELDD0P5AMDBWP143M117H3P48CPDLVT DELAAD1AMDBWP143M169H3P48CPDLVT DELBD1AMDBWP143M169H3P48CPDLVT DELCD1BWP143M169H3P48CPDLVT DELDD1AMDBWP143M169H3P48CPDLVT BUFFD0P5AMDBWP143M117H3P48CPDLVTLL BUFFD1BWP143M117H3P48CPDLVTLL BUFFD1P5BWP143M117H3P48CPDLVTLL BUFFD2BWP143M117H3P48CPDLVTLL BUFFD3BWP143M117H3P48CPDLVT BUFFD1BWP143M169H3P48CPDLVTLL BUFFD2BWP143M169H3P48CPDLVTLL BUFFD3BWP143M169H3P48CPDLVTLL DELAD0P5BWP143M117H3P48CPDLVTLL DELAD1AMDBWP143M117H3P48CPDLVTLL DELCD0P5BWP143M117H3P48CPDLVTLL DELDD0P5AMDBWP143M117H3P48CPDLVTLL DELAAD1AMDBWP143M169H3P48CPDLVTLL DELBD1AMDBWP143M169H3P48CPDLVTLL DELCD1BWP143M169H3P48CPDLVTLL DELDD1AMDBWP143M169H3P48CPDLVTLL"

if { [regexp {hold} $fix_type] } {
    current_scenario -all
    fix_eco_timing   -setup_margin 0 \
        -verbose \
        -pba_mode none \
        -slack_lesser_than 0 \
        -slack_greater_than -9999 \
        -methods { size_cell insert_buffer } \
        -buffer_list $hold_buf_list \
        -physical_mode $physical_mode \
        -ignore_drc \
        -type hold
    
    if { $clock_network == 1 } {
        set clk_buf ""
        foreach c $PTFIXECO_DRC_CLOCK_BUFFERS {
            append clk_buf "*/$c " 
        }
        set_distributed_variables {clk_buf}
        remote_execute {
            define_user_attribute -type boolean -class lib_cell is_clk_cell
            set_user_attribute [get_lib_cell $clk_buf] is_clk_cell true
            set eco_alternative_cell_attribute_restrictions is_clk_cell
            set_eco_options -physical_enable_clock_data
        }
        current_scenario -all
        fix_eco_timing -setup_margin 0 \
            -verbose \
            -pba_mode none \
            -slack_lesser_than 0 \
            -slack_greater_than -9999 \
            -cell_type clock_network \
            -clock_fixes_per_change 1 \
            -clock_max_level_from_reg 0 \
            -physical_mode $physical_mode \
            -ignore_drc \
            -methods { size_cell insert_buffer } \
            -buffer_list $hold_buf_list \
            -type hold
    }
}

current_scenario -all

#source  /home/andys1/eco_n5/pt_uti/enable_improved_setup_buffering.tbc
#remote_execute {
#    source /home/andys1/eco_n5/pt_uti/enable_improved_setup_buffering.tbc
#}

source $P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
##$P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
remote_execute {
    source $P(FLOW_DIR)/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
    ##$FLOW_DIR/supra/templates/pt_shell/enable_improved_setup_buffering.tbc
}


if { [regexp {remove_buffer} $fix_type]  } {
remote_execute {
    process_dont_use [list ]
    process_dont_use_file [list $DONTUSE_CELLLISTFILE_SETUP]
    
}

fix_eco_power \
    -verbose \
    -pba_mode none \
    -methods { remove_buffer }
}


current_scenario -all
pushtimer "write_eco"
remote_execute -verbose {
    write_changes -format icctcl -output DMSA.icctcl.eco
}

# workaround to generate the changes in a text file in DMSA #

poptimer "write_eco"

pushtimer "report_posttiming"

redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/report_timing_max.rpt.gz { report_timing -delay_type max -nets -capacitance -transition_time -input_pins -nosplit -path_type full_clock_expanded -max_paths 100000 -nworst 10 }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/report_timing_min.rpt.gz { report_timing -delay_type min -nets -capacitance -transition_time -input_pins -nosplit -path_type full_clock_expanded -max_paths 100000 -nworst 10 }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/report_global_timing_max.rpt.gz { report_global_timing -include {non_violated} -separate_all_groups -delay_type max }
redirect -compress -file $P(BASE_DIR)/DMSA_SF/rpts/report_global_timing_min.rpt.gz { report_global_timing -include {non_violated} -separate_all_groups -delay_type min }

remote_execute {
    redirect -compress -file qor.rpt.gz {report_qor}
    redirect -compress -file max_tran.rpt.gz {report_constraint -max_transition -all_violators -nosplit}
}

#remote_execute {
#    redirect -compress -file qor.rpt.gz {report_qor}
#    #source "/home/andys1/eco_n5/pt_uti/ptprocs.tcl" 
#    source "/home/weiwelee/script/pt_uti/ptprocs.tcl" 
#    source "${FLOW_DIR}/supra/templates/pt_shell/amdprocs/amd_report_qor_native.tcl"
#    #set_app_var power_enable_analysis true
#    redirect -compress -file amd_qor.rpt.gz {amd_report_qor}
#    redirect -compress -file  amd_leakage.rpt.gz {statLeakagePower}
#    redirect -compress -file report_constraints.rpt.gz {report_constraints}
#}

poptimer "report_posttiming"

foreach_in_collection ecocorner [current_scenario] {
    set cor [get_object_name $ecocorner] 
    if { [file exists "$cor/DMSA.icctcl.eco"] } {
        file copy -force $cor/DMSA.icctcl.eco $P(BASE_DIR)/DMSA_SF/eco/DMSA.$cor.icctcl.eco
    } else {
        echo "" > $P(BASE_DIR)/DMSA_SF/eco/DMSA.$cor.icctcl.eco
    }
    if { [file exists "$cor/pre_qor.rpt.gz"] } {
        file copy -force $cor/pre_qor.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_pre_qor.rpt.gz
    } else {
        echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_pre_qor.rpt.gz
    }
    if { [file exists "$cor/qor.rpt.gz"] } {
        file copy -force $cor/qor.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_qor.rpt.gz
    } else {
        echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_qor.rpt.gz
    }
    #if { [file exists "$cor/before_amd_qor.rpt.gz"] } {
    #    file copy -force $cor/before_amd_qor.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_before_amd_qor.rpt.gz
    #} else {
    #    echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_before_amd_qor.rpt.gz
    #}
    #if { [file exists "$cor/amd_qor.rpt.gz"] } {
    #    file copy -force $cor/amd_qor.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_amd_qor.rpt.gz
    #} else {
    #    echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_amd_qor.rpt.gz
    #}
    #if { [file exists "$cor/before_amd_leakage.rpt.gz"] } {
    #    file copy -force $cor/before_amd_leakage.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_before_amd_leakage.rpt.gz
    #} else {
    #    echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_before_amd_leakage.rpt.gz
    #}
    #if { [file exists "$cor/amd_leakage.rpt.gz"] } {
    #    file copy -force $cor/amd_leakage.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_amd_leakage.rpt.gz
    #} else {
    #    echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_amd_leakage.rpt.gz
    #}
    if { [file exists "$cor/pre_max_tran.rpt.gz"] } {
        file copy -force $cor/pre_max_tran.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_pre_max_tran.rpt.gz
    } else {
        echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_pre_max_tran.rpt.gz
    }
    if { [file exists "$cor/max_tran.rpt.gz"] } {
        file copy -force $cor/max_tran.rpt.gz $P(BASE_DIR)/DMSA_SF/rpts/${cor}_max_tran.rpt.gz
    } else {
        echo "" > $P(BASE_DIR)/DMSA_SF/rpts/${cor}_max_tran.rpt.gz
    }

    if { [file exists "$cor/lef_def.log"] } {
        file copy -force $cor/lef_def.log $P(BASE_DIR)/DMSA_SF/logs/DMSA.${cor}_lef_def.log
        exec gzip -f $P(BASE_DIR)/DMSA_SF/logs/DMSA.${cor}_lef_def.log
    }
    if { [file exists "${cor}/out.log"] } {
        file copy -force ${cor}/out.log $P(BASE_DIR)/DMSA_SF/logs/DMSA.${cor}_out.log
        exec gzip -f $P(BASE_DIR)/DMSA_SF/logs/DMSA.${cor}_out.log
    }

}

#tunesource "tune/PtFixEco/PtFixEco.exit.tcl"

#save_session $P(BASE_DIR)/DMSA_SF/data/dmsa_pt_session
stop_hosts
set f [open DMSA.finished w]
close $f

exit

