# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import re
import datetime
import re
import os
import csv
#import urllib.request
#import requests


class Extractor:
    def __init__(self):
        self.my_account = None
        self.Sender = None
        self.status = []
        self.cbDrcCsv = []
        self.sumCsv = []
        self.ctsCsv = []
        self.disks = {}
        self.tasksModel = []
        self.tiles = {}
        self.tasksModelFile = ""
        self.statusFile = ""
        self.content = ""
        self.vtoInfo = {'tile' : '', 'disk' : '','project':'','ip':'','vto':'','debugger':'','manager':''}

    def set_tasksModelFile(self,tasksModelFile,statusFile):
        self.tasksModelFile = tasksModelFile
        self.statusFile = statusFile

    def write_status(self):
        vto_arr = self.vtoInfo['vto'].split(":")
        print("From:",vto_arr[1])
        with open(self.tasksModelFile,encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # here reader cannot be assign to taskMail directly, otherwise report IO error
            for i in reader:
                self.tasksModel.append(i)
            f.close
        rd_h = {}
        if os.path.exists("tile_status/summ_report/sum.csv"):
            with open("tile_status/summ_report/sum.csv",encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for i in reader:
                    self.sumCsv.append(i)
                f.close
        if os.path.exists("tile_status/summ_report/cbdrc.csv"):
            with open("tile_status/summ_report/cbdrc.csv",encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for i in reader:
                    self.cbDrcCsv.append(i)
                f.close
        if os.path.exists("tile_status/summ_report/cts_info.csv"):
            with open("tile_status/summ_report/cts_info.csv",encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for i in reader:
                    self.ctsCsv.append(i)
                f.close

        for task in self.tasksModel:
            if len(task["runDir"].split(':')) == 0:
                continue
            for rd in task["runDir"].split(':'):
                st = {}
                if rd in rd_h:
                    continue
                if len(rd) == 0:
                    continue
                else:
                    rd_h[rd] = 1
                
                if os.path.exists(rd) and os.path.exists(rd+"/tile.params"):
                    tile = ""
                    description = ""
                    branchFrom = ""
                    nickname = rd.split("/")[-1]
                    with open(rd+"/tile.params",'r') as f:
                        for line in f:
                            res = re.search(r"^TILES_TO_RUN\s+=\s+(\S+)",line)
                            if res:
                                tile = res.group(1)
                                found_tile = 1
                            res = re.search(r"^DESCRIPTION\s+=\s+([\s\S]+)$",line)
                            if res:
                                description = res.group(1)
                            
                            res = re.search(r"^BRANCHED_FROMDIR\s+=\s+(\S+)",line)
                            if res:
                                branchFrom = res.group(1) 
                                print(rd,"BRANCHED_FROMDIR",branchFrom)
                            # Saving matching time
                            if re.search("\S",tile) and re.search("\S",description) and  re.search("\S",branchFrom):
                                break
                        f.close()
                    
                    st["project"] = self.vtoInfo['project']
                    st["tile"] = tile
                    st["time"] = task["time"]
                    st["tag"] = task["tag"]
                    st["sender"] = task["sender"]
                    st["subject"] = re.sub('\n','',task["subject"])
                    print(st["subject"]+"#")
                    st["mailBody"] = "NA"
                    st["description"] =  re.sub('\n','',description)
                    st["runDir"] = rd
                    st["branchFrom"] = branchFrom

                    st["WNS risk"] = "NA"
                    st["TNS risk"] = "NA"
                    st["DRC risk"] = "NA"
                    st["placement WNS"] = "NA" 
                    st["placement TNS"] = "NA"
                    st["placement violation number"] = "NA"
                    st["reroute WNS"] = "NA"
                    st["reroute TNS"] = "NA"
                    st["reroute violation number"] = "NA"
                    st["floorplan utilization"] = "NA"
                    st["placement utilization"] = "NA"
                    st["re-route utilization"] = "NA"
                    st["placement congestion"] = "NA"
                    st["re-route DRC"] = "NA"
                    st["re-route short"] = "NA"
                    st["base DRC"] = "NA"
                    st["calibre DRC"] = "NA"
                    st["LVS"] = "NA"
                    st["main clock"] = "NA"
                    st["clock latency"] = "NA"
                    st["skew"] = "NA"
                    for i in self.sumCsv:
                        if i["NickName"] == nickname and i["Corner"] == "FuncTT0p65v":
                            #print(i)
                            st["WNS risk"] = i["WNS"]
                            st["TNS risk"] = i["TNS"]
                            st["DRC risk"] = i["Drc"]
                            st["placement WNS"] = i["W(ps)"]
                            st["placement TNS"] = i["T(ns)"]
                            st["placement violation number"] = i["NVP.1"]
                            st["reroute WNS"] = i["W(ps).6"]
                            st["reroute TNS"] = i["T(ns).6"]
                            st["reroute violation number"] = i["NVP.7"]
                            st["floorplan utilization"] = i["IniFP"]
                            st["placement utilization"] = i["Place.1"]
                            st["re-route utilization"] = i["ReRoute"]
                            st["placement congestion"] = i["Place"]
                            st["re-route DRC"] = i["ReRtDrc"]
                            st["re-route short"] = i["ReRtShort"]
                           
                    for i in self.cbDrcCsv:
                        if i["NickName"] == nickname:
                            st["base DRC"] = i["BaseFPDrc"]
                            st["calibre DRC"] = i["TileDrc"]
                            st["LVS"] = i["TileLVS"]

                    for i in self.ctsCsv:
                        if i["NickName"] == nickname:
                            if i["Clock"] == "FCLK" or i["Clock"] == "SOCCLK" or  \
                                i["Clock"] == "SMU_MPIOCLK" or ["Clock"] == "UVD_DCLK" or \
                                i["Clock"] == "LCLK" or \
                                i["Clock"] == "NBIO_LCLK" or i["Clock"] == "VCN_DCLK":
                                st["main clock"] = i["Clock"]
                                st["clock latency"] = i["MedL"]
                                st["skew"] = i["GlobalSkew"]
                                break
                            else:
                                st["main clock"] = i["Clock"]
                                st["clock latency"] = i["MedL"]
                                st["skew"] = i["GlobalSkew"]



                    #st["branchFrom"] = ""
                    self.status.append(st)
        
        # update status to csv
        with open(self.statusFile, mode="w", encoding="utf-8-sig", newline="") as f:
            header_list = ["project","tile","time", "tag","sender","subject", "mailBody","description","runDir","branchFrom","WNS risk","TNS risk","DRC risk",\
            "placement WNS","placement TNS","placement violation number","reroute WNS","reroute TNS","reroute violation number",\
            "floorplan utilization","placement utilization","re-route utilization","placement congestion","re-route DRC","re-route short",\
            "base DRC","calibre DRC","LVS","main clock","clock latency","skew"]
            writer = csv.DictWriter(f,header_list)
            writer.writeheader()
            sorted(self.status, key=lambda x: x['time'])
            writer.writerows(self.status)
            f.close()
    def read_assignment(self):
        with open('assignment.csv',encoding='utf-8-sig') as asm:
            reader = csv.reader(asm)

            for i in reader:
                if re.search(r"tile",i[0]):
                    #print(i[0],i[1])
                    self.vtoInfo['tile'] = self.vtoInfo['tile'] + ":" + i[1]
                if re.search(r"disk",i[0]):
                    self.vtoInfo['disk'] = self.vtoInfo['disk'] + ":" + i[1]
                    #print(i[0],i[1])
                if re.search(r"project",i[0]):
                    self.vtoInfo['project'] = i[1]
                    #print(i[0],i[1])
                if re.search(r"vto",i[0]):
                    self.vtoInfo['vto'] = self.vtoInfo['vto'] + ":" + i[1]
                    #print(i[0],i[1])
                if re.search(r"debugger",i[0]):
                    if len(self.vtoInfo['debugger']) > 0:
                        self.vtoInfo['debugger'] = self.vtoInfo['debugger'] + "," + i[1]
                    else:
                        self.vtoInfo['debugger'] = i[1]
                    print(i[0],i[1])
                if re.search(r"manager",i[0]):
                    if len(self.vtoInfo['manager']) > 0:
                        self.vtoInfo['manager'] = self.vtoInfo['manager'] + "," + i[1]
                    else:
                        self.vtoInfo['manager'] = i[1]
                    print(i[0],i[1])



if __name__ == '__main__':
    #print(tileOwner.senderNameList,tileOwner.mailDays)
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--tasksModelFile',type=str, default = "self.tasksModelFile",required=True,help="tasksModelFile file")
    parser.add_argument('--statusFile',type=str, default = "self.statusFile",required=True,help="statusFile file")
    args = parser.parse_args()
    extractor = Extractor()
    extractor.set_tasksModelFile(args.tasksModelFile,args.statusFile)
    extractor.read_assignment()
    extractor.write_status()
