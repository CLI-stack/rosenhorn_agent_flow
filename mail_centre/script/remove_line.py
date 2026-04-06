"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
# This script is to add the original content as quotation
import argparse
import csv
import os
import time
import re

parser = argparse.ArgumentParser(description='remove lines in file1 from file2 ')
parser.add_argument('--f1',type=str, default = "None",required=True,help="file with lines under removed")
parser.add_argument('--f2',type=str, default = "None",required=True,help="file with lines removed")
args = parser.parse_args()

def remove_lines(file1, file2):
    with open(file2, 'r') as f:
        lines_to_remove = f.readlines()

    with open(file1, 'r') as f:
        lines = f.readlines()

    with open(file1, 'w') as f:
        for line in lines:
            if line not in lines_to_remove:
                f.write(line)

# Call the function
remove_lines(args.f1, args.f2)
