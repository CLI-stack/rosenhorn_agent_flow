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

# WARNING: vdci power region info lvl: -81.6480 -25.0 81.6480 25.0 VDD_OTHER: VDDCR_SOCIO -81.6480 -26.5980 81.6480 -25.0 
if (-e $target.error.log) then
    set n_region = `grep "REGION_.*COORD" override.params | grep -v "#" | wc -l`
    if (-e generate_vdci_region.finish || $n_region > 0) then
        echo "# generate_vdci_region.finish or REGION_.*COORD has been defined"
        
    else
        echo "# Found $target.error.log, start generate vdci region"
        set cpp = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "^cpp," | awk -F "," '{print $2}'`
        set rowH = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "^rowH," | awk -F "," '{print $2}'`
        set vdciXoffset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "^vdciXoffset," | awk -F "," '{print $2}'`
        set vdciYoffset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "^vdciYoffset," | awk -F "," '{print $2}'`
        set n_cpp = `echo $cpp | wc -w`
        set n_rowH = `echo $rowH | wc -w`
        if ($n_cpp == 0 || $n_rowH == 0) then
            echo "ERROR: cpp or rowH not defined in assignment.csv"
            set cpp = 0.048
            set rowH = 0.286
        endif
        set main_power = `grep "vdci power region info lvl" $target.error.log | awk '{print $17}' | sed 's/\\n//g'`

        set llx = `grep "vdci power region info lvl" $target.error.log | awk '{print $7}'`
        set llx = `echo "$llx $cpp $vdciXoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set lly = `grep "vdci power region info lvl" $target.error.log | awk '{print $8}'`
        set lly = `echo "$lly $rowH $vdciYoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set urx = `grep "vdci power region info lvl" $target.error.log | awk '{print $9}'`
        set urx = `echo "$urx $cpp $vdciXoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set ury = `grep "vdci power region info lvl" $target.error.log | awk '{print $10}'`
        set ury = `echo "$ury $rowH $vdciYoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`

        #set lvl_region = `grep "vdci power region info lvl" $target.error.log | awk '{print $7,$8,$9,$10}'`
        set lvl_region = "$llx $lly $urx $ury"
        
        set other_power = `grep "vdci power region info lvl" $target.error.log | awk '{print $12}'`
        set llx = `grep "vdci power region info lvl" $target.error.log | awk '{print $13}'`
        set llx = `echo "$llx $cpp $vdciXoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set lly = `grep "vdci power region info lvl" $target.error.log | awk '{print $14}'`
        set lly = `echo "$lly $rowH $vdciYoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set urx = `grep "vdci power region info lvl" $target.error.log | awk '{print $15}'`
        set urx = `echo "$urx $cpp $vdciXoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set ury = `grep "vdci power region info lvl" $target.error.log | awk '{print $16}'`
        set ury = `echo "$ury $rowH $vdciYoffset" | awk '{print int(($1-$3)/$2)*$2+$3}'`
        set other_region = "$llx $lly $urx $ury" 
        #set other_region = `grep "vdci power region info lvl" $target.error.log | awk '{print $13,$14,$15,$16}'`
        #echo "$lvl_region"
        echo "$other_power $other_region"
        echo "REGION_${other_power}_COORD = \\{ $other_region }" >> override.params
        echo "REGION_LS${main_power}_COORD =  \\{ $lvl_region }" >> override.params
        touch generate_vdci_region.finish
        if (-e TileBuilderGenParams_generate_vdci_region) then
            rm TileBuilderGenParams_generate_vdci_region
        endif
        TileBuilderTerm -x "TileBuilderGenParams;TileBuilderOverwriteCommand cmds/FxFp*.cmd;touch TileBuilderGenParams_generate_vdci_region"
        set n_wait = 0
        while(1)
            if (-e TileBuilderGenParams_generate_vdci_region) then
                touch TileBuilderGenParams_generate_vdci_region.pass
                break
            endif
            set n_wait = `expr $n_wait + 1`
            if ($n_wait > 1800) then
                touch TileBuilderGenParams_generate_vdci_region.overtime
                break
            endif
            sleep 1
        end
    endif
endif

