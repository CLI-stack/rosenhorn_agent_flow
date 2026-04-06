import os,re,gzip,sys

from func import Table,Overall
from func import old_shell,shell,outline,timing_from_icc2_qor,timing_from_sort_rpt,pt_qor_timing,icc2_qor_timing,get_pt_timing_groups,get_icc2_timing_groups,get_hold_scenarios,get_pt_si_hold_rpts

if os.path.exists("rpts/FxPlace/qor.rpt.gz"):
    timing_from_icc2_qor("rpts/FxPlace/qor.rpt.gz","**Place_Setup**",35,"setup")
elif os.path.exists("rpts/FxPixPlace/qor.rpt.gz"):
    timing_from_icc2_qor("rpts/FxPixPlace/qor.rpt.gz","**Place_Setup**",35,"setup")

