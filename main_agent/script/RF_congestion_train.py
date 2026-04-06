# -*- coding: utf-8 -*-
"""
Created on Fri Oct 18 20:53:43 2019

@author: csm_c
"""

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

from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import (RandomForestClassifier,
                              ExtraTreesClassifier)  # Eddie Added
from sklearn.tree import DecisionTreeClassifier
import numpy as np
import matplotlib.pyplot as plt
import math
import numpy.linalg as lg
from sklearn import neural_network
#from imblearn.over_sampling import SMOTE
import pandas as pd
import joblib
import random

import argparse
import csv
import os
import time
import re
import gzip

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--node',type=str, default = "None",required=True,help="tech node")
parser.add_argument('--util',type=str, default = "None",required=True,help="utilization")
parser.add_argument('--ar',type=str, default = "None",required=True,help="aspect ratio")
parser.add_argument('--cr',type=str, default = "None",required=True,help="aoi ratio")

args = parser.parse_args()

congestion_th = 0.2
smote_flag = 0

# disable feature
disable_feature = {}
#disable_feature['mr'] = 1

congestion_high = 2
bypass = 1
pin_high = 0.32
pin_low = 0.12
util_high = 0.75
util_low = 0.3
ar_low = 0.33
ar_high = 3
v_feed_low = 2000
h_feed_low = 2000
v_feed_high = 12000
h_feed_high = 12000
cr_low = 0.3
util_delta = 0.02

ratio_drop = 0.33

print("# current congestion threshold: ",congestion_th)
rpt = open(args.node,'r')
fmin = open("min.txt",'w')
favg = open("avg.txt",'w')
fmax = open("max.txt",'w')
forig = open("orig.txt",'w')
fgrp = open("group.txt",'w')
buff_rpt = rpt.readlines()
# $util $mr $ar $cr $w_dens $h_dens

tile = []
util = []
mr = []
ar = []
cr = []
w_dens = []
h_dens = []
h_feed = [] 
v_feed = [] 
hcongestion = []
vcongestion = []
congestion = []
hcongestion_orig = []
vcongestion_orig = []
#smote = SMOTE(random_state=42)

## training
tot_sample = 0
remain_sample = 0
discard_0 = 0
discard_1 = 0
discard_2 = 0
discard_3 = 0
discard_4 = 0
discard_5 = 0
nh0 = 0
nv0 = 0
nh1 = 0
nv1 = 0
dataGroup= {}
minCon = {}
avgCon = {}
maxCon = {}
avgN = {}
avgTCon = {}
selectCongestion = "min"
selectCongestion = "avg"
selectCongestion = "max"
output = 0
for line in buff_rpt:
    tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,\
    hcongestion_ex,vcongestion_ex = line.split()
    util_ex = round(float(util_ex),2)
    mr_ex =round(float(mr_ex),2)
    ar_ex = round(float(ar_ex),2)
    cr_ex= round(float(cr_ex),2)
    w_dens_ex = round(float(w_dens_ex),2)
    h_dens_ex = round(float(h_dens_ex),2)
    v_feed_ex = round(float(v_feed_ex),2)
    h_feed_ex = round(float(h_feed_ex),2)
    hcongestion_ex = round(float(hcongestion_ex),2)
    vcongestion_ex = round(float(vcongestion_ex),2)
    hcongestion_ex_orig = hcongestion_ex
    vcongestion_ex_orig = vcongestion_ex
            
    tot_sample = tot_sample + 1
    if util_ex > util_high and \
        (hcongestion_ex < congestion_th or vcongestion_ex < congestion_th  ):
        discard_1 = discard_1 + 1
        #continue
        
    if util_ex < util_low and \
        (ar_ex  > ar_low and ar_ex < ar_high) and \
        (hcongestion_ex > congestion_th and h_dens_ex > pin_high or \
        vcongestion_ex > congestion_th and w_dens_ex > pin_high) and \
        cr_ex < cr_low and \
        (v_feed_ex < v_feed_low and h_feed_ex < h_feed_low):
        discard_2 = discard_2 + 1
        #print("discard_2",line)
        #continue
    
    if  hcongestion_ex < congestion_th and h_dens_ex < pin_low or \
        vcongestion_ex < congestion_th and w_dens_ex < pin_low :
        discard_5 = discard_5 + 1
        #continue
    
    if util_ex > 0.9 or util_ex < 0.11:
        continue
        
    if w_dens_ex == 0 or h_dens_ex == 0 :
        continue
        
    if hcongestion_ex > congestion_high or vcongestion_ex > congestion_high:
        continue
    
    rn = random.randint(0,9)
    # remove more imbalance 0 data.
    if rn > 10 * ratio_drop and hcongestion_ex < congestion_th and vcongestion_ex < congestion_th:
        rn = rn
        #continue
    
    if hcongestion_ex > congestion_th:
        hcongestion_ex = 1
        nh1 = nh1 + 1
    else:
        hcongestion_ex = 0
        nh0 = nh0 + 1
    if vcongestion_ex > congestion_th:
        vcongestion_ex = 1
        nv1 = nv1 + 1
    else:
        vcongestion_ex = 0
        nv0 = nv0 + 1
    
    remain_sample = remain_sample + 1
    ## bypass feeds and density
    if "mr" in disable_feature:
        mr_ex = 0.1
        
    if bypass == 1:
        v_feed_ex = 1
        h_feed_ex = 1
        v_feed_ex = v_feed_ex
        h_feed_ex = h_feed_ex
        w_dens_ex = 0.16
        h_dens_ex = 0.16
        mr_ex = 0.1
    
    groupName = tile_ex + " " + str(util_ex) + " " + str(mr_ex) +  " " + str(ar_ex) + " " + str(cr_ex) \
                + " " + str(w_dens_ex) + " " + str(h_dens_ex) + " " \
                + str(v_feed_ex) + " " + str(h_feed_ex)
    fgrp.write(groupName+"\n")
    if groupName in dataGroup:
        if minCon[groupName] <= hcongestion_ex + vcongestion_ex:
            dataGroup[groupName] = str(hcongestion_ex) + " " + str(vcongestion_ex)
            minCon[groupName] = hcongestion_ex + vcongestion_ex
            
        if maxCon[groupName] >= hcongestion_ex + vcongestion_ex:
            #dataGroup[groupName] = str(hcongestion_ex) + " " + str(vcongestion_ex)
            maxCon[groupName] = hcongestion_ex + vcongestion_ex
            
        avgTCon[groupName] = hcongestion_ex + vcongestion_ex
        avgN[groupName] = avgN[groupName] + 1
        avgCon[groupName] = avgTCon[groupName] / avgN[groupName]
        if avgCon[groupName] >= 1:
            avgCon[groupName] = 1
        else:
            avgCon[groupName] = 0
        
    else:
        dataGroup[groupName] = str(hcongestion_ex) + " " + str(vcongestion_ex)
        minCon[groupName] = hcongestion_ex + vcongestion_ex
        maxCon[groupName] = hcongestion_ex + vcongestion_ex
        avgCon[groupName] = hcongestion_ex + vcongestion_ex
        avgN[groupName] = 1
        avgTCon[groupName] = hcongestion_ex + vcongestion_ex
    if hcongestion_ex > 0 or vcongestion_ex > 0:
        output = 1
    else:
        output = 0
    #print(groupName,output)
    forig.write(groupName+" "+ str(output)+"\n")
forig.close() 
fgrp.close()
"""
    tile.append(tile_ex)
    util.append(util_ex)
    mr.append(mr_ex)
    ar.append(ar_ex)
    cr.append(cr_ex)
    w_dens.append(w_dens_ex)
    h_dens.append(h_dens_ex)
    h_feed.append(h_feed_ex)
    v_feed.append(v_feed_ex)
        
    hcongestion.append(hcongestion_ex)
    vcongestion.append(vcongestion_ex)
"""

print("Total record:",len(dataGroup))
for name in dataGroup:
    tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,h_feed_ex,v_feed_ex = name.split()
    hcongestion_ex,vcongestion_ex = dataGroup[name].split()
    tile.append(tile_ex)
    util.append(float(util_ex))
    mr.append(float(mr_ex))
    ar.append(float(ar_ex))
    cr.append(float(cr_ex))
    w_dens.append(float(w_dens_ex))
    h_dens.append(float(h_dens_ex))
    h_feed.append(float(h_feed_ex))
    v_feed.append(float(v_feed_ex))
        
    hcongestion.append(float(hcongestion_ex))
    vcongestion.append(float(vcongestion_ex))

    if float(hcongestion_ex) > 0 or float(vcongestion_ex) > 0:
        congestion_ex = 1
    else:
        congestion_ex = 0
    #print(tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,h_feed_ex,v_feed_ex,congestion_ex)
    congestion.append(float(congestion_ex))
    if minCon[name] == 0 :
        fmin.write(name+ " "+ "0" +'\n')
    else:
        fmin.write(name+ " "+ "1" +'\n')
    favg.write(name+ " "+ dataGroup[name]+'\n')
    
fmin.close()
favg.close()
    #print(name,dataGroup[name])

# $util $mr $ar $cr $w_dens $h_dens
Xs0=np.array(util)
Xs1=np.array(mr)
Xs2=np.array(ar)
Xs3=np.array(cr)
Xs4=np.array(w_dens)
Xs5=np.array(h_dens)
Xs6=np.array(h_feed) 
Xs7=np.array(v_feed) 


Yhsi=np.array(hcongestion)
Yvsi=np.array(vcongestion)


i = 0
print ("tile util mr ar cr w_dens h_dens hcongestion vcongestion")
#rf = MLPClassifier(solver='lbfgs', alpha=1e-5, hidden_layer_sizes=(5,2), random_state=1)
#rfh = MLPClassifier(solver='adam', alpha=0.003, hidden_layer_sizes=(64,64,64), random_state=42)
#rfv = MLPClassifier(solver='adam', alpha=0.003, hidden_layer_sizes=(64,64,64), random_state=42)

rfh = RandomForestClassifier(n_estimators=100, random_state=42)
rfv = RandomForestClassifier(n_estimators=100, random_state=42)
#max_depth=13 dataiku
rf = RandomForestClassifier(n_estimators=100,
    random_state=1337,
    max_depth=13,
    min_samples_leaf=1)
#rf = DecisionTreeClassifier(max_leaf_nodes=3, random_state=0)
#rf.class_weight = "balanced"
#rfh = ExtraTreesClassifier(n_estimators=100, random_state=42)
#rfv = ExtraTreesClassifier(n_estimators=100, random_state=42)

Xin = np.array([util,mr,ar,cr,h_dens,h_feed]).T
rfh.fit(Xin,Yhsi)
Xin = np.array([util,mr,ar,cr,w_dens,v_feed]).T
rfv.fit(Xin,Yvsi)
# only one congestion
X_merge = np.array([util,mr,ar,cr,w_dens,h_dens,v_feed,h_feed]).T
Y_merge = np.array(congestion)
rf.fit(X_merge,Y_merge)
joblib.dump(rfh,'rfh_'+str(congestion_th)+'.model')
joblib.dump(rfv,'rfv_'+str(congestion_th)+'.model')
joblib.dump(rf,'rf_'+str(congestion_th)+'.model')

print("Sample summary: ",tot_sample,remain_sample,discard_0,discard_1,discard_2,discard_3,discard_4,nh0,nh1,nh1/nh0,nv0,nv1,nv1/nv0)
rpt.close()
print("# feature_importances: ",rf.feature_importances_)
Xh_ex = np.array([0.8,0.1529,0.5948,0.3537,0.1643,0.15730]).reshape((1,-1))
Xv_ex = np.array([0.8,0.1529,0.5948,0.3537,1.2559,0.06780]).reshape((1,-1))
X_merge = np.array([0.52,0.100,1.102,0.524,0.154,0.411,0,0]).reshape((1,-1))

test= args.util + " 0.100 "  + args.ar + " " + args.cr + " " + "0.16 0.16 1 1"
X_test = np.array(test.split()).reshape((1,-1))
print(X_test,rf.predict(X_test),rf.predict_proba(X_test))
print("# congestion prob:",args.util,args.ar,round(rf.predict_proba(X_test)[0][1],4))

delta = -0.2
feature_name = ["util","mr","ar","cr","v_dens","h_dens","v_feed","h_feed"]
test_arr = test.split()
X_ex = np.array(test_arr).reshape((1,-1))
pre_ex = rf.predict(X_ex)
prob_ex = rf.predict_proba(X_ex)
    
for i in range(len(test_arr)):
    feature_test = test_arr
    feature_test[i] = float(feature_test[i]) * (1 + delta)
    #print("feature_test",feature_test)
    X_test = np.array(feature_test).reshape((1,-1))
    pre_test = rf.predict(X_test)
    prob_test = rf.predict_proba(X_test)
    """
    print('%-15s%-15.3f%-15.3f%-15.3f%-15.3f' % (feature_name[i],round(float(feature_test[i]),2),\
          round(float(prob_test[0][0]),2),round(float(prob_ex[0][0]),2),\
          round(float(prob_test[0][0] - prob_ex[0][0]),2)))
    """ 
