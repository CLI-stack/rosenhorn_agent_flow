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
import pandas as pd
from datetime import datetime
import re
import os
import csv
import numpy as np
import glob
# usage: python3 script/tasks_viewer.py --tasksMail /xxx/tasksMail.csv --tasksModel tasksModel.csv
def tasks_viewer(mailFile,modelFile):
    tasksMail = []
    tasks = []
            
    tasksModel = []
    # read saved tasks
    today = datetime.today()
    #print("Today's date:", today)

    if os.path.exists(modelFile):
        with open(modelFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for task in reader:
                date_task = task['time'].split()[0].split("-")
                datetime_task = datetime(int(date_task[0]), int(date_task[1]), int(date_task[2])) 
                delta = today - datetime_task
                if delta.days > 2:
                    pass
                    #print("date_task",datetime_task,delta.days)
                else:
                    tasksModel.append(task)
            f.close()
    with open(mailFile,encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        current_path = os.getcwd()
        print("#table#")
        print("tag,sender,subject,mailBody,instruction,status,tasks_log,TB_logs,reply")
        for i in reader:
            find = 0
            status = ""
            for j in tasksModel:
                if i['time'] == j['time']:
                    status = j['status']
                    find = 1
            if find == 1:
                pass
            else:
                continue
            if os.path.exists(current_path+ "/data/"+i['tag']+"/"+i['tag']+".log"):
                mailBody = current_path+ "/data/"+i['tag']+"/"+i['tag']+".log"
            else:
                mailBody = ""
            if os.path.exists(current_path+ "/runs/"+i['tag']+".csh"):
                instruction = current_path+ "/runs/"+i['tag']+".csh"
            else:
                instruction = ""
            if os.path.exists(current_path+ "/runs/"+i['tag']+".log"):
                main_log = current_path+ "/runs/"+i['tag']+".log"
            else:
                main_log = ""
            sub_logs_arr = glob.glob(os.path.join(current_path+"/data/"+i['tag']+"/*_"+i['tag']+"*.log")) 
            sub_logs = ";".join(sub_logs_arr) 
            if os.path.exists(current_path+ "/data/"+i['tag']+"_spec.html"):
                reply = current_path+ "/data/"+i['tag']+"_spec.html"
            else:
                reply = ""

            row = i['tag'] + "," + i['sender'] + "," + i['subject'] + "," + mailBody + "," + instruction + "," + status + "," + main_log + "," + sub_logs + "," + reply
            print(row) 
        print("#table end#")
            


 

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--tasksMail',type=str, default = "tasksMail.csv",required=True,help="tasksMail")
    parser.add_argument('--tasksModel',type=str, default = "tasksModel.csv",required=True,help="tasksModel")
    args = parser.parse_args()
    tasks_viewer(args.tasksMail,args.tasksModel)
