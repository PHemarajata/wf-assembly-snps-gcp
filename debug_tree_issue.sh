#!/bin/bash

# Debug script for tree file publishing issue
# This script helps diagnose why tree files aren't being published

echo "🔍 Tree File Publishing Diagnostic"
echo "=================================="
echo ""

# Check current parameters
echo "📋 Current Configuration:"
echo "  Min tree file size: $(grep 'min_tree_filesize' modules/local/build_phylogenetic_tree_parsnp/params.config)"
echo ""

# Function to convert size units
convert_size() {
    local size="$1"
    if [[ "$size" =~ ^([0-9]+)([ckMG]?)$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        case "$unit" in
            "c"|"") echo "$num" ;;
            "k") echo $((num * 1024)) ;;
            "M") echo $((num * 1024 * 1024)) ;;
            "G") echo $((num * 1024 * 1024 * 1024)) ;;
        esac
    else
        echo "0"
    fi
}

# Test the size check logic
echo "🧪 Testing Size Check Logic:"
min_size="100c"
min_bytes=$(convert_size "$min_size")
your_file_bytes=1330

echo "  Minimum required: $min_size ($min_bytes bytes)"
echo "  Your file size: $your_file_bytes bytes"
echo "  Should pass: $([ $your_file_bytes -gt $min_bytes ] && echo "YES ✅" || echo "NO ❌")"
echo ""

# Check publishing configuration
echo "📤 Publishing Configuration:"
echo "  Pattern: *.tree"
echo "  Output path: \${params.outdir}/\${meta.snp_package}/\${meta.recombination}"
echo "  Mode: \${params.publish_dir_mode}"
echo ""

# Provide troubleshooting steps
echo "🔧 Troubleshooting Steps:"
echo ""
echo "1. Check the actual work directory for your tree building task:"
echo "   find work/ -name 'BUILD_PHYLOGENETIC_TREE_PARSNP*' -type d"
echo ""
echo "2. Look at the command log:"
echo "   cat work/*/BUILD_PHYLOGENETIC_TREE_PARSNP/.command.log"
echo ""
echo "3. Check what files are in the work directory:"
echo "   ls -la work/*/BUILD_PHYLOGENETIC_TREE_PARSNP/"
echo ""
echo "4. Look for QC output:"
echo "   cat work/*/BUILD_PHYLOGENETIC_TREE_PARSNP/*.Tree_Output_File.tsv"
echo ""
echo "5. Check if the file was removed by QC:"
echo "   grep -i 'QC.*FAIL\\|removed\\|too small' work/*/BUILD_PHYLOGENETIC_TREE_PARSNP/.command.log"
echo ""

# Provide potential solutions
echo "💡 Potential Solutions:"
echo ""
echo "If the file is being incorrectly removed:"
echo ""
echo "1. **Lower the minimum size threshold:**"
echo "   Edit modules/local/build_phylogenetic_tree_parsnp/params.config"
echo "   Change: min_tree_filesize = '100c'"
echo "   To:     min_tree_filesize = '50c'"
echo ""
echo "2. **Check for file naming issues:**"
echo "   The script looks for files matching '*.Final.tree'"
echo "   Verify your tree file has the correct name pattern"
echo ""
echo "3. **Disable size check temporarily:**"
echo "   Comment out the QC check in the tree building module"
echo "   to see if the file gets published"
echo ""
echo "4. **Check the find command syntax:**"
echo "   The size check uses: find -L \"\${file}\" -type f -size +\"\${min_size}\""
echo "   This might have issues with the 'c' suffix"
echo ""

echo "🎯 Quick Fix:"
echo "If you want to bypass the size check for now, you can:"
echo "1. Copy the tree file manually from the work directory"
echo "2. Or modify the minimum size to be smaller than your file"
echo ""
echo "Your 1.33kb tree file should be perfectly valid!"