import requests
import pandas as pd
import datetime
import os
import re
import csv
# html needn't install
import argparse


def api_call(endpoint_name: str, body: dict, deployment_id: str):
    SERVER = "https://llm-api.amd.com/azure"
    response = requests.post(url=f"{SERVER}/engines/{deployment_id}/{endpoint_name}", 
                             json=body,
                             headers=HEADERS)
    response.raise_for_status()
    return response.json()

def read_csv(vtoInfo,contextFile,tag):
                
    knowledge = ""
    print("###### Read context...")
    print("### Read assignemnt")
    knowledge = vtoInfo['gpt'] + " is your name, you can instruct " + vtoInfo['vto'] + " to execute amd instrucitons." + "\n" + knowledge
    knowledge = vtoInfo['vto'] + " owns " + vtoInfo['tile'] + ", is also responsible for any amd instruction execution." + "\n" + knowledge
    
    knowledge = vtoInfo['fct'] + " is responsible for sdc/timing constraint/false path issue." + "\n" + knowledge
    
    knowledge = vtoInfo['flowLead'] + " is responsible for EDA error/crash/long run time issue." + "\n" + knowledge
    
    knowledge = vtoInfo['librarian'] + " is responsible for EDA library such as NDM/lib/lef/oasis issue." + "\n" + knowledge
    
    knowledge = vtoInfo['manager'] + " is responsible for jira reporting." + "\n" + knowledge
    
    print("### Read basic PD knowledge")
    sheet = "basic"
    #cols = "description,proc defination"
    if os.path.exists('education.csv'):
        edu = "education.csv"
    else:
        edu = "/tools/aticad/1.0/src/zoo/PD_agent/tile/education.csv"
    
    with open(edu,encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        for i in reader:
            knowledge = knowledge + "\n" + "|".join(i)
            
        f.close

    with open("/tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/optimizer.csv",encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        for i in reader:
            knowledge = knowledge + "\n" + "|".join(i)

        f.close

    knowledge = knowledge + "\n" + "# Below are the agent or vto instructions:"
    with open("/tool/aticad/1.0/src/zoo/PD_agent/tile/instruction.csv",encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        for i in reader:
            knowledge = knowledge + "\n" + i[0] 

        f.close


    knowledge = knowledge + "\n" + "Current date is " + str(datetime.datetime.now())
 
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
            run_status = "tile_status/run_status.csv"
            knowledge = knowledge + "\n" + "Current date is " + str(datetime.datetime.now())
            knowledge = knowledge + "\n" + "Below is run status:\n"
            with open(rd+"/"+run_status,encoding='utf-8-sig') as f:
                reader = csv.reader(f)
                # here reader cannot be assign to taskMail directly, otherwise report IO error
                for i in reader:
                    knowledge = knowledge + "|".join(i) + "\n"
                f.close

    with open(vtoInfo['runDir']+"/data/"+tag+"/knowledge.txt",'w',encoding='utf-8') as kn:
        kn.write(knowledge)
    ctx = open(contextFile,'r')
    for line in ctx:
        knowledge = knowledge + "\n" + line
    ctx.close
    question = ""
    answer = gpt_answer(knowledge,question)        


def gpt_answer(knowledge,question0):
    question = knowledge + "\n" + question0
    body = {
        "messages": [
            # Must provide a conversation in the following format. The first message with "system" role is optional.
            {"role": "system", "content": "You are instruction interpreter."},
            {"role": "assistant", "content": knowledge},
            {"role": "user", "content": question}
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
                                      deployment_id="swe-gpt4o-exp1") 
    
    print("----------------------------------------------------------------------------------------------------\n")
    print("# Answer:",chat_completion_result['choices'][0]['message']['content'])
    #print(f"Chat Completion\n{chat_completion_result[choices]}")
    print("\n--------------\n")
    return chat_completion_result['choices'][0]['message']['content']

def read_assignment(source_dir):
    vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'','gpt':'','debugger':'',\
               'manager':'','flowLead':'','fct':'','librarian':'','runDir':''}
    with open(source_dir+"/assignment.csv",encoding='utf-8-sig') as asm:
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
                
            vtoInfo['runDir'] = source_dir 

    return vtoInfo


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='add assignment.csv')
    parser.add_argument('--source_dir',type=str, default = "None",required=True,help="provide agent run dir")
    parser.add_argument('--tag',type=str, default = "None",required=True,help="provide agent run dir")
    parser.add_argument('--contextFile',type=str, default = "None",required=False,help="add context")
    parser.add_argument('--key',type=str, default = "None",required=True,help="llm key")
    args = parser.parse_args()
    vtoInfo = {}
    vtoInfo = read_assignment(args.source_dir)
    HEADERS = {"Ocp-Apim-Subscription-Key": args.key}
    answer = read_csv(vtoInfo,args.contextFile,args.tag)

    #print(knowledge)
    
