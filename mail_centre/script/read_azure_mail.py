import requests
import html2text
import re
from datetime import datetime
import csv
# Make the request
import requests
from requests.auth import HTTPBasicAuth

tenant_id = ""
client_id = ""
client_secret = ""
senderNameList = {}
vtoList = {}
mc = open("mailConfig.txt")
for line in mc:
    if re.search(r"\S",line):
        pass
    else:
        continue
    a_split = line.split()
    if re.search(r"mailDays",a_split[0]):
        mailDays = int(a_split[1])
    if re.search(r"myAccount",a_split[0]):
        myAccount = ' '.join(a_split[1:])
    if re.search(r"senderName",a_split[0]):
        name = ' '.join(a_split[1:])
        senderNameList[name.lower()] = 1
        # print(name)
    if re.search(r"vto",a_split[0]):
        name = ' '.join(a_split[1:])
        name = name.lower()
        vtoList[name] = 1
        # print(name)
        
    if re.search(r"tenant_id",a_split[0]):
        tenant_id = a_split[1]
    if re.search(r"client_id",a_split[0]):
        client_id = a_split[1]
    if re.search(r"client_secret",a_split[0]):
        client_secret = a_split[1]
        
if not re.search('\S',tenant_id):
    print("# tenant_id not set")
    exit() 

if not re.search('\S',client_id):
    print("# client_id not set")
    exit() 

if not re.search('\S',client_secret):
    print("# client_secret not set")
    exit() 

scope = 'https://graph.microsoft.com/.default'
 
# URL for token endpoint
token_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'
 
# Request payload
payload = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': scope
}
 
# Make the request
response = requests.post(token_url, data=payload)
token = response.json().get('access_token')
 
#print("Access Token:", token)
 
# 5. Access Outlook Mail
# Once you have the access token, you can use it to make requests to the Microsoft Graph API. Here’s an example to get the user's mail:
 
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}
 
# URL to access the user's mail
mail_url = f"https://graph.microsoft.com/v1.0/users/{myAccount}/messages?$top=100"

response = requests.get(mail_url, headers=headers)
emails = response.json().get("value", [])
tasks = []
jira_issue_h = {}
jira_solution_h = {}
line_limit = 200
mail_record = {}
for email in emails:
    #print(f"Subject: {email.get('subject')}")
    #print(f"From: {email.get('from', {}).get('emailAddress', {}).get('address')}")
    #print(f"Body Preview: {email.get('bodyPreview')}")
    isJira = 0
    for key in email.get('body'):
        pass
        #print(key)
    mailAddress = email.get('from', {}).get('emailAddress', {}).get('address')
    if mailAddress.lower() in senderNameList:
        pass
    else:
        continue
    Subject = email.get('subject')
    receivedDateTime = email.get('receivedDateTime')
    dt = datetime.strptime(receivedDateTime, "%Y-%m-%dT%H:%M:%SZ")
    tag = dt.strftime("%Y%m%d%H%M%S")
    mail_body = email.get('body')['content']
    is_confirmation_mail = 0
    se = re.search('(\S+)\s+agent\s+confirmation',Subject)
    if se:
        vto = se.group(1)
        print("# found vto",vto)
        if vto in vtoList:
            is_confirmation_mail = 1
            #print("# found agent confirmation mail")
        
    jira_subject = re.sub("Opened","Closed",Subject)
    jira_subject = re.sub("Implemented","Closed",jira_subject)
    if jira_subject in jira_solution_h:
        continue

    h = html2text.HTML2Text()
    h.body_width = 0
    contentLine = []
    is_table = 0
    k = 0
    #print(text_h2t)
    is_confirmation = 0
    text_h2t = h.handle(mail_body)
    for j in text_h2t.split('\n'):
        if is_table == 1:
            if re.search("|",j):
                pass
            else:
                is_table = 0
        if is_confirmation_mail == 1:
            if re.search("confirmed",j.lower()) or re.search("yes",j.lower()):
                is_confirmation = 1
                #print("# found agent confirmation")
                
        if re.search("\S",j):
            #print(j,k,len(contentLine),is_table)
            j = re.sub("\*\*","",j)
            if re.search("--|--",j):
                # add "|" for table head start and end:
                # before " xxx | xxx", after: "| xxx | xxx |"
                contentLine[k-1] = re.sub("\n","",contentLine[k-1])
                contentLine[k-1] = "|" + contentLine[k-1] + "|"
                is_table = 1
                continue
            if re.search("\]\(",j):
                j = re.sub("[\[\]\(\)]"," ",j)
            if is_table == 1:
                if re.search("\|",j):
                    print("# found table flag",j)
                    contentLine.append("|"+j+"|"+'\n')
                    print(contentLine[k])
                else:
                    is_table = 0    
                    contentLine.append(j+'\n')
            else:
                contentLine.append(j+'\n')
            k = k + 1

    #print(text_h2t)
    ## Etract JIRA content
    if jira_subject in jira_solution_h:
        isJira = 1
    found_table = 0
    #html_body = BeautifulSoup(mail_body_no_table,'lxml')
    tableMail = ""
    content_start = 0
    quote_start = 0
    quote_record = 0
    content_valid = ""
    quote_valid = ""
    valid =0
    # split the mail body to line array.
    #contentLine = content.split("\n")
    #print(contentLine)
    n_row = 0
    for i in range(len(contentLine)):
        n_fow = n_row + 1
        if n_row > line_limit:
            print(Subject,n_row,"body exceed line limit",line_limit)
            break
        contentWord = contentLine[i].split()
        #print(mail.Subject,contentWord,i)
        print(contentLine[i])
        if len(contentWord) > 0:
            # check if the first 6 line has Hi ...
            if re.search('|',contentLine[i]):
                pass
            else:
                contentLine[i] = re.sub(' and ',',',contentLine[i])
                contentLine[i] = re.sub(',and ',',',contentLine[i])
            # Start record mail body
            if re.search("Hi ",contentLine[i]) and content_start == 0 and i<=6 and is_confirmation == 0:
                contentLine[i] = re.sub('\/',' ',contentLine[i])
                contentLine[i] = re.sub(':',' ',contentLine[i])
                contentLine[i] = re.sub('\.',' ',contentLine[i])
                contentLine[i] = re.sub("'",' ',contentLine[i])
                for vto in contentLine[i].split():
                    vto = re.sub(',','',vto)
                    vto = vto.lower()
                    if vto in vtoList:
                        #print("#1",vto,contentLine[i],i)
                        content_start = 1
                        valid = 1
            # process confimation mail
            if re.search("Hi ",contentLine[i]) and content_start == 0 and is_confirmation == 1:
                contentLine[i] = re.sub('\/',' ',contentLine[i])
                contentLine[i] = re.sub(':',' ',contentLine[i])
                contentLine[i] = re.sub('\.',' ',contentLine[i])
                contentLine[i] = re.sub("'",' ',contentLine[i])
                # print(contentLine[i])
                for vto in contentLine[i].split():
                    vto = re.sub(',','',vto)
                    vto = vto.lower()
                    if vto in vtoList:
                        #print("#1",vto,contentLine[i],i)
                        content_start = 1
                        valid = 1
           
            # End record mail body, start check quote section
            if re.search(r"^From:",contentWord[0]) and content_start == 1:
                quote_start = 1
                content_start = 0
            # only allow 1 level mail quote
            if re.search(r"^From:",contentWord[0]) and quote_record == 1:
                quote_record = 0
                quote_start = 0
                
            if i>=6 and content_start == 0 and quote_start == 0 and is_confirmation == 0:
                break
                
            if content_start == 1:
                # " or ' will cause messy code
                if re.search("'",contentLine[i]):
                    #print(contentLine[i])
                    contentLine[i] = re.sub("'",' ',contentLine[i])
                se = re.search('sent_from:(.*)',contentLine[i])
                if se:
                    mailAddress = se.group(1)
                    continue

                content_valid= content_valid + ' '.join(contentLine[i].split()) + '\r' # remove redundant space
                #print("# merge",contentLine[i],i)
            
            # start record quote
            if re.search("Hi ",contentLine[i]) and quote_start == 1:
                contentLine[i] = re.sub('\/',' ',contentLine[i])
                contentLine[i] = re.sub('\.',' ',contentLine[i])
                for vto in contentLine[i].split():
                    vto = re.sub(',','',vto)
                    vto = vto.lower()
                    #print("#2",vto)
                    quote_record = 1
                    if vto in vtoList:
                        quote_record = 1
            
            if quote_record == 1:
                quote_valid= quote_valid + ' '.join(contentLine[i].split()) + '\r' # remove redundant space
                
    if valid == 1 or isJira == 1:
        if isJira == 0:
            content_valid = content_valid
        else:
            content_valid = jira_solution_h[jira_subject]
    receivedDateTime = re.sub('T',' ',receivedDateTime)
    receivedDateTime = re.sub('Z','',receivedDateTime)
    print(mailAddress,"|",Subject,"|",receivedDateTime,tag)
    if mailAddress in mail_record:
        if int(tag) - int(mail_record[mailAddress]) < 100:
            continue
        else:
            mail_record[mailAddress] = tag
    else:
        mail_record[mailAddress] = tag
    task = {'time' : receivedDateTime, 'tag':tag,'sender':mailAddress,'subject' : Subject, 'mailBody' : content_valid,\
            'mailQuote' : "",\
            'reply': '','instruction':'','runDir' : '','status' : ''}
    print("------")
    tasks.append(task)

sorted(tasks,reverse=True, key=lambda x: x['time'])
        
        # to avoid \ufeff appear during read from csv, we should use utf-8-sig instead of utf-8
with open("tasksMail.csv", mode="w", encoding="utf-8-sig", newline="") as f:
    header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
    writer = csv.DictWriter(f,header_list)
    writer.writeheader() 
    writer.writerows(tasks[::-1])
    f.close()

