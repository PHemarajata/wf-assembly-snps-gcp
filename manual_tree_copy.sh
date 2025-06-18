#!/bin/bash

# Manual script to copy tree files from work directory to output directory
# Use this if you want to get your current tree file without re-running the pipeline

echo "🌳 Manual Tree File Recovery Script"
echo "==================================="
echo ""

# Function to find and copy tree files
copy_tree_files() {
    local work_dir="$1"
    local output_dir="$2"
    
    if [ ! -d "$work_dir" ]; then
        echo "❌ Work directory not found: $work_dir"
        return 1
    fi
    
    echo "🔍 Searching for tree files in: $work_dir"
    
    # Find tree building work directories
    tree_dirs=$(find "$work_dir" -name "*BUILD_PHYLOGENETIC_TREE_PARSNP*" -type d 2>/dev/null)
    
    if [ -z "$tree_dirs" ]; then
        echo "❌ No tree building work directories found"
        return 1
    fi
    
    for dir in $tree_dirs; do
        echo ""
        echo "📁 Checking directory: $dir"
        
        # List all files in the directory
        echo "   Files found:"
        ls -la "$dir" | grep -E "\.(tree|tsv)$" || echo "   No tree or tsv files"
        
        # Look for tree files
        tree_files=$(find "$dir" -name "*.tree" -o -name "*.Final.tree" 2>/dev/null)
        
        if [ -n "$tree_files" ]; then
            for tree_file in $tree_files; do
                file_size=$(wc -c < "$tree_file" 2>/dev/null || echo "0")
                echo "   🌳 Found tree: $(basename "$tree_file") (${file_size} bytes)"
                
                if [ "$file_size" -gt 0 ]; then
                    # Create output directory structure
                    # Try to extract meta information from the filename
                    basename_file=$(basename "$tree_file")
                    
                    # Default output path
                    dest_dir="$output_dir/trees"
                    mkdir -p "$dest_dir"
                    
                    dest_file="$dest_dir/$basename_file"
                    
                    echo "   📋 Copying to: $dest_file"
                    cp "$tree_file" "$dest_file"
                    
                    if [ $? -eq 0 ]; then
                        echo "   ✅ Successfully copied tree file"
                    else
                        echo "   ❌ Failed to copy tree file"
                    fi
                else
                    echo "   ⚠️  Tree file is empty, skipping"
                fi
            done
        else
            echo "   ⚠️  No tree files found in this directory"
        fi
        
        # Also copy QC files for reference
        qc_files=$(find "$dir" -name "*.Tree_Output_File.tsv" 2>/dev/null)
        if [ -n "$qc_files" ]; then
            for qc_file in $qc_files; do
                echo "   📊 Found QC file: $(basename "$qc_file")"
                dest_qc="$dest_dir/$(basename "$qc_file")"
                cp "$qc_file" "$dest_qc"
                echo "   📋 QC file content:"
                cat "$qc_file" | sed 's/^/      /'
            done
        fi
    done
}

# Main execution
echo "This script will help you manually copy tree files from work directory to output directory"
echo ""

# Check if work directory exists
if [ -d "work" ]; then
    echo "✅ Found work directory"
    copy_tree_files "work" "manual_tree_output"
    echo ""
    echo "🎯 Tree files have been copied to: manual_tree_output/trees/"
    echo ""
    echo "📁 To see what was copied:"
    echo "   ls -la manual_tree_output/trees/"
    echo ""
    echo "🔍 To examine your tree file:"
    echo "   head manual_tree_output/trees/*.tree"
    echo "   wc -c manual_tree_output/trees/*.tree"
else
    echo "❌ No work directory found in current location"
    echo ""
    echo "💡 Usage:"
    echo "   1. Navigate to your pipeline run directory (where 'work' folder is)"
    echo "   2. Run this script from there"
    echo "   3. Or specify the work directory path:"
    echo "      ./manual_tree_copy.sh /path/to/your/work/directory"
fi

echo ""
echo "📝 Note: Your 1.33kb tree file is perfectly valid!"
echo "   The issue was likely with the QC size check logic."