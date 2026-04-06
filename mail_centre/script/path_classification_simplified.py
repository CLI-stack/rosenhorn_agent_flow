import pandas as pd
import argparse
import csv
import os
import time
import re

"""
GPT prompt:
could you help to write python code with below reqirement?
1. with argument name "inCsv" and "outCsv"
2. increase one column "issue categary"
3. if the row in column name "ALOL" > 36, and  column name "Start_clk" match LCLK, add "ALOL > 36"  in colmun "issue categary" if it has value already
3. if the row in column name "ALOL" > 28, and  column name "Start_clk" match MID_SOCCLK,  add "ALOL > 28" in colmun "issue categary" if it has value already
4. if the row in column name "max_fanout" > 25, add "max_fanout > 25" in colmun "issue categary" if it has value already
5. if the row in column name "max_trans_per_period" > 0.2, add "max_trans_per_period > 20% period" in colmun "issue categary" if it has value already
6. if the row in column name "AOI_ratio" > 0.2, add "AOI_ratio > 20%" in colmun "issue categary" if it has value already
"""
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--incsv',type=str, default = "None",required=True,help="the input csv file")
parser.add_argument('--outcsv',type=str, default = "None",required=True,help="the output file")
args = parser.parse_args()

def process_csv(inCsv, outCsv):
    # Read the input CSV file
    df = pd.read_csv(inCsv)

    # Add a new column "issue categary"
    df['issue categary'] = ''

    # Update the "issue categary" based on the condition
    for index, row in df.iterrows():
        if row['ALOL'] > 36 and 'LCLK' in row['Start_clk']:
            df.at[index, 'issue categary'] += 'ALOL > 36; '
        if row['ALOL'] > 28 and 'MID_SOCCLK' in row['Start_clk']:
            df.at[index, 'issue categary'] += 'ALOL > 28; '
        if row['ALOL'] > 28 and 'FCLK' in row['Start_clk']:
            df.at[index, 'issue categary'] += 'ALOL > 28; '
        if row['max_fanout'] > 25:
            df.at[index, 'issue categary'] += 'max_fanout > 25; '
        if row['max_trans_per_period'] > 0.2:
            df.at[index, 'issue categary'] += 'max_trans_per_period > 20% period; '
        if row['AOI_ratio'] > 0.2:
            df.at[index, 'issue categary'] += 'AOI_ratio > 20%; '

    # Write the updated DataFrame to the output CSV file
    df.to_csv(outCsv, index=False)

# Call the function
process_csv(args.incsv, args.outcsv)

