import pandas as pd
import argparse
import csv
import os
import time
import re
import gzip

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--rpt',type=str, default = "None",required=True,help="timing report")
parser.add_argument('--o',type=str, default = "None",required=True,help="path number")

args = parser.parse_args()
n_path = 0
flag = 0
cn = open(args.o,'w')
isu = open("all_timing_issue.list",'w')
high_delay_cell_log = re.sub("_path","_path_high_delay",args.o)
high_delay_cell_log = os.path.abspath(high_delay_cell_log) 
#print("high_delay_cell_log",high_delay_cell_log)
#idl = open(high_delay_cell_log,'w')

clock = ""
path_start = 0
path_end = 0
max_cap = 0
max_trans = 0.0
max_delay = 0.0
high_delay_cell = []
max_fanout = 1
skew = 0.0
library_setup_time = 0.0
clock_edage = {}
half_edge = 0
lol = 0
ls_pin = ""
cpsel_pin = ""
is_place = 0
path_limit = 5000
n_path = 0
path_issue = {}
with gzip.open(args.rpt,'rb') as f:
    for line in f.readlines():
        line = line.decode().strip('\n')
        if n_path > path_limit:
            break

        if re.search('slack\s+\(VIOLATED\)',line) and flag == 1:
            line = re.sub("    "," ",line)
            flag = 0
            path_end = 0
            high_delay_cell_issue = ";".join(high_delay_cell)
            path_issue[path] = high_delay_cell_issue+","+max_fanout_issue+","+lol_issue+","+skew_issue+","+different_clock_issue+","+half_edge_issue+","+ls_pin+","+cpsel_pin
        
        if re.search('Path from',line):
            is_place = 1
            lol_issue = ""
            skew_issue = ""
            max_ranout_issue = ""
            half_edge_issue = ""
            different_clock_h = {}
            different_clock_issue = ""
            clock_edge = {}
            ls_pin = ""
            cpsel_pin = ""
            flag = 1
            continue
        else:
            pass
        
        if re.search('Startpoint:\s+(\S+)\s+',line):
            se = re.search('Startpoint:\s+(\S+)\s+',line)
            startpoint = se.group(1)

        if re.search('Endpoint:\s+(\S+)\s+',line):
            se = re.search('Endpoint:\s+(\S+)\s+',line)
            Endpoint = se.group(1)
            path = startpoint + ";" + Endpoint
            path_issue[path] = ""
            high_delay_cell = []
            print(n_path,path)
            n_path = n_path + 1
 
        if path_start == 1 and re.search("------",line):
            path_start = 0
            #print("# End pick path")
            path_end = 1

        if flag == 1:
            se = re.search("Max\s+Fanout\s+=\s+(\S+)",line)
            if se:
                max_fanout = int(se.group(1))
                if max_fanout > 25:
                    max_fanout_issue = str(max_fanout)
                else:
                    max_fanout_issue = ""
                #print("max_fanout",max_fanout)
            se = re.search("Logic\s+Levels\s+=\s+(\S+)",line)
            if se:
                lol = int(se.group(1))
                if lol > 30 and re.search("FCLK|SOCCLK|GFX|SMN|LCLK",clock):
                    lol_issue = str(lol)
                else:
                    lol_issue = ""
                    #print("lol",lol)

            se = re.search("Clock\s+Skew\s+=\s+(\S+)",line)
            if se:
                skew = float(se.group(1))
                if skew < -200.0 or skew > 200.0:
                    skew_issue = str(skew)
                else:
                    skew_issue = ""
                    #print("skew",skew)

            se = re.search("clock\s+(\S+)\s+\(",line)
            if se:
                clock = se.group(1)
                #print("clock",clock)

            line = re.sub(" Point"," Point Ref_name ",line)
            line = re.sub("    "," ",line)
            line = re.sub("Incr","Cell_Delay",line)
            line = re.sub("Path","Total_Path_Delay",line)
            if re.search("------",line) and path_end == 0:
                path_start = 1
                #print("# Start pick path.")
                continue
            if path_start == 0:
                pass
    
    
        if path_start == 1:
            if re.search('data\s+arrival\s+time',line):
                path_line_left = " ".join(path_line.split()[2:])
                #cn.write("  "+path_line.split()[0]+"    " + path_line.split()[1]+ "    "+fanout+"    "+cap+"   "+ path_line_left+'\n')
                #cn.write(line+'\n')
                continue
            se = re.search("library setup time\s+\S+\s+(\S+)",line)
            if se:
                library_setup_time = float(se.group(1))
                #print("library_setup_time",library_setup_time)

            if re.search('library\s+setup\s+time',line):
                path_line_left = " ".join(path_line.split()[2:])
                #cn.write("  "+path_line.split()[0]+"    " + path_line.split()[1]+ "    "+fanout+"    "+cap+"   "+ path_line_left+'\n')
                #cn.write(line+'\n')
                continue
            
            se = re.search("\((\S+)\s+edge\)",line)
            if se:
                current_edge = se.group(1)+" "+"edge"
                if not clock_edge:
                    clock_edge[current_edge] = 1
                else:
                    if current_edge in clock_edge:
                        half_edge = 0
                        half_edge_issue = ""
                    else:
                        half_edge = 1
                        half_edge_issue = "half edge"
            se = re.search("clock\s+(\S+)\s+\(\S+\s+edge\)",line)
            if se:
                clock = se.group(1)
                clock = re.sub("'","",clock)
                different_clock_h[clock] = 1
                #print("# different_clock_h",len(different_clock_h))
                if len(different_clock_h) > 1:
                    different_clock_issue = "different clock issue" + ";".join(different_clock_h.keys())
                else:
                    different_clock_issue = ""

            if re.search('^\s+clock',line) or re.search('^\s+library ',line) or  re.search('^\s+data ',line):
                #cn.write(line+'\n')
                continue

            if re.search('\(.*\)',line):
                if re.search("&",line):
                    if float(line.split()[-4]) > 100.0:
                        max_delay = float(line.split()[-4])
                        high_delay_cell.append(line.split()[-4]+ " " + line.split()[0]) 
                        #idl.write("high delay: " + line.split()[0]+" "+line.split()[-4]+'\n')
                if re.search("[0-9]+\.[0-9]+\s+[0-9]+\.[0-9]+\s+[0-9]+\.[0-9]+\s+[0-9]+\.[0-9]+\s+",line):
                    se = re.search("[0-9]+\.[0-9]+\s+[0-9]+\.[0-9]+\s+([0-9]+\.[0-9]+)\s+[0-9]+\.[0-9]+\s+",line)
                    if float(se.group(1)) > 100.0:
                        high_delay_cell.append(se.group(1)+ " " + line.split()[0])
                        #idl.write("high delay: " + line.split()[0]+" "+se.group(1)+'\n')
    
                if re.search("/LS\s+",line):
                    ls_pin = line.split()[0]
    
                    #print("false path",ls_pin)

                if re.search("/CPSEL\s+",line):
                    cpsel_pin = line.split()[0]
                    #print("false path",cpsel_pin)
                

                if re.search('\(net\)',line):
                    if len(line.split()) >= 3:
                        fanout = line.split()[2]
                        cap = line.split()[3]
                    #print("# fanout cap",fanout,cap)
                    # merge (net) and output point
                    if len(path_line.split()) > 6:
                        path_line_left = " ".join(path_line.split()[2:])
                        #print(path_line_left)
                        #cn.write("  "+path_line.split()[0]+"    " + path_line.split()[1]+ "    "+fanout+"    "+cap+"   "+ path_line_left+'\n')
                        continue
                else:
                    if re.search('\(.*\)',line):
                        path_line = re.sub('&','',line)
                        continue
                    
            if re.search('\S',line):
                pass
            else:
                #cn.write(line+'\n')
                pass

issue_list = ""

if len(high_delay_cell) > 0:
    #high_delay_cell_list = ';'.join(high_delay_cell) 
    #issue_list = high_delay_cell_list +  ";" + issue_list
    issue_list = high_delay_cell_log + ";" + issue_list

if max_fanout > 25:
    issue_list = "large max_fanout: " + str(max_fanout) + ";" + issue_list

if skew < -200.0 or skew > 200.0:
    issue_list = "large skew: " + str(skew) + ";" + issue_list

if library_setup_time < -200.0:
    issue_list = " large library_setup_time: " + str(library_setup_time) + ";" + issue_list

if half_edge == 1:
    issue_list = "half cycle path" + ";" + issue_list

if lol > 30 and re.search("FCLK|SOCCLK|GFX|SMN|LCLK",clock):
    issue_list = "large LOL: " + str(lol) + ";" + issue_list

if ls_pin == 1:
    issue_list = "False path due to /LS pin" + ";" + issue_list

if cpsel_pin == 1:
    issue_list = "False path due to /CPSEL pin" + ";" + issue_list

cn.write("#table#"+"\n")
cn.write("startpoint endpoint,high_delay_cell_issue,max_fanout_issue,lol_issue,skew_issue,different_clock_issue,half_edge_issue,ls_pin,cpsel_pin"+"\n")
n_path = 0
for path in path_issue:
    if n_path > path_limit:
        break
    if re.search("\S",re.sub(",","",path_issue[path])):
        #print(path,path_issue[path])
        cn.write(path+","+path_issue[path]+"\n")
    n_path = n_path + 1
cn.write("#table end#"+"\n")

isu.close()  
#idl.close()
cn.close()
f.close()
