import argparse
import pandas as pd
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--csv',type=str, default = "tasksModel.csv",required=True,help="csv file")
parser.add_argument('--html',type=str, default = "tasksModel.html",required=True,help="html file")
args = parser.parse_args()
a = pd.read_csv(args.csv,header=None,usecols=[0,2,4])
a.to_html(args.html)
