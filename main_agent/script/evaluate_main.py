
# Copyright (c) 2024 Chen, Simon ; simon1.chen@amd.com;  Advanced Micro Devices, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#from sklearn.externals import joblib
import joblib
import ml_def
import re
congestion_th = 0.4

#rpt_predict = open("navi4c_NLA.txt",'r')
rpt_predict = open("input.txt",'r')
#rpt_predict = open("navi24_NLD.txt",'r')
#rpt_predict = open("navi21_NLD.txt",'r')
#rpt_predict = open("obren.txt",'r')
buff_prpt = rpt_predict.readlines()

rfhm='rfh_'+str(congestion_th)+'.model'
rfvm='rfv_'+str(congestion_th)+'.model'
print("# current lib: ",rfhm,rfvm)
# evaluating & predict
need_incr = 0
util_delta = 0.02
n_p9 = 0
n_p2 = 0


print('%30s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%14s%14s%10s%14s%14s%14s' % (
        "tile,", "ini_util,", "max_util,", "mr,", "ar,", "cr,", "w_dens,", "h_dens,", "v_feed_real,", "h_feed_real,", "pre_h,",
        "pre_v,", "util_delta,","max_0_prob_h,","max_0_prob_v,","max_1_util,","max_1_prob_h,","max_1_prob_v,"))
for line in buff_prpt:
    if len(line.split()) < 11:
        print("imcomplete data")
        continue
    tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,\
    hcongestion_ex,vcongestion_ex = line.split()
    #continue
    result = ml_def.evaluate_util (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex,rfhm,rfvm)
    
    print(re.sub('\s+',',',result))
    #ml_def.evaluate_aspectRatio (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex,rfhm,rfvm)
    # tile_ex,initial_util,util_ex,mr_ex....util_ex-initial_util

test= "df	0.4676690	0	0.8333	0	0.032 	0.041 766	1205	0.1	0.1"

tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex = test.split()
#ml_def.evaluate_aspectRatio (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex,rfhm,rfvm)
#ml_def.evaluate_util (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex,rfhm,rfvm)

#test = "gc_sp11_t	0.497418928	0.221694678	3.0000 0.2693 0.2010 0.8549	472	6022 0.1 0.1"

#ml_def.predict (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,hcongestion_ex,vcongestion_ex,rfhm,rfvm)
