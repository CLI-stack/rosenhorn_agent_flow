"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
# This script is to add the original content as quotation
import argparse
import csv
import os
import time
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--argumentFile',type=str, default = "None",required=True,help="the argumentFile")
parser.add_argument('--item',type=str, default = "None",required=True,help="the task item")
args = parser.parse_args()
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
with open(args.argumentFile,encoding='utf-8-sig') as lt:
    reader = csv.reader(lt)
    for i in reader:
        if args.item.lower() == i[0].lower():
            print( i[0],",",i[1],",",i[2])

