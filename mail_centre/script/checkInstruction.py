# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import re
#from win32com.client.gencache import EnsureDispatch as Dispatch
import pandas as pd
import datetime
#from nltk.corpus import wordnet
import re
import os
#import commands,time
#import win32com.client as win32
#import win32com.client
import csv
import numpy as np
import urllib.request
import requests

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
        self.vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':''}
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
                print(name)
            if re.search(r"ip",a_split[0]):
                self.vtoInfo['ip'] = a_split[1]
                print(a_split[1])

    def update_arguement(self,arguementFile):
        p = open(arguementFile)
        for line in p:
            a_split = line.split()
            if len(a_split)<2:
                continue
            if re.search(r"#",a_split[0]):
                continue
            name = a_split[0]
            self.arguement[name] = "params"
        with open("arguement.csv", mode="w", encoding="utf-8-sig", newline="") as f:
            pwriter = csv.writer(f)
            for i in self.arguement:
                pwriter.writerow([i,self.arguement[i]])
    def read_assignment(self):
        with open('assignment.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)    
            
            for i in reader:
                if re.search(r"tile",i[0]):
                    print(i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                if re.search(r"disk",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    print(i[1])
                if re.search(r"project",i[0]):
                    self.vtoInfo['project'] = i[1]
                    print(i[1])
        return 0
                
    
class MultiLevelModels:
    def __init__(self):
        self.my_account = None
        self.Sender = None
        self.tasksMail = []
        self.instruction = {}
        self.instruction_orig = {}
        self.tasksInstruction = []
        self.tasksModel = []
        self.mailFile = ""
        self.tasksModelFile = ""
        self.instructionFile = ""
        self.arguement = {}
        self.readTask = 0
        self.command = {}
        self.ignoreWord={}
        self.keyword = {}
        self.oneHotDimension = 0
        self.tasks = []
        self.vtoInfo = {}
        self.ip = ''
        self.debug = {"encode":1}
        # when receive request, it may include operation object,e.g. tile name, dir ...
        
        #print(my_account,Sender)
    # update latest arguement into lookup table for mail recongnization 
    def set_mailFile(self,mailFile):
        self.mailFile = mailFile

    def set_tasksModelFile(self,tasksModelFile):
        self.tasksModelFile = tasksModelFile

    def set_instructionFile(self,instructionFile):
        self.instructionFile = instructionFile

    def set_vtoInfo(self,vtoInfo):
        for i in vtoInfo:
            print("set_vto",vtoInfo[i])
            self.vtoInfo[i] = vtoInfo[i]
        
    def read_arguement(self):
        with open('arguement.csv',encoding='utf-8-sig') as lt:
            reader = csv.reader(lt)    
            for i in reader:
                #print(i[0],i[1])
                self.arguement[i[0].lower()]=i[1]
    # load lookup table for mail recongnization
    def read_command(self):
        with open('command.csv',encoding='utf-8-sig') as lt:
            reader = csv.reader(lt)    
            for i in reader:
                #print(i[0],i[1])
                self.command[i[0]]=i[1]
    def read_ignoreWord(self):
        with open('ignoreWord.csv',encoding='utf-8-sig') as lt:
            reader = csv.reader(lt)    
            for i in reader:
                #print(i[0],i[1])
                self.ignoreWord[i[0]]=1
    def read_keyword(self):
        self.oneHotDimension = 0
        with open('keyword.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm) 
            # the dimension of one hot is determined by the keyword number
            for i in reader:
                self.oneHotDimension = self.oneHotDimension + 1
        with open('keyword.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm) 
            oneHot = np.zeros(self.oneHotDimension, dtype=int)
            k = 0
            for i in reader:
                oneHot = np.zeros(self.oneHotDimension, dtype=int)
                oneHot[k] = 1
                k = k + 1
                for j in i:
                    if not j:
                        continue
                    self.keyword[j.lower().strip()] = oneHot
                    if self.debug['encode'] == 1:
                        print(j.strip(),oneHot,self.array_to_dec(oneHot))
                    #print(j,"|",oneHot)
                    
    def read_instruction(self):
        print("## start to read instruction...")
        ins_id = {}
        conflict_id = {}
        with open(self.instructionFile,encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)    
            for ins in reader:
                # scan 2 word each time for some combine work like "kick off","shut down"....
                insLength = len(ins[0].split())
                words = re.sub('[?]',' ',ins[0]).split()
                #print(ins)
                oneHotValue = np.zeros(self.oneHotDimension, dtype=int)
                skip = 0
                #print(ins[0])
                for i in range(insLength):
                    if skip == 1:
                        skip = 0
                        continue
                    if insLength == 1:
                        word = words[i]
                        word_lower = word.lower()
                        if word_lower in self.keyword:
                            oneHotValue = oneHotValue + self.keyword[word_lower]
                            continue
                        
                    if i+1<insLength:
                        word = words[i]
                        phrase = words[i]+ " " + words[i+1]
                        #print(phrase)
                        # phrase has higher priority
                        if phrase in self.keyword:
                            #print(phrase,self.keyword[phrase])
                            oneHotValue = oneHotValue + self.keyword[phrase]
                            # skip next word scanning
                            skip = 1
                            continue
                            #print(word,self.keyword[word],oneHotValue)
                    word = words[i]
                    word_lower = word.lower()
                    if word_lower in self.keyword:
                        oneHotValue = oneHotValue + self.keyword[word_lower]

                
                self.instruction[oneHotValue.tobytes()] = ins[1]
                self.instruction_orig[oneHotValue.tobytes()] = ins[0]
                if oneHotValue.tobytes() in ins_id:
                    if ins_id[oneHotValue.tobytes()] != ins[2]:
                        print("# Conflict",ins_id[oneHotValue.tobytes()],ins[0],ins[2])
                        conflict_id[ins_id[oneHotValue.tobytes()]] = ins[2]
                else:
                    ins_id[oneHotValue.tobytes()] = ins[2]

                #if np.all(oneHotValue==0):
                if self.debug['encode'] == 1:
                    print("instruction",ins,oneHotValue,self.array_to_dec(oneHotValue))
                #self.instruction[i[0]] = i[1]
                #print(i[0],i[1])
        print("### Report conflict instruction...")        
        for insid in conflict_id:
            print(insid,"conflict with",conflict_id[insid])

    def array_to_dec(self,arr):
        dec = 0
        dec_info = ""
        for i in range(len(arr)):
            #dec = dec + arr[i]*2**i
            if arr[i] == 1:
                dec = dec + 1
                dec_info = dec_info + " " + str(i)
        return dec,dec_info
         
    def send_mail(self,sender,subject,mailBody,quote):
        mailBody = re.sub('\\\\n','\n',mailBody)
        mail = 'echo ' + '"'+ mailBody + '\n' + '----------------------------------------------------------------------------------------------------' + \
                '\n' +  quote + ' "'+ \
            ' | formail -I "From: virtual tile owner" -I "MIME-Version:1.0" -I "Content-type:text;charset=utf-8" -I "Subject:Re:'+ subject+ '" | sendmail -oi ' + sender
        #print(mail)
        p = os.popen(mail)
        

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--mailFile',type=str, default = "tasksMail.csv",required=True,help="mailFile file")
    parser.add_argument('--tasksModelFile',type=str, default = "tasksModel.csv",required=True,help="tasksModelFile file")
    parser.add_argument('--instructionFile',type=str, default = "instruction.csv",required=True,help="instructionFile file")
    args = parser.parse_args()

    timeSlot0 = 15
    timeSlot1 = 20
    try:
        tileOwner = TileOwner()
        tileOwner.read_mail_config()
        tileOwner.read_assignment()
    #tileOwner.update_arguement("tile.params")
        print(tileOwner.senderNameList,tileOwner.mailDays)
        multiLevelModels = MultiLevelModels()
        multiLevelModels.set_mailFile(args.mailFile) 
        multiLevelModels.set_tasksModelFile(args.tasksModelFile)
        multiLevelModels.set_instructionFile(args.instructionFile)
        multiLevelModels.set_vtoInfo(tileOwner.vtoInfo)
        multiLevelModels.read_command()
        multiLevelModels.read_arguement()
        multiLevelModels.read_keyword()
        multiLevelModels.read_instruction()
    except Exception as e:
        print("multiLevelModels",e)
    #while True:
    #    curr_time = datetime.datetime.now()
    #    if curr_time.second < timeSlot1 and curr_time.second > timeSlot0:
    #        multiLevelModels.merge_task()
    #        multiLevelModels.generate_instruction()
