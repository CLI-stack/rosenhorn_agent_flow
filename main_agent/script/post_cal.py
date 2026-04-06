import os
import gzip
#import xlwt
#import xlsxwriter
import sys


early_margin = 0
late_margin = 0
slack = 0
skew_margin_total = 0
skew_margin_overslack = 0
m = 0
n = 0
line_new = ''

files = sys.argv[2]+'/merge_'+sys.argv[1]+'.csv'
with open(sys.argv[2]+'/merge_post_'+sys.argv[1]+'.csv','wb') as f0:
  with open(files,'rb') as f1:
    for line in f1.readlines():
      line = line.decode().strip('\n')
      if ',ALOL,' in line:
        line_new = '%s,skew_margin_total,skew_margin_overslack'%(line)
        f0.write("%s\n" %(line_new))
      if 'start' not in line:
        early_margin = float(line.split(',')[-2])
        late_margin = float(line.split(',')[-1])
        slack = line.split(',')[4]
        m = max(early_margin,0)
        n = max(late_margin,0)
        skew_margin_total = float(m) + float(n)
        skew_margin_overslack = float(skew_margin_total) + float(slack)
        #line_new = line + ',' + skew_margin_total + ',' + skew_margin_overslack
        line_new = '%s,%s,%s'%(line,skew_margin_total,skew_margin_overslack)
        f0.write("%s\n" %(line_new))

        early_margin = 0
        late_margin = 0
        slack = 0
        skew_margin_total = 0
        skew_margin_overslack = 0
        m = 0
        n = 0

f0.close()
f1.close()
