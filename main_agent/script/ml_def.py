
import numpy as np
#from sklearn.externals import joblib
import joblib
import math

def evaluate_util (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,\
                   w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,\
                   hcongestion_ex,vcongestion_ex,rfhm,rfvm):
    congestion_th = 0.1
    need_incr = 1
    print_prob = 0
    min_util = 0.3
    max_util = 0.8
    prob_th = 0.75
    util_delta = 0.01
    n_p9 = 0
    n_p2 = 0
    rfh=joblib.load(rfhm)
    rfv=joblib.load(rfvm)
    util_ex = round(float(util_ex),4)
    mr_ex =round(float(mr_ex),4)
    ar_ex = round(float(ar_ex),4)
    cr_ex= round(float(cr_ex),4)
    w_dens_ex = round(float(w_dens_ex),4)
    h_dens_ex = round(float(h_dens_ex),4)
    v_feed_ex = round(float(v_feed_ex)/100000,4)
    h_feed_ex = round(float(h_feed_ex)/100000,4)
    hcongestion_ex = round(float(hcongestion_ex),4)
    vcongestion_ex = round(float(vcongestion_ex),4)
    
    initial_util = util_ex
    util_ex = min_util
    max_0_util = min_util
    max_0_prob_h = 0
    max_0_prob_v = 0
    max_0_util = min_util
    max_1_util = min_util
    max_1_prob_h = 0
    max_1_prob_v = 0
    con_h = 0
    con_v = 1
    is_con = 0
    while util_ex < max_util:
        util_pre = util_ex
        util_ex = util_ex + util_delta
        #mr_ex = mr_ex * (1 + util_delta)
        Xh_ex = np.array([util_ex,mr_ex,ar_ex,cr_ex,h_dens_ex,h_feed_ex]).reshape((1,-1))
        Xv_ex = np.array([util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,v_feed_ex]).reshape((1,-1))
        preh = rfh.predict(Xh_ex)
        prev = rfv.predict(Xv_ex)
        prob_h = rfh.predict_proba(Xh_ex)
        prob_v = rfv.predict_proba(Xv_ex)
        if print_prob == 1:
            print('%-30s%-10.3f%-10.3f%-10.3f%-10.3f%-10.3f'%(tile_ex,util_ex,preh[0], prob_h[0][0], prev[0], prob_v[0][0]))
        if preh[0] == 0 and prev[0] == 0 and util_ex > min_util and prob_h[0][0] > prob_th and prob_v[0][0] > prob_th:
            max_0_util = util_ex
            max_0_prob_h = prob_h[0][0]
            max_0_prob_v = prob_v[0][0]
        
        if preh[0] == 1 and prob_h[0][1] > prob_th and is_con == 0 :
            is_con = 1
            max_1_prob_h = prob_h[0][1]
            max_1_util = util_ex
        
        if prev[0] == 1 and prob_v[0][1] > prob_th and is_con == 0:
            is_con = 1
            max_1_prob_v = prob_v[0][1]
            max_1_util = util_ex
        
    # util incr stop and print final util
    util_delta = max_0_util - initial_util
    v_feed_real = v_feed_ex * 100000
    h_feed_real = h_feed_ex * 100000
    
    return '%-30s%-10.3f%-10.3f%-10.3f%-10.3f%-10.3f%-10.3f%-10.3f%-10d%-10d%-10d%-10d%-14.3f%-10.3f%-10.3f%-10.3f%-10.3f%-10.3f' % (
        tile_ex, initial_util, max_0_util, mr_ex, ar_ex, cr_ex, w_dens_ex, h_dens_ex, v_feed_real, h_feed_real, con_h,
        con_v, util_delta,max_0_prob_h,max_0_prob_v,max_1_util,max_1_prob_h,max_1_prob_v)
        
def predict (tile_ex,util_ex,mr_ex,ar_ex,cr_ex,\
                   w_dens_ex,h_dens_ex,v_feed_ex,h_feed_ex,\
                   hcongestion_ex,vcongestion_ex,rfhm,rfvm):
    congestion_th = 0.4
    util_ex = round(float(util_ex),4)
    mr_ex =round(float(mr_ex),4)
    ar_ex = round(float(ar_ex),4)
    cr_ex= round(float(cr_ex),4)
    w_dens_ex = round(float(w_dens_ex),4)
    h_dens_ex = round(float(h_dens_ex),4)
    v_feed_ex = round(float(v_feed_ex)/100000,4)
    h_feed_ex = round(float(h_feed_ex)/100000,4)
    hcongestion_ex = round(float(hcongestion_ex),4)
    vcongestion_ex = round(float(vcongestion_ex),4)
    if hcongestion_ex > congestion_th:
        hcongestion_ex = 1
    else:
        hcongestion_ex = 0
        
    if vcongestion_ex > congestion_th:
        vcongestion_ex = 1
    else:
        vcongestion_ex = 0
            
    Xh_ex = np.array([util_ex,mr_ex,ar_ex,cr_ex,h_dens_ex,h_feed_ex]).reshape((1,-1))
    Xv_ex = np.array([util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,v_feed_ex]).reshape((1,-1))
    rfh=joblib.load(rfhm)
    rfv=joblib.load(rfvm)
    preh = rfh.predict(Xh_ex)            
    prev = rfv.predict(Xv_ex)
    prob_h = rfh.predict_proba(Xh_ex)
    prob_v = rfv.predict_proba(Xv_ex)
    print(rfhm,rfvm)
    print('{} {} {} {} {} {} {} {} {} {} {} {} {}\n'.format(tile_ex,util_ex,mr_ex,ar_ex,cr_ex,w_dens_ex,h_dens_ex,
        v_feed_ex*100000,
        h_feed_ex*100000,
        preh,prob_h,
        prev,prob_v))
