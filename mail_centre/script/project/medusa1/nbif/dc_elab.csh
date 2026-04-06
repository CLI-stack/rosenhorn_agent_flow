source /proj/verif_release_ro/cbwa_initscript/current/cbwa_init.csh
bootenv -v nbif_pavo
lsf_bsub -R "select[type==RHEL7_64] rusage[mem=30000]" -q regr_high -Ip -P sbio-fe dj -v -l dc_elab.log -e 'releaseflow::dropflow(:rtl_drop).build(:rhea_drop,:rhea_dc)'  -DPUBLISH_BLKS=cip_nbif_t+cip_shub_t
