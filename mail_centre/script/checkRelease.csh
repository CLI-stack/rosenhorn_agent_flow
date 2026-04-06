set tile_list = "io_cldo_t io_dfx_dualdftio_aid0_t io_dfx_dualdftio_aid1_t io_dfx_dualdftio_aid2_t io_dfx_dualdftio_aid3_t io_dfx_dualdftio_aid4_t io_dfx_dualdftio_aid5_t io_dfx_dualdftio_aid6_t io_el3_avfs_aid_t io_misc_dualdftio_aid0_t io_misc_dualdftio_aid1_t io_pa_gpio18_0_t io_pa_gpio18_1_t io_pa_gpio18_s5_t io_pa_gpio18_smuio_t io_soc_avfs_aid_t io_usr_dcap0_t io_usr_dcap1_t io_xvmin_soc_t nbio_dbgu_nbio_t nbio_dbgu_nbio_t1 nbio_shub_t nbio_shub_t1 nbio_sst_fch_t nbio_sst_fch_t1 dfx_dft_aid_t dfx_dftcnr0_aid_t dfx_dftcnr1_aid_t dfx_dftcnr2_aid_t dfx_dftcnr3_aid_t usb0_phy_t usb0_s0_t usb0_s5_t usb0_vdci_t"
set stage_list = "fp_clean place route reroute"
foreach tile (`echo $tile_list`)
    set release = ""
    foreach stage (`echo $stage_list`)
        if (-e /proj/westelk/a0/tiles/NLBp2/$tile/$stage/release.notes ) then
            set release = "$release yes"
        else 
            set release = "$release no" 
            
        endif
    end
    echo "$tile $release"
end
