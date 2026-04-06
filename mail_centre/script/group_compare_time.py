#!/usr/bin/env python
#__author__ = 'zhenggli'
#__email__ ='zhenggli@amd.com'
#__mentor__ = 'Simon.Chen'
#usage: python3.8 group_compare_time.py --run_dir $run_dir --refRuntime $refRuntimefile --output $outputfile
import csv  
import re   
import argparse
import os  
import glob  
from datetime import datetime, timedelta  
from dateutil import parser
import pytz  
import sys
#assign input file1 and file2 and output file
args_parser = argparse.ArgumentParser(usage='%(prog)s --run_dir rundir --refRuntime refRuntimefile  --output output ')  
  
args_parser.add_argument('--run_dir',  
                    type=str,  
                    dest='rundir',  
                    default=[],  
                    help='input is the flow runing target')  
args_parser.add_argument('--refRuntime',  
                    type=str,  
                    dest='refRuntimefile',  
                    default=[],  
                    help='input is the label target')
args_parser.add_argument('--output',  
                    type=str,  
                    dest='output',  
                    default=[],  
                    help='output compare result file')  
args = args_parser.parse_args() 

flow_dir = args.rundir;
output_file1 = os.path.join(flow_dir, 'Running_status.csv');
#running target status
input_file1 = output_file1;
input_file2 = args.refRuntimefile;
output_file = args.output;
# Lists all log files
logs_path = os.path.join(flow_dir, 'logs', '*.log')
logs = glob.glob(logs_path)  
with  open(output_file1, 'w') as output: 
 output.write("Target_name\ttile_name\tduration(h)\n")
 for log in logs:  
    with open(log, 'r', encoding='utf-8', errors='ignore') as file:
        target_set = next((line for line in file if "setenv TARGET_NAME" in line), "")  
        #print(target_set.strip())  
  
        if target_set: 
            with open(log, 'r', encoding='utf-8', errors='ignore') as file:
             first_line = file.readline().strip()  
             parts = first_line.split()  
             if len(parts) > 1:  
                    starttime = ' '.join(parts[1:]) 
             else:  
                    starttime = ""  

             for line in file: 
                if "setenv TARGET_NAME" in line:  
                    parts = line.split()
                    target_name = parts[-1] if parts else ""
  
                if "setenv TOP_MODULE" in line:  
                    parts = line.split()  
                    tile_name = parts[-1] if parts else ""  
  
            print(f"Target Name: {target_name}")  
            print(f"Tile Name: {tile_name}")  
            print(f"Start Time: {starttime}")  

#start calculate the run time
            given_dt_str = starttime
            given_dt = parser.parse(given_dt_str)
            now = datetime.now(pytz.timezone('US/Eastern')) if given_dt.tzinfo else datetime.now()
## calculate the run time
            time_diff = now - given_dt if given_dt.tzinfo == now.tzinfo else now - given_dt.astimezone(now.tzinfo)  
            hours_diff = time_diff.total_seconds() / 3600  
## output the result 
            print(f"time diff: {hours_diff:.2f} hours")
            output.write(f"{target_name}\t{tile_name}\t{hours_diff:.2f}\n")



#Please set the input and output file!!!
#input_file1 = output_file1;
#input_file2 = args.refRuntimefile;
#output_file = args.output; 
#read first csv
data_dict = {}  
with open(input_file1, 'r', newline='') as csvfile:  
    reader = csv.reader(csvfile, delimiter='\t')  
    next(reader)
    found_non_empty_line = False
    for row in reader:  
        #print(row)
        if ''.join(row).strip():  
            found_non_empty_line = True
            #print(found_non_empty_line)
        break
    if not found_non_empty_line:
        print(f"This rundir {flow_dir} haven't running target!!!")
        sys.exit(1)
    else:
        csvfile.seek(0)
        reader = csv.reader(csvfile, delimiter='\t')  
        next(reader)
        for row in reader:
            #print(row)
            if len(row) >= 3: 
                target, tile_name, dur_time = row[:3] 
                if dur_time != 'NA':  
                    data_dict[(target, tile_name)] = dur_time   
 
#read second csv  
with open(input_file2, 'r') as csvfile, open(output_file, 'w') as output:  
    reader = csv.reader(csvfile, delimiter='\t')  
    header = next(reader)  
    # removes the "(hours)" suffix for each element in the table header and builds a dictionary to map target to the column index
    target_to_index = {re.sub(r'\s*\(hours\)', '', target.strip()): index for index, target in enumerate(header[1:], 1)}
    print(target_to_index)
    for row in reader:
        tile = row[0]
        #print(tile)
        #print(data_dict)
      #for (target, tile_name), dur_time in data_dict.items(): 
        if re.match(tile, tile_name):
              #print(tile)
              for (target, tile_name), dur_time in data_dict.items(): 
                #print(data_dict)
                if target in target_to_index:  
                    column_index = target_to_index[target]  
                    target_value = row[column_index]  
                    print(f"Target: {target}, Tile: {tile_name}, Dur_time: {dur_time}, Value: {target_value}.")
                    output.write(f"Target: {target}, Tile: {tile_name}, Dur_time: {dur_time}, Value: {target_value}.\t")
                    parts = target_value.split('~')
                    if len(parts) == 2:  
                        min_target_value = float(parts[0])  
                        max_target_value = float(parts[1])
                        double_maxtime = max_target_value * 2
                        float_dur_time = float(dur_time)
                        if float_dur_time <= max_target_value:  
                            print(f"The duration of {target}: {dur_time}h is in reasonable range")  
                            output.write(f"The duration of {target}: {dur_time}h is in reasonable range\n") 
                        else:
                            if float_dur_time > double_maxtime:
                                print(f"The duration of {target}: {dur_time}h is no in reasonable range and it is more than twice the uptime\n")
                                output.write(f"The duration of {target}: {dur_time}h is no in reasonable range and it is more than twice the uptime\n")
                            else:
                                print(f"The duration of {target}: {dur_time}h is no in reasonable range and it is less than twice the uptime\n")
                                output.write(f"The duration of {target}: {dur_time}h is no in reasonable range and it is less than twice the uptime\n")
              break
                       # break
        else:
            if tile == 'all_tile_range':
               for (target, tile_name), dur_time in data_dict.items():
                if target in target_to_index:
                    #print(target)
                    column_index = target_to_index[target]  
                    target_value = row[column_index]
                    parts = target_value.split('~')
                    if len(parts) == 2:  
                        min_target_value = float(parts[0])  
                        max_target_value = float(parts[1])
                        double_maxtime = max_target_value * 2
                        float_dur_time = float(dur_time)
                        if float_dur_time <= max_target_value:  
                            print(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is in reasonable range")  
                            output.write(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is in reasonable range\n")  
                        else:
                            if float_dur_time > double_maxtime:
                               print(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is no in reasonable range and it is more than twice the uptime\n")
                               output.write(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is no in reasonable range and it is more than twice the uptime\n")
                            else:
                               print(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is no in reasonable range and it is less than twice the uptime\n")
                               output.write(f"This tile: {tile_name} is out of the ref tile! The duration of {target}: {dur_time}h is no in reasonable range and it is less than twice the uptime\n")

