"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""

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

# This script is to add the original content as quotation
import argparse
import csv
import os
import time
import re
import xml.etree.ElementTree as ET 
import networkx as nx

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--run_dir',type=str, default = "None",required=True,help="the run dir info")
args = parser.parse_args()
tbs = open("tbs.log")
target_h = {}
color_h = {'QUEUED':'#00F5FF','SKIPPED':'#C1FFC1','PASSED':'#00CD66','NOTRUN':'#C1CDCD','WAIVED':'#FFB6C1','STOPPING':'#FFFFE0',\
           'FAILED':'#FF0000','RUNNING':'#FFA500','WARNING':'#FFFF00','BLOCKED':'#A52A2A','PENDING':'#9F79EE'}
for line in tbs:
    target = line.split()[1]
    status = line.split()[2]
    target_h[target] = color_h[status]
    print(target,color_h[status])
mytree = ET.parse ("data/flow.xml") 
myroot = mytree.getroot()
#result = myroot.findall
def recursive_print(element,indent=""):
    print(element.attrib)
    #print(element["source"])
    #print(element.source,element.target,element.id)
    #print(element.tag)
    #if element.text:
    #    print(element.text.strip())
    for child in element:
        recursive_print(child,indent+" ")

#recursive_print(myroot)
G = nx.DiGraph()
for elem in myroot.iter():
    #print(elem.attrib)
    if elem.get('source') and elem.get('target'):
        #print(elem.get('source'),elem.get('target'))
        source = elem.get('source')
        target = elem.get('target')
        G.add_edge(source,target)
    else:
        if elem.get('id'):
            id_target = elem.get('id') 
            #print(elem.get('id'))
            G.add_node(id_target)
level_h = {}
list_h = {}
for node in G.nodes():
    #print(node,len(list(nx.ancestors(G, node))))
    level_h[node] = len(list(nx.ancestors(G, node)))
    if re.search('Pt|Tk|Sc|Sort',node):
        continue
    if node in target_h:
        pass
    else:
        continue
    log = ""
    if os.path.exists(args.run_dir+"/logs/"+node+".log"):
        log = args.run_dir+"/logs/"+node+".log"
    elif os.path.exists(args.run_dir+"/logs/"+node+".log.gz"):
        log = args.run_dir+"/logs/"+node+".log.gz"
    else:
        log = node
    if level_h[node] in list_h:
        list_h[level_h[node]] = list_h[level_h[node]] + "," + log+"::"+target_h[node]
    else:
                
        list_h[level_h[node]] = log+"::"+target_h[node]

#print(sorted(level_h.items(), key=lambda x: x[1]))
#for key,value in sorted(level_h.items(), key=lambda x: x[1]):
#    print(key,value)

# Sort the dictionary by key
sorted_dict = dict(sorted(list_h.items()))

# Print the key-value pairs
sp = open("console.spec",'w')
sp.write("#table#"+'\n')
sp.write(",,,,"+'\n')
for key, value in sorted_dict.items():
    #print(f"Key: {key}, Value: {value}")
    sp.write(value+'\n')
    print(value)
sp.write("#table end#"+'\n')
sp.close()
