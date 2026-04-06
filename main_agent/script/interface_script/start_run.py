"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import csv
import os
import datetime 
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--mailBody',type=str, default = "None",required=True,help="mailBody file")
parser.add_argument('--tasksMail',type=str, default = "tasksMail.csv",required=True,help="tasksMailFile file")
args = parser.parse_args()
tasksMail = []
with open(args.tasksMail,encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        tasksMail.append(i)
    f.close
timeLocal = str(datetime.datetime.now())
timeLocal = re.sub(' ','',timeLocal)
timeLocal = re.sub(':','',timeLocal)
timeLocal = re.sub('\.','',timeLocal)
timeLocal = re.sub('-','',timeLocal)
timeLocal = timeLocal[3:-4]
print(timeLocal)
mailAddress = "simon1.chen@amd.com"
mailBody = args.mailBody
mailQuote = ""
tag = timeLocal 
subject = "start run"
task = {'time':timeLocal,'tag':tag,'sender':mailAddress,'subject':subject,'mailBody':mailBody,'mailQuote':mailQuote,\
        'reply':'','instruction':'','runDir':'','status':''}
tasksMail.append(task)

with open(args.tasksMail, mode="w", encoding="utf-8-sig", newline="") as f:
    header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
    writer = csv.DictWriter(f,header_list)
    writer.writeheader()
    #sorted(tasksMail, key=lambda x: x['time'])
    writer.writerows(tasksMail)
    f.close()
