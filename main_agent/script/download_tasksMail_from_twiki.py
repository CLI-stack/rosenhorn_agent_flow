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
import requests  
from requests.auth import HTTPBasicAuth
import re

# TWiki instance details  
twiki_url = 'https://twiki.amd.com'  
attachment_name = 'tasksMail.csv'  
trash_topic = 'TrashAttachment'  # Topic to move the file to  
# Authentication details  
wiki = ""
web = 'your_web'
topic = 'your_topic'
username = 'your_username'
password = 'your_password'
mc = open("mailConfig.txt")
for line in mc:
    a_split = line.split()
    if re.search(r"\S",line):
        pass
    else:
        continue
    if re.search(r"twiki",a_split[0]):
        twiki = a_split[1]
        web = a_split[1].split("/")[6]
        topic = a_split[1].split("/")[7]
    if re.search(r"username",a_split[0]):
        username = a_split[1]
    if re.search(r"password",a_split[0]):
        password = a_split[1]
print(twiki_url,web,topic,attachment_name)
 
file_url = f'{twiki_url}/twiki/pub/{web}/{topic}/{attachment_name}'  
delete_url = f'{twiki_url}/twiki/bin/rename/{web}/{topic}'  
# Print the constructed URL for debugging  
print(f'Constructed URL: {file_url}') 
# delete attach file func
def delete_twiki_attachments(trash_topic, attachment_name, delete_url, username, password):
    # Data payload for the request
    payload = {
        'action': 'delete',  # Action to delete the file
        'newweb': 'Trash',  # Move to Trash
        'newtopic': trash_topic,  # Move to the TrashAttachment topic
        'attachment': attachment_name,  # The attachment you want to delete
    }

    # Send a POST request to move the file to Trash
    response = requests.post(delete_url, data=payload, auth=HTTPBasicAuth(username, password))

    # Check if the request was successful
    if response.status_code == 200:
        print(f"[2]Successfully moved {attachment_name} to Trash.")
    else:
        print(f"Failed to move {attachment_name} to Trash. Status code: {response.status_code}")
        print(response.text)  # Output any error message  

if re.search('twiki',twiki):    
    # Send the GET request to download the file  
    response = requests.get(file_url, auth=(username, password))  
  
    # Check the response  
    if response.status_code == 200:  
        # Save the file to the local filesystem  
        with open(attachment_name, 'wb') as file:  
            file.write(response.content)  
        print(f'[1]File downloaded successfully and saved as {attachment_name}')  
        delete_twiki_attachments(trash_topic, attachment_name, delete_url, username, password)
        #print('Response:', response.text)
    elif response.status_code == 404:
        print(f"Attachment not found: {file_url}")
        print("twiki page has no attachments!please wait Windowns Trminal publish...... ")
    else:  
        print(f'Failed to download file. Status code: {response.status_code}')


