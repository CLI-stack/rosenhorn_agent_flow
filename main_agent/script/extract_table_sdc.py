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
import pandas as pd
parser = argparse.ArgumentParser(description='Parse params')
parser.add_argument('--table',type=str, default = "None",required=True,help="params table")
parser.add_argument('--tag',type=str, default = "None",required=True,help="arguement tag")
args = parser.parse_args()
tb = open(args.table,'r')
arguement = {}
clk_hack = {}
n_line = 0

# Read the text file
df = pd.read_csv(args.table, sep='|')
# Remove empty columns
df = df.dropna(axis=1, how='all')
print(df)
found_h = {}
for col in df.columns.tolist():
    if re.search("tile",col.lower()):
        found_h["tile"] = col
        print("|"+found_h["tile"]+"|")
    if re.search("clk",col.lower()):
        found_h["sdc"] = col

n_line = 1
for index,row in df.iterrows():
    if "tile"  in found_h:
        tile = "."+re.sub(" ","",str(row[found_h["tile"]]).lower())
        print("# Found tile")
    else:
        tile = ""

n_line = 0
for line in tb:
    n_sect = 0
    # extract hacked files
    # generate hack sdc script
    found_pvt = 0
    is_pvt = 0
    for sect in line.split('|'):
        for word in sect.split():
            if re.search("mailto:",word):
                continue
            if n_line == 0 and re.search('CLK',word):
                clk_hack[n_sect] = word
            fpvt= re.search("(\S+)@(\S+)",word.lower())
            if fpvt and len(clk_hack) > 0 :
                freq = fpvt.group(1)
                pvt = fpvt.group(2)
                print(clk_hack[n_sect],freq,pvt)
                with open("data/"+args.tag +"/hack_sdc_" + str(n_line) + "__" + clk_hack[n_sect] + "__" + pvt+".csh",'w') as csh:
                    csh.write("source $source_dir/script/hack_sdc_core.csh "+ pvt + " " + clk_hack[n_sect] + " " + freq + " " + args.tag + "\n")

                if found_pvt == 0 :
                    is_pvt = 1
                    found_pvt = 1

        n_sect = n_sect + 1

    n_line = n_line + 1 

        

tb.close()
