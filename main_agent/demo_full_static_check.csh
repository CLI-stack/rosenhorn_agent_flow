#!/bin/tcsh
# Demo script for full_static_check flow
# Simulates the analysis and email notification flow using existing results

echo "========================================================================"
echo "DEMO: Full Static Check Flow"
echo "========================================================================"

# Set up demo environment
set source_dir = `pwd`
set tag = "demo_`date +%Y%m%d%H%M%S`"
set tile_name = "umc_top"
set ip_name = "umc9_3"
set checktype_name = "full_static_check"
set refdir_name = "/proj/rtg_oss_er_feint1/abinbaba/umc_rosenhorn_Jan19091817"

echo "Tag: $tag"
echo "Tile: $tile_name"
echo "IP: $ip_name"
echo "Refdir: $refdir_name"
echo ""

# Create demo data spec
touch $source_dir/data/${tag}_spec
echo "#text#" > $source_dir/data/${tag}_spec
echo "Demo: Full Static Check Flow" >> $source_dir/data/${tag}_spec
echo "" >> $source_dir/data/${tag}_spec

echo "========================================================================"
echo "Step 1: Simulating Lint Analysis and Notification"
echo "========================================================================"

# Simulate Lint analysis
set checktype_name = "lint"
set temp_lint_spec = "/tmp/${tag}_lint_analysis.tmp"
rm -f $temp_lint_spec

echo "#text#" > $temp_lint_spec
echo "Lint Analysis Results" >> $temp_lint_spec
echo "========================================" >> $temp_lint_spec

# Run actual lint analysis
set lint_report_path = "${refdir_name}/out/linux_3.10.0_64.VCS/umc9_3/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/rhea_lint/leda_waiver.log"

if (-f $lint_report_path) then
    echo "Lint report found: $lint_report_path"
    perl $source_dir/script/rtg_oss_feint/umc/lint_error_extract.pl $lint_report_path $tile_name >> $temp_lint_spec
else
    echo "ERROR: Lint report not found: $lint_report_path" >> $temp_lint_spec
endif

# Send lint notification
echo "Sending Lint notification email..."
set notify_script = "$source_dir/script/rtg_oss_feint/umc/send_static_check_notification.csh"
if (-f $notify_script) then
    $notify_script "$source_dir" "$tag" "$tile_name" "lint" "$temp_lint_spec"
    echo "✓ Lint notification sent"
else
    echo "✗ Notification script not found"
    rm -f $temp_lint_spec
endif

echo ""
echo "========================================================================"
echo "Step 2: Simulating CDC/RDC Analysis and Notification"
echo "========================================================================"

# Simulate CDC/RDC analysis
set checktype_name = "cdc_rdc"
set temp_cdc_spec = "/tmp/${tag}_cdc_rdc_analysis.tmp"
rm -f $temp_cdc_spec

echo "#text#" > $temp_cdc_spec
echo "CDC/RDC Analysis Results" >> $temp_cdc_spec
echo "========================================" >> $temp_cdc_spec

# Run actual CDC/RDC analysis
set cdc_report_path = "${refdir_name}/out/linux_3.10.0_64.VCS/umc9_3/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/cdc_umc_top_output/cdc_report.rpt"
set rdc_report_path = "${refdir_name}/out/linux_3.10.0_64.VCS/umc9_3/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/rdc_umc_top_output/rdc_report.rpt"

if (-f $cdc_report_path && -f $rdc_report_path) then
    echo "CDC report found: $cdc_report_path"
    echo "RDC report found: $rdc_report_path"
    python $source_dir/script/rtg_oss_feint/umc/cdc_rdc_extract_violation.py $cdc_report_path $rdc_report_path $tile_name >> $temp_cdc_spec
else
    echo "ERROR: CDC/RDC reports not found" >> $temp_cdc_spec
endif

# Send CDC/RDC notification
echo "Sending CDC/RDC notification email..."
if (-f $notify_script) then
    $notify_script "$source_dir" "$tag" "$tile_name" "cdc_rdc" "$temp_cdc_spec"
    echo "✓ CDC/RDC notification sent"
else
    echo "✗ Notification script not found"
    rm -f $temp_cdc_spec
endif

echo ""
echo "========================================================================"
echo "Step 3: Simulating Spyglass DFT Analysis and Notification"
echo "========================================================================"

# Simulate Spyglass DFT analysis
set checktype_name = "spg_dft"
set temp_spg_spec = "/tmp/${tag}_spg_dft_analysis.tmp"
rm -f $temp_spg_spec

echo "#text#" > $temp_spg_spec
echo "Spyglass DFT Analysis Results" >> $temp_spg_spec
echo "========================================" >> $temp_spg_spec

# Run actual Spyglass DFT analysis
set spg_report_path = "${refdir_name}/out/linux_3.10.0_64.VCS/umc9_3/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/spg_dft/umc_top/moresimple.rpt"
set error_filter = "$source_dir/script/rtg_oss_feint/umc/spg_dft_error_filter.txt"

if (-f $spg_report_path) then
    echo "Spyglass DFT report found: $spg_report_path"
    perl $source_dir/script/rtg_oss_feint/umc/spg_dft_error_extract.pl $spg_report_path $error_filter $tile_name >> $temp_spg_spec
else
    echo "ERROR: Spyglass DFT report not found: $spg_report_path" >> $temp_spg_spec
endif

# Send Spyglass DFT notification
echo "Sending Spyglass DFT notification email..."
if (-f $notify_script) then
    $notify_script "$source_dir" "$tag" "$tile_name" "spg_dft" "$temp_spg_spec"
    echo "✓ Spyglass DFT notification sent"
else
    echo "✗ Notification script not found"
    rm -f $temp_spg_spec
endif

echo ""
echo "========================================================================"
echo "Step 4: Generating Final Summary"
echo "========================================================================"

# Generate final summary
echo "Running static_check_summary.pl..."
perl $source_dir/script/rtg_oss_feint/umc/static_check_summary.pl $refdir_name $tile_name $error_filter >> $source_dir/data/${tag}_spec

echo "✓ Summary written to data/${tag}_spec"
echo ""
echo "========================================================================"
echo "DEMO COMPLETE"
echo "========================================================================"
echo ""
echo "Results:"
echo "  - Data spec file: $source_dir/data/${tag}_spec"
echo "  - Lint notification HTML: $source_dir/data/${tag}_lint_notify.html"
echo "  - CDC/RDC notification HTML: $source_dir/data/${tag}_cdc_rdc_notify.html"
echo "  - Spyglass DFT notification HTML: $source_dir/data/${tag}_spg_dft_notify.html"
echo ""
echo "To view the final summary:"
echo "  cat $source_dir/data/${tag}_spec"
echo ""
echo "To view notification emails (in browser):"
echo "  firefox $source_dir/data/${tag}_lint_notify.html"
echo "  firefox $source_dir/data/${tag}_cdc_rdc_notify.html"
echo "  firefox $source_dir/data/${tag}_spg_dft_notify.html"
echo ""
echo "========================================================================"
