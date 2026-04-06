import os
import time
from datetime import datetime, timedelta
import argparse
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--f',type=str, default = "None",required=True,help="the file")
args = parser.parse_args()

def days_since_file_created(file_path):
    if os.path.exists(file_path):
        file_time = os.path.getctime(file_path)
        print(file_time)
        file_time = datetime.fromtimestamp(file_time)
        print(file_time)
        now = datetime.now()
        difference = now - file_time
        return difference.days
    else:
        return "0"

# Test the function
file_path = args.f
print(days_since_file_created(file_path))
