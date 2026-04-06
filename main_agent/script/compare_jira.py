"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import csv
import os
import time
import re
import datetime
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--source_dir',type=str, default = "None",required=True,help="source dir")
parser.add_argument('--item',type=str, default = "None",required=True,help="item")
args = parser.parse_args()
#print(args.tag)
timeCurrent = re.sub("-"," ",str(datetime.datetime.now()))
year = timeCurrent.split()[0]
month = timeCurrent.split()[1]
day = timeCurrent.split()[2]
fullTime = year+month+day
jira_file = args.source_dir + "/data/jira/" + args.item + "." + fullTime + ".list"
if os.path.exists("jira"):
    pass
else:
    os.makedirs("jira")

used_file = "jira/" + args.item + "." + fullTime + ".list"
new_file = "jira/" + args.item + ".list"
#print(jira_file,used_file,new_file)
line1_h = {}
line2_h = {}
line3_h = {}

if os.path.exists(jira_file):
    with open(jira_file, 'r') as f1:  # open file A.txt for reading
        lines1 = f1.readlines()  # read all lines from the file into a list

    if os.path.exists(used_file):
        with open(used_file, 'r') as f2:  # open file B.txt for reading
            lines2 = f2.readlines()  # read all lines from the file into a list

        with open(new_file, 'w') as f3:  # open a new file C.txt for writing
            for line in lines1:  # iterate over each line in A.txt
                if line not in lines2:  # check if the line is not in B.txt
                    if line in line3_h:
                        continue
                    line3_h[line] = 1
                    f3.write(line)  # write the line to C.txt if not found in B.txt
    else:
        with open(new_file, 'w') as f3:  # open a new file C.txt for writing
            for line in lines1:  # iterate over each line in A.txt
                print(line)
                if line in line3_h:
                    continue
                line3_h[line] = 1
                f3.write(line)  # write the line to C.txt if not found in B.txt
    f3.close()

    with open(used_file, 'w') as f2:
        for line in lines1:
            if line in line2_h:
                continue
            line2_h[line] = 1
            f2.write(line)
    f2.close()
    f1.close()

