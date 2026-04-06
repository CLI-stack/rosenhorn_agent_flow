import matplotlib.pyplot as plt
import pandas as pd
import argparse
import csv
import os
import time
import re
import gzip
parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--path',type=str, default = "None",required=True,help="path count file list")

args = parser.parse_args()

pcl = open(args.path+"/timing_wall.list",'r')
data = []
data_dict = {}
frq_th  = 2.0
for pc in pcl:
    print("# found ",pc)
    pc = pc.strip('\n')
    label = re.sub("/"," ",pc).split()[-4]
    print(label,pc)
    start = 0
    with gzip.open(pc,'rb') as f:
        for line in f.readlines():
            line = line.decode().strip('\n')
            print(line)
            se = re.search('Tcycle:\s+(\S+)',line)
            if se:
                period = float(se.group(1))
                frq_th = round(1 / period * 1000,2)
            if re.search("frequency",line):
                start = 1
                continue
            if start == 1:
                line = re.sub('\s+',' ',line)
                arr = line.split()
                frequency = float(arr[1])
                value = int(arr[2])
                if frequency not in data_dict:
                    data_dict[frequency] = {}
    
                data_dict[frequency][label] = value

                print(arr)
                data.append([label,arr[1],arr[2]])
                #if re.search('slack\s+\(VIOLATED\)',line) and flag == 1:

# Convert the dictionary to a DataFrame
df = pd.DataFrame.from_dict(data_dict, orient='index').reset_index()
df = df.rename(columns={'index': 'frequency'})

# Display the DataFrame
#print(df)
# Plot the curves
# Specify the column to be used as the X-axis
x_column = 'frequency'


df_sorted = df.sort_values(by=x_column, ascending=False)
df_sorted.to_csv(args.path+"/timing_wall_csv.csv", index=False)
print("frq:",frq_th)
print(df)
df_filtered = df[df['frequency'] <= frq_th]
print(df_filtered)
df_sorted = df_filtered.sort_values(by=x_column, ascending=False)


# Plot each remaining column against the specified X-axis column
for column in df_sorted.columns:
    if column != x_column:
        plt.plot(df_sorted[x_column], df_sorted[column], label=column)

# Add labels and legend
plt.gca().invert_xaxis()
plt.xlabel(x_column)
plt.ylabel('Values')
plt.title('Timing Wall')
plt.legend()

# Show the plot
plt.savefig(args.path+"/timing_wall_png.png", dpi=300)
#plt.show()
