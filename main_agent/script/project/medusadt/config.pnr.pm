############config env
#####IP main clock define 
#default group clock, gc tile--> GFXCLK, df tile --> FCLK, vcn tiles--> DCLK*
# if need extract other  clock, please  define %clk_name =(tile0=>clock_name,tile1=>clock_name);
%clk_name =(cit_usr=>FCLK,vcn=>VCN_DCLK,vcn_m_0_t=>"VCN_VCLK VCN_DCLK",mmhub=>SOCCLK,nbio=>NBIO_LCLK,secip=>SOCCLK);

#cts tree latency limit
 $max_clk_latency = 230;
 $clk_gskew_red =35;
 $main_clk_corner = "tt0p9v100c_typrc100c";
 $main_rpt_corner = "FuncTT0p9v";
 #$main_clk_corner = "tt0p65vm40c_typrc100c_setup";
 #$main_rpt_corner = "FuncTT0p65v";

#config setup corner extact for FX target
@main_corner_l =qw/tt0p9v100c_typrc100c_FuncTT0p9v tt0p65v0c_typrc100c_FuncTT0p65v/;
#@main_corner_l =qw/typrc100c_FuncTT0p9v typrc100c_FuncTT0p65v/;
#F2F grp : 1 only check main clk ;0: total clks exclude async_default
$f2f_mainclk =0;

#config timing wall corner 
%twall_pt=(PtTimFuncTT0p65vReRouteTyprc100cTT0P65VM40CStp=>"FCLK UCLK VCN_DCLK VCN_VCLK",PtTimFuncTT0p9vReRouteTyprc100cTT0P9V100CStp=>default);
  
 ###noSI PT
 #@PtFuncSetup = qw/PtTimFuncTT0p9vReRouteTyprc100cTT0P9V100CStp PtTimFuncTT0p65vReRouteTyprc100cTT0P65VM40CStp PtTimFuncTT0p6vReRouteTyprc100cTT0P6VM40CStp PtTimFuncStpFFG1p05vReRouteTyprc100cFFGNP1P05VM40CStp PtTimFuncStpSSG0p6vReRouteTyprc100cSSGNP0P6VM40CStp/;
 #@PtFuncHld = qw/PtTimFuncHldFFG1p05vReRouteRcbestCCbest0cFFGNP1P05VM40CHld PtTimFuncHldFFG1p05vReRouteRcworstCCworst100cFFGNP1P05VM40CHld PtTimFuncHldSSG0p6vReRouteRcbestCCbest0cSSGNP0P6VM40CHld PtTimFuncHldSSG0p6vReRouteRcworstCCworst100cSSGNP0P6VM40CHld/;
@PtFuncSetup = qw/PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp PtTimFuncTT0p65vReRouteSxTyprc100cTT0P65V0CStp PtTimFuncFFG1p05vReRouteSxTyprc100cFFG1P05V0CStp PtTimFuncSSG0p6vReRouteSxTyprc100cSSG0P6V0CStp/;
 @PtFuncHld = qw/PtTimFuncFFG1p05vReRouteSxRcbestCCbest0cFFG1P05V0CHld PtTimFuncFFG1p05vReRouteSxRcworstCCworst100cFFG1P05V0CHld PtTimFuncSSG0p6vReRouteSxRcbestCCbest0cSSG0P6V0CHld PtTimFuncSSG0p6vReRouteSxRcworstCCworst100cSSG0P6V0CHld/;
 
 #SI PT
 #@PtFuncSetup_SI = qw/PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp PtTimFuncTT0p65vReRouteSxTyprc100cTT0P65VM40CStp PtTimFuncTT0p6vReRouteSxTyprc100cTT0P6VM40CStp PtTimFuncStpFFG1p05vReRouteSxTyprc100cFFGNP1P05VM40CStp PtTimFuncStpSSG0p6vReRouteSxTyprc100cSSGNP0P6VM40CStp/;
 #@PtFuncHld_SI = qw/PtTimFuncHldFFG1p05vReRouteSxSiRcbestCCbest0cFFG1P05V0CHld PtTimFuncHldFFG1p05vReRouteSxSiRcworstCCworst100cFFG1P05V0CHld PtTimFuncHldSSG0p6vReRouteSxSiRcbestCCbest0cSSG0P6V0CHld PtTimFuncHldSSG0p6vReRouteSxSiRcworstCCworst100cSSG0P6V0CHld/;
 #@PtFuncHld_SI = qw/PtTimFuncHldFFG1p05vReRouteSxRcbestCCbest0cFFGNP1P05VM40CHld PtTimFuncHldFFG1p05vReRouteSxRcworstCCworst100cFFGNP1P05VM40CHld PtTimFuncHldSSG0p6vReRouteSxRcbestCCbest0cSSGNP0P6VM40CHld PtTimFuncHldSSG0p6vReRouteSxRcworstCCworst100cSSGNP0P6VM40CHld/;

 @PtFuncSetup_SI = qw/PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp PtTimFuncTT0p65vReRouteSxTyprc100cTT0P65V0CStp PtTimFuncFFG1p05vReRouteSxTyprc100cFFG1P05V0CStp PtTimFuncSSG0p6vReRouteSxTyprc100cSSG0P6V0CStp/;
@PtFuncHld_SI = qw/PtTimFuncFFG1p05vReRouteSxRcbestCCbest0cFFG1P05V0CHld PtTimFuncFFG1p05vReRouteSxRcworstCCworst100cFFG1P05V0CHld PtTimFuncSSG0p6vReRouteSxRcbestCCbest0cSSG0P6V0CHld PtTimFuncSSG0p6vReRouteSxRcworstCCworst100cSSG0P6V0CHld/;
@PtScanSetup = qw/PtTimScanShiftFFG1p05vReRouteTyprc100cFFG1P05V0CStp PtTimScanShiftSSG0p6vReRouteTyprc100cSSG0P6V0CStp/;
 @PtScanSetup_SI= qw/PtTimScanShiftFFG1p05vReRouteSxTyprc100cFFG1P05V0CStp PtTimScanShiftSSG0p6vReRouteSxTyprc100cSSG0P6V0CStp/;
 @PtScanHld = qw/PtTimScanShiftFFG1p05vReRouteRcbestCCbest0cFFG1P05V0CHld PtTimScanShiftFFG1p05vReRouteRcworstCCworst100cFFG1P05V0CHld PtTimScanShiftSSG0p6vReRouteRcbestCCbest0cSSG0P6V0CHld PtTimScanShiftSSG0p6vReRouteRcworstCCworst100cSSG0P6V0CHld/;
 @PtScanHld_SI= qw/PtTimScanShiftFFG1p05vReRouteSxRcbestCCbest0cFFG1P05V0CHld PtTimScanShiftFFG1p05vReRouteSxRcworstCCworst100cFFG1P05V0CHld PtTimScanShiftSSG0p6vReRouteSxRcbestCCbest0cSSG0P6V0CHld PtTimScanShiftSSG0p6vReRouteSxRcworstCCworst100cSSG0P6V0CHld/;


##If flow  merged SI  and noSi report,use below PT setting
# @PtFuncSetup = qw/PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp PtTimFuncTT0p65vReRouteSxTyprc100cTT0P65V0CStp PtTimFuncFFG1p05vReRouteSxTyprc100cFFG1P05V0CStp PtTimFuncSSG0p6vReRouteSxTyprc100cSSG0P6V0CStp/;
# @PtFuncHld = qw/PtTimFuncFFG1p05vReRouteSxRcbestCCbest0cFFG1P05V0CHld PtTimFuncFFG1p05vReRouteSxRcworstCCworst100cFFG1P05V0CHld PtTimFuncSSG0p6vReRouteSxRcbestCCbest0cSSG0P6V0CHld PtTimFuncSSG0p6vReRouteSxRcworstCCworst100cSSG0P6V0CHld/;
 @PtScanSetup = qw/PtTimScanShiftFFG1p05vReRouteTyprc100cFFGNP1P05VM40CStp PtTimScanShiftSSG0p6vReRouteTyprc100cSSGNP0P6VM40CStp/;
 @PtScanSetup_SI= qw/PtTimScanShiftFFG1p05vReRouteSxTyprc100cFFGNP1P05VM40CStp PtTimScanShiftSSG0p6vReRouteSxTyprc100cSSGNP0P6VM40CStp/;
 @PtScanHld = qw/PtTimScanShiftFFG1p05vReRouteRcbestCCbest0cFFGNP1P05VM40CHld PtTimScanShiftFFG1p05vReRouteRcworstCCworst100cFFGNP1P05VM40CHld PtTimScanShiftSSG0p6vReRouteRcbestCCbest0cSSGNP0P6VM40CHld PtTimScanShiftSSG0p6vReRouteRcworstCCworst100cSSGNP0P6VM40CHld/;
 @PtScanHld_SI= qw/PtTimScanShiftFFG1p05vReRouteSxRcbestCCbest0cFFGNP1P05VM40CHld PtTimScanShiftFFG1p05vReRouteSxRcworstCCworst100cFFGNP1P05VM40CHld PtTimScanShiftSSG0p6vReRouteSxRcbestCCbest0cSSGNP0P6VM40CHld PtTimScanShiftSSG0p6vReRouteSxRcworstCCworst100cSSGNP0P6VM40CHld/;

### not need change by owners
#runtime limit
 $time_t = 168;#168h(7days)
 $time_syn = 30;
 $time_postFP = 5;
 $time_place = 30;
 $time_cts= 20;
 $time_optcts = 40;
 $time_route = 24;
 $time_optroute =30;
 $time_reroute =30;

#setup wns tns limit
# $wns_green= -40;
# $wns_red= -60;
# $tns_green= -10.0;
# $tns_red= -30.0;
# $nvp_green= 2000;
# $nvp_red= 5000;
# $OptR_wns_green= -20;
# $OptR_wns_red= -40;
# $OptR_tns_green= -10.0;
# $OptR_tns_red= -20.0;
# $OptR_nvp_green= 2000;
# $OptR_nvp_red= 3000;
# $ptsetup_wns_green= -10;
# $ptsetup_wns_red= -20;
# $ptsetup_tns_green= -2.0;
# $ptsetup_tns_red= -5.0;
# $ptsetup_nvp_green= 1000;
# $ptsetup_nvp_red= 2000;
$wns_green= -40;
 $wns_red= -80;
 $tns_green= -20.0;
 $tns_red= -50.0;
$nvp_green= 1500;
$nvp_red= 3000;
$OptR_wns_green= -30;
$OptR_wns_red= -50;
$OptR_tns_green= -5.0;
$OptR_tns_red= -10.0;
$OptR_nvp_green= 1000;
$OptR_nvp_red= 2000;
$ptsetup_wns_green= -30;
$ptsetup_wns_red= -50;
$ptsetup_tns_green= -5.0;
$ptsetup_tns_red= -10.0;
$ptsetup_nvp_green= 1000;
$ptsetup_nvp_red= 2000;


#hold wns tns limit
 $hld_wns_red= -60;
 $OptR_hld_wns_red= -40;
 $pthld_wns_red= -20;
 $hld_tns_red= -30;
 $OptR_hld_tns_red= -10;
 $pthld_tns_red= -10;
 $hld_nvp_red= 5000;
 $OptR_hld_nvp_red= 2000;
 $pthld_nvp_red= 2000;
 

#congesiton/util for data color
 $cong_green = 0.3;
 $cong_red = 0.5;
 $drc_green = 100;
 $drc_red = 300;
 $short_green = 20;
 $short_red = 50;
 $feed_red = 10000;
 $util_green = 55;
 $util_red = 58;
 $util_delta_green = 5.0;
 $util_delta_red = 6.0 ;

#drv  color limit
 $clk_tran_red= 15;
 $data_tran_red=500;

#$module_l=1;
#timing analysis level
##if set special L for some tile
###%module_exp=(tile1=>L,tile2=>L)
##%module_exp=(gc_2ea_t=>2,gc_2ea_1_t=>2);
$module_l=1;
#$node ="TSMCN4P";
$node ="TSMCN6";




1;
    
    
    

