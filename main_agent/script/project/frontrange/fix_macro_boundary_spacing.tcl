source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/proc_pnr.tcl
if {[get_attribute [current_design] name] == "io_dfx_gpio1p8_pcc_i2c_mid_t"} {

    set group_h(0) "io_pwrgd_soc_gpio1p8_0/uPAD_THM_PWRGD io_pwrgd_soc_gpio1p8_0/uPAD_ESD_VREF io_gpio1p8_0/uPAD_ANALOGIO io_dftgpio/uPAD_PINSTRAP_6 io_gpio1p8_0/uPAD_DBREQ_L nbio_pwrbrk_gpio18v_v1p0_dft_gasket_housing/u_GPIO18V_tsmc3ne17m io_dftgpio/uPAD_PINSTRAP_2 io_dftgpio/uPAD_PINSTRAP_4 io_pwrgd_soc_gpio1p8_0/uPAD_GPIO_TRN18_1 io_dftgpio/uPAD_PINSTRAP_7 io_gpio1p8_0/uPAD_TESTEN io_pwrgd_soc_gpio1p8_0/uPAD_GPIO_ESD18_1 nbio_pwrbrk_out_gpio18v_v1p0_dft_gasket_housing/u_GPIO18V_tsmc3ne17m io_dftgpio/uPAD_PINSTRAP_8 io_dftgpio/uPAD_PINSTRAP_9 pa_smuio_pcc0/uPAD_GPIO_PCC0 io_dftgpio/uPAD_PINSTRAP_0 io_dftgpio/uPAD_PINSTRAP_1 pa_smuio_cf_mpifoe_int/uPAD_GPIO_CF_MPIFOE_INT io_pwrgd_soc_gpio1p8_0/uPAD_GPIO_ESD18_0 io_dftgpio/uPAD_PINSTRAP_3 io_pwrgd_soc_gpio1p8_0/uPAD_GPIO_TRN18_0 pa_smuio_cf_mpifoe_i2c_reset/uPAD_GPIO_CF_MPIFOE_I2C_RESET io_dftgpio/uPAD_PINSTRAP_5 pa_smuio_pcc1/uPAD_GPIO_PCC1"
    set group_h(1) "io_pwrgd_soc_i2c_CF/uPAD_I2C_ESD pa_smuio_i2c/uPAD_SMU_I2C1 pa_smuio_i2c/uPAD_SMU_I2C io_pwrgd_soc_i2c_CF/uPAD_I2C_TRN1 io_pwrgd_soc_i2c_CF/uPAD_I2C_TRN0"

    foreach group [array names group_h] {
        puts $group_h($group)
        fixGroupMacroBoundarySpacing $group_h($group)
    }
}

if {[get_attribute [current_design] name] == "cf_secclk_mid_t"} {

    set group_h(0) "clkphyasp/pll_dfs_gf_clkasp/GPUDFS_0 clkphyasp/pll_dfs_gf_clkasp/systempll"

    foreach group [array names group_h] {
        puts $group_h($group)
        fixGroupMacroBoundarySpacing $group_h($group)
    }
}

if {[get_attribute [current_design] name] == "cf_clkc2_mid_t"} {

    set group_h(0) "clkphy4_mid/pll_dfs_gf_clk4_mid/GPUDFS_1 clkphy4_mid/pll_dfs_gf_clk4_mid/GPUDFS_0 clkphy4_mid/pll_dfs_gf_clk4_mid/systempll"

    foreach group [array names group_h] {
        puts $group_h($group)
        fixGroupMacroBoundarySpacing $group_h($group)
    }
}


if {[get_attribute [current_design] name] == "io_dfx_misc_dualdftio0_mid_t"} {
    fixAllMacroBoundarySpacing 
}

if {[get_attribute [current_design] name] == "io_avfs_socio_mid_t"} {
    fixAllMacroBoundarySpacing
}

