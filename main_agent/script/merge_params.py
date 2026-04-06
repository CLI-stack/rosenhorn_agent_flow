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
import csv
import os
import time
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--origParams',type=str, default = "None",required=True,help="orig params")
parser.add_argument('--newParams',type=str, default = "None",required=True,help="new params")
parser.add_argument('--outParams',type=str, default = "None",required=True,help="out params")
parser.add_argument('--op',type=str, default = "None",required=True,help="op")
args = parser.parse_args()
#print(args.tag)

new_h = {}
newParams = open(args.newParams,'r')
printParams_l = []
printParams_n = 0
printFlag = 0
printFlag1 = 0
multi_line_flag = 0
multi_line = ""
# read new params
for line in newParams:
    # read split line with \ at the end
    if re.search('\\\\$',line):
        line = re.sub("\\\\","",line)
        line = re.sub("\n","",line)
        multi_line = multi_line + line
        multi_line_flag = 1
        #print("multi_line",multi_line)
        continue

    if multi_line_flag == 1:
        multi_line = multi_line + line
        multi_line_flag = 0
        p = multi_line.split('=')
        p[0] = re.sub(' ','',p[0])
        if len(p) > 1:
            print(p)
            new_h[p[0]] = multi_line
        multi_line = ""
        continue

    # start read print params
    if re.search('^<:',line) and re.search(':>',line):
        #print(line)
        printParams = []
        printParams.append(line)
        printParams_l.append(printParams)
        continue

    if re.search('^<:',line):
        #print(line)
        printParams = []
        printParams.append(line)
        printFlag = 1
        continue

    if printFlag == 1 and re.search('^:>',line):
        printFlag = 0
        printParams.append(line)
        printParams_l.append(printParams)
        #print(len(printParams_l),printParams_l)
        continue

    if re.search('<:',line) and  not re.search(':>',line):
        #print(line)
        printParams = []
        printParams.append(line)
        printFlag1 = 1
        continue

    if printFlag1 == 1 and re.search(':>',line):
        printFlag1 = 0
        printParams.append(line)
        printParams_l.append(printParams)
        #print(len(printParams_l),printParams_l)
        continue

    if printFlag1 == 1:
        printParams.append(line)
        continue
 
    if printFlag == 1:
        printParams.append(line)
        continue

    
    p = line.split('=')
    p[0] = re.sub(' ','',p[0])
    if len(p) > 1:
        print(p)
        new_h[p[0]] = line

newParams.close()

orig_h = {}
outParams = open(args.outParams,'w')
origParams = open(args.origParams,'r')
# read original params and write out the params which not in new params
# printParams is temp params line
# printParams_l is all the params section b/w <: :>
for line in origParams:
    if re.search('\\\\$',line):
        line = re.sub("\\\\","",line)
        line = re.sub("\n","",line)
        multi_line = multi_line + line
        multi_line_flag = 1
        #print("# multi line",multi_line)
        continue

    if multi_line_flag == 1:
        multi_line = multi_line + line
        multi_line_flag = 0
        p = multi_line.split('=')
        p[0] = re.sub(' ','',p[0])
        if p[0] in new_h:
            print("# skip",p[0])
            multi_line = ""
            continue
        else:
            outParams.write(multi_line)
            print("# multi line",multi_line)
            multi_line = ""

    # start read print params
    if re.search('^<:',line) and re.search(':>',line):
        #print(line)
        printParams = []
        printParams.append(line)
        printParams_l.append(printParams)
        continue

    if re.search('^<:',line):
        printParams = []
        printParams.append(line)
        printFlag = 1
        continue

    if printFlag == 1 and re.search('^:>',line):
        printFlag = 0
        printParams.append(line)
        foundDuplicated = 0
        for pp in printParams_l:
            print(pp,printParams)
            if pp == printParams:
                print("# Found duplicated print params")
                foundDuplicated = 1
                break 
        if foundDuplicated == 0:
            print("add printParams")
            printParams_l.append(printParams)
        continue
    
    if re.search('<:',line) and  not re.search(':>',line):
        #print(line)
        printParams = []
        printParams.append(line)
        printFlag1 = 1
        continue

    if printFlag1 == 1 and re.search(':>',line):
        printFlag1 = 0
        printParams.append(line)
        printParams_l.append(printParams)
        #print(len(printParams_l),printParams_l)
        continue

    if printFlag1 == 1:
        printParams.append(line)
        continue

    if printFlag == 1:
        printParams.append(line)
        continue

    p = line.split('=')
    p[0] = re.sub(' ','',p[0])
    if p[0] in new_h:
        print("# skip",p[0])
        continue 
    else:
        outParams.write(line)
origParams.close()
#print(len(printParams_l),printParams_l)
# Merge the new params to orignal params
if args.op == 'merge':
    print("# merge params")
    for pn in new_h:
        print(new_h[pn])
        outParams.write(new_h[pn])
    for pp in printParams_l:
        for line in pp:
            outParams.write(line)

outParams.close()
