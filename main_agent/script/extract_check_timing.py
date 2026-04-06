import pandas as pd
import argparse
import csv
import os
import time
import re
import gzip

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--rpt',type=str, default = "None",required=True,help="timing report")
parser.add_argument('--item',type=str, default = "None",required=True,help="path number")

args = parser.parse_args()
flag = 0
n_item = 0
if re.search(f'Func',args.rpt):
    orpt = args.item+'.func.log'
else:
    orpt = args.item+'.scan.log'
cn = open(orpt,'w')
with gzip.open(args.rpt,'rb') as f:
    for line in f.readlines():
        line = line.decode().strip('\n')

        if re.search(f'Information:\s+Checking\s+\'{args.item}\'',line):
            cn.write(line+'\n')
            flag = 1
            continue
    
        if flag == 1 and re.search(f'Information:',line):
            break
        
        if re.search(f'SPARE_lo',line) and flag == 1:
            continue

        if re.search(f'/',line) and flag == 1:
            n_item = n_item + 1    
    
        if flag == 1:
            cn.write(line+'\n')
if n_item > 0:
    current_path = os.getcwd()
    print(f'{n_item} {args.item} violation found, please check {current_path}/{orpt}')

cn.close()
f.close()
