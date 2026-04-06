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
parser.add_argument('--item',type=str, default = "None",required=True,help="item")
parser.add_argument('--argument',type=str, default = "None",required=True,help="argument table")
parser.add_argument('--tag',type=str, default = "None",required=True,help="arguement tag")
args = parser.parse_args()

table_l = []

table_l.append(args.item.split(","))
with open(args.argument,encoding='utf-8-sig') as lt:
    reader = csv.reader(lt)
    for i in reader:
        table_l.append(i)

lt.close()

with open(args.argument,mode="w",encoding='utf-8-sig',newline="") as f:
    writer = csv.writer(f)
    writer.writerows(table_l)

f.close()
tb.close()
