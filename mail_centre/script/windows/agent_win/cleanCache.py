import os
import shutil
import datetime
import time
import argparse
print("### Start to clear py cache which cause outlook API failed...")
parser = argparse.ArgumentParser(description='add Temp/gen_py')
parser.add_argument('--genPy',type=str, default = "None",required=True,help="genPy")
args = parser.parse_args()
path = args.genPy
if os.path.exists(path):
    shutil.rmtree(path)
else:
    print(path,"not exists!")
time.sleep(5)
