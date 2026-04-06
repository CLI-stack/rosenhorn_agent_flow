# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com

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
parser.add_argument('--log',type=str, default = "None",required=True,help="the csv file")
parser.add_argument('--hGrid',type=str, default = "None",required=False,help="the csv file")
parser.add_argument('--hOffset',type=str, default = "None",required=False,help="the csv file")
parser.add_argument('--vGrid',type=str, default = "None",required=False,help="the csv file")
parser.add_argument('--vOffset',type=str, default = "None",required=False,help="the csv file")

args = parser.parse_args()
# time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
macro_llx_l = []
macro_lly_l = []
macro_urx_l = []
macro_ury_l = []
macro_llx = 0 
macro_lly = 0
macro_urx = 0
macro_ury = 0

die_llx = 0
die_lly = 0
die_urx = 0
die_ury = 0
margin = 10.0
# add unresolve macros
error_flag = 0
with open(args.log,'r') as f:
    for line in f:
        res = re.search(r"\s+(\S+)\s+\{(\S+)\s+(\S+)\}\s+\{(\S+)\s+(\S+)\}\s+macro\s+out\s+of\s+boundary\s+\{(\S+)\s+(\S+)\}\s+\{(\S+)\s+(\S+)\}",line)
        #ERROR: tile_dfx/ros_0/genblk2_perfro_macro {-82.7405 -57.5165} {-67.0560 -28.3185} macro out of boundary. {-67.0560 -64.6490} {67.0560 64.6490}
        print(line)
        if res:
            error_flag = 1
            if float(res.group(2)) < macro_llx:
                macro_llx = float(res.group(2))
            if float(res.group(3)) < macro_lly:
                macro_lly = float(res.group(3))
            if float(res.group(4)) > macro_urx:
                macro_urx = float(res.group(4))
            if float(res.group(5)) > macro_ury:
                macro_ury = float(res.group(5))

            die_llx = float(res.group(6))
            die_lly = float(res.group(7))
            die_urx = float(res.group(8))
            die_ury = float(res.group(9))

            print("macro:",macro_llx,macro_lly,macro_urx,macro_ury)
            print("die:",die_llx,die_lly,die_urx,die_ury)
    f.close
if macro_llx < die_llx:
    die_llx = macro_llx - margin
if macro_lly < die_lly:
    die_lly = macro_lly - margin
if macro_urx > die_urx:
    die_urx = macro_urx + margin
if macro_ury > die_ury:
    die_ury = macro_ury + margin
print("Grid",args.hGrid,args.hOffset,args.vGrid,args.vOffset)
die_width = round((die_urx - die_llx) / float(args.hGrid)) * float(args.hGrid) + float(args.hOffset)
die_height = round((die_ury - die_lly) / float(args.vGrid)) * float(args.vGrid) + float(args.vOffset)
if error_flag == 1 :
    print("Grid",args.hGrid,args.hOffset,args.vGrid,args.vOffset,round((die_ury - die_lly) / float(args.vGrid)) * float(args.vGrid)+float(args.vOffset))
    print("new die size",round(die_width,4),round(die_height,4))
