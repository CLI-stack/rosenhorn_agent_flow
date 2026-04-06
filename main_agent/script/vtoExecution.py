# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import re
import pandas as pd
import datetime
import re
import os
import csv
import numpy as np
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
                if len(i) < 2:
                    continue
                if re.search(r"tile",i[0]):
                    #print(i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                if re.search(r"disk",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    #print(i[1])
                if re.search(r"project",i[0]):
                    self.vtoInfo['project'] = i[1]
        return 0
                
    
class ExecutionInterface:
    def __init__(self):
        self.my_account = None
        self.Sender = None
        self.tasks = []
        self.disks = {}
        self.tasksModel = []
        self.tiles = {}
        self.content = ""
        self.tasksModelFile = ""
        self.runCsh = ""

    def set_tasksModelFile(self,tasksModelFile):
        self.tasksModelFile = tasksModelFile
    
    def set_runCsh(self,runCsh):
        self.runCsh = runCsh

    def write_csh(self):
        with open(self.tasksModelFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
            for i in reader:
                self.tasksModel.append(i)
            f.close
        ignoreTag = []
        csh = open(self.runCsh,'w')
        is_exec = 0
        if os.path.exists("ignore_tag.list"):
            igt = open("ignore_tag.list",'r')
            for line in igt:
                ignoreTag.append(line)
        for task in self.tasksModel:
            #print(task)
            is_periodic = 0
            preCsh = {} 
            if task["tag"] in ignoreTag:
                print("# ignore tag",task["tag"])
                continue
            if len(task["status"].split(":")) > 1:
                status_arr = task["status"].split(":")
                if re.search("every",status_arr[0]):
                    if re.search('[0-9]',status_arr[1]):
                        interval = float(status_arr[1])
                    else:
                        self.tasks.append(task)
                        continue
                    if re.search("hour",status_arr[2]):
                        time0 = re.sub(":"," ",task["time"])
                        time0 = re.sub(" 0"," ",time0)
                        timeHour = time0.split()[1]
                        timeCurrent = datetime.datetime.now()
                        timeCurrent0 = re.sub(":"," ",str(timeCurrent))
                        timeCurrent0 = re.sub(" 0"," ",timeCurrent0)
                        timeCurrentHour = timeCurrent0.split()[1]
                        timeCurrentMinute = timeCurrent0.split()[2]
                        # Process time difference 
                        timeCurrentHour = float(timeCurrentHour) + 13.0
                        timeHour = float(timeHour)
                        timeCurrentMinute = float(timeCurrentMinute)
                        remainder = round((timeCurrentHour + round(timeCurrentMinute / 60,5) - timeHour ) % interval,5)
                        print("# Found periodic task",task["tag"],timeHour,timeCurrent,timeCurrentHour,interval,round(timeCurrentMinute/60,5),remainder)
                        if remainder == 0:
                            is_periodic = 1
                    if re.search("day",status_arr[2]):
                        time0 = re.sub("\-"," ",task["time"])
                        time0 = re.sub(" 0"," ",time0)
                        timeDay = time0.split()[2]
                        timeDay = float(timeDay)
                        timeCurrent = datetime.datetime.now()
                        timeCurrent0 = re.sub('\-'," ",str(timeCurrent))
                        timeCurrent0 = re.sub(":"," ",timeCurrent0)
                        timeCurrent0 = re.sub(" 0"," ",timeCurrent0)
                        timeCurrentDay = timeCurrent0.split()[2]
                        timeCurrentHour = timeCurrent0.split()[3]
                        timeCurrentMinute = timeCurrent0.split()[4]
                        # Process time difference 
                        timeCurrentDay = float(timeCurrentDay)
                        timeCurrentHour = float(timeCurrentHour) + 13.0 
                        timeCurrentMinute = float(timeCurrentMinute)
                        remainder = round((timeCurrentDay + round(timeCurrentHour / 24,5) +  round(timeCurrentMinute / (60*24),5) - timeDay ) % interval,5)
                        print("# Found periodic task",task["tag"],timeDay,timeCurrent,timeCurrentDay,interval,"hour",round(timeCurrentHour / 24,5),"min",round(timeCurrentMinute/(60*24),5),remainder)
                        if remainder == 0:
                            is_periodic = 1
            # skip exection when status is non-empty or $tag_spec exist and not periodic task
            if ((len(task["status"]) != 0 or os.path.exists("data/"+task["tag"]+"_spec")) and is_periodic == 0) or is_exec == 1:
                if os.path.exists("data/"+task["tag"]+"_spec"):
                    if re.search("\S",task["status"]) == 0:
                        task["status"] = "running"
                    pass
                    #print("data/"+task["tag"]+"_spec")
                self.tasks.append(task)
                continue
            # check if it is periodic task
            # generate csh for run
            if (len(task["instruction"])) == 0:
                csh.write("source script/greeting.csh "+task["tag"]+" " + task["sender"]+'\n')
                csh.write("set tasksModelFile = " + '"'+ self.tasksModelFile+'"' +'\n')
                csh.write("source script/unrecognized_instruction.csh " +task["tag"] + '\n')
                csh.write("source script/signature_quote.csh " + '\n')
                task["status"] = "finished"
            if task["instruction"] == "# unrelated tiles":
                csh.write("source script/greeting.csh "+task["tag"]+" " + task["sender"]+'\n')
                csh.write("set tasksModelFile = " + '"'+ self.tasksModelFile+'"' +'\n')
                csh.write("source script/unrelated_tile.csh " +task["tag"] + '\n')
                csh.write("source script/signature_quote.csh " + '\n')
                task["instruction"] = ""
                task["status"] = "finished"
                self.tasks.append(task)
                continue

            for sentence in task["instruction"].split(';'):
                if (len(task["instruction"])) == 0:
                    continue
                if is_exec == 0:
                    csh.write("source script/greeting.csh "+task["tag"]+" " + task["sender"]+'\n')
                    csh.write("set tasksModelFile = " + '"'+ self.tasksModelFile+'"' +'\n')
                #print(sentence)

                # * in csh arguement will cause failure
                sentence = re.sub('\*','__',sentence)
                if sentence in preCsh:
                    continue
                else:
                    csh.write(sentence+'\n')
                    preCsh[sentence] = 1
                # only generate 1 instruction per run
                is_exec = 1
            
            task["status"] = "running"
            sp = open("data/"+task["tag"]+"_spec",'w')
            sp.close()
            if len(task["reply"]) == 0:
                task["reply"] = "The job is running..."
            self.tasks.append(task) 
            if is_exec == 1:
                print("# Generate task " + task["tag"])
                csh.write("source script/signature_quote.csh " + '\n')
            
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
    
if __name__ == '__main__':
    timeSlot0 = 30
    timeSlot1 = 35
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--tasksModelFile',type=str, default = "tasksModel.csv",required=True,help="tasksModelFile file")
    parser.add_argument('--runCsh',type=str, default = "tasksModel.csv",required=True,help="runCsh file")
    args = parser.parse_args()
    tileOwner = TileOwner()
    tileOwner.read_assignment()
    #print(tileOwner.senderNameList,tileOwner.mailDays)
    executionInterface = ExecutionInterface()
    try:
        executionInterface.set_tasksModelFile(args.tasksModelFile)
        executionInterface.set_runCsh(args.runCsh)
        curr_time = datetime.datetime.now()
        executionInterface.write_csh()
    except Exception as e:
        print("vtoExecutionInterface",e)

