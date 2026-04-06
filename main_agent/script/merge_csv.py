import pandas as pd
import numpy as np
import sys

h1 = pd.read_csv(sys.argv[2]+"/feature_extract_"+sys.argv[1]+".csv")
h2 = pd.read_csv(sys.argv[2]+"/margin_info_"+sys.argv[1]+".csv")

df = pd.concat([h1,h2],axis=1)
#df.drop_duplicates()  
#df.reset_index(drop=True,inplace=True)
df.to_csv(sys.argv[2]+'/merge_'+sys.argv[1]+'.csv',encoding = 'utf-8')
