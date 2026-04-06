# -*- coding: utf-8 -*-
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
from typing import List, Dict, Tuple
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
        self.vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'',\
        'debugger':'','manager':'','senderName':'','flowLead':'','fct':'','librarian':''}
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
                if len(i) < 2:
                    continue
                if re.search(r"tile$",i[0]):
                    print(i[0],i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                    self.arguement[i[1]]=i[0]
                if re.search(r"^disk$",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    print(i[0],i[1])
                if re.search(r"^project",i[0]):
                    self.vtoInfo['project'] = i[1]
                    print(i[0],i[1])
                if re.search(r"^vto",i[0]):
                    self.vtoInfo['vto'] = self.vtoInfo['vto'] + ":" + i[1].lower()
                    #print(i[0],i[1].lower())

                if re.search(r"debugger",i[0]):
                    if len(self.vtoInfo['debugger']) > 0:
                        self.vtoInfo['debugger'] = self.vtoInfo['debugger'] + "," + i[1].lower()
                    else:
                        self.vtoInfo['debugger'] = i[1].lower()
                    print(i[0],i[1])

                if re.search(r"manager",i[0]):
                    if len(self.vtoInfo['manager']) > 0:
                        self.vtoInfo['manager'] = self.vtoInfo['manager'] + "," + i[1].lower()
                    else:
                        self.vtoInfo['manager'] = i[1].lower()
                    print(i[0],i[1])

                if re.search(r"flowLead",i[0]):
                    if len(self.vtoInfo['flowLead']) > 0:
                        self.vtoInfo['flowLead'] = self.vtoInfo['flowLead'] + "," + i[1].lower()
                    else:
                        self.vtoInfo['flowLead'] = i[1].lower()
                    print(i[0],i[1])

                if re.search(r"fct",i[0]):
                    if len(self.vtoInfo['fct']) > 0:
                        self.vtoInfo['fct'] = self.vtoInfo['fct'] + "," + i[1].lower()
                    else:
                        self.vtoInfo['fct'] = i[1].lower()
                    print(i[0],i[1])

                if re.search(r"senderName",i[0]):
                    if len(self.vtoInfo['senderName']) > 0:
                        self.vtoInfo['senderName'] = self.vtoInfo['senderName'] + "," + i[1].lower()
                    else:
                        self.vtoInfo['senderName'] = i[1].lower()


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
        self.arguementInfo = {}
        self.readTask = 0
        self.command = {}
        self.ignoreWord={}
        self.keyword = {}
        self.oneHotDimension = 0
        self.tasks = []
        self.vtoInfo = {}
        self.patterns = []
        self.ip = ''
        if os.path.exists("vto_debug"):
            self.debug = {"encode":1,"parse":1}
        else:
            self.debug = {"encode":0,"parse":0}

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
            print("set_vto",i,vtoInfo[i])
            self.vtoInfo[i] = vtoInfo[i]
    
        
    def read_arguement(self):
        with open('arguement.csv',encoding='utf-8-sig') as lt:
            reader = csv.reader(lt)    
            for i in reader:
                #print(i[0],i[1])
                #self.arguement[i[0].lower()]=i[1]
                self.arguement[i[0]]=i[1]
                self.arguementInfo[i[1]] = i[1]
                if i[1] == "target":
                    self.arguement[i[0].lower()]=i[1]

        if os.path.exists("tbs.log"):
            tbs = open("tbs.log")
            for line in tbs:
                if len(line.split()) == 3:
                    self.arguement[line.split()[1].lower()]="target"
                    self.arguementInfo["target"] = "target"
                    #print(line.split()[1].lower())
    
    def load_patterns_from_csv(self) -> List[Tuple[str, str, re.Pattern]]:
        patterns = []
        if os.path.exists("patterns.csv"):
            pass
        else:
            self.patterns = patterns
            return patterns

        with open("patterns.csv", mode='r', newline='', encoding='utf-8') as file:
            reader = csv.reader(file)
            for row in reader:
                if len(row) < 2:
                    continue  # skip invalid lines

                pattern = row[0].strip()
                pattern_type = row[1].strip()
                self.arguementInfo[pattern_type]=pattern_type
                flags = 0

                # process match flag
                if len(row) > 2 and row[2].strip():
                    flag_str = row[2].strip().upper()
                    for char in flag_str:
                        if hasattr(re, char):
                            flags |= getattr(re, char)

                try:
                    compiled_re = re.compile(pattern, flags)
                    patterns.append((pattern, pattern_type, compiled_re))
                except re.error as e:
                    print(f"warning: invalid pattern '{pattern}': {e}")
                    continue
        self.patterns = patterns
        return patterns
    
    def match_patterns(self,input_str: str, patterns: List[Tuple[str, str, re.Pattern]]) -> List[Dict[str, str]]:
        matches = []
        for pattern, pattern_type, compiled_re in patterns:
            match = compiled_re.fullmatch(input_str)
            if match:
                matches.append({
                    'match': match.group(),
                    'type': pattern_type,
                    'pattern': pattern
                })
        return matches

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
        with open(self.instructionFile,encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)    
            for ins in reader:
                # scan 2 word each time for some combine work like "kick off","shut down"....
                insLength = len(ins[0].split())
                words = re.sub('[?]',' ',ins[0]).split()
                insLength = len(re.sub('[?]',' ',ins[0]).split())
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
                #if np.all(oneHotValue==0):
                if self.debug['encode'] == 1:
                    print("instruction",ins,oneHotValue,self.array_to_dec(oneHotValue))
                #self.instruction[i[0]] = i[1]
                #print(i[0],i[1])
                
    def merge_task(self):
        print("# merge Task...")
        tasksMail = []
        # read tasks from communicationInterface
        url = self.vtoInfo['ip'] + "/" + self.mailFile
        #response = requests.get(url)
        #tm = open(self.mailFile,'w')

        #if response.status_code == 200:
        #    content = response.text
        #    tm.write(content)
        #tm.close()
        if os.path.exists("data/jira"):
                #print(task["tag"]+" dir existed")
            pass
        else:
            os.makedirs("data/jira")

        with open(self.mailFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
            params_h = {}
            controls_h = {}
            version_h = {}
            p4_h = {}
            for i in reader:
                readMail = 0
                mailBodyProcess = i["mailBody"]
                # Some params contain "," which cannot be replaced.
                if re.search('=',mailBodyProcess):
                    pass
                else:
                    mailBodyProcess = re.sub(',','\n',mailBodyProcess)
                timeCurrent = re.sub("-"," ",str(datetime.datetime.now()))
                year = timeCurrent.split()[0]
                month = timeCurrent.split()[1]
                day = timeCurrent.split()[2]
                fullTime = year+month+day
                # If vto names are not in mail config,skip the mail
                for sentence in mailBodyProcess.split('\n'):
                    if re.search("Hi ",sentence):
                        sentence = re.sub('\/',' ',sentence)
                        sentence = re.sub('\.',' ',sentence)
                        #print(sentence)
                        for vto in sentence.split():
                            vto = re.sub(',','',vto)
                            vto = vto.lower()
                            if vto in self.vtoInfo['vto'].split(":"):
                                if re.search("\S",self.vtoInfo['senderName']):
                                    if re.search(i["sender"].lower(),self.vtoInfo['senderName'].lower()):
                                        print("# Found match defined senderName",i["sender"])
                                        pass
                                    else:
                                        print("# Defined senderName, skip undefined name",i["sender"])
                                        continue

                                if re.search("all",vto):
                                    if i["sender"].lower() in self.vtoInfo['flowLead'].split(",") or \
                                        i["sender"].lower() in self.vtoInfo['fct'].split(",") or \
                                        i["sender"].lower() in self.vtoInfo['manager'].split(",") or \
                                        i["sender"].lower() in self.vtoInfo['librarian'].split(",") :
                                        pass
                                    else:
                                        continue
                                #print(i["mailBody"]) librarian
                                readMail = 1
                        break
                if readMail == 1:
                    self.tasksMail.append(i)
                
                for sentence in mailBodyProcess.split(';;'):
                    # update tool version list for crash trial
                    j = 0
                    sentenceProcess = re.sub('\.$','',sentence)
                    sentenceProcess = re.sub(',',' ',sentenceProcess)
                    words = sentenceProcess.split()
                    for word in sentence.split() :
                        word = re.sub('[?:]','',word)
                        word_version = word.split("/")[0]
                        if word_version.lower() in self.arguement and i['sender'] == "Ontrackinternal.Imap@amd.com":
                            if re.search("edatool",self.arguement[word_version.lower()]):
                                print("# Found tool version",word_version,self.arguement[word_version.lower()])
                                version_h[word] = self.arguement[word_version.lower()]

                            if re.search("params",self.arguement[word_version.lower()]) and re.search("=",sentenceProcess):
                                #params = " ".join(words[j:j+3])
                                #params_h[params] = 1
                                pass
                                #print("# Found params",params)

                            if re.search("controls",self.arguement[word_version.lower()]) and re.search("=",sentenceProcess):
                                controls = " ".join(words[j:j+3])
                                print("# Found controls",controls)
                                controls_h[controls] = 1

                        if re.search('(//.*)',word) and i['sender'] == "Ontrackinternal.Imap@amd.com":
                            p4_h[word] = 1
                            print("# Found p4 file",word)
                        
                        ## check tune file? 
                        j = j + 1

            print ("# Write Jira to list")
            if len(version_h) > 0:
                module_file = "data/jira/edatool.list"
                if os.path.exists(module_file):
                    md = open(module_file,'r')
                    for line in md:
                        version_h[line]  = 1
                    md.close()
                md = open(module_file,'w')
                for version in version_h:
                    md.write(version+"\n")
                md.close()
            
            if len(params_h) > 0:
                #print("params size",len(params_h))
                params_file = "data/jira/params."+ fullTime +".list"
                if os.path.exists(params_file): 
                    pm = open(params_file,'r')
                    for line in pm:
                        params_h[line]  = 0
                       
                    pm.close()
                    
                    pm = open(params_file,'w')
                    
                    for params in params_h:
                        pm.write(params+"\n")
                else:
                    print("write params")
                    pm = open(params_file,'w')
                    for params in params_h:
                        print("# Write params",params)
                        pm.write(params+"\n")
                pm.close()
            if len(controls_h) > 0:
                controls_file = "data/jira/controls." + fullTime+ ".list"
                print("controls size",len(controls_h))
                if os.path.exists(controls_file):
                    pm = open(controls_file,'r')
                    for line in pm:
                        controls_h[line]  = 0

                    pm.close()

                    pm = open(controls_file,'w')

                    for controls in controls_h:
                        pm.write(controls+"\n")
                else:
                    print("write controls")
                    pm = open(controls_file,'w')
                    for controls in controls_h:
                        print("# Write controls",controls)
                        pm.write(controls+"\n")
                pm.close()
            if len(p4_h) > 0:
                p4_file = "data/jira/p4." + fullTime+ ".list"
                print("controls size",len(p4_h))
                if os.path.exists(p4_file):
                    pm = open(p4_file,'r')
                    for line in pm:
                        p4_h[line]  = 0

                    pm.close()

                    pm = open(p4_file,'w')

                    for p4 in p4_h:
                        pm.write(p4+"\n")
                else:
                    print("write p4")
                    pm = open(p4_file,'w')
                    for p4 in p4_h:
                        print("# Write p4",p4)
                        pm.write(p4+"\n")
                pm.close()
            f.close
        tasksModel = []
        # read saved tasks
        if os.path.exists(self.tasksModelFile):
            tsm = open(self.tasksModelFile,'r')
            n_line = 0
            for line in tsm:
                n_line = n_line + 1
                if len(line) > 10000:
                    print("# ERROR: abnormal line:",n_line,len(line),line)
            with open(self.tasksModelFile,encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for task in reader:
                    self.tasksModel.append(task)
                f.close()
        # merge saved tasks with new tasks from communictionInterface
        for task in self.tasksMail:
            find = 0
            for j in self.tasksModel:
                if task['time'] == j['time']:
                    find = 1
                    break

            if find == 0:
                self.tasksModel.append(task)
        # compare each words of sentence with the instruction lookup table.
    def generate_instruction(self):
        '''
        for i in self.keyword:
            if i == 'send':
                print(i,self.keyword[i])
        '''
        print("## start to generate instruction...")
        # extract existed run dir
        runDir_file = self.tasksModelFile+'.runDir'
        rdr = open(runDir_file,'w')
        dirList = []
        # No record task status in this iteration
        print("## record existed run dir.")
        for task in self.tasksModel:
            if task["runDir"] is None:
                continue
            taskDirList = []   
            if re.search("\S",task["runDir"]):
                # remove non exist run dir
                for rd in task["runDir"].split(':'):
                    if os.path.exists(rd) and os.path.exists(rd+"/tile.params"):
                        # Generate runDir.list for legacy run
                        taskDirList.append(rd)
                        if len(rd) > 0:
                            if rd in dirList:
                                continue
                            else:
                                dirList.append(rd)
                            #rdr.write(rd+'\n')
            if os.path.exists("data/"+task["tag"]+"/runDir.list"):
                pass
            else:
                if os.path.exists("data/"+task["tag"]) and len(taskDirList) > 0:
                    tdr = open("data/"+task["tag"]+"/runDir.list",'w')
                    tdr.write(":".join(taskDirList)+'\n')
                    tdr.close()

 
        for idr in reversed(dirList):
            # write all the run dir
            rdr.write(idr+'\n')
        rdr.close()
        if os.path.exists("data/jira"):
                #print(task["tag"]+" dir existed")
            pass
        else:
            os.makedirs("data/jira")

        for task in self.tasksModel:
            # Skip process jira, handle it in monitor
            if task['sender'] == "Ontrackinternal.Imap@amd.com":
                continue
            arguementInfo = {'tile':'tile','file':'file','p4File':'p4File','csh':'csh','perl':'perl','runDir':'runDir','refDir':'refDir',\
                    'sender':task["sender"],'noLsf':'noLsf',\
                    'digit':'digit','date':'date','integer':'integer','unit':'unit','repeat':'repeat','regu':'regu','table':'table','preposition':'preposition',\
                    'clk':'clk','pvt':'pvt','block':'block','role':'role',\
                    'stage':'stage','target':'target','cmds':'cmds','snpstcl':'snpstcl','ip':'ip','analogip':'analogip','sram':'sram','std':'std','edatool':'edatool',\
                    'disk':self.vtoInfo['disk'],'params':'params','controls':'controls','tune':'tune','tag':'tag','checkType':'checkType','updateType':'updateType',\
                    'ownTiles':self.vtoInfo['tile'],'project':self.vtoInfo['project']}
            arguementInfo['runDir'] = runDir_file
            for info in self.arguementInfo:
                if info in arguementInfo:
                    pass
                    #print(info,"exist in initialization.")
                arguementInfo[info] = self.arguementInfo[info]
            iniAlltiles = 0 
            #arguementInfo['table'] = os.path.realpath(table_file)
            #arguementInfo['controls'] = os.path.realpath(controls_file)
            #arguementInfo['params'] = os.path.realpath(params_file)
            if self.debug['encode'] == 1:
                print(task["tag"],task["subject"])
            if task["instruction"] is not None and task["reply"] is not None:
                if len(task["instruction"]) != 0 or len(task["reply"]) != 0:
                    # keep old tasks that has been processed!!!
                    if os.path.exists("data/"+task["tag"]+"_spec"):
                        if re.search("\S",task["status"]):
                            pass
                        else:
                            task["status"] = "running"
                    
                    if re.search("\S",task["runDir"]):
                        pass
                    else:
                        # Fresh run dir into tasksModel.csv if $tag/runDir.list exists
                        if os.path.exists("data/"+task["tag"]+"/runDir.list"):
                            print("# Found empty rundir in csv but exists in data"+task["tag"])
                            rde = open("data/"+task["tag"]+"/runDir.list",'r')
                            for line in rde:
                                if re.search("\S",line):
                                    task["runDir"] = line 
                            rde.close()

                    self.tasks.append(task)
                    continue
            if os.path.exists("data/"+task["tag"]):
                #print(task["tag"]+" dir existed")
                pass
            else:
                os.makedirs("data/"+task["tag"])

            params_file = "data/"+task["tag"]+'.params'
            table_file = "data/"+ task["tag"]+ '.table'
            controls_file = "data/"+ task["tag"]+'.controls'
            csh_file = "data/" + task["tag"] + "/" + task["tag"] +'.csh'
            waiver_file = "data/"+task["tag"]+'.cdc_rdc_waiver'
            constraint_file = "data/"+task["tag"]+'.cdc_rdc_constraint'
            config_file = "data/"+task["tag"]+'.cdc_rdc_config'
            version_file = "data/"+task["tag"]+'.cdc_rdc_version'
            lint_waiver_file = "data/"+task["tag"]+'.lint_waiver'
            p4_file_list = "data/"+task["tag"]+'.p4_files'
            p4_description_file = "data/"+task["tag"]+'.p4_description'
            spg_dft_params_file = "data/"+task["tag"]+'.spg_dft_params'

            pm = open(params_file,'w')
            suspected_params = []
            cn = open(controls_file,'w')
            tb = open(table_file,'w')
            wv = open(waiver_file,'w')
            ct = open(constraint_file,'w')
            cf = open(config_file,'w')
            vr = open(version_file,'w')
            lw = open(lint_waiver_file,'w')
            p4f = open(p4_file_list,'w')
            p4d = open(p4_description_file,'w')
            spg = open(spg_dft_params_file,'w')
            # extract mail body
            mbd = open("data/"+task["tag"]+"/"+task["tag"]+".log",'w')
            mbd.write("Subject:"+task["subject"]+'\n')
            mbd.write(task["mailBody"])
            mbd.close()
            sbj = open("data/"+task["tag"]+"/subject.info",'w')
            sbj.write(re.sub("\?","",task["subject"]))
            sbj.close()
            llmc = open("data/"+task["tag"]+"/llm.txt",'w')
            print("# Create table:",table_file)
            csh = open(csh_file,"w")
            arguementInfo['table'] = table_file
            tagtcl = open("data/"+ task["tag"] + "/" + task["tag"] + ".tcl",'w')
            #arguementInfo['controls'] = controls_file
            #arguementInfo['params'] = params_file
            instruction_start = 0
            pre_csh = ''
            arguementInfo['tag'] = task["tag"]
            skip_text = 0
            # Unify the , to \n
            mailBodyProcess = task["mailBody"]
            # Some params contain "," which cannot be replaced.
            # Also protect waiver/constraint lines from comma replacement
            if re.search('=',mailBodyProcess):
                pass
            elif re.search('cdc report|resetcheck report|netlist ',mailBodyProcess):
                # Don't replace commas in waiver/constraint statements
                pass
            else:
                mailBodyProcess = re.sub(',','\n',mailBodyProcess)
            #mailBodyProcess = re.sub(' and ','\n',mailBodyProcess)
            
            # Don't add space before semicolon for lint waiver lines
            if re.search(r'(error|code|filename|msg|line|column|reason|author)\s*:', mailBodyProcess, re.I):
                # Has lint waiver fields - don't modify semicolons
                pass
            else:
                mailBodyProcess = re.sub(';',' ;\n',mailBodyProcess)
            # handle the p4 path: //xxx/...
            if re.search('\.\.\.$',mailBodyProcess):
                pass
            else:
                mailBodyProcess = re.sub('\.$',' ',mailBodyProcess)
            mailBodyProcess = re.sub('\. ',' . \n',mailBodyProcess)
            idendityTile = 0
            arguementInfoEn = 1
            is_tune = 0
            printParamsFlag = 0
            is_llm = 0
            for sentence in mailBodyProcess.split('\n'):
                found_op = 0
                if is_llm == 1:
                    llmc.write(sentence+'\n') 
                    continue

                # Check sentence-level patterns for waiver/constraint/config/lint_waiver
                sentence_matches = self.match_patterns(sentence, self.patterns)
                if sentence_matches:
                    for match in sentence_matches:
                        # Process waiver, constraint, config, lint_waiver, spg_dft_params, p4_description, and p4_file at sentence level
                        if match['type'] in ['waiver', 'constraint', 'config', 'lint_waiver', 'spg_dft_params', 'p4_description', 'p4_file']:
                            print(f"# Sentence matched - type: {match['type']}")
                            if match['type'] in arguementInfo:
                                if len(arguementInfo[match['type']]) > len(match['type']):
                                    arguementInfo[match['type']] = arguementInfo[match['type']] + "\n" + sentence
                                else:
                                    arguementInfo[match['type']] = arguementInfo[match['type']] + ":" + sentence
                            # Write to specific file based on type
                            if match['type'] == 'waiver':
                                wv.write(sentence + '\n')
                                print(f"# Wrote waiver to: {waiver_file}")
                            elif match['type'] == 'constraint':
                                ct.write(sentence + '\n')
                                print(f"# Wrote constraint to: {constraint_file}")
                            elif match['type'] == 'config':
                                # Ensure config has leading space for YAML indentation
                                if not sentence.startswith(' '):
                                    cf.write(' ' + sentence + '\n')
                                else:
                                    cf.write(sentence + '\n')
                                print(f"# Wrote config to: {config_file}")
                            elif match['type'] == 'lint_waiver':
                                lw.write(sentence + '\n')
                                print(f"# Wrote lint waiver to: {lint_waiver_file}")
                            elif match['type'] == 'p4_description':
                                # Extract description text after "Description:"
                                if 'Description:' in sentence:
                                    desc_text = sentence.split('Description:')[1].strip()
                                    p4d.write(desc_text + '\n')
                                    print(f"# Wrote P4 description: {desc_text}")
                            elif match['type'] == 'spg_dft_params':
                                spg.write(sentence + '\n')
                                print(f"# Wrote Spyglass DFT param to: {spg_dft_params_file}")
                            elif match['type'] == 'p4_file':
                                p4f.write(sentence + '\n')
                                print(f"# Wrote P4 file to: {p4_file_list}")
                            # Skip word-level processing for this sentence
                            continue

                print("# arguementInfoEn",arguementInfoEn)
                if re.search(':>|<:',sentence):
                    sentence = re.sub('[?]',' ',sentence)
                else:
                    sentence = re.sub('\?',' ',sentence)
                    sentence = re.sub(':$',' ',sentence)
                # handle the p4 path: //xxx/...
                if re.search('\.\.\.',sentence):
                    pass
                else:
                    sentence = re.sub('\.$',' .',sentence)
                if re.search("^\|",sentence) and re.search("|$",sentence):
                    if re.search("\|nan\|",sentence):
                        continue
                    tb.write(sentence+'\n')
                    continue
                    
                if self.debug['encode'] == 1:
                    print(sentence)

                if re.search("\.csh\b|\.csh ",sentence) or re.search("\.py\b|\.py ",sentence) or \
                    re.search("\.pl\b|\.pl ",sentence):
                    print("\.csh",sentence)
                    #task["instruction"] = task["instruction"] + ";" + sentence
                    #continue
                words = sentence.split()
                if (len(words)==0):
                    continue
                # Comment the description
                if re.search("^# ",words[0]):
                    continue
                if re.search('^######',words[0]) and skip_text == 0:
                    skip_text = 1
                    continue
                if skip_text == 1:
                    continue
                if re.search('^######',words[0]) and skip_text == 1:
                    skip_text = 0
                    continue
                # Recognize print params
                if re.search('^<:',sentence) and re.search(':>',sentence):
                    pm.write(sentence+'\n')
                    print(sentence)
                    continue

                if re.search('^<:',sentence):
                    pm.write(sentence+'\n')
                    printParamsFlag = 1
                    print(sentence)
                    continue

                if re.search('^:>',sentence):
                    pm.write(sentence+'\n')
                    printParamsFlag = 0
                    continue

                if printParamsFlag == 1:
                    pm.write(sentence+'\n')

                # partially match the instruction,set() can find and remove the duplicated element(match element)
                # scan 2 word each time for some combine work like "kick off","shut down"....
                insLength = len(words)
                oneHotValue = np.zeros(self.oneHotDimension, dtype=int)
                skip = 0
                validTiles = {}
                # No tile related update
                if idendityTile == 1 and arguementInfo['tile'] == 'tile':
                    arguementInfoEn = 0
                
                # Found related tile for update
                if idendityTile == 1 and arguementInfo['tile'] != 'tile':
                    arguementInfoEn = 1 
 
                pre_ins = ''
                is_params = 0
                
                if is_tune == 1 and re.search("source",sentence) and re.search("\.tcl",sentence):
                    tunetcl.write(sentence+'\n')
                    continue        
                else:
                    if re.search("source",sentence) and re.search("\.tcl",sentence):
                        tagtcl.write(sentence+'\n')
                        continue
                for j in range(insLength):
                    found_tile = 0
                    if skip == 1:
                        skip = 0
                        continue
                    word = words[j]
                    #print(word)
                    if j+1<insLength:
                        phrase = words[j] + " " + words[j+1]
                        # phrase has higher priority
                        if phrase in self.keyword:
                            if self.debug['encode'] == 1:
                                print(phrase,self.keyword[phrase])
                            oneHotValue = oneHotValue + self.keyword[phrase]
                            if found_op == 0:
                                # process the previous instruction when new line found operation code
                                found_op = 1
                                if len(pre_csh) == 0:
                                    pass
                                else:
                                    # See new instruction add complete csh with arguement for previous instruction.
                                    for p in pre_csh.split():
                                        # Check if p is arguement
                                        se = re.search('\$(.*)',p)
                                        # If p is arguement, set it.
                                        if se:
                                            arguement_csh = se.group(0)
                                            arguement_csh = re.sub('\$','',arguement_csh)
                                            if len(arguementInfo[arguement_csh]) != 0:
                                                if arguementInfoEn == 1:
                                                    task["instruction"] = task["instruction"] + " " + arguementInfo[arguement_csh]
                                                    print("# check argument:",arguement_csh)
                                            else:
                                                # the arguement has no value
                                                task["instruction"] = ""
                                                task["reply"] = "Dear Sir,\n arguement miss value for" +  pre_csh + " in " + pre_csh
                                                self.send_mail(task["sender"],task["subject"],task["reply"],task["mailBody"])
                                        else:
                                            # If p is not arguement, it is csh
                                            task["instruction"] = task["instruction"] + ";" + "source script/" + p
                                    # clean target info when previous instruction finish
                                    print("# clean target")
                                    arguementInfo['target'] = 'target'

                            # skip next word scanning
                            skip = 1
                            continue
                        if phrase.lower() == 'all tiles' or phrase.lower() == 'all tile' or phrase.lower() == 'any tile' or \
                            phrase.lower() == 'any tiles':
                            arguementInfo['tile'] = self.vtoInfo['tile'] 
                            print("word",phrase.lower(),1)
                            skip = 1
                            continue
                        if phrase.lower() == 'impact tiles' or phrase.lower() == 'impact tile':
                            print("word",phrase.lower(),2)
                            idendityTile = 1                   
                            arguementInfo['tile'] = 'tile' 

                    # check if owned impact tiles
                    for tile in self.vtoInfo['tile'].split(':'):
                        if word == tile :
                            arguementInfo['tile'] = arguementInfo['tile'] + ":" + word
                            found_tile = 1
                    if found_tile == 1:
                        continue

                    # skip arguement scan if impact tiles not owned.
                    if arguementInfoEn == 0:
                        continue
                    # the csv only have lower word

                    # parameters for TB need to be handle specially, has highest priority, since PROJECT may be mixed with project in argument or key word.
                    if word in self.arguement:
                        if self.arguement[word] == 'params' and re.search('=',sentence) :
                            #arguementInfo['params'] = arguementInfo['params'] + ":" + word
                            pm.write(sentence+'\n')
                            print("params",sentence)
                            is_params = 1
                            break
                    if word in self.arguement:
                        if self.arguement[word] == 'controls' and re.search('=',sentence) :
                            arguementInfo['controls'] = arguementInfo['controls'] + ":" + word
                            cn.write(sentence+'\n')
                            print("controls",sentence)
                            is_controls = 1
                            break

                    word_lower = word.lower()
                    if word_lower in self.keyword:
                        if self.debug['encode'] == 1:
                            print(oneHotValue,self.keyword[word_lower])
                        oneHotValue = oneHotValue + self.keyword[word_lower]
                        if found_op == 0:
                            # process the previous instruction when new line found operation code
                            found_op = 1
                            if len(pre_csh) == 0:
                                pass
                            else:
                                # See new instruction add complete csh with arguement for previous instruction.
                                for p in pre_csh.split():
                                    # Check if p is arguement
                                    se = re.search('\$(.*)',p)
                                    # If p is arguement, set it.
                                    if se:
                                        arguement_csh = se.group(0)
                                        arguement_csh = re.sub('\$','',arguement_csh)
                                        if len(arguementInfo[arguement_csh]) != 0:
                                            if arguementInfoEn == 1:
                                                task["instruction"] = task["instruction"] + " " + arguementInfo[arguement_csh]
                                                print("# check argument:",arguement_csh)
                                        else:
                                            # the arguement has no value
                                            task["instruction"] = ""
                                            task["reply"] = "Dear Sir,\n arguement miss value for" +  pre_csh + " in " + pre_csh
                                            self.send_mail(task["sender"],task["subject"],task["reply"],task["mailBody"])
                                    else:
                                        # If p is not arguement, it is csh
                                        task["instruction"] = task["instruction"] + ";" + "source script/" + p
                                # clean target info when previous instruction finish
                                print("# clean target")
                                # Hard code for "optimize run"
                                arguementInfo['target'] = 'target'
                                arguementInfo['clk'] = 'clk'
                                arguementInfo['integer'] = 'integer'

                        # handle keyword and argument same, e.g. place is keyword as well as stage
                        if word_lower in self.arguement:
                            #print("## other argument",word_lower)
                            value = self.arguement[word_lower]
                            if value in arguementInfo:
                                arguementInfo[value] = arguementInfo[value] + ":" + word
 
                        continue

                    se = re.search('(^[0-9]+\/[0-9]+)',word)
                    if se:
                        date = se.group(0)
                        arguementInfo['date'] = arguementInfo['date'] + ":" + date
                        continue
                    
                    se = re.search('(^[0-9]+\.[0-9]+)',word)
                    if se:
                        digit = se.group(0)
                        arguementInfo['digit'] = arguementInfo['digit'] + ":" + digit
                        continue

                    se = re.search('(^[0-9]+$)',word)
                    if se:
                        integer = se.group(0)
                        arguementInfo['integer'] = arguementInfo['integer'] + ":" + integer
                        continue
                    # recognize object if file or tile or argument?
                    word_split = word_lower.split("/")
                    #print(word_split[0])
                    if word_split[0] in self.arguement and self.arguement[word_split[0]] == 'edatool':
                        arguementInfo['edatool'] = arguementInfo['edatool'] + ":" + word
                        print("Found edatool",word)
                        continue
                    # for add command to tune without adding tune name to arguement.csv
                    if re.search("tune/.*/.*",word_lower):
                        if re.search("/tune/",word_lower):
                            pass
                        else:
                            if is_tune == 1:
                                tunetcl.close()
                            tuneDir_array = word.split("/")
                            tuneDir = '/'.join(tuneDir_array[:-1])
                            if os.path.exists("data/"+ task["tag"] + "/" + tuneDir):
                                pass
                            else:
                                os.makedirs("data/"+ task["tag"] + "/" + tuneDir)
                            tunetcl = open("data/"+ task["tag"] + "/" + word,'w')
                            is_tune = 1
                            arguementInfo['tune'] = arguementInfo['tune'] + ":" + word
                            continue
                    
                    if word_lower in self.arguement:
                        print("# Found arguement:",word_lower)
                        sentence_cat=re.sub('[ ]','',sentence)
                        # Detect tune and tcl command
                        if self.arguement[word_lower] == 'snpstcl' and is_tune == 1:
                            print("snpstcl:",sentence)
                            arguementInfo['snpstcl'] = arguementInfo['snpstcl'] + ":" + word
                            tunetcl.write(sentence+'\n')
                            break
                        else:
                            if self.arguement[word_lower] == 'snpstcl':
                                tagtcl.write(sentence+'\n')
                                break

                        if self.arguement[word_lower] == 'csh':
                            print("csh:",sentence)
                            arguementInfo['csh'] = arguementInfo['csh'] + ":" + word
                            csh.write(sentence+'\n')
                            break
 
                        if self.arguement[word_lower] == 'tune':
                            if is_tune == 1:
                                tunetcl.close()
                            tuneDir_array = word.split("/")
                            tuneDir = '/'.join(tuneDir_array[:-1]) 
                            if os.path.exists("data/"+ task["tag"] + "/" + tuneDir):
                                #print("data/"+ task["tag"] + "/" + tuneDir+" existed.")
                                a = 1
                            else:
                                os.makedirs("data/"+ task["tag"] + "/" + tuneDir) 
                            tunetcl = open("data/"+ task["tag"] + "/" + word,'w')
                            is_tune = 1
                        # Detect other arguement, e.g. target
                        if word_lower in self.arguement:
                            print("## other argument",word_lower)
                            value = self.arguement[word_lower]
                            if value in arguementInfo:
                                arguementInfo[value] = arguementInfo[value] + ":" + word
                    # DFX has capital stage requirement
                    elif word in self.arguement:
                        print("## other argument",word)
                        value = self.arguement[word]
                        if value in arguementInfo:
                            arguementInfo[value] = arguementInfo[value] + ":" + word
 
                    # check suspected params or controls
                    if word == "=" and j > 0 and re.search('[A-Z]',words[j-1]):
                        suspected_params.append(sentence)
                    
                    # Identify p4 file 
                    se = re.search('(^//.*)',word)
                    if se:
                        p4File = se.group(0)
                        arguementInfo['p4File'] = arguementInfo['p4File'] + ":" + "\""+ p4File + "\""
                        break

                    # Identify wild
                    se = re.search('(\*)',word)
                    if se:
                        regu = se.group(0)
                        print("# found regu",regu)
                        # word = re.sub('\*','__',word)
                        arguementInfo['regu'] = arguementInfo['regu'] + ":" + word
                        
                        continue
                    
                    # Identify dir
                    se = re.search('(^/[a-zA-Z].*/$)',word)
                    if se:
                        refDir = se.group(0)
                        arguementInfo['refDir'] = arguementInfo['refDir'] + ":" + refDir
                        print("### found refDir 1",refDir)
                        break
                    
                    # Identify file
                    se = re.search('(^/[a-zA-Z].*)',word)
                    if se:
                        refDir = se.group(0)
                        if os.path.exists(refDir+"/"):
                            arguementInfo['refDir'] = arguementInfo['refDir'] + ":" + refDir
                            #print("### found refDir 2",refDir)
                            break
                        else:
                            file = se.group(0)
                            arguementInfo['file'] = arguementInfo['file'] + ":" + file
                            break
                    
                    
                    se = re.search('(^[a-zA-Z].*/[a-zA-Z].*)',word)
                    if se:
                        file = se.group(0)
                        print("found file",file)
                        arguementInfo['file'] = arguementInfo['file'] + ":" + file
                        continue

                    # Identify clock
                    se = re.search("(.*CLK\S*|.*CLOCK\S*)",word)
                    if se:
                        clk = se.group(1)
                        clk = re.sub(',','',clk)
                        clk = re.sub('\.','',clk)
                        clk = re.sub('\?','',clk)
                        arguementInfo['clk'] = arguementInfo['clk'] + ":" + clk
                        continue

                    # Identify pvt
                    se = re.search("(tt|ss|ff)(0p|1p)(.*v)",word.lower()) 
                    if se:
                        pvt = se.group(1) + se.group(2) + se.group(3)
                        arguementInfo['pvt'] = arguementInfo['pvt'] + ":" + pvt
                        continue
                   
                    # check all patterns 
                    matches = self.match_patterns(word,self.patterns)
                    print(self.patterns)
                    print("# check patterns for",word)
                    if matches:
                        for match in matches:
                            print(f"matched - type: {match['type']}, mode: {match['pattern']}")
                            arguementInfo[match['type']] = arguementInfo[match['type']] + ":" + word
                            # Write version to file
                            if match['type'] == 'version':
                                vr.write(word + '\n')
                                print(f"# Wrote version to: {version_file}")
                            # p4_file is now handled at sentence level, skip word-level
        
                    else:
                        pass
                        #print("not matched")

                    for tile in self.vtoInfo['tile'].split(':'):
                        continue
                        if word == tile :
                            if iniAlltiles == 1 :
                                arguementInfo['tile'] = word
                                # override all tiles initialization 
                                iniAlltiles = 0
                            else:
                                arguementInfo['tile'] = arguementInfo['tile'] + ":" + word
                if is_params == 1:
                    is_params = 0
                    continue
                #if np.all(oneHotValue==0):
                #    continue
                # check if the instruction exist and ready to receive arguement
                if self.debug['encode'] == 1:
                    print(oneHotValue,self.array_to_dec(oneHotValue))
                # sentence end check if any instruction at sentence end
                n1,l1 = self.array_to_dec(oneHotValue)
                if oneHotValue.tobytes() in self.instruction and n1 > 0 and arguementInfoEn == 1 :
                    if self.debug['parse'] == 1:
                        print("# 0 detect: ",self.instruction[oneHotValue.tobytes()])
                    pre_reply = self.instruction[oneHotValue.tobytes()].split()
                    # if instruction is description, answer directly
                    if pre_reply[0] == '#':
                        task["instruction"] = ''
                        task["reply"] = self.instruction[oneHotValue.tobytes()]
                        sender_name_arr = task["sender"].split(".")
                        sender_name = sender_name_arr[0]
                        sender_name = re.sub('[0-9]','',sender_name)
                        greeting = "Hi " + sender_name + ",\n"
                        full_reply = greeting + task["reply"]
                        full_reply = re.sub('#','',full_reply,1)
                        task["status"] = 'finished'
                        print("###",full_reply)
                        self.send_mail(task["sender"],task["subject"],full_reply,task["mailBody"])
                        break
                        pre_csh = self.instruction[oneHotValue.tobytes()]
                    pre_csh = self.instruction[oneHotValue.tobytes()]
                    #print(sentence,"|","|",oneHotValue,"|",self.instruction_orig[oneHotValue.tobytes()])
                # see next instruction, should finish arguement receiving    
            # in the mail body end, start to process the arguement which should be received.
                if re.search("use\s+llm",sentence,re.I):
                    print("# Detect llm use, enter llm content reading...")
                    is_llm = 1

            if is_tune == 1:
                tunetcl.close()
            tagtcl.close()
            csh.close()
            llmc.close()
            wv.close()
            ct.close()
            cf.close()
            vr.close()
            lw.close()
            p4f.close()
            p4d.close()
            spg.close()
            # At the mail end, process the last instruction.
            if len(pre_csh.split()) != 0:
                print("end",pre_csh)
                for p in pre_csh.split():
                    se = re.search('\$(.*)',p)
                    if se:
                        arguement_csh = se.group(0)
                        arguement_csh = re.sub('\$','',arguement_csh)
                        #print(arguement_csh,"arguement",arguementInfo[arguement_csh])
                        if len(arguementInfo[arguement_csh]) != 0:
                            task["instruction"] = task["instruction"] + " " + arguementInfo[arguement_csh]
                            print("# check argument:",arguement_csh)
                        else:
                            # the arguement has no value
                            task["instruction"] = ""
                            task["reply"] = "arguement miss value for " +  arguement_csh + " in " + pre_csh
                            print("arguement miss value for" , arguement_csh)
                            self.send_mail(task["sender"],task["subject"],task["reply"],task["mailBody"])
                            break
                    else:
                        if self.debug['parse'] == 1:
                            print("End",task["instruction"],p)
                        task["instruction"] = task["instruction"] + ";" + "source script/" + p
                        #print(p)
                #arguementInfo['tile'] = 'tile'
                #arguementInfo['file'] = 'file'
                #arguementInfo['runDir'] = 'runDir'
                arguementInfo['p4File'] = 'p4File'
                pre_csh = ''
                # when tranlation done, sent the reply "understand"
                if len(task["reply"]) == 0:
                    #task["reply"] = "Dear Sir,\n OK, got it. I will execute:\n" + " " + task["instruction"]
                    task["reply"] = "OK"
                    #self.send_mail(task["sender"],task["subject"],task["reply"],task["mailBody"])
            else:
                if arguementInfoEn == 0:
                    task["instruction"] = "# unrelated tiles"
                if task["reply"] is None:
                    task["reply"] = "Unknown"
                    #self.send_mail(task["sender"],task["subject"],task["reply"],task["mailBody"])
            self.tasks.append(task)
            tb.close()
            pm.close()
            # impact tiles don't have the owned tiles, set instruction empty.
            #if idendityTile == 1 and arguementInfo['tile'] == 'tile':
            #    task["instruction"] = ""
            #    task["status"] = "finished"
            print("suspected_params",suspected_params)
            if len(suspected_params) > 0:
                spt = "Following are suspected params, if true, please add to arguement.csv:"
                for sp in suspected_params:
                    spt = spt + "\n" + sp 
                self.send_mail(task["sender"],"Re:"+task["subject"],spt,task["mailBody"])
                pass

        with open(self.tasksModelFile, mode="w", encoding="utf-8-sig", newline="") as f:
            header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
            writer = csv.DictWriter(f,header_list)
            writer.writeheader() 
            sorted(self.tasks, key=lambda x: x['time'])
            writer.writerows(self.tasks)
            f.close()
        #print(tasks)
        self.readMail = 0
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
        sm = open('send_mail.txt','w')
        mailBody = re.sub('\\\\n','\n',mailBody)
        sm.write(mailBody+'\n')
        sm.write('----------------------------------------------------------------------------------------------------'+'\n')
        sm.write(quote+'\n')
        sm.close()
        mail = 'cat send_mail.txt'+ \
            ' | formail -I "From: PD Agent" -I "To:' + sender + '" -I "MIME-Version:1.0" -I "Content-type:text;charset=utf-8" -I "Subject:Re:'+ subject+ '" | sendmail -oi ' + sender

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
        #tileOwner.read_mail_config()
        tileOwner.read_assignment()
    #tileOwner.update_arguement("tile.params")
        print(tileOwner.senderNameList,tileOwner.mailDays)
        multiLevelModels = MultiLevelModels()
        multiLevelModels.set_mailFile(args.mailFile) 
        multiLevelModels.set_tasksModelFile(args.tasksModelFile)
        multiLevelModels.set_instructionFile(args.instructionFile)
        multiLevelModels.set_vtoInfo(tileOwner.vtoInfo)
        multiLevelModels.read_arguement()
        multiLevelModels.load_patterns_from_csv()
        multiLevelModels.read_keyword()
        multiLevelModels.read_instruction()
        multiLevelModels.merge_task()
        multiLevelModels.generate_instruction()
    except Exception as e:
        print("multiLevelModels",e)
    #while True:
    #    curr_time = datetime.datetime.now()
    #    if curr_time.second < timeSlot1 and curr_time.second > timeSlot0:
    #        multiLevelModels.merge_task()
    #        multiLevelModels.generate_instruction()
