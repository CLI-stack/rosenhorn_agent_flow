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
parser.add_argument('--sdc',type=str, default = "None",required=True,help="sdc")
parser.add_argument('--clk',type=str, default = "None",required=True,help="clk")
parser.add_argument('--frq',type=str, default = "None",required=True,help="frequency")
args = parser.parse_args()
#print(args.tag)
                
if re.search("G",args.frq) or re.search("g",args.frq):
    digit = re.sub("G","",args.frq)
    digit = re.sub("g","",digit)
    print(digit)
    period = round(1.0/float(digit)*1000,1)
elif re.search("M",args.frq) or re.search("m",args.frq):
    digit = re.sub("M","",args.frq)
    digit = re.sub("m","",digit)
    period = round(1.0/float(digit)*1000*1000,1)
else:
    digit = re.sub("[a-z]","",args.frq)
    digit = re.sub("[A-Z]","",digit)
    period = round(1.0/float(digit)*1000,1)

# create_clock -name FCLK -period 437 -waveform { 0 218.5 } [get_ports {Cpl_FCLK}]
isGz = 0
if re.search("\.gz",args.sdc):
    isGz = 1
if os.path.exists(args.sdc) and isGz == 1:
    line_list = []
    with gzip.open(args.sdc,'rt') as f:
        print("Check sdc...")
        for line in f:
            #create_clock -name CHIP_BS10_TCLK -period 100000 -waveform { 0 50000 }
            #line = str(line,encoding='utf-8')
            #line = str(line)
            res = re.search(r"create_clock\s+\-name\s+(\S+)\s+\-period\s+(\S+)\s+\-waveform\s+{\s+0\s+(\S+)\s+}\s+\[get_ports\s+{(\S+)}\]",line)
            if res:
                if res.group(1) == args.clk:
                    print(res.group(1),res.group(2),res.group(3),res.group(4))
                    line_new = "create_clock -name " + args.clk + " -period " + str(period) + " -waveform { 0 " + str(period/2) + " } [get_ports {" + res.group(4) + "}]"
                    print(line_new)
                    line_list.append(line_new)
                    continue
            line_list.append(line)
            
    with gzip.open("hack.sdc.gz",'wb') as o:
        for line in line_list:
            if re.search("\n",line):
                o.write(line.encode('utf-8'))
            else:
                line = line + "\n"
                o.write(line.encode('utf-8'))
    
                
if os.path.exists(args.sdc) and isGz == 0: 
    line_list = []
    with open(args.sdc,'r') as f:
        for line in f:
            #create_clock -name CHIP_BS10_TCLK -period 100000 -waveform { 0 50000 }
            #line = str(line,encoding='utf-8')
            #line = str(line)
            #line = line.lower()
            res = re.search(r"create_clock\s+\-name\s+(\S+)\s+\-period\s+(\S+)\s+\-waveform\s+{\s*0\s+(\S+)\s*}\s+\[get_ports\s+{(\S+)}\]",line)
            if res:
                if res.group(1) == args.clk:
                    print(res.group(1),res.group(2),res.group(3),res.group(4))
                    line_new = "create_clock -name " + args.clk + " -period " + str(period) + " -waveform { 0 " + str(period/2) + " } [get_ports {" + res.group(4) + "}]"
                    print(line_new)
                    line_list.append(line_new)
                    continue
            res = re.search(r"create_clock\s+\-name\s+(\S+)\s+\-period\s+(\S+)\s+\-waveform\s+{\s*0\s+(\S+)\s*}\s+\-add\s+\[get_ports\s+{(\S+)}\]",line)
            if res:
                if res.group(1) == args.clk:
                    print(res.group(1),res.group(2),res.group(3),res.group(4))
                    line_new = "create_clock -name " + args.clk + " -period " + str(period) + " -waveform { 0 " + str(period/2) + " } -add [get_ports {" + res.group(4) + "}]"
                    print(line_new)
                    line_list.append(line_new)
                    continue

            line_list.append(line)
            
    with open("hack.sdc",'w') as o:
        for line in line_list:
            if re.search("\n",line):
                o.write(line)
            else:
                line = line + "\n"
                o.write(line)
                
