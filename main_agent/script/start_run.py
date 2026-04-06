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
parser.add_argument('--arguement',type=str, default = "None",required=True,help="arguement table")
parser.add_argument('--tag',type=str, default = "None",required=True,help="arguement tag")
args = parser.parse_args()
tb = open(args.table,'r')
arguement = {}
with open(args.arguement,encoding='utf-8-sig') as lt:
    reader = csv.reader(lt)
    for i in reader:
        arguement[i[0].lower()]=i[1]

i_p = 1
i_c = 1
i_f = 1
is_params = 0
clk_hack = {}
ar_h = {}
n_line = 0
description_h = {}

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
    if re.search("params",col.lower()):
        found_h["params"] = col
    if re.search("override",col.lower()):
        found_h["override"] = col
    if re.search("util",col.lower()):
        found_h["util"] = col
    if re.search("aspect",col.lower()):
        found_h["ar"] = col
    if re.search("clk",col.lower()):
        found_h["sdc"] = col
    if re.search("file",col.lower()):
        found_h["file"] = col
    if re.search("delta\s+width",col.lower()):
        found_h["delta width"] = col
    if re.search("delta\s+height",col.lower()):
        found_h["delta height"] = col

n_line = 1
for index,row in df.iterrows():
    description_h[n_line] = "table run"
    if "tile"  in found_h:
        tile = "."+re.sub(" ","",str(row[found_h["tile"]]).lower())
        print("# Found tile")
    else:
        tile = ""
    # implement params
    if "params" in found_h:
        sect = re.sub("^ ","",str(row[found_h["params"]]))
        sect = re.sub(" $","",sect)
        params = ""
        if len(sect) == 0:
            continue
        print("sect",sect)
        # check if params section
        is_params = 0
        is_controls = 0
        sect = re.sub('=',' = ',sect)
        for word in sect.split():
            if word.lower() in arguement and re.search("=",sect) and arguement[word.lower()] == 'params':
                print("create params",word)
                is_params = 1
                p = open("data/"+args.tag+".sub"+str(i_p)+tile+".params",'w')
                i_p = i_p + 1
                break
        for word in sect.split():
            if word.lower() in arguement and re.search("=",sect) and arguement[word.lower()] == 'controls':
                is_controls = 1
                c = open("data/"+args.tag+".sub"+str(i_c)+tile+".controls",'w')
                i_c = i_c + 1
                break

        if is_params == 1:
            words = sect.split("=")
            for i in range(len(words)):
                params = ""
                #print(words[i])
                if len(words) == 2:
                    params = sect
                    p.write(params+'\n')
                    if re.search("DESCRIPTION",params):
                        params_tmp = re.sub("DESCRIPTION","",params)
                        description_h[n_line] = re.sub("=","",params_tmp)
                        print("# Found description",params_tmp)

                    break
                if i == len(words)-1:
                    continue
                value = words[i].split()
                print(1,params,value)
                if len(value) == 0:
                    continue
                if len(value) > 1:
                    params = value[-1] + " = "
                else:
                    params = value[0] + " = "
                value = words[i+1].split()
                #print(2,params,value)
                if i == len(words)-2:
                    params = params + ' '.join(value)
                else:
                    params = params + ' '.join(value[:-1])
                print(params)
                if re.search("DESCRIPTION",params):
                    params_tmp = re.sub("DESCRIPTION","",params)
                    description_h[n_line] = re.sub("=","",params_tmp)
                    print("# Found description",params_tmp)
                if re.search("NICKNAME",params) or  re.search("TILES_TO_RUN",params):
                    continue
                p.write(params+'\n')
            p.close()
        if is_controls == 1:
            words = sect.split("=")
            for i in range(len(words)):
                params = ""
                #print(words[i])
                if len(words) == 2:
                    params = sect
                    c.write(params+'\n')
                    break
                if i == len(words)-1:
                    continue
                value = words[i].split()
                #print(1,params,value)
                if len(value) == 0:
                    continue
                if len(value) > 1:
                    params = value[-1] + " = "
                else:
                    params = value[0] + " = "
                value = words[i+1].split()
                #print(2,params,value)
                if i == len(words)-2:
                    params = params + ' '.join(value)
                else:
                    params = params + ' '.join(value[:-1])
                print(params)
                c.write(params+'\n')
            c.close()

    # implement multi override.params or overide.controls
    if "override" in found_h:
        for ov in str(row[found_h["override"]]).split():
            if re.search("params",ov):
                with open(ov, 'r') as file1:
                # Read the contents of file1
                    data = file1.read()

                # Open the second file in write mode
                with open("data/"+args.tag+".sub"+str(n_line)+tile+".params", 'a') as file2:
                # Write the data to file2
                    file2.write(data)

                pass
            if re.search("controls",ov):
                with open(ov, 'r') as file1:
                # Read the contents of file1
                    data = file1.read()

                # Open the second file in write mode
                with open("data/"+args.tag+".sub"+str(n_line)+tile+".controls", 'a') as file2:
                # Write the data to file2
                    file2.write(data)


    # implement util and aspect ratio shmoo 
    if "util" in found_h or "ar" in found_h:
        if "util" in found_h and "ar" in found_h:
            print(row[found_h["util"]],row[found_h["ar"]])
            arg = str(row[found_h["util"]]) + " " +  str(row[found_h["ar"]])
            description = description_h[n_line] +  ";utilization" + str(row[found_h["util"]]) + " / shmoo aspect ratio " + str(row[found_h["ar"]])
        elif "util" in found_h:
            print(row[found_h["util"]],"NA")
            arg = str(row[found_h["util"]]) + " " + "NA"
            description = description_h[n_line] + ";utilization" + str(row[found_h["util"]])
        elif "ar" in found_h:
            print("NA",row[found_h["ar"]])
            arg = "NA" + " " +  str(row[found_h["ar"]])
            description = description_h[n_line] + ";aspect ratio " + str(row[found_h["ar"]])

        with open("data/"+args.tag +"/run__" + str(n_line) + "__" + "util_ar" + ".csh",'w') as csh:
            csh.write("source $source_dir/script/gen_util_ar_tune.csh " + arg +  " " + args.tag + "\n")
        csh.close()
        p = open("data/"+args.tag+".sub"+str(n_line)+".params",'a')
        p.write("DESCRIPTION = " + description + "\n")
        p.close()

    # implement width and heigh grow
    if "delta width" in found_h or "delta height" in found_h:
        if "delta width" in found_h and "delta height" in found_h:
            print(row[found_h["delta width"]],row[found_h["delta height"]])
            arg = str(row[found_h["delta width"]]) + " " +  str(row[found_h["delta height"]])
            description = description_h[n_line] + ";delta width" + str(row[found_h["delta width"]]) + " / delta height " + str(row[found_h["delta height"]])
        elif "delta width" in found_h:
            print(row[found_h["delta width"]],"NA")
            arg = str(row[found_h["delta width"]]) + " " + "NA"
            description = description_h[n_line] + ";delta width" + str(row[found_h["delta width"]])
        elif "delta height" in found_h:
            print("NA",row[found_h["delta height"]])
            arg = "NA" + " " +  str(row[found_h["delta height"]])
            description = description_h[n_line] + ";delta height " + str(row[found_h["delta height"]])

        with open("data/"+args.tag +"/run__" + str(n_line) + "__" + "incr_width_height" + ".csh",'w') as csh:
            csh.write("source $source_dir/script/gen_incr_width_height_tune.csh " + arg +  " " + args.tag + "\n")
        csh.close()
        p = open("data/"+args.tag+".sub"+str(n_line)+".params",'a')
        p.write("DESCRIPTION = " + description + "\n")
        p.close()

     
    # implement files hacked extraction
    if "file" in found_h:
        pass
        sect = str(row[found_h["file"]])
        if len(sect) == 0:
            continue
        #print(sect)
        # check if controls section
        is_file = 0
        is_created = 0
        for word in sect.split():
            if os.path.exists(word):
                if is_created == 0:
                    f = open("data/"+args.tag+".sub"+str(i_f)+".files",'w')
                    is_created = 1
                    i_f = i_f + 1
                    f.write(word+'\n')
                else:
                    f.write(word+'\n')
        if is_created == 1:
            f.close()
    n_line = n_line + 1


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
                with open("data/"+args.tag +"/run__" + str(n_line) + "__" + clk_hack[n_sect] + "__" + pvt+".csh",'w') as csh:
                    csh.write("source $source_dir/script/hack_sdc_freq.csh "+ pvt + " " + clk_hack[n_sect] + " " + freq + " " + args.tag + "\n")

                if found_pvt == 0 :
                    is_pvt = 1
                    found_pvt = 1

        n_sect = n_sect + 1
    if n_line in description_h:
        pass
    else:
        description_h[n_line] = "Shmoo Freq"
        print("# inital shmoo frq",n_line)

    if is_pvt == 1:
        description = ""
        for sect in line.split('|'):
            if re.search("@",sect):
                print("# check params",description_h[n_line])
                description = description_h[n_line] + ";" + sect
        p = open("data/"+args.tag+".sub"+str(n_line)+".params",'a')
        p.write("DESCRIPTION = " + description + "\n")
        p.close()
    n_line = n_line + 1 

        

tb.close()
