# Copyright (c) 2024 xiaoxiao.wang(little); xiaoxiao.wang@amd.com;  Advanced Micro Devices, Inc.
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
import os
import requests
import re
from datetime import datetime
# Get the current date and time
current_time = datetime.now()
# Format the time as a string
formatted_time = current_time.strftime("%Y%m%d%H%M%S")
print("Formatted Date and Time:", formatted_time)
attachment_name = 'tasksMail.csv' 
#csv_file_path = r'C:\PD_Agent\agent_win_4\agent_wintasksMail.csv'
csv_file_path = r'tasksMail.csv'
twiki_url = 'https://twiki.amd.com'
twiki = ""
web = 'your_web'  
topic = 'your_topic'
username = 'your_username'
password = 'your_password'
mc = open("mailConfig.txt")
for line in mc:
    if re.search(r"\S",line):
        pass
    else:
        continue
    a_split = line.split()
    if re.search(r"twiki",a_split[0]):
        twiki = a_split[1]
        web = a_split[1].split("/")[6]
        topic = a_split[1].split("/")[7]
    if re.search(r"username",a_split[0]):
        username = a_split[1]
    if re.search(r"password",a_split[0]):
        password = a_split[1]

if re.search('twiki',twiki):
    # check csv file exists
    attachment_status_url = f'{twiki_url}/twiki/pub/{web}/{topic}/{attachment_name}'
    # get twiki page attach status
    
    response = requests.get(attachment_status_url, auth=(username, password))
    if response.status_code == 200:
        print(f"Attachment is available: {attachment_status_url},wait linux server catch tasksMail.csv ......")
    elif response.status_code == 404:
        print(f"[1]Attachment not found: {attachment_status_url},prepare publish tasksMail.csv ......")
    else:
        print(f"Failed to retrieve attachment. Status code: {response.status_code},please dubug twiki page status or wait next loop ......")
    
    # check csv file exists
    if os.path.exists(csv_file_path) and response.status_code == 404:
        attach_url = f'{twiki_url}/twiki/bin/upload/{web}/{topic}'
        print (attach_url) 
        # Prepare the file and metadata  
        files = {  
            'filepath': (attachment_name, open(csv_file_path, 'rb')),  
        }  
        data = {  
            'filename': attachment_name,  
            'filecomment': formatted_time,  
            'createlink': 'on',  
        }  
        # Send the POST request to attach the file  
        response = requests.post(attach_url, files=files, data=data, auth=(username, password))  
        # Check the response  
        if response.status_code == 200:  
            print('[2]File attached successfully!')  
        else:  
            print(f'Failed to attach file. Status code: {response.status_code}')  
            print('Response:', response.text)  
    elif not os.path.exists(csv_file_path):
        print(f"tasksMail.csv do not exist: {csv_file_path}")

