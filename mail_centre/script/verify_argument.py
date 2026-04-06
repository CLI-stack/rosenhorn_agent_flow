# -*- coding: utf-8 -*-
"""
Created on Fri May 25 13:30:23 2023
@author: Simon Chen
"""
import argparse
import re
import pandas as pd
import datetime
import re
import os
import csv
import numpy as np

def read_arguement():
    arguement_h = {}
    with open('arguement.csv',encoding='utf-8-sig') as lt:
        reader = csv.reader(lt)
        for i in reader:
            #print(i[0],i[1])
            arguement_h[i[0].lower()]=i[1]
    return arguement_h

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update task csv item')
    parser.add_argument('--params',type=str, default = "params",required=True,help="params")
    args = parser.parse_args()
    arguement_h = {}
    arguement_h = read_arguement()
    #if args.params.lower() in arguement_h and arguement_h[args.params.lower()] == 'params':
    if args.params.lower() in arguement_h:
        print(args.params,arguement_h[args.params.lower()])
