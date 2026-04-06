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
parser.add_argument('--i',type=str, default = "None",required=True,help="the csv file")
parser.add_argument('--o',type=str, default = "None",required=True,help="the csv file")
args = parser.parse_args()
# add unresolve macros
line_h = []
flag = 0
o = open(args.o,'w')
with open(args.i,'r') as f:
    for line in f:
        line = str(line)
        if re.search("#table#",line):
            line_h = []
            flag = 1
            line_h.append(line)
            continue

        if re.search("#table end#",line):
            print(line_h)
            if len(line_h) > 2 :
                for li in line_h:
                    o.write(li)
                o.write(line)
                flag = 0
            else:
                line_h = []
                flag = 0
                continue
        if flag == 1:
            line_h.append(line)
            print("# add table",line)
            print(len(line_h))
            continue


        o.write(line)        

    f.close
    o.close

