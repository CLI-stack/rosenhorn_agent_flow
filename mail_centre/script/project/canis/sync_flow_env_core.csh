#!/tool/aticad/1.0/bin/tcsh -f
set CHIP_RELEASE = `grep ^CHIP_RELEASE tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
#set PROJECT = `grep -P '^\bPROJECT\b' tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//pg' | tr -d '_er' | tr 'a-z' 'A-Z' | tr -d "\n"`
set PROJECT = `grep -P '^\bPROJECT\b' tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//pg' | tr -d '_er' | tr -d "\n"`
set PERSONALITY = `grep ^PERSONALITY tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
set TILEBUILDER_FREEZEFLOWRELEASE = `grep ^TILEBUILDER_FREEZEFLOWRELEASE tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
set TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL = `grep ^TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
set TILEBUILDER_FREEZESTACKDATARELEASE = `grep ^TILEBUILDER_FREEZESTACKDATARELEASE tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
#set TILEBUILDER_FREEZEPROJECTPARAMS = `grep ^TILEBUILDER_FREEZEPROJECTPARAMS tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
set TILEBUILDER_FREEZEDATARELEASE = `grep ^TILEBUILDER_FREEZEDATARELEASE tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`
set TILEBUILDER_FREEZEPROJDATARELEASE = `grep ^TILEBUILDER_FREEZEPROJDATARELEASE tile.params | awk -F = '{print $NF}' | sed -r -n 's/\s+//gp' | tr -d "\n"`

cd $FLOW_DIR
echo "Syncing flow @${TILEBUILDER_FREEZEFLOWRELEASE}"
p4 sync ...@${TILEBUILDER_FREEZEFLOWRELEASE}
cd -
echo "\n"

cd $ALLTILES_DIR/../../
echo "Syncing data label @${TILEBUILDER_FREEZEDATARELEASE}"
p4 sync ...@${TILEBUILDER_FREEZEDATARELEASE}
cd -
echo "\n"
#cd $FLOW_DIR
#echo "Syncing data label @${TILEBUILDER_FREEZESTACKDATARELEASE}"
#p4 sync @${TILEBUILDER_FREEZESTACKDATARELEASE}
#cd -
#echo "\n"
#cd $ALLTILES_DIR
#echo "Syncing ALLTILES_DIR area"
#p4 sync ...
#cd -
#echo "\n"

#echo "Syncing project params"
#cd $ALLTILES_DIR/params/supra/project/
#p4 sync ...@${TILEBUILDER_FREEZEPROJECTPARAMS}
#cd -
#echo "\n"
#cd $ALLTILES_DIR/params/supra/personality/$PROJECT/
#p4 sync ...@${TILEBUILDER_FREEZEPROJECTPARAMS}
#cd -
#echo "\n"
#cd $ALLTILES_DIR/params/supra/actions/$PROJECT/
#p4 sync ...@${TILEBUILDER_FREEZEPROJECTPARAMS}
#cd -
#echo "\n"
#cd $ALLTILES_DIR/params/supra/project_dft/
#p4 sync ...@${TILEBUILDER_FREEZEPROJECTPARAMS}
#cd -
#echo "\n"
#cd $ALLTILES_DIR/params/supra/tile/mi350xcd/a0/rel_latest/
#p4 sync ...@${TILEBUILDER_FREEZEPROJECTPARAMS}
#cd -
#echo "\n"


cd $ALLTILES_DIR/params/supra/stack/
echo "Syncing stack label @${TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL}"
p4 sync ...@${TILEBUILDER_SEPARATE_STACK_PARAMS_LABEL}
cd -
echo "\n"


##sync data label
##sync stack tune ,//depot/tools/soc/pd/common/tunables
cd tune/stack/
echo "Syncing stack tune label @${TILEBUILDER_FREEZESTACKDATARELEASE}"
p4 sync ...@${TILEBUILDER_FREEZESTACKDATARELEASE}
cd -
echo "\n"




echo "Syncing project tune files @${TILEBUILDER_FREEZEPROJDATARELEASE}"
cd tune/project/
p4 sync ...@${TILEBUILDER_FREEZEPROJDATARELEASE}
cd -
echo "\n"
#echo "Syncing all latest ProjectTune/a0/tune"
#cd $ALLTILES_DIR/ProjectTune/a0/tune
#p4 sync @${TILEBUILDER_FREEZEPROJDATARELEASE}
#cd -
#echo "\n"


#echo "special update"
#cd $ALLTILES_DIR/params/supra/stack/N6/soc_pd/personality
#p4 sync //depot/tools/soc/pd/common/params/N6/TileBuilder/soc_pd/personality/placenroute.params#7
#cd -




#belong to data label . no need update
#echo "Syncing stack files"
#cd tune/stack
#p4 sync ...
#cd -

#echo "Syncing power EM fix"
#cd $ALLTILES_DIR/scripts/tile_flow/project_tune_script/
#p4 sync ...
#cd -
#
#
#cd $ALLTILES_DIR/ProjectTune/a0/tune
#if !(-d EdcCdc) then
#echo "Make dir EdcCdc"
#mkdir EdcCdc;
#endif
#cd -
#cd $ALLTILES_DIR/ProjectTune/a0/tune/EdcCdc
#p4 sync ...
#cd -
#
#
#cd $ALLTILES_DIR/../
#if !(-d nl) then
#echo "Make dir nl"
#mkdir nl;
#endif
#if !(-d nl/prelayout) then
#echo "Make dir nl/prelayout"
#mkdir nl/prelayout
#endif
#if !(-d nl/prelayout/CHIP) then
#echo "Make dir nl/prelayout/CHIP"
#mkdir nl/prelayout/CHIP
#endif
#if !(-d nl/prelayout/CHIP/constraints) then
#echo "Make dir nl/prelayout/CHIP/constraints"
#mkdir nl/prelayout/CHIP/constraints
#endif
#if !(-d nl/prelayout/CHIP/constraints/SpecialTimingChecks) then
#echo "Make dir nl/prelayout/CHIP/constraints/SpecialTimingChecks"
#mkdir nl/prelayout/CHIP/constraints/SpecialTimingChecks
#endif
#cd -
#
#
#
#echo "Sync SpecialTimingChecks scripts"
#cd $ALLTILES_DIR/../nl/prelayout/CHIP/constraints/SpecialTimingChecks
#p4 sync ...
#cd -
