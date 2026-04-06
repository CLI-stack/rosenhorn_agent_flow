xhost +
source /tool/aticad/1.0/src/sysadmin/cpd.cshrc
setprj weisshorn
echo $DISPLAY
setenv TB_UNIX_GROUP tsmc7_ip
setenv TB_NORETRACE 1
setenv TILEBUILDER_RELEASE TileBuilder-2024.10
setenv TILEBUILDER_RELEASE_OVERRIDE TileBuilder-2024.10
setenv TAPEOUT_OVERRIDE b0
