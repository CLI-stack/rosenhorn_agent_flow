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
parser.add_argument('--argument',type=str, default = "None",required=True,help="argument table")
parser.add_argument('--tag',type=str, default = "None",required=True,help="arguement tag")
args = parser.parse_args()
tb = open(args.table,'r')

n_line = 0
table_l = []
for line in tb:
    n_sect = 0
    # extract params
    row_l = []
    valid = 1
    for sect in line.split('|'):
        if sect == "nan":
            valid = 0
        if len(sect) == 0 or re.search("\n",sect):
            continue
        row_l.append(sect)
        print("sect",sect)
        # check if params section
    if valid == 1:
        table_l.append(row_l)

with open(args.argument,encoding='utf-8-sig') as lt:
    reader = csv.reader(lt)
    for i in reader:
        pass
        #table_l.append(i)

lt.close()

with open(args.argument,mode="w",encoding='utf-8-sig',newline="") as f:
    writer = csv.writer(f)
    writer.writerows(table_l)

f.close()
tb.close()
