# -*- coding: utf-8 -*-
"""
Created on Fri Oct 18 20:53:43 2019

@author: csm_c
"""

# -*- coding: utf-8 -*-
"""
Created on Wed Oct  2 20:23:40 2019

@author: simchen
"""


import numpy as np
from numpy import unique
from numpy import where
from sklearn.datasets import make_classification
from sklearn.cluster import DBSCAN
import matplotlib.pyplot as plt
import math
import numpy.linalg as lg
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
#parser.add_argument('--node',type=str, default = "None",required=True,help="tech node")

#args = parser.parse_args()
X,_ = make_classification(n_samples=1000,n_features=2,n_informative=2,n_redundant=0,n_clusters_per_class=1,random_state=4)
print("X",X)
model = DBSCAN(eps=0.3,min_samples=9)
yhat = model.fit_predict(X)
print("yhat",yhat)
clusters = unique(yhat)
print("clusters",clusters)
for cluster in clusters:
    row_ix = where(yhat == cluster)
    plt.scatter(X[row_ix,0],X[row_ix,1])
plt.show()
