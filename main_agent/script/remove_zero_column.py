import pandas as pd
import argparse
import csv
import os
import time
import re
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--incsv',type=str, default = "None",required=True,help="the input csv file")
parser.add_argument('--outcsv',type=str, default = "None",required=True,help="the output file")

args = parser.parse_args()

# Load your CSV file
df = pd.read_csv(args.incsv)

# Iterate over each column
for col in df.columns:
    # If all values, except the first one (header), in the column are 0
    if df[col][1:].eq(0).all():
        # Drop the column
        df = df.drop(col, axis=1)

# Save the result to a new CSV file
df.to_csv(args.outcsv, index=False)
