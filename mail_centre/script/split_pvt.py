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
parser.add_argument('--table',type=str, default = "None",required=True,help="pvt table")
args = parser.parse_args()
#print(args.tag)
clk_hack = {}
with open(args.table,'r') as f:
    n_line = 0
    for line in f:
        n_sect = 0
        for sect in line.split('|'):
            for word in sect.split():
                if n_line == 0 and re.search('CLK',word):
                    clk_hack[n_sect] = word
                fpvt= re.search("(\S+)@(\S+)",word.lower())
                if fpvt:
                    freq = fpvt.group(1)
                    pvt = fpvt.group(2)
                    print(clk_hack[n_sect],freq,pvt)
                    with open("run__" + str(n_line) + "__" + clk_hack[n_sect] + "__" + pvt+".csh",'w') as csh:
                        csh.write("source csh/hack_sdc.csh "+ pvt + " " + clk_hack[n_sect] + " " + freq + "\n")
            n_sect = n_sect + 1
        n_line = n_line + 1


                        
