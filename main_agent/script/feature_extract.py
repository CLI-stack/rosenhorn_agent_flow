import os
import gzip
#import xlwt
import xlsxwriter
import sys
import csv
from fnmatch import fnmatch,fnmatchcase
import re
import sys
#rpts/PtFlatFUNCTT0P9VTYPRC100CTT0P9V100CStpTiming/GC_GFXCLK_max.rpt.gz


###feature defination###
##slack 
##start 
##end 
##ALOL 
##RLOL 
##max_fanout 
##max_trans 
##max_cell_dly 
##Start_clk 
##Start_clk_edge 
##Start_edge_time 
##End_clk 
##End_clk_edge 
##End_edge_time 
##skew 
##clk_uncertanty 
##lib_setup_time 
##start_lib 
##end_lib 
##elvt_ratio(%) 
##ulvt_ratio(%) 
##ulvtll_ratio(%) 
##lvt_ratio(%) 
##lvtll_ratio(%) 
##svt_ratio(%) 
##distance 
##distance_detour
#########################

##AOI number
##cell number
##SI noise
##delay cell/low driver buf(D1/D2/D0p5)


setting_enable_location = 0
def max_out(a,b):
  a = float(a)
  b = float(b)
  if (a>b):
    return a
  if (a<=b):
    return b

pin_check_list = [\
'RD->Q', \
'SD->Q', \
'RESETH->Q', \
'SETH->Q', \
'RD->QN', \
'SD->QN', \
'RESETH->QN', \
'SETH->QN', \
'RD->SD', \
'SD->RD', \
'S->R', \
'R->S' \
]

#release_dir = '/proj/navi44-pdrel11-backup/NLC/'
#IP_list = ['smu_asp_clk_t','smu_clk_dfs2_t','smu_clk_dfs6_t','smu_ctsen_0_t','smu_fuse_t','smu_mpio_t']
#IP_list = ['smu_asp_sib_baco_t','smu_clk_dfs3_t','smu_clk_dfs8_t','smu_ctsen_1_t','smu_mp1_t','smu_thm_t']
#IP_list = ['df_tcdxh_t','df_mall_1_t','df_tcdx_dce_t','df_tcdxb_1_t','df_tcdxg_1_t','df_tcdxi_chip_t','df_mall_chip_1_t','df_tcdx_gcmx2_chip_t','df_tcdxb_chip_1_t','df_tcdxg_chip_1_t','df_tcdxi_t','df_mall_chip_t','df_tcdx_gcmx2_t','df_tcdxb_chip_2_t','df_tcdxg_chip_t','df_mall_t','df_tcdx_mmhub0_mmhub1_t','df_tcdxb_chip_t','df_tcdxg_t','df_tcdx_pie_t','df_tcdxb_t','df_tcdxh_1_t','df_tcdxa_1_t','df_tcdxc_1_t','df_tcdxh_chip_1_t']
#IP_list = ['pcie_cphy16_t']

#release_dir = '/proj/navi44-pdrel3-backup/NLB/'
#files = release_dir + tile + '/latest/' + 'workspace/'+ 'rpts/' + 'PtTimFuncTT0p9vReRouteSxTyprc100cTT0P9V100CStp/si_' + group + '_max.rpt.gz'
#files = release_dir + tile + '/latest/' + 'workspace/'+ 'rpts/' + 'SortFuncTT0p9vReRouteSxStpGrp/S.INTERNAL.sorted.gz'
#file_dir = '/proj/wek_pd_fct_4/xinyucao/ML/ML_tile/NLBm2_data/'

if len(sys.argv) < 2:
    print("Usage: python script.py <argument>")
    sys.exit(1)  # Exit with a non-zero status to indicate an error

file_dir = sys.argv[1]
#Files = [\
#'abnormal_delay1', \
#'abnormal_delay2', \
#'abnormal_delay3', \
#'abnormal_delay4', \
#'abnormal_delay5', \
#'async_clock', \
#'async_clock2', \
#'async_clock3', \
#]
#files = 'rpts/' + 'SortFuncTT0p9vReRouteSxStpGrp/S.INTERNAL.sorted.gz'
#print(files)
#files = 'rpts/SortAllReRouteSxStpGrp/S.INTERNAL.sorted.gz'
#for File in Files:
files = file_dir
#print(files)

with open('output','wb') as f0:
  f0.write('start,end,period,slack,slack_per_period,ALOL,RLOL,max_fanout,max_trans_per_period,max_cell_dly_per_period,Start_clk,Start_clk_edge,Start_edge_time_per_period,End_clk,End_clk_edge,End_edge_time_per_period,skew,skew_overslack_per_period,clk_uncert_per_period,lib_stp_time,start_lib,end_lib,AOI_cell,AOI_ratio,DEL_cell,Low_driver_buf,SI_total_per_period,pll_num,pll_dly_per_period,elvt_ratio(%),ulvt_ratio(%),ulvtll_ratio(%),lvt_ratio(%),lvtll_ratio(%),svt_ratio(%),distance,distance_detour,async_tag,disable_timing_arc,case_analyze,remove_generated_clk,external_delay\n')
  #for tile in IP_list:
 
  i = 0
  matrix = []
  result = []
  dic_inst = {}
  UNIT = 2000
  distance_delta = distance_act = distance_detour = distance = 0
  loc_x_inst = loc_x_top = loc_x_tile = loc_x_inst_prev = loc_x_inst_start = loc_x_inst_end = 0
  loc_y_inst = loc_y_top = loc_y_tile = loc_y_inst_prev = loc_y_inst_start = loc_y_inst_end = 0
  #initial_status()
  #with open('output','wb') as f0:
    #f0.write('Group,slack,start,end,ALOL,RLOL,max_fanout,max_trans,max_cell_dly,Start_clk,Start_clk_edge,Start_edge_time,End_clk,End_clk_edge,End_edge_time,skew,clk_uncertanty,lib_setup_time,start_lib,end_lib,elvt_ratio(%),ulvt_ratio(%),ulvtll_ratio(%),lvt_ratio(%),lvtll_ratio(%),svt_ratio(%)\n')
  #Group = ['FCLK']
  #Group = ['DCN_DISPCLK']
  #Clock = ['FCLK']
  

  #def_dir = release_dir + tile + '/latest/' + 'workspace/'+ 'data/ReRoute.def.gz'
  def_dir = '../../../data/ReRoute.def.gz'
  #output_dir = '/home/xinyucao/ML/ML_tile/data/' + 'feature_extract_' + tile + '.csv'
  #output_dir = 'feature_extract.csv'
  #sdc_dir = release_dir + tile + '/latest/' + 'workspace/'+ 'data/sdc/setup.FuncTT0p9v.sdc'
  
  #sdc_file = 'sdc_tt0p9v_' + tile
  #if os.path.exists(sdc_dir) == 1:
  #  grep_clk_cmd = 'zgrep -E \'create_clock|create_generated_clock\' ' + sdc_dir + ' > ' + sdc_file 
  #  os.system(grep_clk_cmd)
  #  print('sdc info is ready')
  
  
  #for group in Group:
  
  #def initial_status() :
  start = ''
  end = ''
  path_tag = 0
  data_tag = 0
  slack = 0
  ALOL = 0
  RLOL = 0
  fanout = 0
  max_fanout = 0
  trans = 0
  max_trans = 0
  cell_dly = 0
  max_cell_dly = 0
  Start_clk = ''
  Start_clk_edge = ''
  Start_edge_time = 0
  End_clk = ''
  End_clk_edge = ''
  End_edge_time = 0
  launch_lty = 0
  capture_lty = 0
  crpr = 0
  skew = 0
  clk_uncert = 0
  lib_stp_time = 0
  start_lib = ''
  end_lit = ''
  m = 0
  vt_total = []
  tile_inst_key = {}
  num_tag = 1
  Key = []
  AOI_cell = 0
  cell_num = 0
  DEL_cell = 0
  Low_driver_buf = 0
  si = 0
  SI_total = 0
  pll_num = 0
  pll_dly = 0
  group = ''
  period = 0
  AOI_ratio = 0 
  skew_overslack_per_period = 0
  cell_loc = x1 = y1 = x_loc = y_loc = x_loc_pre = y_loc_pre = 0
  cell_loc_start = x1_start = y1_start = x_loc_start = y_loc_start = 0
  cell_loc_end = x1_end = y1_end = x_loc_end = y_loc_end = 0
  distance = distance_delta = distance_act = distance_detour = 0
  cell_dly_total = 0
  net_dly = 0
  net_dly_total = 0
  net_dly_percent = 0
  cell_dly_percent = 0
  pin_cnt = 0
  pin1 = pin2 = cell2 = ref2 = pin_vector = ''
  async_tag = disable_timing_arc = case_analyze = remove_generated_clk = 0
  input_delay = output_delay = external_delay = 0
  with gzip.open(files,'rb') as f1: 
    for line in f1.readlines():
      line = line.decode().strip('\n')
      if 'Startpoint' in line :
        start = str(line.split()[1])
        if '/CP' in start or '/CLK' in start or '/SRAM' in start:
          start = os.path.split(start)[0]
          #print(start)
        #print(start)
      if 'Endpoint' in line :
        end = str(line.split()[1])
        if '/CP' in end or '/CLK' in end or '/SRAM' in end or 'pma/' in end or '/PDP' in end:
          end = os.path.split(end)[0]
        #print(end)
      if 'Path Group' in line:
        group = line.split()[2]
      if 'input external delay' in line:
        input_delay = float(line.split()[3])
      if 'output external delay' in line:
        output_delay = float(line.split()[3])


      #if start in line and start and 'Startpoint' not in line and 'Endpoint' not in line and '/Z ' not in line and '/ZN ' not in line and '/D' not in line and '/CP' not in line and '/CLK' not in line and '/CK' not in line and '/CLKM ' not in line and '(net)' not in line and '/Q' in line:
      if start in line and start and 'Startpoint' not in line and 'Endpoint' not in line and '/CK' not in line and '/CP' not in line and '(net)' not in line and 'internal path' not in line and ' edge)' not in line:
        data_tag = 1
        start_lib = str(line.split()[1])
        #print(line)
  
        inst_start = start
        key_start = {} 
        key_start['No'] = 0 
        key_start['inst'] = str(inst_start)
        #print(key_start)
        Key.append(key_start)
  
  
        if inst_start not in dic_inst:
          dic_inst[inst_start] = ''
        cell_num = cell_num + 1
        #print(line)
        if setting_enable_location == 1:
          cell_loc_start = line.split()[7]
          if cell_loc_start == 'unplaced':
            cell_loc_start = (0,0)
          x1_start = cell_loc_start.split(',')[0]

          x_loc_start = float(x1_start.split('(')[1])
          y1_start = cell_loc_start.split(',')[1]
          y_loc_start = float(y1_start.split(')')[0])

          x_loc_per = x_loc_start
          y_loc_per = y_loc_start
        if setting_enable_location == 1:
         x_loc_per = x_loc_start = y_loc_per = y_loc_start = 0        

      if end in line and end and 'Endpoint' not in line and '/CP ' not in line and '/CP0' not in line and '/CP1' not in line and 'CK ' not in line and 'CLK ' not in line and '(net)' not in line:
        #if end in line and end  and 'Endpoint' not in line and '/Q' not in line and '/CP ' not in line and '/CP0' not in line and '/CP1' not in line and '(net)' not in line and 'Last common pin' not in line and 'CKINV' not in line and 'CKBUF' not in line and '/ZN ' not in line and '/Z ' not in line and '_pll' not in line:
        data_tag = 0
        end_lib = str(line.split()[1])
        #print(line)
  
        inst_end = end
        key_end = {} 
        key_end['No'] = num_tag 
        key_end['inst'] = str(inst_end)
        #print(key_start)
        Key.append(key_end)
  
  
        if inst_end not in dic_inst:
          dic_inst[inst_end] = ''
        cell_num = cell_num + 1
        #print(line)
        if setting_enable_location == 1:        
          cell_loc_end = line.split()[9]
          if cell_loc_end == 'unplaced':
            cell_loc_end = (0,0)        
          x1_end = cell_loc_end.split(',')[0]
          x_loc_end = float(x1_end.split('(')[1])
          y1_end = cell_loc_end.split(',')[1]
          y_loc_end = float(y1_end.split(')')[0])
          distance =  abs(x_loc_end - x_loc_start) + abs(y_loc_end - y_loc_start)
          distance_delta = abs(x_loc_end-x_loc_per)+abs(y_loc_end-y_loc_per)
          distance_act = distance_act+distance_delta
          distance_detour = distance_act-distance

          distance = round(distance/UNIT,2)
          distance_detour = round(distance_detour/UNIT,2)
        if setting_enable_location == 0:
          distance = distance_delta = distance_act = distance_detour = 0
        #print(distance,distance_detour) 
  
      if start in line and start and 'Startpoint' not in line and '/CP' in line:
        launch_lty = float(line.split()[6])
      if end in line and end and 'Endpoint' not in line and '/CP' in line and len(line.split()) > 7:
        #print(line)
        capture_lty = float(line.split()[6])

      if 'clock reconvergence pessimism' in line:
        crpr = float(line.split()[-2])
      if data_tag == 1 and '/Z' in line and '(net)' not in line and float(line.split()[-4]) != 0.00:
        #print(line)
        #if line.split()[3] != 0:
        ALOL = ALOL + 1
        vt_total.append(str(line.split()[1]))
        data_inst = line.split()[0]
  
  
        inst = line.split()[0]
        inst_new =  inst.split('/Z')[0]
  
  
        key_1 = {} 
        key_1['No'] = num_tag 
        key_1['inst'] = str(inst_new)
        #print(key_start)
        Key.append(key_1)
  
        #print(inst_new)
        if inst_new not in dic_inst:
          dic_inst[inst_new] = ''
  
        num_tag = num_tag + 1
        cell_num = cell_num + 1
  
  
      if data_tag == 1 and '/Z' in line and 'INV' not in line and 'BUF' not in line and '(net)' not in line:
        RLOL = RLOL + 1
      if data_tag == 1 and '/Z' in line and ('AOI' in line or 'OAI' in line) and '(net)' not in line:
        AOI_cell = AOI_cell + 1
      if data_tag == 1 and '/Z' in line and 'DEL' in line and '(net)' not in line:
        DEL_cell = DEL_cell + 1
      if data_tag == 1 and 'systempll' in line and '_data' in line:
        pll_num =  pll_num + 1
        pll_dly = float(line.split()[3])
      #if data_tag == 1 and '/Z' in line and ('BUF' in line or 'INV' in line) and '(net)' not in line and ('D0' in line or 'D0p5' in line or 'D1' in line or 'D2' in line) and ('D10' not in line and 'D12' not in line):
      if data_tag == 1 and '/Z' in line and ('BUF' in line or 'INV' in line) and '(net)' not in line and ('T01_' in line.split()[1] or 'T02_' in line.split()[1]):
        Low_driver_buf = Low_driver_buf + 1
      if data_tag == 1 and '(net)' in line  and len(line.split()) > 2:
        #print(len(line.split()))
        #print(line)
        fanout = line.split()[-2]
        max_fanout = max_out(fanout,max_fanout)
      if data_tag == 1 and '/Z' not in line and '/Q' not in line and '/CO' not in line and '/S' not in line and '/D' not in line and len(line.split()) > 4:
        #print(line)        
        trans = line.split()[2]
        max_trans = max_out(trans,max_trans)
        #print(trans)
        #si = float(line.split()[4])
        #SI_total = float(SI_total) + float(si)
        SI_total = 0
        #print(si,SI_total)
        net_dly = line.split()[3]
        #print(net_dly,line)
        net_dly_total = float(net_dly_total) + float(net_dly)


      if data_tag == 1 and '/Z' in line and '(net)' not in line:
        #cell_dly = line.split()[-5]
        cell_dly = line.split()[4]
        max_cell_dly = max_out(cell_dly,max_cell_dly)
        cell_dly_total = float(cell_dly_total) + float(cell_dly)        
        #print(line)
        max_cell_dly = max_out(cell_dly,max_cell_dly) 
        #print(line)
        if setting_enable_location == 1:
          cell_loc = line.split()[-1]
          if cell_loc == 'unplaced':
            cell_loc = (0,0)        
          x1 = cell_loc.split(',')[0]
          x_loc = float(x1.split('(')[1])
          y1 = cell_loc.split(',')[1]
          y_loc = float(y1.split(')')[0])

          distance_delta = abs(x_loc - x_loc_per)+abs(y_loc - y_loc_per)
          distance_act = distance_act + distance_delta
          x_loc_per = x_loc
          y_loc_per = y_loc
        if setting_enable_location == 0:
          distance = distance_delta = distance_act = distance_detour = 0          

      if 'clock ' in line and 'edge' in line and '(recover' not in line:
        if m == 0:
          Start_clk = str(line.split()[1])
          Start_clk_edge = str(line.split()[2].split('(')[1])
          Start_edge_time = float(line.split()[5])
          m = m + 1
        if m == 1:
          End_clk = str(line.split()[1])
          End_clk_edge = str(line.split()[2].split('(')[1])
          End_edge_time = float(line.split()[5])
          if 'systempll/DCOCLK' in End_clk or 'systempll/syspll_custom_PrePllOut_clk_pin' in End_clk or ('systempll/pc_custom' in End_clk and 'clk_pin_0' in End_clk) or ('dcn_phy_t' in End_clk and '/phy' in End_clk) or 'systempll/pc_sapr_clk_tdc' in End_clk or ('dxio_serdes_cphy4444_t' in End_clk and '/uephy_tx4rx4_n7_pn' in End_clk):
            remove_generated_clk = 1
      if 'inter-clock uncertainty' in line:
        clk_uncert = float(line.split()[-2])
      if 'library setup time' in line:
        lib_stp_time = float(line.split()[-2])
      if '(net)' not in line and '(HDN' in line and data_tag == 1:
        pin_cnt += 1
        cell2 = os.path.split(line.split()[0])[0]
        ref2 = line.split()[1]
        pin2 = os.path.split(line.split()[0])[1]
        #print(pin2)
        if pin_cnt % 2 == 0:
          pin_vector = str(pin1+'->'+pin2)
          ##disable timing arc check
          for pin_check in pin_check_list:
            if pin_vector == pin_check:
              disable_timing_arc = 1
          if pin_vector == 'CLK1->CLKSEL' or pin_vector == 'CLK2->CLKSEL':
            if 'ch/s0_bif_tile/s0_pg1/clock_spine_s0_bif/hi' in cell2 and 'IoDftMux/d0nt_I0' in cell2 and 'MPCTS' in cell2:
              disable_timing_arc = 1
            if 'MUX2_CK' in ref2 and 'genblk1_clone_for_mpcts/d0nt_scan_clkmux/d0nt_mux' not in cell2 and 'genblk1_clone_for_mpcts/d0nt_ssb_clkmux/d0nt_mux' not in cell2 and 'mrk_scan_clkmux_' not in cell2 and 'd0nt_tp_scan_clkmux' not in cell2 and 'genblk1_clone_for_mpcts/d0nt_scan_reg_clkmux/d0nt_mux' not in cell2: 
              disable_timing_arc = 1
            if '/tile_dfx/dft_clk_cntl_*/genblk*_mrk_scan_clkmux_' in cell2 and '/d0nt_mux' in cell2:
              disable_timing_arc = 1
          if 'clone_for_mpcts/d0nt_ssb_clkmux/' in cell2 and 'd0nt_mux*MPCTS' in cell2 and pin2 == 'CLKSEL':
           case_analyze = 1 
        pin1 = pin2
        
      if 'slack' in line and 'VIOLATED' in line and 'increase' not in line: 
        slack = float(line.split()[2])
        skew = int((capture_lty - End_edge_time) - (launch_lty - Start_edge_time) + crpr)
        if Start_clk != End_clk and Start_clk not in End_clk and End_clk not in Start_clk:
          async_tag = 1
        external_delay = input_delay - output_delay
        #print(skew,Start_edge_time,launch_lty,End_edge_time,capture_lty,crpr)
  
        #s = vt.count('*ULVT*')
        #print(s)
        #result = [case for case in vt if fnmatchcase(case,"*ULVT)")]
        #print(len(result))

  
        vt_count = float(len(vt_total))
        #print(vt_total)
        #print(vt_count)
        if vt_count == 0:
          elvt_ratio = 'None'
          ulvt_ratio = 'None'
          ulvtll_ratio = 'None'
          lvt_ratio = 'None'
          lvtll_ratio = 'None'
          svt_ratio = 'None'
        else:
          elvt = [case for case in vt_total if fnmatchcase(case,"*ELVT*")]
          ulvt = [case for case in vt_total if fnmatchcase(case,"*ULT*")]
          ulvtll = [case for case in vt_total if fnmatchcase(case,"*ULTLL*")]
          lvt = [case for case in vt_total if fnmatchcase(case,"*LVT*")] 
          lvtll = [case for case in vt_total if fnmatchcase(case,"*LVTLL*")]
          svt = [case for case in vt_total if fnmatchcase(case,"*SVT*")]
          elvt_count = len(elvt)
          ulvt_count = len(ulvt)
          ulvtll_count = len(ulvtll)
          lvt_count = len(lvt) - elvt_count
          lvtll_count = len(lvtll) - ulvtll_count
          svt_count = len(svt)
          ulvt_count = ulvt_count - ulvtll_count
  
          elvt_ratio = round(elvt_count/vt_count*100,2)
          ulvt_ratio = round(ulvt_count/vt_count*100,2)
          ulvtll_ratio = round(ulvtll_count/vt_count*100,2)
          lvt_ratio = round(lvt_count/vt_count*100,2)
          lvtll_ratio = round(lvtll_count/vt_count*100,2)
          svt_ratio = round(svt_count/vt_count*100,2)
        #print(elvt_ratio,ulvt_ratio,ulvtll_ratio,lvt_ratio,lvtll_ratio,svt_ratio)
  
  
        #json = 'data/FlatFUNCTT0P9VTYPRC100CTT0P9V100CStpTiming/design.json' 
        #with open(json,'rb') as f2:
        #  for line2 in f2.readlines():
        #    for key in tile_inst_key:           
        #      if key in line2 and 'def.gz' in line2:
        #        #print(ALOL)
        #        def_dir = line2.split('\"')[1]
        #        #print(def_dir)
  
        #        with gzip.open(def_dir,'rb') as f3:
        #          for line3 in f3.readlines():
        #            value = tile_inst_key[key]
        #            cnt = value.count(',')
  
        #            i = 0
        #            for i in range(0,cnt):
        #              value_new = value.split(',')[i]
        #              i = i + 1 
  
        #              if value_new in line3 and ('FIXED' in line3 or 'PLACED' in line3):
        #                print(line3)
        #                #key_x[value_new] = 
  
  
        #        f3.close()
        #f2.close()
  
  
        ###scale period related features based on clk
        period = 0
        if '\'' in End_clk:
          End_clk2 = End_clk.split('\'')[0]
        else:
          End_clk2 = End_clk
  
        #with open(sdc_file,'rb') as f3:
        #  for line_sdc in f3.readlines():
        #    if End_clk2 in line_sdc:
        #      print(line_sdc)
        #      period = float(line_sdc.split()[4])
        #      #print(period)
        #      break
        #print(End_clk2,period)
        #period = End_edge_time - Start_edge_time
        if Start_edge_time == End_edge_time:
          period = 999999
        else:
          period = End_edge_time - Start_edge_time



        slack_per_period = round(slack/period,4)
        max_trans_per_period = round(max_trans/period,4)
        Start_edge_time_per_period = Start_edge_time/period
        End_edge_time_per_period = End_edge_time/period
        SI_total_per_period = round(SI_total/period,4)
        clk_uncert_per_period = round(clk_uncert/period,4)
        pll_dly_per_period = round(pll_dly/period,4)
        max_cell_dly_per_period = round(max_cell_dly/period,4)
  
        if cell_num > 0:
          AOI_ratio = round(float(AOI_cell)/float(cell_num),4)
        else:
          AOI_ratio = 0

        AOI_ratio = round(float(AOI_cell)/float(cell_num),4)        
        skew_overslack_per_period = round((skew-slack)/period,4)
        #net_dly_percent = float(net_dly_total)/(float(net_dly_total)+float(cell_dly_total))
        #cell_dly_percent = float(cell_dly_total)/(float(net_dly_total)+float(cell_dly_total))
        #j = {}
        #j['No'] = -1
        #j['tile'] = tile
        #j['slack_per_period'] = slack_per_period
        #j['start'] = start
        #j['end'] = end
        #j['period'] = period
        ##j['dic_top'] = dic_top 
        #j['ALOL'] = ALOL
        #j['RLOL'] = RLOL
        #j['max_fanout'] = max_fanout
        #j['max_trans_per_period'] = max_trans_per_period
        #j['max_cell_dly_per_period'] = max_cell_dly_per_period
        #j['Start_clk'] = Start_clk
        #j['Start_clk_edge'] = Start_clk_edge
        #j['Start_edge_time_per_period'] = Start_edge_time_per_period
        #j['End_clk'] = End_clk 
        #j['End_clk_edge'] = End_clk_edge 
        #j['End_edge_time_per_period'] = End_edge_time_per_period
        #j['skew'] = skew
        #j['clk_uncert_per_period'] = clk_uncert_per_period 
        #j['lib_stp_time'] = lib_stp_time
        #j['start_lib'] = start_lib
        #j['end_lib'] = end_lib
        #j['AOI_cell'] = AOI_cell
        #j['AOI_ratio'] = AOI_ratio
        #j['DEL_cell'] = DEL_cell
        #j['Low_driver_buf'] =Low_driver_buf
        #j['SI_total_per_period'] = SI_total_per_period
        #j['pll_num'] = pll_num
        #j['pll_dly_per_period'] = pll_dly_per_period
        #j['elvt_ratio'] = elvt_ratio 
        #j['ulvt_ratio'] = ulvt_ratio
        #j['ulvtll_ratio'] = ulvtll_ratio
        #j['lvt_ratio'] = lvt_ratio
        #j['lvtll_ratio'] = lvtll_ratio
        #j['svt_ratio'] = svt_ratio
  
        j = []
        #j.append(tile) 
        j.append(start) 
        j.append(end)
        j.append(period)
        j.append(slack)
        j.append(slack_per_period) 
        j.append(ALOL) 
        j.append(RLOL) 
        j.append(max_fanout) 
        j.append(max_trans_per_period) 
        j.append(max_cell_dly_per_period) 
        j.append(Start_clk) 
        j.append(Start_clk_edge) 
        j.append(Start_edge_time_per_period) 
        j.append(End_clk) 
        j.append(End_clk_edge) 
        j.append(End_edge_time_per_period)
        j.append(skew)
        j.append(skew_overslack_per_period) 
        j.append(clk_uncert_per_period) 
        j.append(lib_stp_time) 
        j.append(start_lib) 
        j.append(end_lib) 
        j.append(AOI_cell) 
        j.append(AOI_ratio) 
        j.append(DEL_cell) 
        j.append(Low_driver_buf) 
        j.append(SI_total_per_period) 
        j.append(pll_num) 
        j.append(pll_dly_per_period) 
        j.append(elvt_ratio) 
        j.append(ulvt_ratio) 
        j.append(ulvtll_ratio) 
        j.append(lvt_ratio) 
        j.append(lvtll_ratio) 
        j.append(svt_ratio)
        j.append(distance)
        j.append(distance_detour)
        j.append(async_tag)
        j.append(disable_timing_arc)
        j.append(case_analyze)
        j.append(remove_generated_clk)
        j.append(external_delay)

        matrix.append(j)              
  
        #Key.insert(0,j)
  
        #print(Key)
        #result.append(Key)
        
  
        f0.write("%s\n" %(matrix[i]))
        #print(matrix)
        #print(i)
        i = i + 1
        m = 0
        #print("%s %s %s %s" %(slack,data_tag,ALOL,RLOL)) 
        #initial_status()
        start = ''
        end = ''
        path_tag = 0
        data_tag = 0
        slack = 0
        ALOL = 0
        RLOL = 0
        fanout = 0
        max_fanout = 0
        trans = 0
        max_trans = 0
        cell_dly = 0
        max_cell_dly = 0
        Start_clk = ''
        Start_clk_edge = ''
        Start_edge_time = 0
        End_clk = ''
        End_clk_edge = ''
        End_edge_time = 0
        launch_lty = 0
        capture_lty = 0
        crpr = 0
        skew = 0
        clk_uncert = 0
        lib_stp_time = 0
        start_lib = ''
        end_lit = ''
        m = 0
        vt_total = []
        tile_inst_key = {}
        num_tag = 0
        AOI_cell = 0
        cell_num = 0
        DEL_cell = 0
        Low_driver_buf = 0
        si = 0
        SI_total = 0
        Key = []
        pll_num = 0
        pll_dly = 0
        group = ''
        CLK_standard = ''
        period = 0
        AOI_ratio = 0 
        skew_overslack_per_period = 0
        cell_loc = x1 = y1 = x_loc = y_loc = x_loc_pre = y_loc_pre = 0
        cell_loc_start = x1_start = y1_start = x_loc_start = y_loc_start = 0
        cell_loc_end = x1_end = y1_end = x_loc_end = y_loc_end = 0
        distance = distance_delta = distance_act = distance_detour = 0
        cell_dly_total = 0
        net_dly = 0
        net_dly_total = 0
        net_dly_percent = 0
        pin_cnt = 0  
        pin1 = pin2 = cell2 = ref2 = pin_vector = ''
        disable_timing_arc = case_analyze = remove_generated_clk = 0
        async_tag = 0
        input_delay = output_delay = external_delay = 0
      if 'slack' in line and 'VIOLATED' in line and 'increase' in line: 
       break 
  
  


#print('logical ready')
output = 'feature_extract_' + sys.argv[2] + '.csv'
with open(output,'w') as f2:
  with open('output','r') as f3:
    for line in f3.readlines():
      line_1 = line.replace('[','')
      line_2 = line_1.replace(']','')
      line_3 = line_2.replace('\'','')
      line_4 = line_3.replace('\"','')
      line_5 = line_4.replace('(','')
      line_6 = line_5.replace(')','')

      f2.write("%s" %(line_6)) 
     
  f2.close()
  f3.close()
  #print('feature_extract_finished')
f0.close()
f1.close() 

#  #print(result)
#  
#  def_dir2 = 'def_' + tile
#  print(def_dir2)
#  if os.path.exists(def_dir2) != 1:
#    tmpdir2 = 'zgrep -P "FIXED|PLACED" ' + def_dir + '| grep -v DCAP | grep -v FILL | grep -v TAPER | grep -v dfifiller > ' + def_dir2
#    os.system(tmpdir2)
#    print('def dir okay')
#  
#  with open(def_dir2,'rb') as f2:
#    print('gzip okay')
#    for line_def in f2.readlines():
#      for inst_element in dic_inst:
#        if inst_element == 'phy_housing_wrp_TMDP/u_dwc_usbc31dptxphy_phy_x4_ns/pma/rx2_ana_dword_iclk_icheckpin1':
#          oo = 'phy_housing_wrp_TMDP/u_dwc_usbc31dptxphy_phy_x4_ns/pma'
#          inst_element = oo
#        if inst_element in line_def and  ('FIXED' in line_def or 'PLACED' in line_def) and 'GDCAP' not in line_def:
#          #print(line_def)
#          mm = line_def.split('(')[1]
#          #print(mm)
#          dic_inst[inst_element] = mm.split()[0] + ' ' + mm.split()[1]
#          #print(dic_inst[inst_element])
#          #print(line)
#  
#  
#  f2.close()
#  
#  
#  
#  print('def is ready')
#    
#  with open(output_dir,'wb') as f0:
#    f0.write('tile,slack,start,end,ALOL,RLOL,max_fanout,max_trans,max_cell_dly,Start_clk,Start_clk_edge,Start_edge_time,End_clk,End_clk_edge,End_edge_time,skew,clk_uncertanty,lib_setup_time,start_lib,end_lib,AOI_number,cell_number,delay_cell_number,low_driver_buf_number,SI_total,PLL_number,PLL_delay,elvt_ratio(%),ulvt_ratio(%),ulvtll_ratio(%),lvt_ratio(%),lvtll_ratio(%),svt_ratio(%),distance,distance_detour\n')
#    total_num = float(len(result) + 1)
#    num = 0
#    for x in result:
#      #print(x)
#      for i in (range(len(x))): 
#        if i > 0:
#          loc_x_inst_prev = loc_x_inst
#          loc_y_inst_prev = loc_y_inst
#        else:
#          loc_x_inst_prev = 0
#          loc_y_inst_prev = 0
#        for y in x:
#          #print(y)
#          if y['No'] == i:
#  
#            for inst_cycle in dic_inst:
#              #print(y['inst'])
#              if y['inst'] == 'phy_housing_wrp_TMDP/u_dwc_usbc31dptxphy_phy_x4_ns/pma/rx2_ana_dword_iclk_icheckpin1':
#                y['inst'] = 'phy_housing_wrp_TMDP/u_dwc_usbc31dptxphy_phy_x4_ns/pma'
#              if y['inst'] == inst_cycle:
#                #print(dic_inst[inst_cycle])
#                #print(tile_cycle)
#                #print(inst_cycle)
#                loc_x_inst = float(dic_inst[inst_cycle].split()[0])
#                loc_y_inst = float(dic_inst[inst_cycle].split()[1])
#                #print(loc_x_inst)
#                #print(loc_y_inst)
#                #if orient_top == 'N':
#                #  loc_x_inst = float(loc_x_top) + float(loc_x_tile)
#                #  loc_y_inst = float(loc_y_top) + float(loc_y_tile)
#                #elif orient_top == 'FN':
#                #  loc_x_inst = float(loc_x_top) - float(loc_x_tile)
#                #  loc_y_inst = float(loc_y_top) + float(loc_y_tile)
#                #elif orient_top == 'S':
#                #  loc_x_inst = float(loc_x_top) - float(loc_x_tile)
#                #  loc_y_inst = float(loc_y_top) - float(loc_y_tile)
#                #elif orient_top == 'FS':
#                #  loc_x_inst = float(loc_x_top) + float(loc_x_tile)
#                #  loc_y_inst = float(loc_y_top) - float(loc_y_tile)
#                loc_x_inst = round(loc_x_inst/UNIT,2)
#                loc_y_inst = round(loc_y_inst/UNIT,2)
#                #print(y)
#                #print(len(x))
#                #print(loc_x_inst,loc_y_inst)
#                break
#    
#  
#        if i > 0:
#          distance_delta = abs(loc_x_inst - loc_x_inst_prev) + abs(loc_y_inst - loc_y_inst_prev)
#          distance_act = distance_act + distance_delta
#          #print('act')
#          #print(distance_act)
#          #print(i,len(x))
#       
#        if i == 0:
#          loc_x_inst_start = loc_x_inst
#          loc_y_inst_start = loc_y_inst
#          #print('start')
#          #print(loc_x_inst_start,loc_y_inst_start)
#        if i == len(x) - 2:
#          loc_x_inst_end = loc_x_inst
#          loc_y_inst_end = loc_y_inst
#          #print('end')
#          #print(loc_x_inst_end,loc_y_inst_end)
#          distance =  abs(loc_x_inst_end - loc_x_inst_start) + abs(loc_y_inst_end - loc_y_inst_start)
#          distance_detour = distance_act - distance
#          break
#        
#        loc_x_top = loc_x_tile = loc_x_inst_prev = 0
#        loc_y_top = loc_y_tile = loc_y_inst_prev = 0
#     
#    
#      distance = round(distance,2)
#      distance_detour = round(distance_detour,2)
#    
#      #print('distance')
#      #print(distance,distance_detour)
#    
#      for z in x:
#        if z['No'] == -1:
#          #print(z)
#          z['distance'] = distance
#          z['distance_detour'] = distance_detour
#          #print(z)
#  
#          out = []
#          out.append(z['tile'])
#          out.append(z['period'])
#          out.append(z['slack_per_period'])
#          out.append(z['start'])
#          out.append(z['end'])
#          out.append(z['ALOL'])
#          out.append(z['RLOL'])
#          out.append(z['max_fanout'])
#          out.append(z['max_trans_per_period'])
#          out.append(z['max_cell_dly_per_period'])
#          out.append(z['Start_clk'])
#          out.append(z['Start_clk_edge'])
#          out.append(z['Start_edge_time_per_period'])
#          out.append(z['End_clk'])
#          out.append(z['End_clk_edge'])
#          out.append(z['End_edge_time_per_period'])
#          out.append(z['skew'])
#          out.append(z['clk_uncert_per_period'])
#          out.append(z['lib_stp_time'])
#          out.append(z['start_lib'])
#          out.append(z['end_lib'])
#          out.append(z['AOI_cell'])
#          out.append(z['AOI_ratio'])
#          out.append(z['DEL_cell'])
#          out.append(z['Low_driver_buf'])
#          out.append(z['SI_total_per_period'])
#          out.append(z['pll_num'])
#          out.append(z['pll_dly_per_period'])
#          out.append(z['elvt_ratio'])
#          out.append(z['ulvt_ratio'])
#          out.append(z['ulvtll_ratio'])
#          out.append(z['lvt_ratio'])
#          out.append(z['lvtll_ratio'])
#          out.append(z['svt_ratio'])
#          out.append(z['distance'])
#          out.append(z['distance_detour'])
#  
#          line_1 = str(out).replace('[','')
#          line_2 = line_1.replace(']','')
#          line_3 = line_2.replace('\'','')
#          line_4 = line_3.replace('\"','')
#          line_5 = line_4.replace('(','')
#          line_6 = line_5.replace(')','')
#  
#  
#          f0.write("%s\n" %(line_6))
#          num = num + 1
#          num_process = round(float(num/total_num),3)
#  
#      distance = distance_detour = distance_act = 0
#  f0.close()
#
##print('feature extraction has been done!')
