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

from pymongo import MongoClient
import argparse
import csv
import os
import time
import re

parser = argparse.ArgumentParser(description='Update mongodb')
#parser.add_argument('--ip',type=str, default = "None",required=True,help="the ip")
parser.add_argument('--db',type=str, default = "None",required=True,help="the db")
parser.add_argument('--user',type=str, default = "None",required=True,help="the user")
parser.add_argument('--psw',type=str, default = "None",required=True,help="the psw")
args = parser.parse_args()
# Create a client
client = MongoClient('mongodb://127.0.0.1:27017/')
#client = MongoClient(f'mongodb://{args.user}:{args.psw}@{args.ip}:27017/{args.db}')

# Access the 'mydatabase' database
db = client[args.db]
db.command('createUser',args.user,pwd=args.psw,roles=["readWrite"])
