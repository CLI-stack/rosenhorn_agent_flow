# Created on Mon Feb 24 14:30:23 2025 @author: Gullipalli Taraka Raja Sekhar tarakarajasekhar.gullipalli@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set i = 1
touch $source_dir/data/${tag}_spec

echo " " >! $source_dir/data/${tag}_spec

set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' `
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' `
set n_refDir_size = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set n_file_size = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`

#Setting the Reference filename.
if ($n_file_size == 0) then 
   set n_file =  $n_refDir/../tiles.list
endif   

if (-e $n_file) then
  set tile_list_exists = 1
else
  set tile_list_exists = 0
endif 
  #echo "tile_list_exists $tile_list_exists" >> $source_dir/data/${tag}_spec
  #echo "tile_list_exists $tile_list_exists"

if (($n_refDir_size > 0) && ($tile_list_exists == 1)) then
  echo "Hi All, " >> $source_dir/data/${tag}_spec
  echo " " >> $source_dir/data/${tag}_spec
  echo "Below Tiles are pending for release, please send the ETA and reason for delay. " >> $source_dir/data/${tag}_spec
  echo " " >> $source_dir/data/${tag}_spec
  echo "--------- Start  --------" >> $source_dir/data/${tag}_spec

  foreach tilename (`cat $n_file`)
      if (-e $n_refDir/$tilename) then
      else
          printf "%-4s %s\n" "$i" "$tilename" >> $source_dir/data/${tag}_spec
          @ i ++
      endif
  end
else 
endif
endif
if (($n_refDir_size > 0) && ($tile_list_exists == 1)) then
  echo "---------- End  ---------" >> $source_dir/data/${tag}_spec
  echo " " >> $source_dir/data/${tag}_spec
  echo "Release Directory : $n_refDir ">> $source_dir/data/${tag}_spec
  echo "Reference Release file $n_file" >> $source_dir/data/${tag}_spec
endif

if ($n_refDir_size == 0) then
  echo "ERROR: SPECIFY THE RELEASE DIRECTORY TO CHECK FOR RELEASED TILES." >> $source_dir/data/${tag}_spec
endif

if ($tile_list_exists == 0) then
  echo "ERROR: Reference TILE list is not specified in Mail and $n_file is not present. Atleast one of them should present" >> $source_dir/data/${tag}_spec
endif

set run_status = "finished"
cd $source_dir
source csh/env.csh --> creating chdir: issues.
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh --> creating hang issue.

