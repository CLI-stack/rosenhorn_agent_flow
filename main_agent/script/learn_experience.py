"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
""" 
import argparse
import csv
import os
import time
import re

parser = argparse.ArgumentParser(description='Parse params')
parser.add_argument('--table',type=str, default = "None",required=True,help="params table")
parser.add_argument('--arguement',type=str, default = "None",required=True,help="arguement table")
parser.add_argument('--tag',type=str, default = "None",required=True,help="arguement tag")
args = parser.parse_args()
tb = open(args.table)
arguement = {}
exp = {}
experience = []
with open(args.arguement,encoding='utf-8-sig') as lt:
    reader = csv.reader(lt)
    for i in reader:
        arguement[i[0].lower()]=i[1]

for line in tb:
    box  = line.split('|')
    if len(box) != 8:
        f = open(args.tag + ".fail",'w')
        f.close()
        break
    se = re.search('\btag\b',box[0])
    if se:
        print("This is table head")
        continue
    # first is empty, end is return
    exp["tag"] = args.tag
    exp["question/issue"] = box[2]
    exp["answer/root cause"] = box[3]
    exp["instruction"] = box[4]
    exp["path"] = box[5]
    exp["author"] = box[6]
    experience.append(exp)

    

with open('experience.csv',encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        experience.append(i)
    f.close

with open('experience.csv', mode="w", encoding="utf-8-sig", newline="") as f:
    header_list = ["tag","question/issue","answer/root cause", "instruction","path","author"]
    writer = csv.DictWriter(f,header_list)
    writer.writeheader()
    sorted(experience, key=lambda x: x['tag'])
    writer.writerows(experience)
    f.close()

