"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import csv
import os
import time
import re
import gzip
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--indef',type=str, default = "None",required=True,help="def")
args = parser.parse_args()
#print(args.tag)
if re.search("\.gz",args.indef):
    isGz = 1
x_l = []
y_l = []
if os.path.exists(args.indef) and isGz == 1:
    print(args.indef)
    with gzip.open(args.indef,'rt') as f:
        print("Check def...")
        for line in f:
            if re.search(r"DIEAREA\s+\(",line):
                print(line) 
                line = re.sub("DIEAREA","",line)
                line = re.sub("\)","",line)
                line = re.sub(";","",line)
                for coor in line.split("("):
                    res = re.search("(\S+)\s+(\S+)",coor)
                    if res:
                        x_l.append(res.group(1))
                        y_l.append(res.group(2))
                        
                print(x_l,y_l)
    llx = min(x_l)
    urx = max(x_l)
    lly = min(y_l)
    ury = max(y_l)
    print("# min max point",llx,urx,lly,ury,(float(urx) - float(llx))/(float(ury) - float(lly)))
