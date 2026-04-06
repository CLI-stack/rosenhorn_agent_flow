xhost +
source /tools/aticad/1.0/src/sysadmin/cpd.cshrc
setprj magnus
setenv STACK soc_pd
setenv NODE_LIST N3E
setenv USE_NODES N3E
setenv TB_IGNORE_RETIRE_PARAMS 1
setenv TB_UNIX_GROUP_OVERRIDE magnus1
setenv TILEBUILDER_DATATREE_TOSYNC pd_common
# test
