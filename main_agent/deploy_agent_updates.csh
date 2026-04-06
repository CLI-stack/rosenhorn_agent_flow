#!/bin/tcsh
# Agent Flow Deployment Script
# Purpose: Deploy latest agent flow updates from golden path to target directory
# Usage: deploy_agent_updates.csh <target_main_agent_directory>
#
# Example: deploy_agent_updates.csh /proj/user/agent_flow/main_agent

if ($#argv < 1) then
    echo "ERROR: Target directory not specified"
    echo "Usage: deploy_agent_updates.csh <target_main_agent_directory>"
    echo ""
    echo "Example:"
    echo "  deploy_agent_updates.csh /proj/user/agent_flow/main_agent"
    exit 1
endif

set target_dir = $1
set golden_path = "/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent"

# Validate target directory
if (! -d $target_dir) then
    echo "ERROR: Target directory does not exist: $target_dir"
    exit 1
endif

echo "**AGENT FLOW DEPLOYMENT SCRIPT**"
echo "________________________________________________________________________________"
echo ""
echo "Golden Path: $golden_path"
echo "Target Path: $target_dir"
echo ""
echo "Starting deployment..."
echo ""

# Create backup of existing files
set backup_dir = "${target_dir}_backup_`date +%Y%m%d_%H%M%S`"
echo "Creating backup at: $backup_dir"
mkdir -p $backup_dir

# Backup critical files if they exist
if (-f $target_dir/patterns.csv) cp $target_dir/patterns.csv $backup_dir/
if (-f $target_dir/instruction.csv) cp $target_dir/instruction.csv $backup_dir/
if (-f $target_dir/arguement.csv) cp $target_dir/arguement.csv $backup_dir/
if (-f $target_dir/keyword.csv) cp $target_dir/keyword.csv $backup_dir/
if (-f $target_dir/script/vtoHybridModel.py) cp $target_dir/script/vtoHybridModel.py $backup_dir/
if (-f $target_dir/script/genie_cli.py) cp $target_dir/script/genie_cli.py $backup_dir/
if (-f $target_dir/script/genie_env.csh) cp $target_dir/script/genie_env.csh $backup_dir/
if (-d $target_dir/script/rtg_oss_feint) cp -r $target_dir/script/rtg_oss_feint $backup_dir/

echo ""
echo "**STEP 1: Removing Read-Only Permissions from Target Files**"
echo "________________________________________________________________________________"
echo ""

# Change permissions on existing files BEFORE copying to allow overwrite
echo "Updating permissions on existing target files..."

if (-f $target_dir/patterns.csv) then
    chmod 644 $target_dir/patterns.csv
    echo "  ✓ patterns.csv - read-only removed"
endif

if (-f $target_dir/instruction.csv) then
    chmod 644 $target_dir/instruction.csv
    echo "  ✓ instruction.csv - read-only removed"
endif

if (-f $target_dir/arguement.csv) then
    chmod 644 $target_dir/arguement.csv
    echo "  ✓ arguement.csv - read-only removed"
endif

if (-f $target_dir/keyword.csv) then
    chmod 644 $target_dir/keyword.csv
    echo "  ✓ arguement.csv - read-only removed"
endif


if (-f $target_dir/script/vtoHybridModel.py) then
    chmod 644 $target_dir/script/vtoHybridModel.py
    echo "  ✓ vtoHybridModel.py - read-only removed"
endif

if (-f $target_dir/script/genie_cli.py) then
    chmod 644 $target_dir/script/genie_cli.py
    echo "  ✓ genie_cli.py - read-only removed"
endif

if (-f $target_dir/script/genie_env.csh) then
    chmod 755 $target_dir/script/genie_env.csh
    echo "  ✓ genie_env.csh - read-only removed"
endif

if (-d $target_dir/script/rtg_oss_feint) then
    echo "  ✓ Updating permissions on rtg_oss_feint directory..."
    find $target_dir/script/rtg_oss_feint -type f -exec chmod 644 {} \;
    echo "  ✓ rtg_oss_feint - all files writable"
endif

echo ""
echo "**STEP 2: Deploying Configuration Files**"
echo "________________________________________________________________________________"
echo ""

# Copy configuration files
echo "Copying patterns.csv..."
cp $golden_path/patterns.csv $target_dir/
chmod 644 $target_dir/patterns.csv
echo "  ✓ patterns.csv deployed"

echo "Copying instruction.csv..."
cp $golden_path/instruction.csv $target_dir/
chmod 644 $target_dir/instruction.csv
echo "  ✓ instruction.csv deployed"

echo "Copying arguement.csv..."
cp $golden_path/arguement.csv $target_dir/
chmod 644 $target_dir/arguement.csv
echo "  ✓ arguement.csv deployed"

echo "Copying keyword.csv..."
cp $golden_path/keyword.csv $target_dir/
chmod 644 $target_dir/keyword.csv
echo "  ✓ keyword.csv deployed"


echo ""
echo "**STEP 3: Deploying Python Processing Engine**"
echo "________________________________________________________________________________"
echo ""

# Copy Python scripts
echo "Copying vtoHybridModel.py..."
cp $golden_path/script/vtoHybridModel.py $target_dir/script/
chmod 644 $target_dir/script/vtoHybridModel.py
echo "  ✓ vtoHybridModel.py deployed"

echo "Copying genie_cli.py..."
cp $golden_path/script/genie_cli.py $target_dir/script/
chmod 644 $target_dir/script/genie_cli.py
echo "  ✓ genie_cli.py deployed"

echo "Copying genie_env.csh..."
cp $golden_path/script/genie_env.csh $target_dir/script/
chmod 755 $target_dir/script/genie_env.csh
echo "  ✓ genie_env.csh deployed"

echo ""
echo "**STEP 4: Deploying rtg_oss_feint Scripts**"
echo "________________________________________________________________________________"
echo ""

# Remove old rtg_oss_feint directory if exists
if (-d $target_dir/script/rtg_oss_feint) then
    echo "Removing old rtg_oss_feint directory..."
    rm -rf $target_dir/script/rtg_oss_feint
endif

# Copy entire rtg_oss_feint directory
echo "Copying rtg_oss_feint directory..."
cp -r $golden_path/script/rtg_oss_feint $target_dir/script/
echo "  ✓ rtg_oss_feint directory deployed"

echo ""
echo "**STEP 5: Removing tmplongforce from vtoExecution.csh**"
echo "________________________________________________________________________________"
echo ""

# Remove tmplongforce to allow jobs to run longer than 3 days
set vto_exec = "$target_dir/csh/vtoExecution.csh"
if (-f $vto_exec) then
    echo "Checking vtoExecution.csh for tmplongforce..."

    # Check if tmplongforce exists
    set has_tmplongforce = `grep -c "||tmplongforce" $vto_exec`

    if ($has_tmplongforce > 0) then
        echo "  Found tmplongforce in $has_tmplongforce location(s)"
        echo "  Removing tmplongforce to enable unlimited runtime..."

        # Create backup
        cp $vto_exec ${vto_exec}.bak

        # Remove ||tmplongforce from all bsub commands
        sed -i 's/||tmplongforce//g' $vto_exec

        # Verify removal
        set remaining = `grep -c "||tmplongforce" $vto_exec`
        if ($remaining == 0) then
            echo "  ✓ tmplongforce successfully removed from all LSF commands"
            echo "  ✓ Jobs can now run longer than 3 days on regr_high queue"
            rm ${vto_exec}.bak
        else
            echo "  ✗ WARNING: tmplongforce removal incomplete"
            echo "  ✗ Restoring backup..."
            mv ${vto_exec}.bak $vto_exec
        endif
    else
        echo "  ✓ No tmplongforce found (already clean)"
    endif
else
    echo "  ⚠ WARNING: vtoExecution.csh not found at $vto_exec"
endif

echo ""
echo "**STEP 6: Setting Final Permissions**"
echo "________________________________________________________________________________"
echo ""

# Set read/write permissions for all files in rtg_oss_feint
echo "Setting read/write permissions on all files..."
find $target_dir/script/rtg_oss_feint -type f -exec chmod 644 {} \;
echo "  ✓ All files set to read/write (644)"

# Set execute permissions for shell scripts
echo "Setting execute permissions on shell scripts..."
find $target_dir/script/rtg_oss_feint -type f -name "*.csh" -exec chmod 755 {} \;
echo "  ✓ All .csh scripts set to executable (755)"

echo ""
echo "Deployment completed successfully!"
echo "Backup Location: $backup_dir"
echo ""
echo "All files have been deployed with proper read/write permissions."
echo "________________________________________________________________________________"
