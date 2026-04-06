# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com

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


# could you write python code that read the csv named "checklist.csv":
# 1. the first column is "id".
# 2. the second column is "DESC", read this colmun, and merge with content in a file name "template.txt", and write to a file with name "$id.prompt"

import csv
import argparse

parser = argparse.ArgumentParser(description='add template')
parser.add_argument('--t',type=str, default = "None",required=True,help="prompt template")
parser.add_argument('--c',type=str, default = "None",required=True,help="checklist csv")
args = parser.parse_args()


# Read the content of the template file
with open(args.t, 'r') as template_file:
    template_content = template_file.read()

# Open the CSV file and process each row
with open(args.c, 'r') as csv_file:
    csv_reader = csv.DictReader(csv_file)

    for row in csv_reader:
        # Get the id and DESC from the current row
        id_value = row['id']
        desc_content = row['DESC']

        # Merge the DESC content with the template content
        merged_content = f"{template_content}\n{desc_content}"

        # Write the merged content to a new file named "$id.prompt"
        output_filename = f"prompt/{id_value}.prompt"
        with open(output_filename, 'w') as output_file:
            output_file.write(merged_content)

print("Prompt files have been created successfully.")
