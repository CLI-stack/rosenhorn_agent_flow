"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
# This script is to add the original content as quotation
import argparse
import csv
import os
import time
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--csv',type=str, default = "None",required=True,help="the csv file")
args = parser.parse_args()
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
print("# Start check",args.csv)
pre_col = 0
n = 0
try:
    with open(args.csv,encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        for i in reader:
            if pre_col == 0:
                    pre_col = len(i)
            if pre_col != 0 and pre_col != len(i):
                print("# Column not consistent in line:",n,pre_col,len(i))
            pre_col = len(i)
            n = n + 1
            #print(len(i),",".join(i))
            
        f.close
except Exception as e:
        print(args.csv,"is illegal.",e)
