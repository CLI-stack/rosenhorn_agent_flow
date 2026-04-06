set A [get_object_name [get_lib_cells -filter "name == HDN6BLVT08_ND2_1 \
                                            || name == HDN6BLVT08_OAI21_V1_1 \ 
                                            || name == HDN6BLVT08_AO2BB2_1 \
                                            || name == HDN6BLVT08_NR4_1 \
                                            || name == HDN6BLVT08_AN2_1 \
                                            || name == HDN6BLVT08_FSDPQ_V2Y2_1 \
                                            || name == HDN6BLVT08_FSDPQ_FTOV2Y2_1 \
                                            || name == HDN6BLVT08_AOI22_1 \
                                            || name == HDN6BLVT08_AO22_1 \
                                            || name == HDN6BLVT08_OAI211_1 \
                                            || name == HDN6BLVT08_ND2_1 \ 
                                            || name == HDN6BLVT08_FSDPQ_V2Y2_8 \
                                            || name == HDN6BLVT08_AN2_2 \ 
                                            || name == HDN6BLVT11_AN2_1 \
                                            || name == HDN6BSVT08_AN2_1 \ " ]]
set_placement_spacing_label -name A -side both -lib_cells [get_lib_cells $A]
set_placement_spacing_rule -labels {A A} {0 2}
