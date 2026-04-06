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
parser.add_argument('--tag',type=str, default = "None",required=True,help="the task tag")
parser.add_argument('--tasksModelFile',type=str, default = "None",required=True,help="the tasksModelFile")
parser.add_argument('--item',type=str, default = "None",required=True,help="the task item")
args = parser.parse_args()
rrp_l = []
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
with open(args.tasksModelFile,encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    rrp = open("data/"+args.tag+"/report_runProgress",'w')
    rd_h = {}
    for i in reader:
        tag = i['tag']
        runDir = i['runDir'] 
        if len(runDir.split(":")) == 0 or runDir == ":" :
            continue
        for rd in runDir.split(":"):
            rd = re.sub("\n","",rd)
            rd = re.sub("\r","",rd)
            if  os.path.exists(rd) and os.path.exists(rd+"/tile.params"):
                if rd in rd_h:
                    continue
                print(tag+":"+rd)
                rrp_l.append(tag+":"+rd)
                #rrp.write(tag+":"+rd+'\n')
                rd_h[rd] = 1
    
    f.close
rrp_l.reverse()
print(rrp_l)
for l in rrp_l:
    rrp.write(l+'\n')

rrp.close()
