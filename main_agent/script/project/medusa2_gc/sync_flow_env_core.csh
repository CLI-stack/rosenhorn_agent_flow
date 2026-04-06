#
set bold = `tput bold`;
set normal = `tput sgr0`;
#
#set flowrelease_label   = `grep "^TILEBUILDER_FREEZEFLOWRELEASE" tile.params | awkk 3`;
#set project_label       = `grep "^TILEBUILDER_FREEZEDATARELEASE" tile.params | awkk 3`;
#set stack_label         = `grep "^TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL" tile.params | awkk 3`;

if ( -e tile.params ) then
    set prj_name = `egrep -w PROJECT tile.params | egrep -v "#" | awkk 3`
    #
    set flowrelease_label   = `grep TILEBUILDER_FREEZEFLOWRELEASE tile.params  | egrep -v "#" | awk '{print $3}'`;
    set project_label       = `grep TILEBUILDER_FREEZEDATARELEASE tile.params  | egrep -v "#" | awk '{print $3}'`;
    set stack_label         = `grep TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL tile.params  | egrep -v "#" | awk '{print $3}'`;
    #
    set crwd = `pwd`
    #
    cd $ALLTILES_DIR
    set project_lbl_sts = `p4 labels | egrep -c $project_label`;
###########################
    if ($project_lbl_sts) then
        echo "[INFO]: syncing ALLTILES_DIR to $project_label ..."
        p4 sync ...@$project_label
    else
        echo "[ERROR]: No such label found with name $project_label. Please check if you have started the run with correct project label.."
    endif
###########################
    cd $ALLTILES_DIR/params/supra/stack
    set stack_lbl_sts = `p4 labels | egrep -c $stack_label`;
    if ($stack_lbl_sts) then
        echo "[INFO]: Syncing Stack Level Params and Controls to $stack_label"
        p4 sync ...@$stack_label
    endif
###########################
    cd $FLOW_DIR
    set flow_lbl_sts = `p4 labels | egrep -c $flowrelease_label`;
    if ($flow_lbl_sts) then
        echo "[INFO]: syncing FLOW_DIR to $flowrelease_label ..."
        p4 sync ...@$flowrelease_label
    endif

    ## Sync TileBuilder tag file
    #cat /tool/aticad/1.0/src/tools/seras/TileBuilder.tagfile | awk '{print "p4 sync "$0}' | csh

###########################
    echo "[INFO]: Syncing tune files"
    cd $crwd/tune/project/
    p4 sync ...@$project_label
    cd $crwd/tune/stack/
    p4 sync ...@$stack_label
    cd $crwd

    # Update Seras
    #TileBuilderUpdateSeras

    #
    echo "DONE syncing for flow label and tune files"
    echo "[INFO] : Please make sure to run ${bold}TileBuilderGenParams${normal} and ${bold}TileBuilderMake${normal}";
    #
    else
        echo "[ERROR]: No such label found with name $label. Please give correct label name.."
        cd $crwd
    endif
else
    echo "[ERROR]: Source this script in run dir"
endif
