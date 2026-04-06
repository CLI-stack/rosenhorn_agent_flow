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

def read_csv(question,contextFile):
    knowledge = ""
    print("###### Read context...")
    print("### Read basic PD knowledge")
    cols = "concept,explaination"
    sheet = "basic"
    #cols = "description,proc defination"
    if os.path.exists('education.csv'): 
        knowledge = knowledge + "\n" + pd.read_csv('education.csv').to_string()
    elif os.path.exists('none.csv'):
        pass
    else:
        knowledge = knowledge + "\n" + pd.read_csv('/tools/aticad/1.0/src/zoo/PD_agent/tile/education.csv').to_string()

    
    knowledge = knowledge + "\n" + "Current date is " + str(datetime.datetime.now())
    context = ""
    if contextFile == 0:
        pass
    else:
        ctx = open(contextFile,'r')
        for line in ctx:
            knowledge = knowledge + "\n" + line
        ctx.close

    with open("knowledge.txt",'w',encoding='utf-8') as kn:
        kn.write(knowledge)
        
    answer = gpt_answer(knowledge,question)
        
    
def gpt_answer(knowledge,question0):
    question = knowledge + "\n" + question0
    body = {
        "messages": [
            # Must provide a conversation in the following format. The first message with "system" role is optional.
            {"role": "system", "content": "You are physical design engineer."},
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
                                      deployment_id="swe-gpt4o-exp1") 
    
    print("# Answer:",chat_completion_result['choices'][0]['message']['content'])
    #print(f"Chat Completion\n{chat_completion_result[choices]}")
    return chat_completion_result['choices'][0]['message']['content']


def generate_table(data):
    df = pd.DataFrame(data)
    html_table = df.to_html(index=False, header=False)
    return html_table
 

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='add key')
    parser.add_argument('--question',type=str, default = "None",required=True,help="add question")
    parser.add_argument('--key',type=str, default = "None",required=True,help="add api key")
    parser.add_argument('--contextFile',type=str, default = "None",required=False,help="add context")
    args = parser.parse_args()
    
    HEADERS = {"Ocp-Apim-Subscription-Key": args.key}
    if args.contextFile:
        mailBodyProcess = read_csv(args.question,args.contextFile)
    else:
        mailBodyProcess = read_csv(args.question,0)


    #print(knowledge)
    
