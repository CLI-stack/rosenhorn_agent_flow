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

def merge_task(mailFile,tasksLLMFile):
    print("# merge Task...")
    tasksMail = []
    tasks = []
    # read tasks from communicationInterface
    with open(mailFile,encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        # here reader cannot be assign to taskMail directly, otherwise report IO error
        for i in reader:
            tasksMail.append(i)
            
    tasksModel = []
    # read saved tasks
    today = datetime.today()
    print("Today's date:", today)

    if os.path.exists(tasksLLMFile):
        with open(tasksLLMFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for task in reader:
                date_task = task['time'].split()[0].split("-")
                datetime_task = datetime(int(date_task[0]), int(date_task[1]), int(date_task[2])) 
                delta = today - datetime_task
                if delta.days > 2:
                    print("date_task",datetime_task,delta.days)
                else:
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

    with open(tasksLLMFile, mode="w", encoding="utf-8-sig", newline="") as f:
        header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
        writer = csv.DictWriter(f,header_list)
        writer.writeheader()
        sorted(tasksModel, key=lambda x: x['time'])
        writer.writerows(tasksModel)
        f.close()
 

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--mailFile',type=str, default = "tasksMail.csv",required=True,help="mailFile")
    parser.add_argument('--tasksLLMFile',type=str, default = "tasksMail_llm.csv",required=True,help="tasksLLMFile")
    args = parser.parse_args()
    merge_task(args.mailFile,args.tasksLLMFile)
