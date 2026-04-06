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
parser.add_argument('--rpt',type=str, default = "None",required=True,help="aoi")
args = parser.parse_args()
#print(args.tag)
if re.search("\.gz",args.rpt):
    isGz = 1
if os.path.exists(args.rpt) and isGz == 1:
    print(args.rpt)
    parsing = 0
    tot_area = 0
    aoi_area = 0
    aoi = 0
    with gzip.open(args.rpt,'rt') as f:
        print("Check rpt...")
        for line in f:
            res = re.search(r"Name\s+Type\s+Count\s+Width\s+Height\s+Area\s+PinDens\s+SiteName\s+siteArea",line)
            if res:
                parsing = 1
            lc = re.search(r"lib_cell\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)",line)
            if lc and parsing == 1:
                count = lc.group(1)
                area = lc.group(4)
                if aoi == 1:
                    aoi_area = aoi_area + float(count) + float(area)
                tot_area = tot_area + float(count) + float(area)
                aoi = 0
                #print(lc.group(1),lc.group(4)) 
            if re.search(r"OA|AOI|NR4|ND4|AN4ADD",line) and parsing == 1:
                aoi = 1
                #print(line)

    print("# aoi ratio:",tot_area,aoi_area,aoi_area/tot_area*1.1) 
