"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import csv
import os
import time
import re
arguement = {}
word = "Setup"
word_lower = word.lower()
with open("tasksModel.csv",encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        senderName = i["sender"].split(".")[0]
        print(i["runDir"])
    f.close

