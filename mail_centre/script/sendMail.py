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
parser.add_argument('--source_dir',type=str, default = "None",required=True,help="the run dir info")
#parser.add_argument('--target_run_dir',type=str, default = "None",required=True,help="the run dir info")
parser.add_argument('--status',type=str, default = "None",required=True,help="the running status")
parser.add_argument('--reply',type=str, default = "None",required=True,help="the reply content")
parser.add_argument('--html',type=str, default = "None",required=True,help="html file")
parser.add_argument('--tasksModelFile',type=str, default = "tasksModel.csv",required=True,help="tasksModelFile file")
parser.add_argument('--extraMailAddress',type=str, default = "",required=False,help="send mail per tasks")
args = parser.parse_args()
#print(args.tag)
def send_mail(sender,vto,subject,mailBody,quote,html):
    mailBody = re.sub('\\\\n','\n',mailBody) 
    mail = 'cat ' + html + '| formail -I "To:' + sender + ' " -I "From:'+ vto + '" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:Re:'+ \
             subject+ '" | /sbin/sendmail -oi ' + sender

    #print(mail)
    p = os.popen(mail)
    # allow the mail sent out without thread kill
    time.sleep(2)

tasksModel = []
toAddr = []
if re.search("none",args.extraMailAddress):
    pass
else:
    if re.search("@amd\.com",args.extraMailAddress):
        for addr in args.extraMailAddress.split(":"):
            toAddr.append(addr)

vto = "All"
with open('assignment.csv',encoding='utf-8-sig') as asm:
    reader = csv.reader(asm)
    for i in reader:
        if re.search(r"vto",i[0]):
            vto = i[1]
            print(i[0],i[1])
            break

vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'','debugger':'','manager':''}
with open('assignment.csv',encoding='utf-8-sig') as asm:
    reader = csv.reader(asm)

    for i in reader:
        if re.search(r"vto",i[0]):
            vtoInfo['vto'] = vtoInfo['vto'] + ":" + i[1]
            print(i[0],i[1])
        if re.search(r"debugger",i[0]):
            toAddr.append(i[1].lower())
            if len(vtoInfo['debugger']) > 0:
                vtoInfo['debugger'] = vtoInfo['debugger'] + "," + i[1]
            else:
                vtoInfo['debugger'] = i[1]
            print(i[0],i[1])
        if re.search(r"manager",i[0]):
            toAddr.append(i[1].lower())
            if len(vtoInfo['manager']) > 0:
                vtoInfo['manager'] = vtoInfo['manager'] + "," + i[1]
            else:
                vtoInfo['manager'] = i[1]
            print(i[0],i[1])


with open(args.source_dir+"/"+args.tasksModelFile,encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        if i['tag'] == args.tag:
            #print(i['tag'])
            #i['runDir'] = i['runDir'] + ':' + args.target_run_dir
            i['runDir'] = re.sub('::',':',i['runDir'])
            i['status'] = args.status
            i['reply'] = args.reply
            #print(i)
            quote = "From:" + i['sender'] + "\n" + i["mailBody"]
            toAddr.append(i["sender"].lower())
            toAddr_uniq = list(set(toAddr))
            toAddr_uniq_list = ",".join(toAddr_uniq)
            #send_mail(i["sender"] + ','+vtoInfo['manager'] + ',' + vtoInfo['debugger'],vto,i["subject"],i['reply'],quote,args.html)
            send_mail(toAddr_uniq_list,vto,i["subject"],i['reply'],quote,args.html)
    f.close

