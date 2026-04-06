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
parser.add_argument('--log',type=str, default = "None",required=True,help="the csv file")
args = parser.parse_args()
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
macro_h = {}
with open(args.csv,encoding='utf-8-sig') as f:
    reader = csv.reader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        #print(",".join(i))
        if i[1] == "analogip":
            #print(i)
            macro_h[i[0]] = "analogip"
            
    f.close

macro_list = []
srams_list = []
# add unresolve macros
with open(args.log,'r') as f:
    for line in f:
        line = str(line)
        line = re.sub("\'"," ",line)
        line = re.sub(":"," ",line)
        for word in line.split():
            if word in macro_h:
                print(word)
                macro_list.append(word+"\n")
                break
        for word in line.split():
            if re.search("/",word):
                continue
            if re.search("\d+x\d+m",word):
                print(word)
                srams_list.append(word+"\n")
                break
            
            
    
    f.close

if len(macro_list) > 0 :
    if os.path.exists("data/analogs.list"):
        with open("data/analogs.list",'r') as f:
            for line in f:
                line = str(line)
                if line in macro_list:
                    pass
                else:
                    macro_list.append(line)

            f.close

    ml = open("analogs.list",'w')
    for word in macro_list:
        ml.write(word)
    ml.close

if len(srams_list) > 0 :
    if os.path.exists("data/srams.list"):
        with open("data/srams.list",'r') as f:
            for line in f:
                line = str(line)
                if line in srams_list:
                    pass
                else:
                    srams_list.append(line)

            f.close

    ml = open("srams.list",'w')
    for word in srams_list:
        ml.write(word)
    ml.close

