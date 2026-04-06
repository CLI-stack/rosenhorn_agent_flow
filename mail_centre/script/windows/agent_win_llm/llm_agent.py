# Copyright (c) 2024 Chen, Simon simon1.chen@amd.com Advanced Micro Devices, Inc.
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

import requests
import pandas as pd
import datetime
import os
import re
import csv
import win32com.client as win32
import win32com.client
# html needn't install
import html
from bs4 import BeautifulSoup 
import argparse

SERVER = "https://llm-api.amd.com/azure"
HEADERS = {"Ocp-Apim-Subscription-Key": "YOUR_KEY"}


def api_call(endpoint_name: str, body: dict, deployment_id: str):
    response = requests.post(url=f"{SERVER}/engines/{deployment_id}/{endpoint_name}", 
                             json=body,
                             headers=HEADERS)
    response.raise_for_status()
    return response.json()

def read_xlsx(xlsx,sheet,cols):
    # Load spreadsheet  
    xl = pd.ExcelFile(xlsx)  
      
    # Load a sheet into a DataFrame by name  
    ### read basic knowledge
    illustration = ""
    if re.search("explaination",cols):
        illustration = "below is AMD basic PD knowledge table:"
        df1 = xl.parse(sheet)  
    elif re.search("instruction",cols):
        illustration = "below is AMD instructions table:"
        df1 = xl.parse(sheet)
    elif re.search("question",cols):
        illustration = "below is AMD optimization recipe table:"
        df1 = xl.parse(sheet)
    xl.close()
      
    # Access columns  
    knowledge = illustration
    knowledge = knowledge + "\n" + cols
    for index, row in df1.iterrows(): 
        n = 0
        skip = 0
        for col in cols.split(","):
            if row[col] == "known":
                skip = 1
        if skip == 1 :
            continue
        dataset = ""
        for col in cols.split(","):
            if n == 0:
                #print(row[col])
                dataset = str(row[col]) + " : "
                n = n + 1
                continue
                #print(dataset)
            dataset = dataset + " , "+ str(row[col])
            
        knowledge = knowledge + "\n" + dataset
            
    return knowledge

def read_csv(mailFile,tasksModelFile,vtoInfo):
    print("###### Read mail csv and filter greeting....")
    tasksMail = []
    tasks = []
    vtoList = {}
    with open(mailFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
            params_h = {}
            controls_h = {}
            version_h = {}
            p4_h = {}
            for i in reader:
                readMail = 0
                mailBodyProcess = i["mailBody"]
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
                        #print(sentence)
                        for vto in sentence.split():
                            vto = re.sub(',','',vto)
                            vto = vto.lower()
                            if vto in vtoInfo['gpt'].split(":"):
                                #print(i["mailBody"])
                                readMail = 1
                        break
                if readMail == 1:
                    tasksMail.append(i)
    tasksModel = []
        # read saved tasks
    if os.path.exists(tasksModelFile):
        with open(tasksModelFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for task in reader:
                tasksModel.append(task)
            f.close()
    # merge saved tasks with new tasks from communictionInterface
    for task in tasksMail:
        find = 0
        for j in tasksModel:
            if task['time'] == j['time']:
                find = 1
                break

        if find == 0:
            tasksModel.append(task)
                
    knowledge = ""
    print("###### Read context...")
    print("### Read assignemnt")
    print("#",vtoInfo['vto'],vtoInfo['tile'])
    knowledge = vtoInfo['gpt'] + " is your name, you can instruct " + vtoInfo['vto'] + " to execute amd instrucitons." + "\n" + knowledge
    knowledge = vtoInfo['vto'] + " owns " + vtoInfo['tile'] + ", is also responsible for any amd instruction execution." + "\n" + knowledge
    
    knowledge = vtoInfo['fct'] + " is responsible for sdc/timing constraint/false path issue." + "\n" + knowledge
    
    knowledge = vtoInfo['flowLead'] + " is responsible for EDA error/crash/long run time issue." + "\n" + knowledge
    
    knowledge = vtoInfo['librarian'] + " is responsible for EDA library such as NDM/lib/lef/oasis issue." + "\n" + knowledge
    
    knowledge = vtoInfo['manager'] + " is responsible for jira reporting." + "\n" + knowledge
    
    print("### Read basic PD knowledge")
    cols = "concept,explaination"
    sheet = "basic"
    #cols = "description,proc defination"
    knowledge = knowledge + "\n" + read_xlsx("education.xlsx",sheet,cols)
    
    print("### Read AMD instructions")
    sheet = "instruction"
    cols = "description,amd standard instruction"
    #cols = "description,proc defination"
    knowledge = knowledge + "\n" + read_xlsx("education.xlsx",sheet,cols)
    
    print("### Read optimization strategy")
    sheet = "optimizer"
    cols = "question,answer,amd params,amd command,tune,TBG,overwrite cmd,TBM,rerun"
    knowledge = knowledge + "\n" + read_xlsx("education.xlsx",sheet,cols)
    ##
    # read remote csv, need pass word
    """
    "tile_status/summ_report/all_hold_I2.csv tile_status/summ_report/all_hold_pt.csv \
    tile_status/summ_report/all_setup_I2.csv tile_status/summ_report/all_setup_detail_I2.csv \
    tile_status/summ_report/all_setup_pt.csv tile_status/summ_report/area.csv \
    tile_status/summ_report/cbdrc.csv tile_status/summ_report/config.csv \
    tile_status/summ_report/congestion_drc_util.csv tile_status/summ_report/cts_info.csv \
    tile_status/summ_report/drv.csv tile_status/summ_report/fm.csv \
    tile_status/summ_report/power.csv tile_status/summ_report/runsta.csv \
    tile_status/summ_report/runtime.csv tile_status/summ_report/sum.csv \
    tile_status/summ_report/tool.csv tile_status/nickname_dir.list"
    """
    csv_list = "tile_status/summ_report/all_hold_pt.csv tile_status/summ_report/all_setup_I2.csv \
    tile_status/summ_report/all_setup_pt.csv tile_status/summ_report/area.csv \
    tile_status/summ_report/cbdrc.csv tile_status/summ_report/power.csv \
    tile_status/summ_report/congestion_drc_util.csv tile_status/summ_report/cts_info.csv \
    tile_status/summ_report/runtime.csv tile_status/summ_report/tool.csv \
    tile_status/summ_report/sum.csv tile_status/nickname_dir.list"
    status_list = ""
    nowledge = knowledge + "\n" + "Below are the tile status:"
    if 'runDir' in vtoInfo:
        for rd in vtoInfo['runDir'].split(":"):
            if re.search('\S',rd):    
                pass
            else:
                continue
            print("# Agent run dir:",rd)
            csv_list = "tile_status/run_status.csv"
            for rc in csv_list.split():
                if re.search('\S',rc):
                    pass
                else:
                    continue
                remote_csv = "https://logviewer-atl.amd.com" + rd + "/" + rc
                status_list = "https://logviewer-atl.amd.com" + rd + "/" + rc + "\n" + status_list
                request_csv = requests.get(remote_csv,auth=("YOUR_UID","YOUR_PASSWORD")).text
                soup = BeautifulSoup(request_csv, 'html.parser')  
                pre_tag = soup.find('pre')  
                csv_only = pre_tag.string  

                knowledge = knowledge + "\n" + "Current date is " + str(datetime.datetime.now())
                knowledge = knowledge + "\n" + "Below is " + rc + ":"
                knowledge = knowledge + "\n" + csv_only
    
    with open("knowledge.txt",'w',encoding='utf-8') as kn:
        kn.write(knowledge)
        
    #print(knowledge)
    ### Start process unreplied mail
    print("###### Process unreplied mail...")
    for task in tasksModel:
        # Skip process jira, handle it in monitor
        if task['sender'] == "Ontrackinternal.Imap@amd.com":
            continue
        if task["instruction"] is not None and task["reply"] is not None:
            if len(task["instruction"]) != 0 or len(task["reply"]) != 0:
                # keep old tasks that has been processed!!!
                tasks.append(task)
                continue
        #### Process request ####
        print("###### Start query GPT...")
        
        senderName = task["sender"].split(".")[0]
        senderName = re.sub('[0-9]+','',senderName)
        
        greeting = "Hi " + senderName + ","
        greeting = text_to_html(greeting)
        # GPT can generate greeting itself.
        #greeting = ""
        # knowledge + status
        answer = gpt_answer(knowledge,task["mailBody"])
        answer = text_to_html(answer)
        table_arr = []
        quote = ""
        mc = open("mailConfig.txt")
        myAccount = "PD agent"
        for line in mc:
            a_split = line.split()
            if re.search(r"myAccount",a_split[0]):
                myAccount = a_split[1]
            if re.search(r"vto",a_split[0]):
                name = ' '.join(a_split[1:])
                name = name.lower()
                vtoList[name] = 1
                print(name)
        
        for line in task["mailBody"].split("\n"):
            if re.search("|",line) and len(line.split("|")) > 1 :
                table_arr.append(line.split("|"))
            else:
                quote = quote + "\n" + line

        table = generate_table(table_arr)
        quote = text_to_html(quote)
        
        data = [['A', 'B', 'C'], ['1', '2', '3'], ['X', 'Y', 'Z']]
        #content = content + "\n" + generate_table(data)
        quote_head = "Tag: " + task["tag"] + "\n" + "From: " + task["sender"] + "\n" + "Sent:" + task["time"] + "\n" \
                    + "To: Chen, Simon (SRDC PD) <Simon1.Chen@amd.com>" + "\n" + "Subject: Re:" + task["subject"] + "\n"
        quote_head = text_to_html(quote_head)

        signature = "\n" + "Thanks," + "\n" + "GPT0(PD Agent)" + "\n"
        signature = text_to_html(signature)
        # GPT can signature greeting itself.
        #signature = ""
        greeting = ""
        signature = ""
        if len(table_arr) == 0 :
            table = ""
        content = greeting + "\n" + answer + "\n" + table + "\n" + signature + "\n" + "\n" + "<hr>" + "\n" + quote_head + "\n" + quote 
        #print(content)
        send_mail(task["sender"],task["subject"],content)
        
        # split mail if content contain mail sent to different agent.
        # need transfer the table.
        mail_list = []
        mail_list = split_mail(answer)
        print(mail_list)
        for mail in mail_list:
            res = re.search("Hi\s+(\S+),",mail)
            if res:
                if res.group(1) in vtoList:
                    pass
                # only sent to agent
                    #send_mail(myAccount,task["subject"],mail)

        task["instruction"] = "reply"
        tasks.append(task)
                    
    with open(tasksModelFile, mode="w", encoding="utf-8-sig", newline="") as f:
        header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
        writer = csv.DictWriter(f,header_list)
        writer.writeheader() 
        sorted(tasks,key=lambda x: x['time'])
        writer.writerows(tasks)
        f.close()
    return mailBodyProcess


def send_mail(address,subject,content):
    outlook = win32.Dispatch('Outlook.Application')
    mail_item = outlook.CreateItem(0) # 0: creat mail
    mail_item.Recipients.Add(address)
    mail_item.Subject = subject
    mail_item.BodyFormat = 2          # 2: Html format
    mail_item.HTMLBody = content
    #mail_item.Attachments.Add('pip.txt')   
    mail_item.Send()

def split_mail(content):
    mail_list = []
    mail = ""
    for line in content.split("\n"):
        if line == "\n":
            continue
        if re.search("(Hi\s+\S+,|Dear\s+\S+,)",line):
            line = re.sub(".*Hi","Hi",line)
            line = re.sub(".*Dear","Hi",line)
            mail_list.append(mail)
            mail = ""
            mail = mail + line
        else:
            mail = mail + line
    mail_list.append(mail)
    return mail_list
    
def gpt_answer(knowledge,question0):
    question = knowledge + "\n" + question0
    body = {
        "messages": [
            # Must provide a conversation in the following format. The first message with "system" role is optional.
            {"role": "system", "content": "You are instruction interpreter."},
            {"role": "assistant", "content": knowledge},
            {"role": "user", "content": question0}
        ],
        "temperature": 0,
        "n": 2,
        "stream": False,
        "stop": None,
        "max_Tokens": 1000,
        "presence_Penalty": 0,
        "frequency_Penalty": 0,
        "logit_Bias": None,
        "user": None
    }
    # deployment_id="swe-gpt35-turbo-exp1"
    chat_completion_result = api_call(endpoint_name="chat/completions",
                                      body=body,
                                      deployment_id="swe-gpt4-32k-exp1") 
    
    print("# Question:",question0)
    print("----------------------------------------------------------------------------------------------------\n")
    print("# Answer:",chat_completion_result['choices'][0]['message']['content'])
    #print(f"Chat Completion\n{chat_completion_result[choices]}")
    print("\n--------------\n")
    return chat_completion_result['choices'][0]['message']['content']

def read_assignment(asm):
    vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'','gpt':'','debugger':'',\
               'manager':'','flowLead':'','fct':'','librarian':'','runDir':''}
    with open(asm,encoding='utf-8-sig') as asm:
        reader = csv.reader(asm)    
        for i in reader:
            if re.search(r"tile",i[0]):
                #print(i[0],i[1])
                if re.search("\S",vtoInfo['tile']):
                    vtoInfo['tile'] = vtoInfo['tile'] + "/" + i[1]
                else:
                    vtoInfo['tile'] = i[1]
                
            if re.search(r"disk",i[0]):
                vtoInfo['disk'] = vtoInfo['disk'] + ":" + i[1]
                #print(i[0],i[1])
                
            if re.search(r"project",i[0]):
                vtoInfo['project'] = i[1]
                #print(i[0],i[1])
                
            if re.search(r"vto",i[0]):
                vtoInfo['vto'] = i[1]
                
            if re.search(r"librarian",i[0]):
                vtoInfo['librarian'] = i[1]
            
            if re.search(r"flowLead",i[0]):
                vtoInfo['flowLead'] = i[1]
            
            if re.search(r"flowLead",i[0]):
                vtoInfo['flowLead'] = i[1]
            
            if re.search(r"fct",i[0]):
                vtoInfo['fct'] = i[1]
            
            if re.search(r"gpt",i[0]):
                vtoInfo['gpt'] = i[1]
            
            if re.search(r"debugger",i[0]):
                if len(vtoInfo['debugger']) > 0:
                    vtoInfo['debugger'] = vtoInfo['debugger'] + "," + i[1]
                else:
                    vtoInfo['debugger'] = i[1]
                
            if re.search(r"manager",i[0]):
                vtoInfo['manager'] = i[1]
                
            if re.search(r"runDir",i[0]):
                if len(vtoInfo['runDir'].split(":")) > 0:
                    vtoInfo['runDir'] = vtoInfo['runDir'] + ":" + i[1]
                else:
                    vtoInfo['runDir'] = i[1]
    return vtoInfo

def text_to_html(text):  
    # Convert special characters to HTML safe sequences  
    safe_text = html.escape(text)  
    html_text = ""
    for line in safe_text.split("\n"):
        html_text = f"{html_text}\n{line}<br>" 
    # Wrap the text in HTML tags  
    #html_text = f"<html>\n<body>\n{html_text}<hr>\n</body>\n</html>"  
  
    return html_text  

def generate_table(data):
    df = pd.DataFrame(data)
    html_table = df.to_html(index=False, header=False)
    return html_table
 

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='add assignment.csv')
    parser.add_argument('--asm',type=str, default = "None",required=True,help="add assignment.csv")
    args = parser.parse_args()
    vtoInfo = {}
    vtoInfo = read_assignment(args.asm)
    mailBodyProcess = read_csv("tasksMail.csv","tasksModel.csv",vtoInfo)

    #print(knowledge)
    
