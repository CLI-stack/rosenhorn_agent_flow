#if ( `perl /home/chenchai/scripts/TB_control_seras.pl -grep "StX\S+" | egrep -v "SKIPPED|PASSED|WARNING" | wc -l` > 0 || `perl /home/chenchai/scripts/TB_control_seras.pl -grep "PtClockGrp\S+" | egrep -v "SKIPPED|PASSED|WARNING" | wc -l` > 0 ) then
#    echo "Please wait for your StXtrct* and PtClockGrp* targets to finish before sourcing DMSA"
#    exit
#endif
source /tools/aticad/1.0/src/sysadmin/cpd.cshrc
set n_eco = `grep PERSONALITY tile.params | grep -v "#" | awk '{print $3}' | grep eco | wc -w`
if ($n_eco > 0) then
    echo "# ECO run valid."
else
    echo "# ECO run invalid."
    exit
endif
set n_stx_cmd = `ls cmds/StXtrct*.cmd | grep -v sbpf | wc -l`
set n_stx_spef = `ls data/Xtrct*.gz | wc -l`
set n_pt_grp_cmd = `ls cmds/PtClockGrp* | wc -l`
set n_pt_grp_log = `ls logs/PtClockGrp*.gz | wc -l`

if (-e DMSA.started) then
    echo "# DMSA has been finished"
    exit
endif

if ($n_stx_cmd == $n_stx_spef && $n_pt_grp_cmd == $n_pt_grp_log && $n_stx_cmd > 0 && $n_pt_grp_cmd > 0) then
    echo "# Stx*.gz and PtClockGrp*.tcl done, start to run DMSA."
else
    echo "# Stx*.gz and PtClockGrp*.tcl not done"
    exit
endif
touch DMSA.started
mkdir -p $BASE_DIR/DMSA_SF/logs
mkdir -p $BASE_DIR/DMSA_SF/cmds
mkdir -p $BASE_DIR/DMSA_SF/rpts
mkdir -p $BASE_DIR/DMSA_SF/eco
mkdir -p $BASE_DIR/DMSA_SF/data

rm -rf system_log
rm -rf command_log
rm -rf $BASE_DIR/nonsi_Pt*
rm -rf $BASE_DIR/si_Pt*
rm -rf [0-9]*.out
rm -rf Synopsys_stack_trace_*.txt
rm -rf crte_*.txt

set lsfProj = `egrep TILEBUILDER_LSFPROJECT target.controls | grep -v "LSFPROJECT_" | grep -v "#" | awk '{print $3}'`
set non_si_ptTarget = `ls cmds/PtTimFunc* | grep -v Sx | sed 's/\// /g' | awk '{print $2}' | sed 's/\.cmd//g'`
set si_ptTarget =  `ls cmds/PtTimFunc* | grep  Sx | sed 's/\// /g' | awk '{print $2}' | sed 's/\.cmd//g'`
# TIMING_SI_HOLD_ssg0p55v0c_MARGIN
set margins = ""
foreach corner (`ls cmds/PtTimFunc* | grep -v Sx | sed 's/\// /g' | awk '{print $2}' | sed 's/\.cmd//g'`)
    set pvt = `echo $corner |  sed 's/PtTimFunc//g' | sed 's/Eco/ /g' | awk '{print $1}'` 
    set is_stp = `echo $corner | grep -i stp | wc -w`
    if ($is_stp > 0) then
        set margin = 0
    else
        set margin = `grep "TIMING_HOLD.*MARGIN" tile.params | grep -v "#" | grep -i $pvt | head -n 1 | awk '{print $3}'` 
    endif
    set margins = "$margins $margin"
end
#set nonsi_ptTarget_uncertainty =  `ls cmds/PtTimFunc* | grep -v Sx | uniq -c | awk '{print $1-1}'`
set nonsi_ptTarget_uncertainty = "$margins"
set margins = ""
foreach corner (`ls cmds/PtTimFunc* | grep  Sx | sed 's/\// /g' | awk '{print $2}' | sed 's/\.cmd//g'`)
    set pvt = `echo $corner |  sed 's/PtTimFunc//g' | sed 's/Eco/ /g' | awk '{print $1}'`
    set is_stp = `echo $corner | grep -i stp | wc -w`
    if ($is_stp > 0) then
        set margin = 0
    else
        set margin = `grep "TIMING_SI_HOLD.*MARGIN" tile.params | grep -v "#" | grep -i $pvt | head -n 1 | awk '{print $3}'`
    endif
    set margins = "$margins $margin"
end

#set si_ptTarget_uncertainty = `ls cmds/PtTimFunc* | grep Sx | uniq -c | awk '{print $1-1}'`
set si_ptTarget_uncertainty = "$margins"

echo "set FLOWDIR $FLOW_DIR" > $BASE_DIR/DMSA_SF/cmds/DMSA_common_setting.tcl

cat >> $BASE_DIR/DMSA_SF/cmds/DMSA_common_setting.tcl << EOF
########## below need your manual settting ############### \
########## below can be "drv","setup","hold","drv setup hold" 
set fix_type "setup hold" 
########## below can be changed to the corner for dmsa to read eg PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp PtTimFuncFFG1p05vReRouteSxRcworstCCworst100cFFG1P05V0CHld 
set nonsi_ptTarget     {$non_si_ptTarget } 
set    si_ptTarget     {$si_ptTarget } 
########## below is path margin corresponding above corner (Navi44 Hld margin: 8 for FFG Hld, 30 for SSG Hld) 
set nonsi_ptTarget_uncertainty {$nonsi_ptTarget_uncertainty} 
set si_ptTarget_uncertainty {$si_ptTarget_uncertainty} 
########## below can be 1/0 , 1 enable physical aware , 0 disable physical aware 
set physical_aware_setup 1 
set physical_aware_hold 1 
########## below can be 1/0 , 1 enable push pull clock , 0 disable push pull clock , recommended only when fix rate for data path is low
set clock_network 0 
########## below can be 1/0, 1 enable ULVT to fix timing , 0 disable ULVT to fix timing (GCH please set to 1, SOC please set to 0) 
set enable_ulvt 1 
########## below can be 1/0, 1 enable ELVT to fix timing , 0 disable ELVT to fix timing 
#set enable_elvt 0 
########## below can be 1/0 , 1 means no area increase , 0 means it can increase cell area to fix timing 
set stp_no_area_increase 0 
########## below can be 1/0 , 1 will set IO path to dont touch true, 0 will NOT set any dont touch to IO 
set IO_dont_touch 1
########################################
EOF

set pt_module = `egrep "^PT_SHELL_MODULE\s" $BASE_DIR/target.controls | egrep -v "#"  | awkk 3`

set si_ptTarget = ""
set nonsi_ptTarget = ""

echo `cat $BASE_DIR/DMSA_SF/cmds/DMSA_common_setting.tcl | egrep nonsi_ptTarget | egrep Pt | sed 's/nonsi_ptTarget/nonsi_ptTarget =/g' | sed 's/{/\"/g' | sed 's/}/\"/g'` > $BASE_DIR/DMSA_SF/cmds/init_dmsa.csh
echo `cat $BASE_DIR/DMSA_SF/cmds/DMSA_common_setting.tcl | egrep " si_ptTarget" | egrep Pt | sed 's/si_ptTarget/si_ptTarget =/g' | sed 's/{/\"/g' | sed 's/}/\"/g'` >> $BASE_DIR/DMSA_SF/cmds/init_dmsa.csh

source $BASE_DIR/DMSA_SF/cmds/init_dmsa.csh

echo "##### Saving Pt Session\n"

set ptsession = ""
foreach ptsession ($nonsi_ptTarget)
    if ( ! -f "cmds/$ptsession.cmd" ) then
        echo "ERROR: $ptsession is not found, please check the dmsa_main_eco.csh"
        echo "ERROR: $ptsession is not found, please check the dmsa_main_eco.csh" > $BASE_DIR/DMSA_SF/logs/DMSA_init.log
        sleep 5
        exit
    endif
    $FLOW_DIR/supra/scripts/generic/filterpt.pl -loadparaloc -ptfixeco_slave -nohostoptions -noupdate -removecouple -saveslacks -enable_filter 0 -append_param_links $BASE_DIR/cmds/$ptsession.cmd $BASE_DIR/DMSA_SF/cmds/$ptsession.cmd
end

set ptsession = ""
foreach ptsession ($si_ptTarget)
    if ( ! -f "cmds/$ptsession.cmd" ) then 
        echo "ERROR: $ptsession is not found, please check the dmsa_main_eco.csh"
        echo "ERROR: $ptsession is not found, please check the dmsa_main_eco.csh" > $BASE_DIR/DMSA_SF/logs/DMSA_init.log
        sleep 5
        exit
    endif
    $FLOW_DIR/supra/scripts/generic/filterpt.pl -loadparaloc -ptfixeco_slave -nohostoptions -noupdate -saveslacks -enable_filter 1 -append_param_links $BASE_DIR/cmds/$ptsession.cmd $BASE_DIR/DMSA_SF/cmds/$ptsession.cmd
end

echo "\n##### Pt sessions saved, Performing DMSA fix..."

 
module unload primetime
module load $pt_module
bsub -P $lsfProj -R 'rusage[mem=10000]' -q regr_high  -R 'select[(type==any)]' -Ip pt_shell -multi_scenario -f  /home/simchen/aigc/dmsa_n3.tcl  | tee $BASE_DIR/DMSA_SF/logs/DMSA.log
#bsub -P $lsfProj -R 'rusage[mem=10000]' -q regr_high  -R 'select[(type==any)]' pt_shell -multi_scenario -f  /home/simchen/aigc/dmsa_n3.tcl  | tee $BASE_DIR/DMSA_SF/logs/DMSA.log

#source /tools/aticad/1.0/src/zoo/PD_agent/tile/wait_file_finish.csh DMSA.finished 
less $BASE_DIR/DMSA_SF/logs/DMSA.log | egrep -i "error" >> $BASE_DIR/DMSA_SF/logs/DMSA.log

rm -rf system_log
rm -rf command_log
rm -rf $BASE_DIR/nonsi_Pt*
rm -rf $BASE_DIR/si_Pt*
rm -rf [0-9]*.out
rm -rf Synopsys_stack_trace_*.txt
rm -rf crte_*.txt

wc -l $BASE_DIR/DMSA_SF/eco/DMSA.*.icctcl.eco | egrep -v total | sort -k1,1 -r | head -n 1 | awkk 2 | xargs -I % cp -p % $BASE_DIR/DMSA_SF/eco/DMSA.icctcl.eco

echo "\nSummary qor table:\n"
#perl /home/ziweiong/perl/qor_amd_leakage_table.pl
#perl /home/weiwelee/script/pt_uti/qor_amd_leakage_table.pl
