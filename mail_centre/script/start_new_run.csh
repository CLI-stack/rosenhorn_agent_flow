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

set project = $1
set tile = $2
set runDir = $3
set disk = $4
set params = $5
set tune = $6
set tag = $7
set table = $8
set refDir = $9
set file = $10
set diskUsage = 0
set diskUsed = ""
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set start_new_run = 1
touch $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_file = `echo $file | sed 's/^file//g' | sed 's/:/ /g' | wc -w`
#source csh/env.csh
set tile_filter = ""
source $source_dir/script/unalias.csh
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
        set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
        set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
        if ($n_rd_tile == 0) then
        else
            set tile_filter = "$tile_filter $t"
        endif
    end
    set tile = "$tile_filter"
else
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set n_tile_filter = `echo $tile_filter | wc -w`
if ($n_tile_filter == 0 && $n_tile > 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | awk '{print $1}' | sed 's/\/$//g'`
set n_refDir = `echo $refDir | wc -w`
if ($n_refDir > 0) then
    set is_assigned = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "disk," | grep $refDir | wc -w`
else 
    set is_assigned = 0
endif
#set params = `resolve $params`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The TB session for $tile has been started at: 
EOF
set n_params = 0 
set n_files = 0
set eff_rd = ""
if (-e $table) then
    set n_table = `head -n 1 $table | sed 's/|/ /g' | awk '{print NF}'`
    echo "# check table $n_table"
    if ($n_table > 0) then
        python3 $source_dir/py/start_run.py --table $table --arguement $source_dir/arguement.csv --tag $tag
        set n_params = `ls $source_dir/data/$tag.sub*.params | wc -l`
        if ($n_params == 0) then
            set n_params = `ls $source_dir/data/$tag.sub*.controls | wc -l`
        endif
        if (-e $source_dir/data/$tag.sub0.params || -e $source_dir/data/$tag.sub1.params)  then
            set n_params = `ls $source_dir/data/$tag.sub*.params | wc -l`
        endif
        if (-e $source_dir/data/$tag.sub0.controls || -e $source_dir/data/$tag.sub1.controls)  then
            set n_params = `ls $source_dir/data/$tag.sub*.controls | wc -l`
        endif

        if (-e $source_dir/data/$tag.sub0.files || -e $source_dir/data/$tag.sub1.files ) then
            set n_files = `ls $source_dir/data/$tag.sub*.files | wc -l`
            touch data/$tag.runDirFiles
        endif
    else
        set n_params = 0
        echo "# No table used."
    endif
endif
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set rd_valid = 0
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,Params" >> $source_dir/data/${tag}_spec
set startEnv = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "startEnv," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_startEnv = `echo $startEnv | wc -w`
set noXterm = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "noXterm," | awk -F "," '{print $2}'`
set n_noXterm = `echo $noXterm | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    set rd_valid = 0
    echo "# run for $t $runDir"
    set run_used = 0
    set n_runDir = `cat $runDir | wc -w`
    echo "$n_runDir"
    if ($n_runDir > 0) then
        foreach rd (`cat $runDir`)
            echo "# check $rd."
            set n_rd = `echo $rd | wc -w`
            if ($n_rd == 0) then
                continue
            endif
            if ($rd_valid == 1) then
                continue
            endif
            if (-e $rd/tile.params) then
                set curr_tile = `grep ^TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            # found the matched tile run
                if ($t == $curr_tile) then
                    set run_used = 1
                    # If use latest run reasonable?
                    echo "# Found ref dir: $rd"
                    set rd_valid = $rd
                endif
            endif
        end
    endif
        #set baseDir = `echo "$rd" | sed 's/\// /g' | awk '{print "/"$1"/"$2"/"$3"/"$4"/"$5}'`
        #cd $baseDir
    set runQuota = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "runQuota," | awk -F "," '{print $2}' | sed 's/\r//g'`
    set n_runQuota = `echo $runQuota | wc -w`
    if ($n_runQuota > 0) then
    else
        set runQuota = 50
    endif
    set disks = `python3 $source_dir/script/assign_disk.py --csv $source_dir/assignment.csv --tile $t`
    set diskUsage = 0
    foreach d (`echo $disks`)
        set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
        if ($temp > $diskUsage) then
            set diskUsage = $temp
            set diskUsed = $d
        endif
    end
    if ($is_assigned > 0) then
        set diskUsed = $refDir
    endif
    if (-e $diskUsed/$vto) then
        cd $diskUsed/$vto
        if (-e $t) then
            cd $t
        else
            mkdir -p $t
            cd $t
        endif
    else
        cd $diskUsed
        mkdir -p $diskUsed/$vto/$t
        cd $diskUsed/$vto/$t
    endif
    # Params in table
    if ($n_params > 0 ) then
        set n_subs = `ls $source_dir/data/$tag.sub*.params | wc -l` 
        if ($n_subs > 0) then
            set subs = `ls $source_dir/data/$tag.sub*.params `
        else
            set subs = `ls $source_dir/data/$tag.sub*.controls`
        endif
        foreach pf (`echo $subs`)
            set sub = `echo $pf | sed 's/\./ /g' | awk '{print $2}'`
            set is_sub_tile = `echo $pf | sed 's/\./ /g' | awk '{print NF}'`
            echo "# is_sub_tile $is_sub_tile"
            if ($is_sub_tile == 4) then
                set sub_tile = `echo $pf | sed 's/\./ /g' | awk '{print $3}'`
                set n_sub_tile = `echo $t | grep $sub_tile | wc -w`
                echo "# $t $sub_tile $n_sub_tile"
                if ($n_sub_tile == 0) then
                    continue
                endif
            endif
            if ($is_sub_tile == 3) then
                set sub_tile = $t 
                set n_sub_tile = `echo $t | grep $sub_tile | wc -w`
                echo "# $t $sub_tile $n_sub_tile"
                if ($n_sub_tile == 0) then
                    continue
                endif
            endif
            set dir = ${tag}_${sub}
            # assign the available disk
            foreach d (`echo $disk | sed 's/:/ /g'`)
                break
                set n_diskUsed = `echo $diskUsed | wc -w`
                #set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
                set temp = `ls -1d $d/$vto/$t/* | wc -l`
                set vol = `df $d | grep -v Filesystem | awk '{print $2/1000000}'`
                set n_rest = `echo $vol $temp | awk -v awk_runQuota="$runQuota" '{print int($1-($2+1)*awk_runQuota)}'`
                echo "$d | $temp | $vol | $n_rest"
                if ($n_rest < 0) then
                    continue
                endif
                set diskUsage = $temp
                set diskUsed = $d
                set n_diskUsed = `echo $diskUsed | wc -w`
                break
            end

            mkdir $dir
            cd $dir
            echo "### Start run at $diskUsed/$vto/$t/$dir"
            touch override.params
            touch override.controls
            rm override.params
            rm override.controls
 
            echo "NICKNAME = ${tag}_${sub}" > override.params
            echo "TILES_TO_RUN = $t" >> override.params
            echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
            set n_refDir = `echo $refDir | wc -w`
            if ($n_refDir > 0) then
                echo "# Use refDir:$refDir"
                if (-e $refDir/override.params) then
                    cat $refDir/override.params | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                    cp $refDir/override.params override.refDir.params
                endif
                if (-e $refDir/override.controls) then
                    cat $refDir/override.controls >> override.controls
                endif
            endif

            if ($run_used == 1 && $n_refDir == 0 && $start_new_run == 0) then
                cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
                cp $rd_valid/override.params override.rd_valid.params
                python3 $source_dir/py/merge_params.py --origParams override.params --newParams $pf --outParams out.params --op remove
                cp out.params override.params

                cat $rd_valid/override.controls | egrep -v "NICKNAME|TILES_TO_RUN" >> override.controls
                if (-e $source_dir/data/${tag}.${sub}.controls) then
                    python3 $source_dir/py/merge_params.py --origParams override.controls --newParams $source_dir/data/${tag}.${sub}.controls --outParams out.controls --op remove
                    cp out.controls override.controls
                endif
            endif

            if ($run_used == 0 && $n_refDir == 0 && $start_new_run == 0) then
                set n_formal_release_params = 0
                foreach p (`ls -lat $source_dir/data/*.params | awk '{print $9}'`)
                    set n_formal_release_params = `grep DESCRIPTION $p |  grep -i "formal release" | wc -w`
                    set n_chip_release = `egrep "CHIP_RELEASE|FLOORPLAN_POINTER" $p | wc -l`
                    if ($n_formal_release_params > 0 && $n_chip_release == 2) then
                        cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                        cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" > override.formal_release_params
                        break
                    endif
                end
                if ($n_formal_release_params == 0) then
                    echo "$t,NA,# No formal release params" >> $source_dir/data/${tag}_spec
                    #continue
                endif
            endif
 
            set paramsCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "params," | awk -F "," '{print $2}' | sed 's/\r//g'`
            if (-e $paramsCenter/$t/override.params) then
                sed -i '/NICKNAME/d' $paramsCenter/$t/override.params
                eperl $paramsCenter/$t/override.params > $paramsCenter/$t/override.flat.params
                python3 $source_dir/py/merge_params.py --origParams override.params --newParams $paramsCenter/$t/override.params --outParams out.params --op merge
                cp out.params override.params
            endif
            if (-e $paramsCenter/$t/override.controls) then
                eperl $paramsCenter/$t/override.controls > $paramsCenter/$t/override.flat.controls
                python3 $source_dir/py/merge_params.py --origParams override.controls --newParams $paramsCenter/$t/override.controls --outParams out.controls --op merge
                cp out.controls override.controls
            endif
            
            if (-e $source_dir/data/$tag.params) then
                # remove double back slash 
                sed -i 's/\\\\/\\/g' $source_dir/data/$tag.params
                cat $source_dir/data/$tag.params | egrep -v "NICKNAME|TILES_TO_RUN|ECO_SCEDIR" >> override.params
            endif
            if (-e $source_dir/data/$tag.controls) then
                cat $source_dir/data/$tag.controls >> override.controls
            endif
 
            if ($n_subs > 0) then
                set description_mail = `egrep "^DESCRIPTION\s" $source_dir/data/$tag.params | grep -v "^#" | awk '{for(i=3; i<=NF; i++) printf "%s%s", $i, (i==NF ? "\n" : OFS)}'` 
                set description_tb = `egrep "^DESCRIPTION\s" $pf | grep -v "^#" | awk '{for(i=3; i<=NF; i++) printf "%s%s", $i, (i==NF ? "\n" : OFS)}'`
                set description_merge = "DESCRIPTION = $description_mail;$description_tb"
                cat $pf | grep -v "NICKNAME" >> override.params
                echo $description_merge >> override.params
            endif
            if (-e $source_dir/data/${tag}.${sub}.controls) then
                cat $source_dir/data/${tag}.${sub}.controls >> override.controls
            endif
            echo "$is_sub_tile | $source_dir/data/${tag}.${sub}.$sub_tile.controls"
            if ($is_sub_tile == 4) then
                if (-e $source_dir/data/${tag}.${sub}.$sub_tile.controls) then
                    cat $source_dir/data/${tag}.${sub}.$sub_tile.controls >> override.controls
                endif
            endif
            echo "# check source dir params"
            if (-e $source_dir/data/${tag}.${sub}.params) then
                #cat $source_dir/data/${tag}.${sub}.params | egrep -v "NICKNAME|TILES_TO_RUN|ECO_SCEDIR" >> override.params
            endif
            echo "# print final params"
            cat override.params
            echo "# end print final params"

            echo "# print final controls"
            cat override.controls
            echo "# end print final controls"

            set tb_dir = `pwd`
            set eff_rd = "$eff_rd $tb_dir"
            if ($n_startEnv > 0) then
                if (-e $startEnv) then
                    echo "# use start_env $startEnv"
                    if ($n_noXterm > 0) then
                        source $startEnv;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished &
                    else
                        xterm -e "source $startEnv;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished" &
                    endif
                endif
            else
                if (-e $source_dir/script/project/$project/start_env.csh) then
                    echo "# use start env $source_dir/script/project/$project/start_env.csh"
                    if ($n_noXterm > 0) then
                        source $source_dir/script/project/$project/start_env.csh;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished &
                    else
                        xterm -e "source $source_dir/script/project/$project/start_env.csh;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished" &
                    endif
                else
                    if ($n_noXterm > 0) then
                        source /tools/aticad/1.0/src/sysadmin/cpd.cshrc;setenv FAMILY supra;setprj $project;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished &
                    else
                        xterm -e "source /tools/aticad/1.0/src/sysadmin/cpd.cshrc;setenv FAMILY supra;setprj $project;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}_${sub}.log;touch ${t}_${tag}.finished" &
                    endif
                endif
            endif
            cd  $diskUsed/$vto/$t
        end
    else
        echo "# start new run"
        set dir = $tag
         # assign the available disk
        foreach d (`echo $disk | sed 's/:/ /g'`)
            break
            set n_diskUsed = `echo $diskUsed | wc -w`
            #set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
            set temp = `ls -1d $d/$vto/$t/* | wc -l`
            set vol = `df $d | grep -v Filesystem | awk '{print $2/1000000}'`
            set n_rest = `echo $vol $temp | awk -v awk_runQuota="$runQuota" '{print int($1-($2+1)*awk_runQuota)}'`
            echo "$d | $temp | $vol | $n_rest"
            if ($n_rest < 0) then
                continue
            endif
            set diskUsage = $temp
            set diskUsed = $d
            set n_diskUsed = `echo $diskUsed | wc -w`
            break
        end

        if (-e $dir) then
            cd $dir
        else
            mkdir $dir
            cd $dir
        endif
        echo "### Start run at $diskUsed/$vto/$t/$dir"
        touch override.params
        touch override.controls
        rm override.params
        rm override.controls
        echo "NICKNAME = $tag" > override.params
        echo "TILES_TO_RUN = $t" >> override.params
        echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
        set n_refDir = `echo $refDir | wc -w`
        echo "# check ref run."
        if ($n_refDir > 0) then
            echo "# Use refDir:$refDir"
            if (-e $refDir/override.params) then
                #python3 $source_dir/script/merge_params.py --origParams $refDir/override.params --newParams override.params --outParams out.params --op remove
                #cp out.params override.params
                cat $refDir/override.params | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                
                cp $refDir/override.params override.refDir.params
            endif
            if (-e $refDir/override.controls) then
                cat $refDir/override.controls >> override.controls
            endif
        endif
        echo "# check used run."
        if ($run_used == 1 && $n_refDir == 0 && $start_new_run == 0) then
            cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            cp $rd_valid/override.params override.rd_valid.params
            cat $rd_valid/override.controls | egrep -v "NICKNAME|TILES_TO_RUN" >> override.controls
        endif
        echo "# check historical params $run_used | $n_refDir"
        
        if ($run_used == 0 && $n_refDir == 0 && $start_new_run == 0) then
            set n_formal_release_params = 0
            foreach p (`ls -lat $source_dir/data/*.params | awk '{print $9}'`)
                echo "# $p"
                set n_formal_release_params = `grep DESCRIPTION $p |  grep -i "formal release" | wc -w`
                set n_chip_release = `egrep "CHIP_RELEASE|FLOORPLAN_POINTER" $p | wc -l`
                echo "# $n_formal_release_params $n_chip_release"
                if ($n_formal_release_params > 0 && $n_chip_release > 0) then
                    cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                    cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" > override.formal_release_params
                    break
                endif
            end
            if ($n_formal_release_params == 0) then
                echo "$t,NA,# No formal release params" >> $source_dir/data/${tag}_spec
                #continue
            endif
        endif
        echo "# check mail params, remove old params from prevous run"
        if (-e $source_dir/data/$tag.params) then
            # remove double back slash 
            sed -i 's/\\\\/\\/g' $source_dir/data/$tag.params
            cat $source_dir/data/$tag.params | egrep -v "NICKNAME|TILES_TO_RUN" > new.params
            python3 $source_dir/py/merge_params.py --origParams override.params --newParams new.params --outParams out.params --op remove
        endif
        cp out.params override.params
        if (-e $source_dir/data/$tag.controls) then
            python3 $source_dir/py/merge_params.py --origParams override.controls --newParams $source_dir/data/$tag.controls --outParams out.controls --op merge
            cp out.controls override.controls
        endif
        
        echo "# check params center params."
        set paramsCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "params," | awk -F "," '{print $2}' | sed 's/\r//g'`
        echo "$paramsCenter/$t/override.params"
        if (-e $paramsCenter/$t/override.params) then
            sed -i '/NICKNAME/d' $paramsCenter/$t/override.params
            eperl $paramsCenter/$t/override.params > $paramsCenter/$t/override.flat.params
            python3 $source_dir/py/merge_params.py --origParams override.params --newParams $paramsCenter/$t/override.params --outParams out.params --op merge
            cp out.params override.params
        endif
        echo "# check params center controls."
        if (-e $paramsCenter/$t/override.controls) then
            eperl $paramsCenter/$t/override.controls > $paramsCenter/$t/override.flat.controls
            python3 $source_dir/py/merge_params.py --origParams override.controls --newParams $paramsCenter/$t/override.controls --outParams out.controls --op merge
            cp out.controls override.controls
        endif

        echo "# check source dir params"
        set secdir = ""
        set n_secdir = 0
        if (-e $source_dir/data/$tag.params) then
            cat $source_dir/data/$tag.params | egrep -v "NICKNAME|TILES_TO_RUN|ECO_SCEDIR" >> override.params
            set n_ECO_SCEDIR = `egrep "^ECO_SCEDIR" $source_dir/data/$tag.params | wc -w` 
            if ($n_ECO_SCEDIR > 0)  then
                set secdir = `grep ECO_SCEDIR $source_dir/data/$tag.params | grep -v "#" | grep $t | head -n 1`
                set n_secdir = `echo $secdir | wc -w` 
                if ($n_secdir > 0) then
                    echo $secdir >> override.params
                endif
                echo "" > $source_dir/data/$tag/$t.eco
                echo "ECO_NEWCMD = $source_dir/data/$tag/$t.eco" >> override.params
            endif
        endif
         echo "# check dmsa eco"
        if ($n_secdir > 0) then
            foreach eco (`ls $secdir/DMSA_SF/eco/*.eco`)
                echo "source -e -v $eco" >> $source_dir/data/$tag/$t.eco
            end
        endif
        echo "# Check any eco"
        if ($n_file > 0) then
            echo "" > $source_dir/data/$tag/$t.eco
            foreach eco (`echo $file | sed 's/^file//g' | sed 's/:/ /g'`)
                set n_eco = `echo $eco | grep "${t}.eco" | wc -w` 
                if ($n_eco > 0) then
                    echo "source -e -v $eco" >> $source_dir/data/$tag/$t.eco
                endif
            end
            cat $source_dir/data/$tag/$t.eco | sort -u > $source_dir/data/$tag/$t.sort.eco
            echo "ECO_NEWCMD = $source_dir/data/$tag/$t.sort.eco" >> override.params
        endif
        echo "# add description"
        set n_description = `grep DESCRIPTION override.params | grep -v "#" | wc -w`
        set description = `grep DESCRIPTION override.params | grep -v "#"`
        if ($n_description == 0) then
            if (-e $source_dir/data/$tag/subject.info) then
                set description = `cat $source_dir/data/$tag/subject.info | sed 's/\[//g' | sed 's/\]//g'`
                set description = "DESCRIPTION = $description"
                set description = "$description $secdir"
                echo $description >> override.params
            endif
        else
            set description = "$description $secdir"
        endif
    
        echo "# print final params"
        cat override.params
        echo "# end print final params"
       
        echo "# print final controls"
        cat override.controls
        echo "# end print final controls"
 
        echo "# start run"
        if ($n_startEnv > 0) then
            if (-e $startEnv) then
                echo "# use start_env $startEnv"
                if ($n_noXterm > 0) then
                    source $startEnv;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished &
                else
                    xterm -e "source $startEnv;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished" &
                endif
            endif
        else
            if (-e $source_dir/script/project/$project/start_env.csh) then
                echo "# use start env $source_dir/script/project/$project/start_env.csh"
                if ($n_noXterm > 0) then
                    source $source_dir/script/project/$project/start_env.csh;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished &
                else
                    xterm -e "source $source_dir/script/project/$project/start_env.csh;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished" &
                endif
            else
                if ($n_noXterm > 0) then
                    source /tools/aticad/1.0/src/sysadmin/cpd.cshrc;setenv FAMILY supra;setprj $project;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished &
                else
                    xterm -e "source /tools/aticad/1.0/src/sysadmin/cpd.cshrc;setenv FAMILY supra;setprj $project;TileBuilderStart --params override.params --controls override.controls >& $source_dir/data/$tag/${t}_${tag}.log;touch ${t}_${tag}.finished" &
                endif
            endif
        endif
        set tb_dir = `pwd`
        set eff_rd = "$eff_rd $tb_dir"
    endif
    cd $source_dir
end

# perform instruction in effective run dir
set tuneCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "tune," | awk -F "," '{print $2}' | sed 's/\r//g'`

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep ^TILES_TO_RUN override.params | grep -v "#" | awk '{print $3}' | sort -u`
    set n_wait = 0
    echo "# Go to TB run $rd for |${t}|"
    while(1)
        set run_dir = `ls -1dlar main/pd/tiles/${t}_*_TileBuilder* | tail -n 1 | awk '{print $9}'`
        set n_run_dir = `echo $run_dir | wc -w`
        echo "# ls: No match # is expected, be patience to wait 10~20 min for TB start $n_run_dir"
        if ($n_run_dir > 0 ) then
            set run_dir = `resolve $run_dir`
            echo "# check $run_dir and wait logs/UpdateTunable.log.gz"
            set sub = `grep NICKNAME override.params | grep -v "#" | awk '{print $3}' | sed 's/_/ /g' | sed 's/sub//g' | awk '{print $2}'`
            set n_sub = `echo $sub | wc -w`
            if ($n_sub > 0) then
                echo "$sub" > $run_dir/$tag.task
            else
                touch $run_dir/$tag.task
            endif

            #if ($n_files > 0) then
            #    set run_dir = `resolve $run_dir`
            #    echo "$t,$run_dir,$tag.$sub.files" >> $source_dir/data/$tag.runDirFiles
            #endif
            cd $run_dir
            set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
            if (-e revrc.main && -e tile.params) then
                TileBuilderTerm -x "serascmd -find_jobs "status==NOTRUN dir=~$curr_dir" --action run" 
            endif
            cd -
        endif
        if (-e $run_dir/logs/UpdateTunable.log.gz) then
            echo "# $run_dir/logs/UpdateTunable.log.gz is available."
            set params_part = `egrep  "DESCRIPTION" $run_dir/tile.params | grep -v "#" | head -n 1`
            set chip_release = `grep CHIP_RELEASE $run_dir/tile.params | grep -v "#"`
            set params_part = "$params_part;$chip_release"
            set fp_pointer = `grep FLOORPLAN_POINTER $run_dir/tile.params | grep -v "#"`
            set params_part = "$params_part;$fp_pointer"
            set run_status = "started"
            set target_run_dir = "${target_run_dir}:$run_dir"
            set reply = "The TB run has been started."
            echo "$t,$run_dir,$params_part" >> $source_dir/data/${tag}_spec
            set n_agent_tune = `ls $source_dir/script/project/$project/tune/*/*.tcl | wc -l`
            echo "# Copy agent tune. $n_agent_tune $project"
            
            if ($n_agent_tune > 0) then
                foreach target_path (`ls -1d $source_dir/script/project/$project/tune/*`) 
                    set target = `echo $target_path | sed 's/\// /g' | awk '{print $NF}'`
                    echo "# $target_path $target"
                    if (-e $run_dir/tune/$target) then
                        foreach tcl_path (`ls $source_dir/script/project/$project/tune/$target/*.tcl`)
                            echo "# copy $tcl_path"
                            set tcl = `echo $tcl_path | sed 's/\// /g' | awk '{print $NF}'`
                            if (-e $run_dir/tune/$target) then
                                if (-e $run_dir/tune/$target/$tcl) then
                                echo "cp -rf $tcl_path  $run_dir/tune/$target/$tcl"
                                    # cat $tcl_path >> $run_dir/tune/$target/$tcl
                                    chmod 766 $run_dir/tune/$target/$tcl
                                    cp -rf $tcl_path $run_dir/tune/$target/$tcl
                                else
                                    echo "cp $tcl_path $run_dir/tune/$target/"
                                    cp $tcl_path $run_dir/tune/$target/
                                endif
                            endif
                        end
                    else
                        echo "cp -rf  $source_dir/script/project/$project/tune/$target $run_dir/tune/"
                        cp -rf  $source_dir/script/project/$project/tune/$target $run_dir/tune/
                    endif
                end
            endif
            if ($n_files > 0) then
                set run_dir = `resolve $run_dir`
                echo "$t,$run_dir,$tag.sub${sub}.files" >> $source_dir/data/$tag.runDirFiles
            endif

            echo "# Copy tune center tune."
            if (-e ${tuneCenter}/${t}) then
                echo "# Found tune in tune Center, copying tune."
                foreach target_path (`ls -1d $tuneCenter/$t/tune/*`)
                    set target = `echo $target_path | sed 's/\// /g' | awk '{print $NF}'`
                    if (-e $run_dir/tune/$target) then
                        foreach tcl_path (`ls $tuneCenter/$t/tune/$target/*.tcl`)
                            set tcl = `echo $tcl_path | sed 's/\// /g' | awk '{print $NF}'`
                            if (-e $run_dir/tune/$target/$tcl) then
                                # cat $tcl_path >> $run_dir/tune/$target/$tcl
                                echo "cp -rf $tcl_path  $run_dir/tune/$target/$tcl"
                                chmod 766 $run_dir/tune/$target/$tcl
                                cp -rf $run_dir/tune/$target/$tcl $run_dir/tune/$target/$tcl.bk
                                cp -rf $tcl_path  $run_dir/tune/$target/$tcl
                            else
                                cp $tcl_path $run_dir/tune/$target/
                            endif
                        end
                    else
                        cp -rf  $tuneCenter/$t/tune/$target $run_dir/tune/
                    endif
                end
            endif

            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 240) then
            set run_status = "failed"
            set logs = ""
            foreach log (`resolve $source_dir/data/$tag/${t}_${tag}_*.log`)
                set logs = "$log $logs"
            end
            echo "$t,$rd, Long time to wait tune. please check TB logs:;$logs" >> $source_dir/data/${tag}_spec
            set target_run_dir = "${target_run_dir}:"            
            break
        endif
        sleep 30
    end
end
echo "# finished start new run."
echo "#table end#" >> $source_dir/data/${tag}_spec
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
