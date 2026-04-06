# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
# Copyright (c) 2024 Chen, Simon simon1.chen@amd.com Advanced Micro Devices, Inc.
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

import re
from win32com.client.gencache import EnsureDispatch as Dispatch
import pandas as pd
import datetime
import time
from bs4 import BeautifulSoup
import re
import os
#import commands,time
import win32com.client as win32
import win32com.client
import csv
import numpy as np
import argparse
import html2text
#parser = argparse.ArgumentParser(description='argparse testing')
#parser.add_argument('--name','-n',type=str, default = "bk",required=True,help="a programmer's name")
class TileOwner:
    def __init__(self):   
        self.my_account = None
        self.Sender = None
        self.senderNameList = {}
        self.mailDays = 8
        self.vtoList = {}
        self.sysList = {}
        self.tasks = []
        self.myAccount= {}
        
        #print(self.my_account,self.Sender)
    def set_tasks(self,tasks):
        self.tasks = tasks
    def set_data(self,data):
        for key.value in data.iterms():
            if hasattr(self,key):
                setattr(self,key,value)
    def read_mail_config(self):
        sender_name_list = {}
        mc = open("mailConfig.txt")
        for line in mc:
            if re.search(r"\S",line):
                pass
            else:
                continue
            a_split = line.split()
            if re.search(r"mailDays",a_split[0]):
                self.mailDays = int(a_split[1])
            if re.search(r"myAccount",a_split[0]):
                self.myAccount = ' '.join(a_split[1:])
            if re.search(r"senderName",a_split[0]):
                name = ' '.join(a_split[1:])
                self.senderNameList[name] = 1
                print(name)
            if re.search(r"vto",a_split[0]):
                name = ' '.join(a_split[1:])
                name = name.lower()
                self.vtoList[name] = 1
                print(name)
            if re.search(r"sys",a_split[0]):
                name = ' '.join(a_split[1:])
                name = name.lower()
                self.sysList[name] = 1
                print(name)
    
class CommunicationInterface:
    def __init__(self):
        self.my_account = None
        self.Sender = None
        self.tasks = []
        self.sys = []
        self.tasksModel = []
        self.tasksPrinted = []
        self.readMail = 0
        #print(my_account,Sender)
        
        
    def draw_content(self,my_account,mailDays,senderNameList,vtoList,sysList):
        self.readMail = 1
        n = 0
        outlook = Dispatch("Outlook.Application").GetNamespace("MAPI") 
        inbox = outlook.Folders[my_account].Folders["inbox"] 
        Mail_Messages = inbox.Items     
        Mail_Messages.Sort("[ReceivedTime]", True) 
        task = {}
        tasks = []
        sys = []
        jira_issue_h = {}
        jira_solution_h = {}
        line_limit = 100
        for mail in Mail_Messages: 
            isSys = 0
            n = n + 1
            isJira = 0
            if hasattr(mail, 'SenderName') and mail.MessageClass!= 'IPM.Schedule.Meeting.Request' and hasattr(mail, "Sender"): 
                #print(dir(mail))
                #print(mail.SenderName,mail.ReceivedTime.date(),(datetime.datetime.now()-datetime.timedelta(days=days)).date())
                date = mail.ReceivedTime.date()
                content = mail.Body
                #if mail.SenderName == Sender and mail.ReceivedTime.date()>\
                #print(mail.SenderName)
                if mail.ReceivedTime.date()< (datetime.datetime.now()-datetime.timedelta(days=mailDays)).date():
                    break
                if mail.SenderName in senderNameList and \
                mail.ReceivedTime.date()> (datetime.datetime.now()-datetime.timedelta(days=mailDays)).date():
                       # and 'release' in mail.Subject: 
                    #print(mail.SenderName)
                    if mail.SenderEmailType=='EX':
                        if mail.Sender.GetExchangeUser() != None:
                        #print(mail.Sender.GetExchangeUser().PrimarySmtpAddress)
                            mailAddress = mail.Sender.GetExchangeUser().PrimarySmtpAddress
                        else:
                        #print(mail.Sender.GetExchangeDistributionList().PrimarySmtpAddress)
                            mailAddress = mail.Sender.GetExchangeDistributionList().PrimarySmtpAddress
                    else:
                    #print(mail.SenderEmailAddress)
                        mailAddress = mail.SenderEmailAddress
                    #print("receive from",mailAddress)
                    se = re.search('(\S+)\s+agent\s+confirmation',mail.Subject)
                    is_confirmation_mail = 0
                    if se:
                        vto = se.group(1)
                        print("# found vto",vto)
                        if vto in vtoList:
                            is_confirmation_mail = 1
                            #print("# found agent confirmation mail")
                        
                    jira_subject = re.sub("Opened","Closed",mail.Subject)
                    jira_subject = re.sub("Implemented","Closed",jira_subject)
                    if jira_subject in jira_solution_h:
                        continue
                    content = mail.Body
                    # process table
                    mail_body = mail.HTMLBody
                    mail_body = re.sub('<br>',' ',mail_body)
                    # extract text and table
                    #text_h2t = html2text(mail_body)
                    h = html2text.HTML2Text()
                    h.body_width = 0
                    h.body_width = 1000
                    text_h2t = h.handle(mail_body)
                    contentLine = []
                    is_table = 0
                    k = 0
                    print(text_h2t)
                    is_confirmation = 0
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
                    html_body = BeautifulSoup(mail_body,'html.parser')
                    # remove talbe 
                    html_tables = html_body.find_all('table')
                    if len(html_tables) > 0 and  re.search("Jira",mail.SenderName) :
                        #print(html_tables)
                        p_h = {}
                        for table in html_tables:
                            #print("######",table.find_all('tr'))
                            n_tr = 0
                            for tr in table.find_all('tr'):
                                for td in tr.find_all('td'):
                                    for div in td.find_all('div',class_="je_preview"):
                                        #print("div++++++")
                                        has_text = 0
                                        p_value = ""
                                        for p in div.find_all('p'):
                                            #print(n_tr,"####",p.get_text().split('\n'))    
                                            if re.search("\S",p.get_text()) and p.get_text() not in p_h:
                                                pass
                                            else:
                                                continue
                                            #print("########## p ############")
                                            #print(p.get_text())
                                        if jira_subject in jira_solution_h:
                                            jira_issue_h[jira_subject] = ""
                                            for p in div.find_all('p'):
                                                if re.search("Hi",p.get_text()):
                                                    continue
                                                if re.search("Thanks",p.get_text()) or \
                                                    re.search("regards",p.get_text()):
                                                    break
                                                jira_issue_h[jira_subject] =  jira_issue_h[jira_subject] + ";;" + p.get_text()
                                        else:
                                            jira_solution_h[jira_subject] = ""
                                            for p in div.find_all('p'):
                                                if re.search("Hi",p.get_text()) or \
                                                    re.search("BRS",p.get_text()) or \
                                                    re.search("Dongsheng",p.get_text()) or \
                                                    re.search("Wenqiang",p.get_text()) :
                                                    continue
                                                if re.search("Thanks",p.get_text()) or \
                                                    re.search("regards",p.get_text()):
                                                    break
                                                jira_solution_h[jira_subject] = jira_solution_h[jira_subject] + ";;" + p.get_text()
                                        has_div = 1        
                    #print(mail.Subject,mail.ReceivedTime,"###",len(mail_body.split("\n")))
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
                            print(mail.Subject,n_row,"body exceed line limit",line_limit)
                            break
                        contentWord = contentLine[i].split()
                        #print(mail.Subject,contentWord,i)
                        #print(contentLine[i])
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
                                print(contentLine[i])
                                for vto in contentLine[i].split():
                                    vto = re.sub(',','',vto)
                                    vto = vto.lower()
                                    if vto in vtoList:
                                        #print("#1",vto,contentLine[i],i)
                                        content_start = 1
                                        valid = 1
                            # redudant code for sys, ignored
                            if re.search("Hi ",contentLine[i]) and content_start == 0 and i<=6:
                                contentLine[i] = re.sub('\/',' ',contentLine[i])
                                contentLine[i] = re.sub('\.',' ',contentLine[i])
                                for vto in contentLine[i].split():
                                    vto = re.sub(',','',vto)
                                    vto = vto.lower()
                                    if vto in sysList:
                                        #print("#1",vto,contentLine[i],i)
                                        content_start = 1
                                        valid = 1
                                        isSys = 1
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
                                        
                            # redudant code for sys, ignored
                            if re.search("Hi ",contentLine[i]) and quote_start == 1:
                                contentLine[i] = re.sub('\/',' ',contentLine[i])
                                contentLine[i] = re.sub('\.',' ',contentLine[i])
                                for vto in contentLine[i].split():
                                    vto = re.sub(',','',vto)
                                    vto = vto.lower()
                                    #print("#2",vto)
                                    if vto in sysList:
                                        quote_record = 1
                                        isSys = 1
                            
                            if quote_record == 1:
                                quote_valid= quote_valid + ' '.join(contentLine[i].split()) + '\r' # remove redundant space
                                
                    if valid == 1 or isJira == 1:
                        if isJira == 0:
                            content_valid = content_valid
                        else:
                            content_valid = jira_solution_h[jira_subject]
                        tag = re.sub('000\+00:00','',str(mail.ReceivedTime))
                        tag = re.sub('[ :-]','',tag)
                        tag = re.sub('^20','',tag)
                        tag = re.sub('\.','',tag)
                        #print("simplify",tag)
                        task = {'time' : mail.ReceivedTime, 'tag':tag,'sender':mailAddress,'subject' : mail.Subject, 'mailBody' : content_valid,\
                                'mailQuote' : quote_valid,\
                                'reply': '','instruction':'','runDir' : '','status' : ''}
                        if isSys == 0:
                            if task not in tasks:
                                tasks.append(task)
                            #print(mail.Subject,mail.ReceivedTime)
                            if task not in self.tasksPrinted:
                                self.tasksPrinted.append(task)
                                print(mailAddress,mail.Subject,mail.ReceivedTime)
                        else:
                            if task not in sys:
                                sys.append(task)
                            #print(mail.Subject,mail.ReceivedTime)
                            if task not in self.tasksPrinted:
                                self.tasksPrinted.append(task)
                                print(mailAddress,mail.Subject,mail.ReceivedTime)
                            

        sorted(tasks,reverse=True, key=lambda x: x['time'])
        sorted(sys, key=lambda x: x['time'])
        self.tasks = tasks
        self.sys = sys
        
        # to avoid \ufeff appear during read from csv, we should use utf-8-sig instead of utf-8
        with open("tasksMail.csv", mode="w", encoding="utf-8-sig", newline="") as f:
            header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
            writer = csv.DictWriter(f,header_list)
            writer.writeheader() 
            writer.writerows(tasks[::-1])
            f.close()
            
        return 0
    
    def send_mail(self,address,content):
        outlook = win32.Dispatch('Outlook.Application')
        mail_item = outlook.CreateItem(0) # 0: creat mail
        mail_item.Recipients.Add(address)
        mail_item.Subject = 'vto'
        mail_item.BodyFormat = 2          # 2: Html format
        mail_item.HTMLBody  = content
        #mail_item.Attachments.Add('pip.txt')   
        mail_item.Send()
        
    
if __name__ == '__main__':
    timeSlot0 = 0 # in 60 second, which slot allow read mail.
    timeSlot1 = 60
    print("# Start Agent at:",datetime.datetime.now())
    tileOwner = TileOwner();
    tileOwner.read_mail_config()
    communicationInterface = CommunicationInterface()
    #commands.getstatusoutput("df -lh|awk '{print $5}'|grep '%'|awk -F '%' '{print $1}'|grep -v Use")
    print(tileOwner.senderNameList,tileOwner.mailDays)
    # AttributeError: module 'win32com.gen_py.00062FFF-0000-0000-C000-000000000046x0x9x6' has no attribute 'CLSIDToPackageMap'
    # If errors are found, do this
    # clear contents of C:\Users\<username>\AppData\Local\Temp\gen_py
    # that should fix it, to test it type
    n = 0
    while True:
        time.sleep(2)
        
        curr_time = datetime.datetime.now()
        
        if curr_time.second < timeSlot1 and curr_time.second > timeSlot0:
            #print("# start read mail")
            n = n + 1
            if n > 3:
                break
            print(n)
            communicationInterface.draw_content(my_account=tileOwner.myAccount,\
                        mailDays=tileOwner.mailDays,senderNameList = tileOwner.senderNameList,\
                        vtoList = tileOwner.vtoList,sysList = tileOwner.sysList)
    
    outlook = win32.Dispatch('Outlook.Application')
    mail_item = outlook.CreateItem(0) # 0: creat mail
    mail_item.Recipients.Add('simon1.chen@amd.com')
    mail_item.Subject = 'Mail Test'
    mail_item.BodyFormat = 2          # 2: Html format
    mail_item.HTMLBody  = '''
        <H2>Hello, This is a test mail.</H2>
        Hello Guys.
        '''
#mail_item.Attachments.Add('pip.txt')   
#mail_item.Send()
"""
if mail.SenderEmailType=='EX':
    if mail.Sender.GetExchangeUser() != None:
        #print(mail.Sender.GetExchangeUser().PrimarySmtpAddress)
        mailAddress = mail.Sender.GetExchangeUser().PrimarySmtpAddress
    else:
        #print(mail.Sender.GetExchangeDistributionList().PrimarySmtpAddress)
        mailAddress = mail.Sender.GetExchangeDistributionList().PrimarySmtpAddress
else:
    #print(mail.SenderEmailAddress)
    mailAddress = mail.SenderEmailAddress
"""
