echo "# Start to enable user floorplan."
if (-e floorplan.txt) then
    echo "# Already enable user floorplan."
else
    if (-e data/floorplan) then
        set dir = `pwd`
        set cur_dir = `pwd`
        echo "$dir/data/floorplan" > floorplan.txt
        echo "I2_MLPLACE_MACROS = 1" >> override.params
        echo "MLPLACE_USER_FLOORPLAN = $dir/floorplan.txt" >> override.params 
        echo 'FLOORPLAN_VLG = <:=$FLOORPLAN_DIR:>/<:=$TOP_MODULE:>.v.gz' >> override.params
        set target = "FxFpPlaceMacros"
        p4 sync ../../../../TileBuilder/supra/templates/fc_shell/fx_mlmp.tcl
        if (-e enable_user_floorplan_TileBuilderGenParams) then
            rm enable_user_floorplan_TileBuilderGenParams
        endif
        touch enable_user_floorplan_TileBuilderGenParams
        rm enable_user_floorplan_TileBuilderGenParams
        TileBuilderTerm --localterm -x "TileBuilderGenParams;TileBuilderOverwriteCommand cmds/FxFpPlaceMacros.cmd;touch enable_user_floorplan_TileBuilderGenParams" 
        source $source_dir/script/wait_file_finish.csh  enable_user_floorplan_TileBuilderGenParams
        source $source_dir/script/rerun_target_core.csh $target
    endif
endif
