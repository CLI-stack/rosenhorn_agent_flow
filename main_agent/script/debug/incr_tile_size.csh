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

if (-e $target.error.log) then 
    if (-e incr_tile_size.finish) then
    else
        # Regenerate vdci region after shmoo tile size
        if (-e generate_vdci_region.finish) then
            rm generate_vdci_region.finish
        endif
        echo "# Found $target.error.log, start shmoo diesize"
        set new_diesize = `egrep "increase width or hight" $target.error.log | awk '{print $6,$7}'`
        set n_new_diesize = `echo $new_diesize | wc -w`
        if ($n_new_diesize > 0) then
            echo "CHOSEN_COLDSTART = 1" >>  override.params 
            echo "COLDSTART_CORE_SIDE_LENGTH = $new_diesize" >>  override.params
            echo "setCenterCoor" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "source data/incr_width_height_pin.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            # echo "source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/check_fix_offtrack.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            sed -i "/incr_width_height /d" tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            sed -i "/check_vdci_pin/d" tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "move_objects -force -delta {0 0} [get_ports *]" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_vdci_pin.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            if (-e TileBuilderGenParams_incr_diesize) then
                rm TileBuilderGenParams_incr_diesize
            endif
            TileBuilderTerm -x "TileBuilderGenParams;TileBuilderGenParams_incr_diesize"
            set n_wait = 0
            while(1)
                if (-e TileBuilderGenParams_incr_diesize) then
                    touch TileBuilderGenParams_incr_diesize.pass
                    break
                endif
                set n_wait = `expr $n_wait + 1`
                if ($n_wait > 1800) then
                    touch TileBuilderGenParams_incr_diesize.overtime
                    break
                endif
                sleep 1
            end
            source $source_dir/script/rerun_target_core.csh $target
        endif
        touch incr_tile_size.finish
    endif
endif
