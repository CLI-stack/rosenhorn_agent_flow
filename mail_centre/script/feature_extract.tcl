###added margin info in Pt session
set start  ""
set end  ""
set prefix_to_filter "feature_extract_"
set suffix_to_filter ".csv"
set file_list [ls ../../../path_classification_simplified/feature_extract_$corner.csv]
foreach files [split $file_list] {
  set fi [open $files r]
  set fo [open ../../../path_classification_simplified/margin_info_$corner.csv w]
  while {[gets $fi line] > 0} {
    set i  0
    foreach tmpline [split $line ,] {
  
      if {$i == 0} {
        set start  $tmpline
        if {$start == "start"} {
          set early_margin "early_margin"
        } else {
          set early_margin [get_attribute   [get_timing_paths -to $start] slack]
          if {$early_margin == ""} {
            set early_margin 0
          }
        }
      }
      
      if {$i == 1} {
        set end  $tmpline
        if {$end == "end"} {
          set late_margin "late_margin"
        } else {
          set late_margin [get_attribute   [get_timing_paths -from $end] slack]
          if {$late_margin == ""} {
            set late_margin 0
          }
        } 
  
        set output_line "$early_margin,$late_margin"
        puts $fo $output_line
        break
      }
  
      set i [expr $i + 1]
  
    }
  }
  
  close $fi
  close $fo

}
echo "Finished" > ../../../TileBuilderLoadTiming.finished
exit
