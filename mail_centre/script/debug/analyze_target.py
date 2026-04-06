"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
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

import argparse
import csv
import os
import time
import re
import gzip

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--tag',type=str, default = "None",required=True,help="the task tag")
parser.add_argument('--source_dir',type=str, default = "None",required=True,help="the run dir info")
parser.add_argument('--run_dir',type=str, default = "None",required=True,help="the run dir info")
parser.add_argument('--status',type=str, default = "None",required=True,help="the running status")
parser.add_argument('--reply',type=str, default = "None",required=True,help="the reply content")
parser.add_argument('--html',type=str, default = "None",required=True,help="html file")
parser.add_argument('--sender',type=str, default = "None",required=True,help="sender address")
parser.add_argument('--debugFile',type=str, default = "debug.csv",required=True,help="debug file")
parser.add_argument('--target',type=str, default = "None",required=True,help="target file")
parser.add_argument('--fail',type=str, default = "None",required=True,help="is failed")
args = parser.parse_args()
#print(args.tag)
def send_mail(sender,subject,mailBody,quote,html):
    mailBody = re.sub('\\\\n','\n',mailBody) 
    mail = 'cat ' + html + '| formail -I "To:' + sender + ' " -I "From: virtual tile owner" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:'+ \
             subject+ '" | sendmail -oi ' + sender

    #print(mail)
    p = os.popen(mail)
    # allow the mail sent out without thread kill
    time.sleep(2)

tasksModel = []
errors = []
errFlag = 0
isLog = 0
# collect error info first
if os.path.exists("logs/"+args.target+".log.gz"):
    with gzip.open("logs/"+args.target+".log.gz",'r') as f:
        print("# check target",args.target, args.fail)
        for line in f:
            #line = str(line,encoding='utf-8')
            line = str(line)
            line = re.sub('[?:,\']',' ',line)
            line = re.sub('\. ',' ',line)
            line = re.sub('^b\s+','',line)
            #line = line.lower()
            # avoid print message contain error
            if re.search(r"puts",line.lower()) :
                continue
            if re.search(r"error",line.lower()) or \
                re.search(r"segmentation fault",line.lower()) or \
                re.search(r"stack trace",line.lower()) or \
                re.search(r"warning",line.lower()) or \
                re.search(r"unable to",line.lower()) or \
                re.search(r"no such",line.lower()):
                errFlag = 1
                errors.append(line)
                continue
            if errFlag == 1:
                errors.append(line)
                errFlag = 0
else:
    with open("logs/"+args.target+".log",'r') as f:
        isLog = 1
        for line in f:
            line = str(line)
            line = re.sub('[?:,\']',' ',line)
            line = re.sub('\. ',' ',line)
            # avoid print message contain error
            if re.search(r"puts",line.lower()) :
                continue
            #line = line.lower()
            if re.search(r"error",line.lower()) or \
                re.search(r"segmentation fault",line.lower()) or \
                re.search(r"stack trace",line.lower()) or \
                re.search(r"no such",line.lower()) or \
                re.search(r"warning",line.lower()) or \
                re.search(r"traceback",line.lower()):
                errFlag = 1
                errors.append(line)
                continue
            if errFlag == 1:
                errors.append(line)
                errFlag = 0

# check error infor
csh = open("fix_error."+args.target+".csh",'w')
# fixFlat means if found match error
fixFlag = 0

log = open(args.target+".error.log",'w')
log.write("Hi Expert,"+'\n')
log.write(args.target+" failed due to: "+'\n')
li_h = {}
lif_h = {}
write_link = 0
if os.path.exists(args.source_dir+'debug.csv'):
    debug_csv = args.source_dir+'debug.csv'
else:
    debug_csv = args.source_dir+"/script/debug/debug.csv"

with open(debug_csv,encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        if fixFlag == 1:
            pass
            #continue
        issue = i['issue']
        for line in errors:
            lineArr= []
            line = line.rstrip("\n")
            for word in line.split():
                word = re.sub('\.$','',word)
                lineArr.append(word.lower())
                 
            for li in issue.split('\n'):
                count = 0
                li = re.sub('[?:,\']',' ',li)
                li = re.sub('\. ',' ',li)
                li_file = re.sub(' ','_',li)
                for word in li.split():
                    if word.lower() in lineArr:
                        count = count + 1
                        #print("line:",lineArr)
                        #print("li:",li.split())
                        #print("# check word",line,word.lower(),count,len(li.split()))
                if count == len(li.split()): 
                    if write_link == 0:
                        log.write("http://logviewer-atl.amd.com/"+args.run_dir+"/"+args.target+".log"+'\n')
                        write_link = 1
                    if li in li_h:
                        li_h[li] = li_h[li] + 1
                    else:
                        li_h[li] = 1
                        lif_h[li] = open(li_file+"."+args.target+".analyze_target.log",'w')
                    
                    if li_h[li] > 50:
                        continue

                    print("# Found issue: "+li+'\n')
                    if re.search('\\n',line):
                        log.write(line)
                        lif_h[li].write(line)
                    else:
                        log.write(line[:500]+'\n')
                        lif_h[li].write(line[:500]+'\n')
                    if os.path.exists("logs/"+args.target+".log"): 
                        if li in li_h:
                            if li_h[li] == 1:
                                csh.write("#"+li+'\n')
                                csh.write("cp "+"logs/"+args.target+".log ./"+'\n')
                                csh.write("source "+args.source_dir+"/script/debug/"+i['action']+'\n')
                        # for unfinished job, log should not be removed, and no duplicat error process 
                        # since monitor execute one time per hour, if the duration too short, it may has issue
                        #csh.write("rm -rf "+"logs/"+args.target+".log"+'\n')
                    if os.path.exists("logs/"+args.target+".log.gz"):
                        if li in li_h:
                            if li_h[li] == 1:
                                csh.write("#"+li+'\n')
                                csh.write("cp "+"logs/"+args.target+".log.gz ./"+'\n')
                                csh.write("source "+args.source_dir+"/script/debug/"+i['action']+'\n')
                    #send_mail(args.sender,args.target,"####","###",log)
                    fixFlag = 1 
                    print(line)
    f.close
## Cannot identify issue, auto retrace
if fixFlag == 0 and isLog == 0:
    if os.path.exists(args.target+".failed"):
        rerun = 1
        nt = open(args.target+".failed",'r')
        for line in nt:
            if re.search(r"rerun:",line):
                rerun = line.split()[1]
                rerun = rerun + 1
                print("# rerun:",rerun)

        nt.close
        #print("# Report error")
    else:
        # fail 1 here means if the failure is show stop, no matter key word can be match in log, 
        # the $target.failed will be generated and send mail; 0 means if no match error, no action
        if args.fail == "1":
            nt = open(args.target+".failed",'w')
            ntf = open("Unknow_Error."+ args.target+".analyze_target.log",'w')
            nt.write(args.run_dir + '\n')
            nt.write("Unknow Error" + '\n')
            ntf.write("Unknow Error" + '\n')
            nt.close()
            ntf.close()
        #csh.write("source "+args.source_dir+"/debug/"+"retrace.csh")
csh.close()
for li in lif_h:
    lif_h[li].close()
log.close()
if fixFlag == 0:
    if os.path.exists(args.target+".error.log"):
        os.remove(args.target+".error.log")

    
