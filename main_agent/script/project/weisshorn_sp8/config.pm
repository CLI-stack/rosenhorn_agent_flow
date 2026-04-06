############config env
#%clk_name =(dcn_dsc_t=>DCE_DSCCLK1,dcn_dsc_0_t=>DCE_DSCCLK0,dcn_dsc_1_t=>DCE_DSCCLK3);
%clk_name =(cit_=>USRFCLK,df_=>FCLK,vcn_=>DCLK);
#
# #noSI PT
 @PtFuncSetup = qw/PtTimFuncTT0p9vEcoRouteSiTyprc100cTT0P9V100CStp PtTimFuncTT0p65vEcoRouteSiTyprc100cTT0P65V0CStp PtTimFuncFFG1p05vEcoRouteSiTyprc100cFFG1P05V0CStp PtTimFuncSSG0p6vEcoRouteSiTyprc100cSSG0P6V0CStp/;
#If flow  merged SI  and noSi report,use below PT setting
####SI PT
 @PtFuncSetup_SI = qw/PtTimFuncTT0p9vEcoRouteSiTyprc100cTT0P9V100CStp PtTimFuncTT0p65vEcoRouteSiTyprc100cTT0P65V0CStp PtTimFuncFFG1p05vEcoRouteSiTyprc100cFFG1P05V0CStp PtTimFuncSSG0p6vEcoRouteSiTyprc100cSSG0P6V0CStp/;
 @PtScanSetup = qw/PtTimScanShiftFFG1p05vEcoRouteTyprc100cFFG1P05V0CStp PtTimScanShiftSSG0p6vEcoRouteTyprc100cSSG0P6V0CStp/;
 @PtScanSetup_SI= qw/PtTimScanShiftFFG1p05vEcoRouteSiTyprc100cFFG1P05V0CStp PtTimScanShiftSSG0p6vEcoRouteSiTyprc100cSSG0P6V0CStp/;





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
 $time_ecoroute_red =10;
 $time_eco_t_red=15;

#setup wns tns limit
 $wns_green= -50;
 $wns_red= -25;
 $tns_green= -1.0;
 $tns_red= -3.0;
 $nvp_green= 200;
 $nvp_red= 500;
 $ptsetup_wns_green= 0;
 $ptsetup_wns_red= 0;
 $ptsetup_tns_green= 0;
 $ptsetup_tns_red= 0;
 $ptsetup_nvp_green= 0;
 $ptsetup_nvp_red= 0;

#hold wns tns limit
 $pthld_wns_red= 0;
 $pthld_tns_red= 0;
 $pthld_nvp_red= 0;


#congesiton/util for data color
 $cong_green = 0.5;
 $cong_red = 1;
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
 $clk_tran_red= 0;
 $data_tran_red=0;
 $no_email = 1;
1;
    
    
    

