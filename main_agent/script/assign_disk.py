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
parser.add_argument('--csv',type=str, default = "None",required=True,help="the assignment.csv")
parser.add_argument('--tile',type=str, default = "None",required=False,help="the tile name")
parser.add_argument('--ip',type=str, default = "None",required=False,help="ip name")
args = parser.parse_args()
disk_l = []
tile_flag = 1
ip_flag = 1
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
with open(args.csv,encoding='utf-8-sig') as f:
    reader = csv.reader(f)
    # here reader cannot be assign to taskMail directly, otherwise report IO error
    for i in reader:
        #print(i,tile_flag)
        if tile_flag == 1 and re.search("^disk",i[0]):
            disk_l = []
            tile_flag = 0
            disk_l.append(i[1])
            continue
        
        if ip_flag == 1 and re.search("^disk",i[0]):
            disk_l = []
            ip_flag = 0
            disk_l.append(i[1])
            continue

        if re.search("^disk",i[0]):
            disk_l.append(i[1])

        if re.search("^tile",i[0]):
            tile_flag = 1
        if re.search("^ip",i[0]):
            ip_flag = 1

        if re.search("^tile",i[0]) and len(disk_l) > 0 and re.search(args.tile,i[1]):
            print(" ".join(disk_l))
    
        if re.search("^ip",i[0]) and len(disk_l) > 0 and re.search(args.ip,i[1]):
            print(" ".join(disk_l))

            
    f.close

