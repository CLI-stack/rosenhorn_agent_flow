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
parser.add_argument('--xml',type=str, default = "None",required=True,help="the task tag")
parser.add_argument('--direction',type=str, default = "None",required=True,help="the task tag")
parser.add_argument('--targets',type=str, default = "None",required=True,help="the task tag")

args = parser.parse_args()
mytree = ET.parse (args.xml) 
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


def get_downstream_nodes_with_levels(graph, start_node):
    # Perform BFS traversal
    bfs_successors = dict(nx.bfs_successors(graph, start_node))
    
    # Initialize levels dictionary
    levels = {start_node: 0}  # Start node is at level 0
    
    # Traverse BFS successors to calculate levels
    for node, successors in bfs_successors.items():
        for successor in successors:
            levels[successor] = levels[node] + 1  # Level of successor = level of current node + 1
    
    return levels

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
# nx.dfs_preorder_nodes(G,args.target)
# nx.bfs_tree(G,args.target)
end_node_h = {}
for target in args.targets.split():
    # print(target)
    levels = get_downstream_nodes_with_levels(G,target)
    # print(levels)
    max_level_node = max(levels, key=levels.get)
    max_level = levels[max_level_node]
    if max_level_node == "PRIM_OUT":
        end_node_h[target] = 1
    else:
        end_node_h[max_level_node] = 1
    
    # print(target,max_level_node)

end_node_list = ""
for en in end_node_h:
    end_node_list = end_node_list + " " + en

print(end_node_list)
