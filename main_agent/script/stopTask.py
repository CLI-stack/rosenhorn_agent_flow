"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import csv
import os
import time
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--tag',type=str, default = "None",required=True,help="the task tag")
parser.add_argument('--source_run_dir',type=str, default = "None",required=True,help="the run dir info")
parser.add_argument('--target_run_dir',type=str, default = "None",required=True,help="the run dir info")
parser.add_argument('--status',type=str, default = "None",required=True,help="the running status")
parser.add_argument('--reply',type=str, default = "None",required=True,help="the reply content")
parser.add_argument('--html',type=str, default = "None",required=True,help="html file")
parser.add_argument('--ins',type=str, default = "None",required=True,help="instruction")
parser.add_argument('--tasksModelFile',type=str, default = "tasksModel.csv",required=True,help="tasksModelFile file")
args = parser.parse_args()
#print(args.tag)

tasksModel = []
with open(args.source_run_dir+"/"+args.tasksModelFile,encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        if re.search(args.ins,i['instruction']):
            #print(i['tag'])
            i['runDir'] = i['runDir'] 
            i['runDir'] = re.sub('::',':',i['runDir'])
            i['status'] = "finished"
            i['reply'] = args.reply
            #print(i)
        tasksModel.append(i)
    f.close

with open(args.source_run_dir+"/"+args.tasksModelFile, mode="w", encoding="utf-8-sig", newline="") as f:
    header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
    writer = csv.DictWriter(f,header_list)
    writer.writeheader()
    sorted(tasksModel, key=lambda x: x['time'])
    writer.writerows(tasksModel)
    f.close()
