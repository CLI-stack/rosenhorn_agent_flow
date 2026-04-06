# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import re
import datetime
import re
import os
import csv
#import urllib.request
#import requests


class TileOwner:
    def __init__(self):   
        self.my_account = None
        self.Sender = None
        self.senderNameList = {}
        self.mailDays = 8
        self.tasks = []
        self.tiles = {}
        self.disks = {}
        self.runDir = {}
        self.vtoInfo = {'tile' : '', 'disk' : '','project':''}
        self.arguement = {}
        
        #print(self.my_account,self.Sender)
    def set_tasks(self,tasks):
        self.tasks = tasks
    def set_data(self,data):
        for key.value in data.iterms():
            if hasattr(self,key):
                setattr(self,key,value)
    def read_mail_config(self):
        sender_name_list = {}
        mc = open("mailConfig.txt")
        for line in mc:
            a_split = line.split()
            if re.search(r"mailDays",a_split[0]):
                self.mailDays = int(a_split[1])
            if re.search(r"senderName",a_split[0]):
                name = ' '.join(a_split[1:])
                self.senderNameList[name] = 1
                #print(name)
    def read_assignment(self):
        with open('assignment.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)    
            
            for i in reader:
                if re.search(r"tile",i[0]):
                    #print(i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                if re.search(r"disk",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    #print(i[1])
                if re.search(r"project",i[0]):
                    self.vtoInfo['project'] = i[1]
        return 0
                
    
class Monitor:
    def __init__(self):
        self.my_account = None
        self.Sender = None
        self.tasks = []
        self.disks = {}
        self.tasksModel = []
        self.tiles = {}
        self.tasksModelFile = ""
        self.content = ""
        self.finishedLog = "logs/FxStreamOut.log.gz"
        self.vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'','debugger':'','manager':''}

    def set_tasksModelFile(self,tasksModelFile):
        self.tasksModelFile = tasksModelFile

    def write_dir(self):
        vto_arr = self.vtoInfo['vto'].split(":")
        print("From:",vto_arr[1])
        with open(self.tasksModelFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
            for i in reader:
                self.tasksModel.append(i)
            f.close
        csh = open('runDir.list','w')
        rd_h = {}
        for task in self.tasksModel:
            # The tasks have finished or no run dir will skip monitor.
            #print(task["instruction"],task["runDir"])
            if len(task["runDir"].split(':')) == 0:
                self.tasks.append(task)
                continue
            # generate csh for run
            run_status = task["status"]
            # Assume all run finished
            #task["status"] = "finished"
            for rd in task["runDir"].split(':'):
                if rd in rd_h:
                    continue
                if len(rd) == 0:
                    continue
                #if os.path.exists(rd+"/"+self.finishedLog):
                #    continue
                else:
                    # Any run not found the finishedLog, set to original status
                    task["status"] = run_status 
                    rd_h[rd] = 1
                
                if os.path.exists(rd):
                    #print(len(rd),rd)
                    csh.write(rd+"\n")
                    pass
                # only generate 1 instruction per run
            # Let sender known all run finished
            if task["status"] == "finished" and re.search("/",task["runDir"]):
                senderName = task["sender"].split(".")[0]
                senderName = re.sub('[0-9]','',senderName)
                if os.path.exists('data/'+task["tag"]+'.sentMail.spec'):
                    print("# Remove original ",'data/'+task["tag"]+'.sentMail.spec')
                    p = os.popen('rm data/'+task["tag"]+'.sentMail.spec') 
            
                fcfg = open('data/'+ task["tag"] + '.finished.cfg','w')
                fcfg.write('senderName '+ senderName + '\n')
                fcfg.write('sender '+ task["sender"] + ','+self.vtoInfo['manager'] + '\n')
                fcfg.write('runDir ' + task['runDir'] + '\n')
                fcfg.write('subject Finished:' +task["subject"] + '\n')
                fcfg.close()
                task["reply"] = "Hi "+ senderName+ ",\n This run has finished."
                #self.send_mail(task["sender"]+','+self.vtoInfo['manager'],task["subject"],task["reply"],task["mailBody"])
            self.tasks.append(task)
        csh.close()
        # update status to csv
        """
        with open(self.tasksModelFile, mode="w", encoding="utf-8-sig", newline="") as f:
            header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
            writer = csv.DictWriter(f,header_list)
            writer.writeheader()
            sorted(self.tasks, key=lambda x: x['time'])
            writer.writerows(self.tasks)
            f.close()
        """
    def read_assignment(self):
        with open('assignment.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)

            for i in reader:
                if re.search(r"tile",i[0]):
                    #print(i[0],i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                if re.search(r"disk",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    #print(i[0],i[1])
                if re.search(r"project",i[0]):
                    self.vtoInfo['project'] = i[1]
                    #print(i[0],i[1])
                if re.search(r"vto",i[0]):
                    self.vtoInfo['vto'] = self.vtoInfo['vto'] + ":" + i[1]
                    #print(i[0],i[1])
                if re.search(r"debugger",i[0]):
                    if len(self.vtoInfo['debugger']) > 0:
                        self.vtoInfo['debugger'] = self.vtoInfo['debugger'] + "," + i[1]
                    else:
                        self.vtoInfo['debugger'] = i[1]
                    print(i[0],i[1])
                if re.search(r"manager",i[0]):
                    if len(self.vtoInfo['manager']) > 0:
                        self.vtoInfo['manager'] = self.vtoInfo['manager'] + "," + i[1]
                    else:
                        self.vtoInfo['manager'] = i[1]
                    print(i[0],i[1])


    def send_mail(self,sender,subject,mailBody,quote):
        sm = open('send_mail.txt','w')
        mailBody = re.sub('\\\\n','\n',mailBody)
        sm.write(mailBody+'\n')
        sm.write('----------------------------------------------------------------------------------------------------'+'\n')
        sm.write(quote+'\n')
        sm.close()
        vto_arr = self.vtoInfo['vto'].split(":")
        vto = vto_arr[1]
        print("From:",vto)
        mail = 'cat send_mail.txt'+ \
            ' | formail -I "From:' + vto + '" -I "To:' + sender + '" -I "MIME-Version:1.0" -I "Content-type:text;charset=utf-8" -I "Subject:Finished:'+ subject+ '" | sendmail -oi ' + sender
        #print(mail)
        p = os.popen(mail)
 

if __name__ == '__main__':
    #print(tileOwner.senderNameList,tileOwner.mailDays)
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--tasksModelFile',type=str, default = "self.tasksModelFile",required=True,help="tasksModelFile file")
    args = parser.parse_args()
    moniotor = Monitor()
    moniotor.set_tasksModelFile(args.tasksModelFile)
    moniotor.read_assignment()
    moniotor.write_dir()
